import 'dart:convert';
import 'package:cheat_days/features/auth/domain/user_settings.dart';
import 'package:cheat_days/features/pantry/domain/pantry_item.dart';
import 'package:cheat_days/features/records/domain/meal_record.dart';
import 'package:cheat_days/features/recipes/domain/recipe.dart';
import 'package:cheat_days/features/shopping_list/domain/shopping_item.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class AiSuggestion {
  final String recipeId;
  final String? sideDishId;
  final String messieComment;
  final String reason;

  AiSuggestion({
    required this.recipeId,
    this.sideDishId,
    required this.messieComment,
    required this.reason,
  });
}

class AiService {
  late final GenerativeModel _model;

  AiService() {
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.0-flash',
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  /// Get current season based on month
  String _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return '春';
    if (month >= 6 && month <= 8) return '夏';
    if (month >= 9 && month <= 11) return '秋';
    return '冬';
  }

  /// Get day of week in Japanese
  String _getDayOfWeek() {
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[DateTime.now().weekday - 1];
  }

  Future<AiSuggestion?> suggestMeal({
    required List<Recipe> candidates,
    required UserSettings settings,
    List<MealRecord>? recentMeals,
    List<PantryItem>? pantryItems,
    List<String>? excludedRecipeIds,
    String? feedback,
  }) async {
    if (candidates.isEmpty) return null;

    final candidatesJson =
        candidates
            .map(
              (r) => {
                "id": r.id,
                "name": r.name,
                "ingredients": r.ingredients.map((i) => i.name).toList(),
                "category": r.category,
                "cuisine": r.cuisine,
                "timeMinutes": r.timeMinutes,
                "tags": r.tags,
              },
            )
            .toList();

    final recentMealsText =
        recentMeals != null && recentMeals.isNotEmpty
            ? recentMeals
                .take(10)
                .map((m) => "${m.recipeName} (${m.mealType})")
                .join(', ')
            : 'なし';

    final pantryText =
        pantryItems != null && pantryItems.isNotEmpty
            ? pantryItems
                .where((p) => p.estimatedAmount != 'なし')
                .map((p) => "${p.ingredientName}(${p.estimatedAmount})")
                .join(', ')
            : '不明';

    final prompt = '''
あなたは献立提案アシスタント「メッシー」です。
小型恐竜のキャラで、有能・実用的・ちょっとドライな性格です。
語尾は必ず「〜っシー」にしてください。

## ユーザー情報
- 最近の食事履歴: $recentMealsText
- 苦手な食材: ${settings.dislikedIngredients.isNotEmpty ? settings.dislikedIngredients.join(', ') : 'なし'}
- 冷蔵庫にありそうなもの: $pantryText
- 人数: ${settings.servingSize}人分
- 今日の曜日: ${_getDayOfWeek()}曜日
- 季節: ${_getCurrentSeason()}

${excludedRecipeIds != null && excludedRecipeIds.isNotEmpty ? '## 除外するレシピID\n${excludedRecipeIds.join(", ")}\n' : ''}
${feedback != null ? '## ユーザーのフィードバック\n$feedback\n' : ''}

## レシピ候補（JSON）
${jsonEncode(candidatesJson)}

## タスク
1. 上記のレシピ候補から最適な「主菜（Main）」を1品選んでください
2. その主菜に合う「副菜（Side/Soup）」があれば1品選んでください（なければnull）
3. 選定理由を簡潔に
4. メッシーとしての一言コメント

## 出力形式（JSON）
{
  "selectedRecipeId": "主菜のレシピID",
  "sideDishRecipeId": "副菜のレシピID（またはnull）",
  "reason": "選定理由",
  "messieComment": "コメント"
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) return null;

      String cleanText =
          text.replaceAll(RegExp(r'^```json\s*|```$'), '').trim();
      cleanText = cleanText.replaceAll(RegExp(r'^```\s*|```$'), '').trim();

      final Map<String, dynamic> json = jsonDecode(cleanText);

      return AiSuggestion(
        recipeId: json['selectedRecipeId'],
        sideDishId: json['sideDishRecipeId'],
        messieComment: json['messieComment'],
        reason: json['reason'] ?? '',
      );
    } catch (e) {
      print("AI Error: $e");
      return null;
    }
  }

  Future<RecipeFeedback?> getRecipeFeedback({
    required String recipeName,
    required List<Recipe> availableRecipes,
  }) async {
    final similarRecipesJson =
        availableRecipes
            .take(20)
            .map((r) => {"id": r.id, "name": r.name, "cuisine": r.cuisine})
            .toList();

    final prompt = '''
あなたは献立アシスタント「メッシー」です。
性格: 有能で実用的、でも根は優しい。語尾は「〜っシー」。

ユーザーが「$recipeName」を作りました。

## レシピDB
${jsonEncode(similarRecipesJson)}

## 出力（JSON）
{
  "comment": "短い感想（15文字程度）",
  "similarRecipe": {
    "id": "類似レシピID or null",
    "name": "レシピ名",
    "reason": "一言理由"
  },
  "arrangement": "実用的なアレンジ・豆知識（30文字程度）"
}

## コメントのトーン
- さらっと認める程度はOK（「いいっシー」「おつかれっシー」）
- 確認や質問は禁止（「作った？」「ちゃんとやった？」はNG）
- 過剰なテンションは禁止（「すごすぎるっシー！！」はNG）

## 良い例
- 「いいっシー」「おつかれっシー」「なかなかっシー」
- 「余った分は明日のお弁当にもいけるっシー」
- 「次は味変で柚子胡椒もありっシー」
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) return null;

