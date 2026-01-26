import 'package:cheat_days/features/agent/data/messie_agent_service.dart';
import 'package:cheat_days/features/agent/domain/messie_action.dart';
import 'package:cheat_days/features/auth/repository/auth_repository.dart';
import 'package:cheat_days/features/auth/data/user_repository.dart';
import 'package:cheat_days/features/auth/domain/user_settings.dart';
import 'package:cheat_days/features/context/data/user_context_provider.dart';
import 'package:cheat_days/features/recipes/data/recipe_repository.dart';
import 'package:cheat_days/features/recipes/domain/recipe.dart';
import 'package:cheat_days/features/records/data/meal_record_repository.dart';
import 'package:cheat_days/features/records/domain/meal_record.dart';
import 'package:cheat_days/features/shopping_list/data/shopping_list_repository.dart';
import 'package:cheat_days/features/shopping_list/domain/shopping_item.dart';
import 'package:cheat_days/features/pantry/data/pantry_repository.dart';
import 'package:cheat_days/features/pantry/domain/pantry_item.dart';
import 'package:cheat_days/features/recipes/presentation/daily_suggestion_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// チャットメッセージモデル
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

/// エージェント状態
class MessieAgentState {
  final Recipe? currentSuggestion;
  final Recipe? sideDish;
  final Map<String, dynamic>? recipeAdjustments;
  final bool isProcessing;
  final String? lastMessage;
  final List<MessieAction> recentActions;
  final List<ChatMessage> chatHistory;

  const MessieAgentState({
    this.currentSuggestion,
    this.sideDish,
    this.recipeAdjustments,
    this.isProcessing = false,
    this.lastMessage,
    this.recentActions = const [],
    this.chatHistory = const [],
  });

  MessieAgentState copyWith({
    Recipe? currentSuggestion,
    Recipe? sideDish,
    Map<String, dynamic>? recipeAdjustments,
    bool? isProcessing,
    String? lastMessage,
    List<MessieAction>? recentActions,
    List<ChatMessage>? chatHistory,
  }) {
    return MessieAgentState(
      currentSuggestion: currentSuggestion ?? this.currentSuggestion,
      sideDish: sideDish ?? this.sideDish,
      recipeAdjustments: recipeAdjustments ?? this.recipeAdjustments,
      isProcessing: isProcessing ?? this.isProcessing,
      lastMessage: lastMessage ?? this.lastMessage,
      recentActions: recentActions ?? this.recentActions,
      chatHistory: chatHistory ?? this.chatHistory,
    );
  }
}

/// エージェントNotifier
class MessieAgentNotifier extends StateNotifier<MessieAgentState> {
  final Ref _ref;

  MessieAgentNotifier(this._ref) : super(const MessieAgentState());

  /// 初期提案を設定
  void setSuggestion(Recipe? main, Recipe? side) {
    state = state.copyWith(
      currentSuggestion: main,
      sideDish: side,
      recipeAdjustments: null,
    );
  }

  /// DailySuggestionStateと同期
  void syncWithDailySuggestion(DailySuggestionState dailyState) {
    if (dailyState.recipe != null &&
        dailyState.recipe!.id != state.currentSuggestion?.id) {
      final initialComment = dailyState.messieComment;
      List<ChatMessage> newHistory = [];
      if (initialComment != null) {
        newHistory.add(ChatMessage(text: initialComment, isUser: false));
      }

      state = state.copyWith(
        currentSuggestion: dailyState.recipe,
        sideDish: dailyState.sideDish,
        recipeAdjustments: null,
        chatHistory: newHistory,
        lastMessage: initialComment,
      );
    }
  }

