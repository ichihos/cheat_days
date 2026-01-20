import 'dart:convert';
import 'package:cheat_days/features/auth/domain/user_settings.dart';
import 'package:cheat_days/features/recipes/domain/recipe.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class AiSuggestion {
  final String recipeId;
  final String messieComment;
  final String reason;

  AiSuggestion({
    required this.recipeId,
    required this.messieComment,
    required this.reason,
  });
}

class AiService {
  late final GenerativeModel _model;

  AiService() {
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-3-flash-preview',
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  Future<AiSuggestion?> suggestMeal({
    required List<Recipe> candidates,
    required UserSettings settings,
  }) async {
    if (candidates.isEmpty) return null;

    // Simplify recipe data to save tokens and reduce noise
    final candidatesJson =
        candidates
            .map(
              (r) => {
                "id": r.id,
                "name": r.name,
                "ingredients": r.ingredients.map((i) => i.name).toList(),
                "season": r.seasons,
              },
            )
            .toList();

    final prompt = '''
あなたは献立提案アシスタント「メッシー」です。

## ユーザー情報
- 苦手な食材: ${settings.dislikedIngredients}
- 家族人数: ${settings.servingSize}人分

## レシピ候補（JSON）
${jsonEncode(candidatesJson)}

## タスク
1. 上記のレシピ候補から最適な1品を選んでください。
2. 選定理由を簡潔に述べてください。
3. メッシーとしての一言コメント（語尾は「〜っシー」）を作成してください。

## 出力形式（JSON）
{
  "selectedRecipeId": "ID",
  "reason": "選定理由",
  "messieComment": "コメント"
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text == null) return null;

      // Clean markdown code blocks if present
      String cleanText =
          text.replaceAll(RegExp(r'^```json\s*|```$'), '').trim();
      // Sometimes it might just have ``` without json
      cleanText = cleanText.replaceAll(RegExp(r'^```\s*|```$'), '').trim();

      final Map<String, dynamic> json = jsonDecode(cleanText);

      return AiSuggestion(
        recipeId: json['selectedRecipeId'],
        messieComment: json['messieComment'],
        reason: json['reason'] ?? '',
      );
    } catch (e) {
      print("AI Error: $e");
      return null;
    }
  }
}
