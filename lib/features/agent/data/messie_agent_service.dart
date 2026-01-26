import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cheat_days/features/agent/domain/messie_action.dart';
import 'package:cheat_days/features/auth/domain/user_settings.dart';
import 'package:cheat_days/features/context/domain/user_context.dart';
import 'package:cheat_days/features/recipes/domain/recipe.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final messieAgentServiceProvider = Provider<MessieAgentService>((ref) {
  return MessieAgentService();
});

/// メッシーAIエージェントサービス
/// ユーザーメッセージを解析し、アクションを決定して実行
class MessieAgentService {
  late final GenerativeModel _model;

  MessieAgentService() {
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  /// ユーザーメッセージを処理し、アクションリストを返す
  Future<MessieAgentResponse> processMessage({
    required String message,
    required UserSettings settings,
    required UserContext? userContext,
    required Recipe? currentSuggestion,
    required List<Recipe> availableRecipes,
    required List<dynamic>
    chatHistory, // Using dynamic to avoid circular import if needed, or better define ChatMessage in domain
  }) async {
    final prompt = _buildAgentPrompt(
      message: message,
      settings: settings,
      userContext: userContext,
      currentSuggestion: currentSuggestion,
      availableRecipes: availableRecipes,
      chatHistory: chatHistory,
    );

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text == null) {
        return MessieAgentResponse(
          actions: [
            const MessieAction(
              type: MessieActionType.reply,
              message: 'エラーが発生したっシー',
            ),
          ],
        );
      }

      return _parseResponse(text);
    } catch (e) {
      debugPrint('MessieAgent Error: $e');
      return MessieAgentResponse(
        actions: [
          const MessieAction(
            type: MessieActionType.reply,
            message: '通信エラーっシー。もう一度試してほしいっシー',
          ),
        ],
      );
    }
  }

  String _buildAgentPrompt({
    required String message,
    required UserSettings settings,
    required UserContext? userContext,
    required Recipe? currentSuggestion,
    required List<Recipe> availableRecipes,
    required List<dynamic> chatHistory,
  }) {
    final contextInfo = userContext?.toPromptSummary() ?? '冷蔵庫情報なし';

    final currentRecipeInfo =
        currentSuggestion != null
            ? '''
現在の提案レシピ:
- ID: ${currentSuggestion.id}
- 名前: ${currentSuggestion.name}
- カテゴリ: ${currentSuggestion.category}
- 調理時間: ${currentSuggestion.timeMinutes}分
- 材料: ${currentSuggestion.ingredients.map((i) => i.name).join(', ')}
'''
            : '提案レシピなし';

    final alternativeRecipes = availableRecipes
        .where((r) => r.id != currentSuggestion?.id)
        .take(5)
        .map((r) => '${r.id}: ${r.name} (${r.timeMinutes}分)')
        .join('\n');

    // Format last 10 messages for context
    final historyStr = chatHistory
        .take(10) // Limit context window
        .map((msg) {
          // msg is expected to have 'text' and 'isUser'
          // We'll handle the dynamic type safely
          try {
            final isUser = (msg as dynamic).isUser as bool;
            final text = msg.text as String;
            return isUser ? "User: $text" : "Messie: $text";
          } catch (_) {
            return "";
          }
        })
        .where((s) => s.isNotEmpty)
        .join('\n');

    return '''
あなたは献立アシスタント「メッシー」です。
小型恐竜のキャラで、有能・実用的・ちょっとドライ、でも根は優しい性格です。

## ユーザー情報
- 人数: ${settings.servingSize}人分
- 苦手な食材: ${settings.dislikedIngredients.isNotEmpty ? settings.dislikedIngredients.join(', ') : 'なし'}

$contextInfo

$currentRecipeInfo

## 代替レシピ候補（現在の提案以外）
$alternativeRecipes

## 会話履歴
$historyStr

## 今のユーザーのメッセージ
$message

## 利用可能なアクション

### reply
ユーザーへの返答（必ず含める）
data: { "message": "返答テキスト（語尾は必ず「〜っシー」）" }

### change_suggestion
提案メニューを別のものに変更
data: { 
  "recipeId": "新しいレシピID（現在のID${currentSuggestion?.id ?? ''}以外から選択）", 
  "reason": "変更理由" 
}
**重要**: 変更時は、理由だけでなく「〜ならどうっシー？白ごはんと合わせれば最高！」のように、魅力を伝える具体的なコメントをreplyに含めてください。

### adjust_recipe
現在のレシピを調整（**食材不足時はこれを最優先**）
data: { 
  "adjustments": [
    { "type": "scale", "scale": 0.5 },
    { "type": "substitute", "target": "玉ねぎ", "replacement": "白菜" },
    { "type": "remove", "target": "マヨネーズ" }
  ]
}
**重要**: ユーザーが「〇〇がない」と言った場合は、買い物リストに追加するのではなく、まず`substitute`（代替）か`remove`（削除）で対応してください。「それなら〇〇で代用できるっシー！」と提案してください。

### add_to_shopping
買い物リストにアイテム追加（**ユーザーが明示的に「買って」と言った場合のみ**）
data: { "items": ["鶏肉", "玉ねぎ", "卵"] }
**重要**: 食材がないと言われただけでは追加しないでください。まずは`adjust_recipe`で対応できないか検討してください。

### record_meal
料理を記録
data: { "recipeId": "レシピID", "mealType": "dinner" }

### generate_recipe
既存のレシピに適切なものがない場合、新しいレシピを考案する
data: {
  "name": "ホッキ貝の旨煮",
  "reason": "ホッキ貝と酒に合うつまみがないため",
  "timeMinutes": 15,
  "ingredients": [
    { "name": "ホッキ貝", "amount": "4個", "unit": "個", "isMain": true },
    { "name": "酒", "amount": "大さじ2", "unit": "大さじ", "isMain": false },
    { "name": "醤油", "amount": "大さじ1", "unit": "大さじ", "isMain": false },
    { "name": "みりん", "amount": "大さじ1", "unit": "大さじ", "isMain": false },
    { "name": "生姜", "amount": "1片", "unit": "片", "isMain": false }
  ],
  "steps": [
    "ホッキ貝は身を外して洗う",
    "鍋に調味料と生姜を入れて煮立たせる",
    "ホッキ貝を入れてさっと煮る"
  ]
}
**重要**: 冷蔵庫にあるものやユーザーの要望に合わせて、**既存のレシピプールにない場合のみ**使用してください。

### update_fridge
冷蔵庫の食材情報を更新
data: { 
  "updates": [
    { "ingredient": "玉ねぎ", "status": "has" },
    { "ingredient": "牛乳", "status": "none" }
  ]
}

## 出力形式（JSON）
{
  "actions": [
    { "type": "アクション名", "data": {...} },
    { "type": "reply", "data": { "message": "返答" } }
  ]
}

## ルール
1. 必ず最後にreplyアクションを含める
2. 複数アクションを同時実行可能
3. 返答は60文字以内で簡潔に
4. **語尾は必ず「〜っシー」**（「っス」は禁止）
5. アクション実行時は何をしたか説明
6. **change_suggestionの場合**
   - 必ず現在のレシピと異なるIDを選んでください。
   - replyメッセージで「それなら〇〇はどうっシー？〜が美味しいっシー！」と具体的に提案してください。
''';
  }

  MessieAgentResponse _parseResponse(String rawText) {
    try {
      // Clean up JSON
      String cleanText =
          rawText
              .replaceAll(RegExp(r'^```json\s*'), '')
              .replaceAll(RegExp(r'```$'), '')
              .trim();

      final json = jsonDecode(cleanText) as Map<String, dynamic>;
      final actionsJson = json['actions'] as List<dynamic>? ?? [];

      final actions =
          actionsJson.map((actionJson) {
            final actionMap = actionJson as Map<String, dynamic>;
            final type = actionMap['type'] as String? ?? 'reply';
            final data = actionMap['data'] as Map<String, dynamic>? ?? {};

            // Extract message from data for reply type
            String? message;
            if (type == 'reply' && data.containsKey('message')) {
              message = data['message'] as String?;
            }

            MessieActionType actionType;
            switch (type) {
              case 'change_suggestion':
                actionType = MessieActionType.changeSuggestion;
                break;
              case 'generate_recipe':
                actionType = MessieActionType.generateRecipe;
                break;
              case 'adjust_recipe':
                actionType = MessieActionType.adjustRecipe;
                break;
              case 'add_to_shopping':
                actionType = MessieActionType.addToShopping;
                break;
              case 'record_meal':
                actionType = MessieActionType.recordMeal;
                break;
              case 'update_fridge':
                actionType = MessieActionType.updateFridge;
                break;
              default:
                actionType = MessieActionType.reply;
            }

            return MessieAction(type: actionType, message: message, data: data);
          }).toList();

      // Ensure there's at least a reply action
      if (!actions.any((a) => a.type == MessieActionType.reply)) {
        actions.add(
          const MessieAction(type: MessieActionType.reply, message: '了解っシー'),
        );
      }

      return MessieAgentResponse(actions: actions, rawResponse: rawText);
    } catch (e) {
      debugPrint('Parse error: $e, raw: $rawText');
      return MessieAgentResponse(
        actions: [
          const MessieAction(
            type: MessieActionType.reply,
            message: '処理中にエラーが発生したっシー',
          ),
        ],
        rawResponse: rawText,
      );
    }
  }
}
