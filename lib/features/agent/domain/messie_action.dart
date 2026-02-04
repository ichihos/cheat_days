/// Messie Agent Action Types and Models
///
/// メッシーが実行できるアクションの定義
library;

/// アクションタイプ
enum MessieActionType {
  /// 通常の返答のみ
  reply,

  /// 提案メニューを別のものに変更
  changeSuggestion,

  /// 現在のレシピを調整（材料減・代替等）
  adjustRecipe,

  /// レシピの手順を編集
  editRecipeSteps,

  /// 買い物リストにアイテムを追加
  addToShopping,

  /// 料理記録を追加
  recordMeal,

  /// 冷蔵庫状況を更新
  updateFridge,

  /// 新しいレシピを生成
  generateRecipe,
}

/// メッシーのアクション
class MessieAction {
  final MessieActionType type;
  final String? message;
  final Map<String, dynamic> data;

  const MessieAction({required this.type, this.message, this.data = const {}});

  factory MessieAction.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'reply';
    MessieActionType type;

    switch (typeStr) {
      case 'change_suggestion':
        type = MessieActionType.changeSuggestion;
        break;
      case 'adjust_recipe':
        type = MessieActionType.adjustRecipe;
        break;
      case 'edit_recipe_steps':
        type = MessieActionType.editRecipeSteps;
        break;
      case 'add_to_shopping':
        type = MessieActionType.addToShopping;
        break;
      case 'record_meal':
        type = MessieActionType.recordMeal;
        break;
      case 'update_fridge':
        type = MessieActionType.updateFridge;
        break;
      case 'generate_recipe':
        type = MessieActionType.generateRecipe;
        break;
      default:
        type = MessieActionType.reply;
    }

    return MessieAction(
      type: type,
      message: json['message'] as String?,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    String typeStr;
    switch (type) {
      case MessieActionType.changeSuggestion:
        typeStr = 'change_suggestion';
        break;
      case MessieActionType.adjustRecipe:
        typeStr = 'adjust_recipe';
        break;
      case MessieActionType.editRecipeSteps:
        typeStr = 'edit_recipe_steps';
        break;
      case MessieActionType.addToShopping:
        typeStr = 'add_to_shopping';
        break;
      case MessieActionType.recordMeal:
        typeStr = 'record_meal';
        break;
      case MessieActionType.updateFridge:
        typeStr = 'update_fridge';
        break;
      case MessieActionType.generateRecipe:
        typeStr = 'generate_recipe';
        break;
      default:
        typeStr = 'reply';
    }

    return {
      'type': typeStr,
      if (message != null) 'message': message,
      'data': data,
    };
  }

  @override
  String toString() => 'MessieAction($type, message: $message)';
}

/// エージェントからのレスポンス（複数アクション対応）
class MessieAgentResponse {
  final List<MessieAction> actions;
  final String? rawResponse;

  const MessieAgentResponse({required this.actions, this.rawResponse});

  /// 返答メッセージを取得（replyアクションから）
  String get replyMessage {
    final replyAction = actions.firstWhere(
      (a) => a.type == MessieActionType.reply,
      orElse:
          () => const MessieAction(
            type: MessieActionType.reply,
            message: 'エラーが発生したっシー',
          ),
    );
    return replyAction.message ?? 'エラーが発生したっシー';
  }

  /// 特定タイプのアクションが含まれているか
  bool hasAction(MessieActionType type) {
    return actions.any((a) => a.type == type);
  }

  /// 特定タイプのアクションを取得
  MessieAction? getAction(MessieActionType type) {
    try {
      return actions.firstWhere((a) => a.type == type);
    } catch (_) {
      return null;
    }
  }
}

/// レシピ調整の詳細
class RecipeAdjustment {
  final String type; // "scale", "substitute", "remove", "add"
  final String target; // 対象の食材
  final String? replacement; // 代替食材（substituteの場合）
  final double? scale; // スケール（scaleの場合）

  const RecipeAdjustment({
    required this.type,
    required this.target,
    this.replacement,
    this.scale,
  });

  factory RecipeAdjustment.fromJson(Map<String, dynamic> json) {
    return RecipeAdjustment(
      type: json['type'] as String? ?? 'remove',
      target: json['target'] as String? ?? '',
      replacement: json['replacement'] as String?,
      scale: (json['scale'] as num?)?.toDouble(),
    );
  }
}