      String cleanText =
          text.replaceAll(RegExp(r'^```json\s*|```$'), '').trim();
      cleanText = cleanText.replaceAll(RegExp(r'^```\s*|```$'), '').trim();

      final Map<String, dynamic> json = jsonDecode(cleanText);

      return RecipeFeedback(
        comment: json['comment'] ?? '',
        similarRecipeName: json['similarRecipe']?['name'],
        similarRecipeReason: json['similarRecipe']?['reason'],
        arrangement: json['arrangement'] ?? '',
      );
    } catch (e) {
      print("AI Feedback Error: $e");
      return null;
    }
  }

  Future<List<String>> getShoppingSuggestions({
    required List<PantryItem> pantryItems,
    required List<MealRecord> recentMeals,
    required List<ShoppingItem> currentList,
  }) async {
    final lowPantryItems =
        pantryItems
            .where(
              (p) => p.estimatedAmount == 'なし' || p.estimatedAmount == '少し',
            )
            .map((p) => p.ingredientName)
            .toList();

    final currentListNames = currentList.map((i) => i.name).toList();

    final prompt = '''
あなたは献立アシスタント「メッシー」です。
ユーザーの状況に合わせて、買い物リストに追加すべき食材を3つ提案してください。

## ユーザー情報
- 冷蔵庫で少なくなっているもの: ${lowPantryItems.join(', ')}
- 最近作った料理: ${recentMeals.take(5).map((m) => m.recipeName).join(', ')}
- 現在の買い物リスト: ${currentListNames.join(', ')}
- 季節: ${_getCurrentSeason()}

## タスク
1. 冷蔵庫の補充、または最近の傾向から推測して、買うべき食材を3つ挙げてください。
2. すでに買い物リストにあるものは除外してください。

## 出力形式（JSON配列）
["食材A", "食材B", "食材C"]
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) return [];

      String cleanText =
          text.replaceAll(RegExp(r'^```json\s*|```$'), '').trim();
      cleanText = cleanText.replaceAll(RegExp(r'^```\s*|```$'), '').trim();

      final List<dynamic> json = jsonDecode(cleanText);
      return json.map((e) => e.toString()).toList();
    } catch (e) {
      print("Shopping Suggestion Error: $e");
      return [];
    }
  }

  /// Chat with Messie
  /// Returns a text response from Messie
  Future<String> chatWithMessie({
    required String message,
    required UserSettings settings,
    List<MealRecord>? recentMeals,
    List<PantryItem>? pantryItems,
  }) async {
    final recentMealsText =
        recentMeals != null && recentMeals.isNotEmpty
            ? recentMeals.take(5).map((m) => "${m.recipeName}").join(', ')
            : 'なし';

    final pantryText =
        pantryItems != null && pantryItems.isNotEmpty
            ? pantryItems
                .where((p) => p.estimatedAmount != 'なし')
                .map((p) => p.ingredientName)
                .join(', ')
            : '不明';

    final prompt = '''
あなたは献立アシスタント「メッシー」です。
小型恐竜のキャラで、有能・実用的・ちょっとドライ、でも根は優しい性格です。
語尾は必ず「〜っシー」にしてください。

## ユーザー情報
- 最近の食事: $recentMealsText
- 冷蔵庫: $pantryText
- 季節: ${_getCurrentSeason()}

## ユーザーのメッセージ
$message

## タスク
ユーザーのメッセージに対して、メッシーとして返信してください。
- 献立の相談なら、冷蔵庫の中身や最近の食事を考慮してアドバイスしてください。
- 雑談なら、適度にドライに、でも親身に返してください。
- 50文字以内で簡潔に返してください。

## 返信例
- 「その中なら、鶏肉で照り焼きにするのが簡単っシー」
- 「今日は寒いから鍋もいいかもっシー」
- 「了解っシー。無理せず適当にやるっシー」
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      return text?.replaceAll(RegExp(r'\n+'), ' ').trim() ?? 'エラーが発生したっシー';
    } catch (e) {
      print("Chat Error: $e");
      return '通信エラーっシー。もう一度試してほしいっシー';
    }
  }
}

class RecipeFeedback {
  final String comment;
  final String? similarRecipeName;
  final String? similarRecipeReason;
  final String arrangement;

  RecipeFeedback({
    required this.comment,
    this.similarRecipeName,
    this.similarRecipeReason,
    required this.arrangement,
  });
}
