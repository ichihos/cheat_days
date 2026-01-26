import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cheat_days/features/auth/domain/user_settings.dart';
import 'package:cheat_days/features/context/domain/user_context.dart';
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

class ShoppingSuggestion {
  final String name;
  final String reason;
  ShoppingSuggestion({required this.name, required this.reason});
}

class AiService {
  late final GenerativeModel _model;
  late final GenerativeModel _textModel; // For plain text responses

  AiService() {
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
    _textModel = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash',
      // No JSON constraint - returns plain text
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
      debugPrint("AI Error: $e");
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
      debugPrint("AI Feedback Error: $e");
      return null;
    }
  }

  Future<List<ShoppingSuggestion>> getRelatedShoppingSuggestions({
    required String addedItemName,
    required List<PantryItem> pantryItems,
    required List<MealRecord> recentMeals,
    required List<ShoppingItem> currentList,
  }) async {
    final currentListNames = currentList.map((i) => i.name).toList();
    final pantryNames = pantryItems
        .where((p) => p.estimatedAmount != 'なし')
        .map((p) => p.ingredientName)
        .join(', ');

    final prompt = '''
あなたは献立アシスタント「メッシー」です。
ユーザーが買い物リストに「$addedItemName」を追加しました。
これに関連して、一緒に買うべき食材を最大3つ提案してください。

## 判断基準
- 一般的に一緒に使われる食材（例：カレールー→じゃがいも、玉ねぎ）
- 最近の食事履歴や冷蔵庫の中身から、消費してしまっていそうなもの
- 季節的に合うもの

## ユーザー情報
- 冷蔵庫にあるもの: $pantryNames
- 現在の買い物リスト: ${currentListNames.join(', ')}
- 季節: ${_getCurrentSeason()}

## 除外基準
- すでに買い物リストにあるもの
- 冷蔵庫に「ある」となっているもの

## 出力形式（JSON配列）
[
  { "name": "提案食材名", "reason": "提案理由（「〜も一緒にどう？」のような短い質問形式）" }
]

## 理由の例
- 「カレー作るなら玉ねぎも減ってない？」
- 「パンなら牛乳も一緒にどう？」
- 「トマト缶あるし、パスタも補充する？」
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) return [];

      String cleanText =
          text.replaceAll(RegExp(r'^```json\s*|```$'), '').trim();
      cleanText = cleanText.replaceAll(RegExp(r'^```\s*|```$'), '').trim();

      final List<dynamic> json = jsonDecode(cleanText);
      return json
          .map(
            (e) => ShoppingSuggestion(
              name: e['name'] as String,
              reason: e['reason'] as String,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint("Related Shopping Suggestion Error: $e");
      return [];
    }
  }

  /// Chat with Messie
  /// Returns a text response from Messie with context-aware suggestions
  Future<String> chatWithMessie({
    required String message,
    required UserSettings settings,
    UserContext? userContext,
    List<MealRecord>? recentMeals,
    List<PantryItem>? pantryItems,
  }) async {
    // Use UserContext if available, otherwise fall back to basic info
    String contextInfo;
    if (userContext != null) {
      contextInfo = userContext.toPromptSummary();
    } else {
      final recentMealsText =
          recentMeals != null && recentMeals.isNotEmpty
              ? recentMeals.take(5).map((m) => m.recipeName).join(', ')
              : 'なし';
      final pantryText =
          pantryItems != null && pantryItems.isNotEmpty
              ? pantryItems
                  .where((p) => p.estimatedAmount != 'なし')
                  .map((p) => p.ingredientName)
                  .join(', ')
              : '不明';
      contextInfo = '''
## 冷蔵庫の状況
- ありそうなもの: $pantryText
- 最近の食事: $recentMealsText
- 季節: ${_getCurrentSeason()}
''';
    }

    final prompt = '''
あなたは献立アシスタント「メッシー」です。
小型恐竜のキャラで、有能・実用的・ちょっとドライ、でも根は優しい性格です。
語尾は必ず「〜っシー」にしてください。

$contextInfo

## ユーザー設定
- 苦手な食材: ${settings.dislikedIngredients.isNotEmpty ? settings.dislikedIngredients.join(', ') : 'なし'}
- 人数: ${settings.servingSize}人分

## ユーザーのメッセージ
$message

## タスク
ユーザーのメッセージに対して、メッシーとして返信してください。

## 重要なルール
- ユーザーが「○○がない」と言った場合、冷蔵庫にある食材で代替案を具体的に提案してください
  例: 「玉ねぎがない」→「白菜を細かめに切って使っても美味しいっシー」
- 代替案は冷蔵庫にありそうなものから選んでください
- 「無理」「厳しい」だけでなく、「こうすればできる」という建設的な提案を
- 60文字以内で簡潔に返してください
- JSONではなく、プレーンテキストで返してください

## 良い返信例
- 「マヨなしでもヨーグルト+酢でタルタル風になるっシー」
- 「玉ねぎないなら、白菜細かく切って入れても甘みが出て美味しいっシー」
- 「鶏肉あるなら照り焼きが簡単っシー。甘辛で白米進むっシー」
''';

    try {
      final response = await _textModel.generateContent([Content.text(prompt)]);
      final text = response.text;
      return text?.replaceAll(RegExp(r'\n+'), ' ').trim() ?? 'エラーが発生したっシー';
    } catch (e) {
      debugPrint("Chat Error: $e");
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