  /// ユーザーメッセージを処理
  Future<String> processUserMessage(String message) async {
    final updatedHistory = List<ChatMessage>.from(state.chatHistory)
      ..add(ChatMessage(text: message, isUser: true));

    state = state.copyWith(isProcessing: true, chatHistory: updatedHistory);

    try {
      final settings = await _ref.read(userSettingsProvider.future);
      final userContext = await _ref.read(userContextProvider.future);
      final recipes = await _ref.read(recipeRepositoryProvider).getAllRecipes();

      final agentService = _ref.read(messieAgentServiceProvider);
      final response = await agentService.processMessage(
        message: message,
        settings: settings,
        userContext: userContext,
        currentSuggestion: state.currentSuggestion,
        availableRecipes: recipes,
        chatHistory:
            state
                .chatHistory, // Pass history (excluding current message which is added separately in prompt but useful to verify)
      );

      for (final action in response.actions) {
        await _executeAction(action, recipes);
      }

      final updatedHistoryWithReply = List<ChatMessage>.from(state.chatHistory)
        ..add(ChatMessage(text: response.replyMessage, isUser: false));

      state = state.copyWith(
        isProcessing: false,
        lastMessage: response.replyMessage,
        recentActions: response.actions,
        chatHistory: updatedHistoryWithReply,
      );

      return response.replyMessage;
    } catch (e) {
      final errorHistory = List<ChatMessage>.from(state.chatHistory)
        ..add(ChatMessage(text: '処理中にエラーが発生したっシー: $e', isUser: false));

      state = state.copyWith(isProcessing: false, chatHistory: errorHistory);
      return '処理中にエラーが発生したっシー: $e';
    }
  }

  /// アクションを実行
  Future<void> _executeAction(MessieAction action, List<Recipe> recipes) async {
    switch (action.type) {
      case MessieActionType.changeSuggestion:
        await _handleChangeSuggestion(action, recipes);
        break;
      case MessieActionType.adjustRecipe:
        _handleAdjustRecipe(action);
        break;
      case MessieActionType.addToShopping:
        await _handleAddToShopping(action);
        break;
      case MessieActionType.recordMeal:
        await _handleRecordMeal(action);
        break;
      case MessieActionType.updateFridge:
        await _handleUpdateFridge(action);
        break;
      case MessieActionType.generateRecipe:
        await _handleGenerateRecipe(action);
        break;
      case MessieActionType.reply:
        break;
    }
  }

  /// レシピ生成を処理
  Future<void> _handleGenerateRecipe(MessieAction action) async {
    final name = action.data['name'] as String?;
    final ingredientsList = action.data['ingredients'] as List<dynamic>?;
    final stepsList = action.data['steps'] as List<dynamic>?;
    final timeMinutes = action.data['timeMinutes'] as int? ?? 15;

    if (name == null || ingredientsList == null || stepsList == null) return;

    // Convert ingredients
    final ingredients =
        ingredientsList.map((i) {
          final map = i as Map<String, dynamic>;
          return Ingredient(
            name: map['name'] ?? '',
            amount: map['amount'] ?? '',
            unit: map['unit'] ?? '',
            isMain: map['isMain'] ?? false,
          );
        }).toList();

    // Convert steps
    final steps = stepsList.map((s) => s.toString()).toList();

    // Create a temporary Recipe object
    // Use a unique ID prefixed with 'generated_'
    final generatedRecipe = Recipe(
      id: 'generated_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      imageUrl: '', // No image for generated recipe
      category: 'main', // Default to main
      cuisine: 'other', // Default
      timeMinutes: timeMinutes,
      costYen: 0, // Unknown
      difficulty: 2, // Medium default
      seasons: [],
      ingredients: ingredients,
      steps: steps,
      tags: ['AI考案'],
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      currentSuggestion: generatedRecipe,
      recipeAdjustments: null,
    );
  }

  /// 提案変更
  Future<void> _handleChangeSuggestion(
    MessieAction action,
    List<Recipe> recipes,
  ) async {
    final recipeId = action.data['recipeId'] as String?;
    if (recipeId == null) return;

    final newRecipe = recipes.where((r) => r.id == recipeId).firstOrNull;
    if (newRecipe != null) {
      state = state.copyWith(
        currentSuggestion: newRecipe,
        recipeAdjustments: null,
      );
    }
  }

