import 'dart:convert' show jsonDecode;
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:cheat_days/features/recipes/domain/recipe.dart';
import 'package:cheat_days/features/recipes/data/recipe_repository.dart';

final adminAiServiceProvider = Provider<AdminAiService>((ref) {
  return AdminAiService(ref);
});

/// AIレシピ生成の進捗状態
class RecipeGenerationProgress {
  final int total;
  final int completed;
  final String currentTask;
  final List<GeneratedRecipeResult> results;

  RecipeGenerationProgress({
    required this.total,
    required this.completed,
    required this.currentTask,
    this.results = const [],
  });

  double get progress => total > 0 ? completed / total : 0;
}

/// 生成されたレシピの結果
class GeneratedRecipeResult {
  final String name;
  final bool success;
  final String? error;
  final Recipe? recipe;

  GeneratedRecipeResult({
    required this.name,
    required this.success,
    this.error,
    this.recipe,
  });
}

/// 管理者用AIサービス
/// レシピ生成と画像生成を統合
class AdminAiService {
  final Ref _ref;
  late final GenerativeModel _recipeModel;
  late final ImagenModel _imagenModel;

  AdminAiService(this._ref) {
    final vertexAI = FirebaseAI.vertexAI(location: 'global');

    // レシピ生成用モデル（JSON出力）
    _recipeModel = vertexAI.generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    // 画像生成用モデル（Imagen 3.0 - Gemini WebはResponseModalitiesにバグあり）
    _imagenModel = vertexAI.imagenModel(
      model: 'imagen-3.0-generate-002',
    );
  }

  /// レシピ名のリストからレシピデータを生成
  Future<Map<String, dynamic>> generateRecipeData(String recipeName) async {
    final prompt = '''
あなたは日本の家庭料理のレシピ作成エキスパートです。
「$recipeName」のレシピをJSON形式で作成してください。

## 出力形式
{
  "name": "レシピ名",
  "category": "main|side|soup|rice|noodle|salad|dessert",
  "cuisine": "japanese|western|chinese|korean|other",
  "timeMinutes": 調理時間（分）,
  "costYen": 概算コスト（円）,
  "difficulty": 1-3の難易度,
  "calories": カロリー（kcal）,
  "seasons": ["春", "夏", "秋", "冬"]のうち適切なもの,
  "tags": ["タグ1", "タグ2"],
  "ingredients": [
    {"name": "材料名", "amount": "分量", "unit": "単位", "isMain": true/false}
  ],
  "steps": [
    "手順1",
    "手順2"
  ]
}

## ルール
- 2人分の分量で記載
- 材料は一般的なスーパーで手に入るもの
- 手順は簡潔かつ具体的に
- 調理時間は下ごしらえ含む
- isMainは主要な材料のみtrue（最大3つ）
''';

    try {
      final response = await _recipeModel.generateContent([
        Content.text(prompt),
      ]);
      final text = response.text;
      if (text == null) throw Exception('Empty response from AI');

      String cleanText =
          text
              .replaceAll(RegExp(r'^```json\s*'), '')
              .replaceAll(RegExp(r'```$'), '')
              .trim();

      return jsonDecode(cleanText) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Recipe generation error: $e');
      rethrow;
    }
  }

  /// イラスト風画像を生成（Imagen 3.0使用）
  Future<Uint8List?> generateRecipeImage(String recipeName) async {
    final prompt =
        'A beautiful watercolor illustration of "$recipeName" Japanese dish. '
        'Warm appetizing style, soft hand-drawn aesthetic with visible brush strokes. '
        'Dish centered on warm cream background like aged paper. '
        'Traditional Japanese ceramic bowl presentation. '
        'Soft shadows, inviting and delicious appearance. No text or labels.';

    try {
      final response = await _imagenModel.generateImages(prompt);

      // 画像データを取得
      if (response.images.isNotEmpty) {
        return response.images.first.bytesBase64Encoded;
      }

      return null;
    } catch (e) {
      debugPrint('Image generation error: $e');
      return null;
    }
  }

  /// 画像をFirebase Storageにアップロード
  Future<String> uploadImage(Uint8List imageData, String recipeName) async {
    final fileName =
        'recipes/${const Uuid().v4()}_${_sanitizeFileName(recipeName)}.png';
    final ref = FirebaseStorage.instance.ref().child(fileName);

    await ref.putData(imageData, SettableMetadata(contentType: 'image/png'));

    return await ref.getDownloadURL();
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  /// レシピを完全に生成（データ＋画像＋DB保存）
  Future<Recipe> generateCompleteRecipe(
    String recipeName, {
    void Function(String status)? onStatusUpdate,
  }) async {
    onStatusUpdate?.call('レシピデータを生成中...');

    // 1. レシピデータを生成
    final recipeData = await generateRecipeData(recipeName);

    onStatusUpdate?.call('イラスト画像を生成中...');

    // 2. 画像を生成
    String imageUrl = '';
    final imageBytes = await generateRecipeImage(recipeName);
    if (imageBytes != null) {
      onStatusUpdate?.call('画像をアップロード中...');
      imageUrl = await uploadImage(imageBytes, recipeName);
    }

    onStatusUpdate?.call('データベースに保存中...');

    // 3. Recipeオブジェクトを作成
    final recipe = Recipe(
      id: const Uuid().v4(),
      name: recipeData['name'] ?? recipeName,
      imageUrl: imageUrl,
      category: recipeData['category'] ?? 'main',
      cuisine: recipeData['cuisine'] ?? 'japanese',
      timeMinutes: recipeData['timeMinutes'] ?? 30,
      costYen: recipeData['costYen'] ?? 500,
      difficulty: recipeData['difficulty'] ?? 1,
      seasons: List<String>.from(recipeData['seasons'] ?? []),
      calories: recipeData['calories'],
      ingredients:
          (recipeData['ingredients'] as List<dynamic>?)
              ?.map(
                (i) => Ingredient(
                  name: i['name'] ?? '',
                  amount: i['amount']?.toString() ?? '',
                  unit: i['unit'] ?? '',
                  isMain: i['isMain'] ?? false,
                ),
              )
              .toList() ??
          [],
      steps: List<String>.from(recipeData['steps'] ?? []),
      tags: List<String>.from(recipeData['tags'] ?? []),
      createdAt: DateTime.now(),
    );

    // 4. Firestoreに保存
    await _ref.read(recipeRepositoryProvider).saveRecipe(recipe);

    return recipe;
  }

  /// 複数レシピを一括生成
  Stream<RecipeGenerationProgress> generateMultipleRecipes(
    List<String> recipeNames,
  ) async* {
    final results = <GeneratedRecipeResult>[];
    final total = recipeNames.length;

    for (int i = 0; i < recipeNames.length; i++) {
      final name = recipeNames[i];

      yield RecipeGenerationProgress(
        total: total,
        completed: i,
        currentTask: '「$name」を生成中... (${i + 1}/$total)',
        results: List.from(results),
      );

      try {
        final recipe = await generateCompleteRecipe(name);
        results.add(
          GeneratedRecipeResult(name: name, success: true, recipe: recipe),
        );
      } catch (e) {
        results.add(
          GeneratedRecipeResult(
            name: name,
            success: false,
            error: e.toString(),
          ),
        );
      }

      // レート制限対策で少し待機
      await Future.delayed(const Duration(seconds: 2));
    }

    yield RecipeGenerationProgress(
      total: total,
      completed: total,
      currentTask: '完了',
      results: results,
    );
  }
}
