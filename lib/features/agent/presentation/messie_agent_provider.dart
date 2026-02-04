import 'package:cheat_days/features/agent/data/messie_agent_service.dart';
import 'package:cheat_days/features/agent/domain/messie_action.dart';
import 'package:cheat_days/features/auth/repository/auth_repository.dart';
import 'package:cheat_days/features/auth/data/user_repository.dart';
import 'package:cheat_days/features/context/data/user_context_provider.dart';
import 'package:cheat_days/features/recipes/data/recipe_repository.dart';
import 'package:cheat_days/features/recipes/data/customized_recipe_repository.dart';
import 'package:cheat_days/features/recipes/domain/recipe.dart';
import 'package:cheat_days/features/recipes/domain/customized_recipe.dart';
import 'package:cheat_days/features/recipes/domain/menu_slot.dart';
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
  final List<MenuSlot> menuSlots; // 献立スロット（主菜、副菜、主食など）
  final int currentSlotIndex; // 現在表示中のスロットインデックス
  final String? customizedRecipeId;
  final String? sideDishCustomizedRecipeId;
  final Map<String, dynamic>? recipeAdjustments;
  final bool isProcessing;
  final String? lastMessage;
  final List<MessieAction> recentActions;
  final List<ChatMessage> chatHistory;

  const MessieAgentState({
    this.currentSuggestion,
    this.sideDish,
    this.menuSlots = const [],
    this.currentSlotIndex = 0,
    this.customizedRecipeId,
    this.sideDishCustomizedRecipeId,
    this.recipeAdjustments,
    this.isProcessing = false,
    this.lastMessage,
    this.recentActions = const [],
    this.chatHistory = const [],
  });

  /// 現在表示中のスロット
  MenuSlot? get currentSlot =>
      menuSlots.isNotEmpty && currentSlotIndex < menuSlots.length
          ? menuSlots[currentSlotIndex]
          : null;

  /// 現在表示中のレシピ
  Recipe? get currentRecipe => currentSlot?.recipe ?? currentSuggestion;

  MessieAgentState copyWith({
    Recipe? currentSuggestion,
    Recipe? sideDish,
    List<MenuSlot>? menuSlots,
    int? currentSlotIndex,
    String? customizedRecipeId,
    String? sideDishCustomizedRecipeId,
    Map<String, dynamic>? recipeAdjustments,
    bool? isProcessing,
    String? lastMessage,
    List<MessieAction>? recentActions,
    List<ChatMessage>? chatHistory,
  }) {
    return MessieAgentState(
      currentSuggestion: currentSuggestion ?? this.currentSuggestion,
      sideDish: sideDish ?? this.sideDish,
      menuSlots: menuSlots ?? this.menuSlots,
      currentSlotIndex: currentSlotIndex ?? this.currentSlotIndex,
      customizedRecipeId: customizedRecipeId ?? this.customizedRecipeId,
      sideDishCustomizedRecipeId:
          sideDishCustomizedRecipeId ?? this.sideDishCustomizedRecipeId,
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
  Future<void> syncWithDailySuggestion(DailySuggestionState dailyState) async {
    if (dailyState.recipe != null &&
        dailyState.recipe!.id != state.currentSuggestion?.id) {
      final initialComment = dailyState.messieComment;
      List<ChatMessage> newHistory = [];
      if (initialComment != null) {
        newHistory.add(ChatMessage(text: initialComment, isUser: false));
      }

      // カスタマイズ済みレシピを初期化
      final user = _ref.read(authStateProvider).value;
      String? customizedId;
      String? sideDishCustomizedId;
      Recipe? displayRecipe = dailyState.recipe;
      Recipe? displaySideDish = dailyState.sideDish;

      if (user != null && dailyState.recipe != null) {
        try {
          final customizedRepo = _ref.read(customizedRecipeRepositoryProvider);

          // メインレシピの初期化
          final customized = await customizedRepo.initializeTodaysRecipe(
            user.uid,
            dailyState.recipe!,
          );
          customizedId = customized.id;
          displayRecipe = customized.recipe;

          // 副菜の初期化
          if (dailyState.sideDish != null) {
            final sideDishCustomized =
                await customizedRepo.initializeSideDishRecipe(
                  user.uid,
                  dailyState.sideDish!,
                );
            sideDishCustomizedId = sideDishCustomized.id;
            displaySideDish = sideDishCustomized.recipe;
          }
        } catch (e) {
          // 初期化に失敗してもオリジナルレシピを表示
        }
      }

      // メニュースロットを作成
      final slots = <MenuSlot>[];

      // 主菜
      if (displayRecipe != null) {
        slots.add(MenuSlot(
          id: 'main_${displayRecipe.id}',
          type: MenuSlotType.main,
          recipe: displayRecipe,
          isRequired: true,
        ));
      }

      // 副菜
      if (displaySideDish != null) {
        slots.add(MenuSlot(
          id: 'side_${displaySideDish.id}',
          type: MenuSlotType.side,
          recipe: displaySideDish,
        ));
      }

      // 主食スロット（主菜が麺類やご飯ものでない場合）
      final mainCategory = displayRecipe?.category ?? '';
      if (mainCategory != 'noodle' && mainCategory != 'rice') {
        slots.add(MenuSlot.empty(MenuSlotType.staple));
      }

      state = state.copyWith(
        currentSuggestion: displayRecipe,
        sideDish: displaySideDish,
        menuSlots: slots,
        currentSlotIndex: 0,
        customizedRecipeId: customizedId,
        sideDishCustomizedRecipeId: sideDishCustomizedId,
        recipeAdjustments: null,
        chatHistory: newHistory,
        lastMessage: initialComment,
      );
    }
  }

  /// 現在のスロットインデックスを更新
  void setCurrentSlotIndex(int index) {
    if (index >= 0 && index < state.menuSlots.length) {
      state = state.copyWith(currentSlotIndex: index);
    }
  }

  /// スロットを追加
  void addMenuSlot(MenuSlot slot) {
    final newSlots = [...state.menuSlots, slot];
    state = state.copyWith(menuSlots: newSlots);
  }

  /// スロットを削除
  void removeMenuSlot(String slotId) {
    final newSlots = state.menuSlots.where((s) => s.id != slotId).toList();
    state = state.copyWith(
      menuSlots: newSlots,
      currentSlotIndex: state.currentSlotIndex.clamp(0, newSlots.length - 1),
    );
  }

  /// スロットのレシピを更新
  void updateSlotRecipe(String slotId, Recipe recipe) {
    final newSlots = state.menuSlots.map((slot) {
      if (slot.id == slotId) {
        return slot.copyWith(recipe: recipe, isEmpty: false);
      }
      return slot;
    }).toList();
    state = state.copyWith(menuSlots: newSlots);
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
        chatHistory: state.chatHistory,
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
        await _handleAdjustRecipe(action);
        break;
      case MessieActionType.editRecipeSteps:
        await _handleEditRecipeSteps(action);
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
    final generatedRecipe = Recipe(
      id: 'generated_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      imageUrl: '',
      category: 'main',
      cuisine: 'other',
      timeMinutes: timeMinutes,
      costYen: 0,
      difficulty: 2,
      seasons: [],
      ingredients: ingredients,
      steps: steps,
      tags: ['AI考案'],
      createdAt: DateTime.now(),
    );

    // 生成されたレシピもカスタマイズ済みレシピとして保存
    final user = _ref.read(authStateProvider).value;
    String? customizedId;

    if (user != null) {
      try {
        final customizedRepo = _ref.read(customizedRecipeRepositoryProvider);
        final customized = await customizedRepo.initializeTodaysRecipe(
          user.uid,
          generatedRecipe,
        );
        customizedId = customized.id;
      } catch (_) {}
    }

    state = state.copyWith(
      currentSuggestion: generatedRecipe,
      customizedRecipeId: customizedId,
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
      // 新しいレシピでカスタマイズ済みレシピを初期化
      final user = _ref.read(authStateProvider).value;
      String? customizedId;

      if (user != null) {
        try {
          final customizedRepo = _ref.read(customizedRecipeRepositoryProvider);
          final customized = await customizedRepo.initializeTodaysRecipe(
            user.uid,
            newRecipe,
          );
          customizedId = customized.id;
        } catch (_) {}
      }

      state = state.copyWith(
        currentSuggestion: newRecipe,
        customizedRecipeId: customizedId,
        recipeAdjustments: null,
      );
    }
  }

  /// レシピ調整
  Future<void> _handleAdjustRecipe(MessieAction action) async {
    final adjustmentsData = action.data['adjustments'] as List<dynamic>?;
    if (adjustmentsData == null) return;

    final currentRecipe = state.currentSuggestion;
    if (currentRecipe == null) return;

    List<Ingredient> newIngredients = List.from(currentRecipe.ingredients);
    List<String> adjustmentDescriptions = [];

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
            adjustmentDescriptions.add(
              '分量を${adjustment.scale}倍に調整',
            );
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
            adjustmentDescriptions.add(
              '${adjustment.target}を${adjustment.replacement}に変更',
            );
          }
          break;
        case 'remove':
          newIngredients.removeWhere((i) => i.name.contains(adjustment.target));
          adjustmentDescriptions.add('${adjustment.target}を削除');
          break;
      }
    }

    // レシピ名に「(調整済み)」を付ける（まだ付いていなければ）
    String adjustedName = currentRecipe.name;
    if (!adjustedName.contains('(調整済み)')) {
      adjustedName = '$adjustedName (調整済み)';
    }

    final adjustedRecipe = currentRecipe.copyWith(
      ingredients: newIngredients,
      name: adjustedName,
    );

    // Firebaseに保存
    final user = _ref.read(authStateProvider).value;
    if (user != null && state.customizedRecipeId != null) {
      try {
        final customizedRepo = _ref.read(customizedRecipeRepositoryProvider);
        await customizedRepo.updateRecipe(
          user.uid,
          state.customizedRecipeId!,
          adjustedRecipe,
          RecipeAdjustmentLog(
            type: adjustments.map((a) => a.type).join(', '),
            description: adjustmentDescriptions.join(', '),
            timestamp: DateTime.now(),
          ),
        );
      } catch (_) {}
    }

    state = state.copyWith(
      currentSuggestion: adjustedRecipe,
      recipeAdjustments: {'adjustments': adjustmentsData},
    );
  }

  /// レシピの手順を編集
  Future<void> _handleEditRecipeSteps(MessieAction action) async {
    final newSteps = action.data['steps'] as List<dynamic>?;
    if (newSteps == null) return;

    final currentRecipe = state.currentSuggestion;
    if (currentRecipe == null) return;

    final steps = newSteps.map((s) => s.toString()).toList();

    // レシピ名に「(調整済み)」を付ける（まだ付いていなければ）
    String adjustedName = currentRecipe.name;
    if (!adjustedName.contains('(調整済み)')) {
      adjustedName = '$adjustedName (調整済み)';
    }

    final adjustedRecipe = currentRecipe.copyWith(
      steps: steps,
      name: adjustedName,
    );

    // Firebaseに保存
    final user = _ref.read(authStateProvider).value;
    if (user != null && state.customizedRecipeId != null) {
      try {
        final customizedRepo = _ref.read(customizedRecipeRepositoryProvider);
        await customizedRepo.updateRecipe(
          user.uid,
          state.customizedRecipeId!,
          adjustedRecipe,
          RecipeAdjustmentLog(
            type: 'edit_steps',
            description: '手順を編集',
            timestamp: DateTime.now(),
          ),
        );
      } catch (_) {}
    }

    state = state.copyWith(currentSuggestion: adjustedRecipe);
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
      final status = map['status'] as String?;

      if (ingredientName == null || status == null) continue;

      String estimatedAmount;
      if (status == 'has' || status == 'ある') {
        estimatedAmount = 'ある';
      } else if (status == 'none' || status == 'なし') {
        estimatedAmount = 'なし';
      } else if (status == 'little' || status == '少し') {
        estimatedAmount = '少し';
      } else {
        estimatedAmount = 'ある';
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
              lastUsed: DateTime.now(),
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
              id: '',
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
      final newRecipe = recipes.first;

      // 新しいレシピでカスタマイズ済みレシピを初期化
      final user = _ref.read(authStateProvider).value;
      String? customizedId;

      if (user != null) {
        try {
          final customizedRepo = _ref.read(customizedRecipeRepositoryProvider);
          final customized = await customizedRepo.initializeTodaysRecipe(
            user.uid,
            newRecipe,
          );
          customizedId = customized.id;
        } catch (_) {}
      }

      state = state.copyWith(
        currentSuggestion: newRecipe,
        customizedRecipeId: customizedId,
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