  /// レシピ調整
  void _handleAdjustRecipe(MessieAction action) {
    final adjustmentsData = action.data['adjustments'] as List<dynamic>?;
    if (adjustmentsData == null) return;

    final currentRecipe = state.currentSuggestion;
    if (currentRecipe == null) return;

    List<Ingredient> newIngredients = List.from(currentRecipe.ingredients);

    final adjustments =
        adjustmentsData
            .map((a) => RecipeAdjustment.fromJson(a as Map<String, dynamic>))
            .toList();

    for (final adjustment in adjustments) {
      switch (adjustment.type) {
        case 'scale':
          if (adjustment.scale != null) {
            newIngredients =
                newIngredients.map((i) {
                  final amountNum = double.tryParse(i.amount);
                  if (amountNum != null) {
                    final newAmount = (amountNum * adjustment.scale!)
                        .toStringAsFixed(1)
                        .replaceFirst(RegExp(r'\.0$'), '');
                    return i.copyWith(amount: newAmount);
                  }
                  return i;
                }).toList();
          }
          break;
        case 'substitute':
          if (adjustment.replacement != null) {
            newIngredients =
                newIngredients.map((i) {
                  if (i.name.contains(adjustment.target)) {
                    return i.copyWith(name: adjustment.replacement!);
                  }
                  return i;
                }).toList();
          }
          break;
        case 'remove':
          newIngredients.removeWhere((i) => i.name.contains(adjustment.target));
          break;
      }
    }

    final adjustedRecipe = currentRecipe.copyWith(
      ingredients: newIngredients,
      name: '${currentRecipe.name} (調整済み)',
    );

    state = state.copyWith(
      currentSuggestion: adjustedRecipe,
      recipeAdjustments: {'adjustments': adjustmentsData},
    );
  }

  /// 冷蔵庫状況を更新
  Future<void> _handleUpdateFridge(MessieAction action) async {
    final updates = action.data['updates'] as List<dynamic>?;
    if (updates == null) return;

    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final pantryRepo = _ref.read(pantryRepositoryProvider);
    final currentPantry = await pantryRepo.getPantryItems(user.uid);

    for (final update in updates) {
      final map = update as Map<String, dynamic>;
      final ingredientName = map['ingredient'] as String?;
      final status = map['status'] as String?; // has, none, etc

      if (ingredientName == null || status == null) continue;

      String estimatedAmount;
      if (status == 'has' || status == 'ある') {
        estimatedAmount = 'ある';
      } else if (status == 'none' || status == 'なし') {
        estimatedAmount = 'なし';
      } else if (status == 'little' || status == '少し') {
        estimatedAmount = '少し';
      } else {
        estimatedAmount = 'ある'; // Default
      }

      final existingItem =
          currentPantry
              .where((i) => i.ingredientName == ingredientName)
              .firstOrNull;

      if (estimatedAmount == 'なし') {
        if (existingItem != null) {
          await pantryRepo.updateItem(
            user.uid,
            existingItem.copyWith(
              estimatedAmount: 'なし',
              lastUsed: DateTime.now(), // Mark as used up
            ),
          );
        }
      } else {
        if (existingItem != null) {
          await pantryRepo.updateItem(
            user.uid,
            existingItem.copyWith(
              estimatedAmount: estimatedAmount,
              lastPurchased:
                  estimatedAmount == 'ある'
                      ? DateTime.now()
                      : existingItem.lastPurchased,
            ),
          );
        } else {
          await pantryRepo.addItem(
            user.uid,
            PantryItem(
              id: '', // Generated
              ingredientName: ingredientName,
              estimatedAmount: estimatedAmount,
              lastPurchased: DateTime.now(),
            ),
          );
        }
      }
    }
    _ref.invalidate(userContextProvider);
  }

  /// 買い物リストに追加
  Future<void> _handleAddToShopping(MessieAction action) async {
    final items = action.data['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return;

    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final shoppingRepo = _ref.read(shoppingListRepositoryProvider);
    for (final item in items) {
      await shoppingRepo.addItem(
        user.uid,
        ShoppingItem(
          id: '',
          name: item.toString(),
          isAiSuggested: true,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  /// 料理記録
  Future<void> _handleRecordMeal(MessieAction action) async {
    final recipeId = action.data['recipeId'] as String?;
    final mealType = action.data['mealType'] as String? ?? 'dinner';

    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final recipe = state.currentSuggestion;
    if (recipe == null) return;

    await _ref
        .read(mealRecordRepositoryProvider)
        .addRecord(
          user.uid,
          MealRecord(
            id: '',
            recipeId: recipeId ?? recipe.id,
            recipeName: recipe.name,
            imageUrl: recipe.imageUrl,
            mealType: mealType,
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );
  }

  /// 提案を再読み込み
  Future<void> refreshSuggestion() async {
    final recipes = await _ref.read(recipeRepositoryProvider).getAllRecipes();
    if (recipes.isNotEmpty) {
      recipes.shuffle();
      state = state.copyWith(
        currentSuggestion: recipes.first,
        recipeAdjustments: null,
      );
    }
  }
}

/// エージェントProvider
final messieAgentProvider =
    StateNotifierProvider<MessieAgentNotifier, MessieAgentState>((ref) {
      return MessieAgentNotifier(ref);
    });
