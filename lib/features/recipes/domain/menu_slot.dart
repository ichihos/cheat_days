import 'recipe.dart';

/// メニュースロットのタイプ
enum MenuSlotType {
  main,   // 主菜
  side,   // 副菜
  staple, // 主食（ご飯、パン、麺など）
  soup,   // 汁物
}

extension MenuSlotTypeExtension on MenuSlotType {
  String get label {
    switch (this) {
      case MenuSlotType.main:
        return '主菜';
      case MenuSlotType.side:
        return '副菜';
      case MenuSlotType.staple:
        return '主食';
      case MenuSlotType.soup:
        return '汁物';
    }
  }

  String get emoji {
    switch (this) {
      case MenuSlotType.main:
        return '🍖';
      case MenuSlotType.side:
        return '🥗';
      case MenuSlotType.staple:
        return '🍚';
      case MenuSlotType.soup:
        return '🍲';
    }
  }

  /// レシピのカテゴリからMenuSlotTypeを推測
  static MenuSlotType fromCategory(String category) {
    switch (category) {
      case 'main':
        return MenuSlotType.main;
      case 'side':
        return MenuSlotType.side;
      case 'rice':
      case 'noodle':
        return MenuSlotType.staple;
      case 'soup':
        return MenuSlotType.soup;
      default:
        return MenuSlotType.main;
    }
  }
}

/// 献立の1つのスロット（主菜、副菜、主食など）
class MenuSlot {
  final String id;
  final MenuSlotType type;
  final Recipe? recipe;
  final bool isRequired; // 必須かどうか
  final bool isEmpty; // 空のスロット（「追加」ボタン用）

  MenuSlot({
    required this.id,
    required this.type,
    this.recipe,
    this.isRequired = false,
    this.isEmpty = false,
  });

  MenuSlot copyWith({
    String? id,
    MenuSlotType? type,
    Recipe? recipe,
    bool? isRequired,
    bool? isEmpty,
  }) {
    return MenuSlot(
      id: id ?? this.id,
      type: type ?? this.type,
      recipe: recipe ?? this.recipe,
      isRequired: isRequired ?? this.isRequired,
      isEmpty: isEmpty ?? this.isEmpty,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'recipeId': recipe?.id,
      'isRequired': isRequired,
    };
  }

  factory MenuSlot.fromMap(Map<String, dynamic> map, List<Recipe> recipes) {
    final recipeId = map['recipeId'] as String?;
    Recipe? recipe;
    if (recipeId != null) {
      try {
        recipe = recipes.firstWhere((r) => r.id == recipeId);
      } catch (_) {}
    }

    return MenuSlot(
      id: map['id'] ?? '',
      type: MenuSlotType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => MenuSlotType.main,
      ),
      recipe: recipe,
      isRequired: map['isRequired'] ?? false,
    );
  }

  /// レシピから新しいMenuSlotを作成
  factory MenuSlot.fromRecipe(Recipe recipe, {String? id}) {
    return MenuSlot(
      id: id ?? 'slot_${DateTime.now().millisecondsSinceEpoch}',
      type: MenuSlotTypeExtension.fromCategory(recipe.category),
      recipe: recipe,
      isRequired: recipe.category == 'main',
    );
  }

  /// 空のスロット（追加用）を作成
  factory MenuSlot.empty(MenuSlotType type) {
    return MenuSlot(
      id: 'empty_${type.name}',
      type: type,
      recipe: null,
      isRequired: false,
      isEmpty: true,
    );
  }
}

/// 今日の献立全体
class TodaysMenu {
  final List<MenuSlot> slots;
  final String? messieComment;
  final DateTime date;

  TodaysMenu({
    required this.slots,
    this.messieComment,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  /// 主菜を取得
  MenuSlot? get mainDish => slots.where((s) => s.type == MenuSlotType.main && !s.isEmpty).firstOrNull;

  /// 副菜リストを取得
  List<MenuSlot> get sideDishes => slots.where((s) => s.type == MenuSlotType.side && !s.isEmpty).toList();

  /// 主食を取得
  MenuSlot? get staple => slots.where((s) => s.type == MenuSlotType.staple && !s.isEmpty).firstOrNull;

  /// 汁物を取得
  MenuSlot? get soup => slots.where((s) => s.type == MenuSlotType.soup && !s.isEmpty).firstOrNull;

  /// 表示用のスロット（空のスロットも含む）
  List<MenuSlot> get displaySlots {
    final result = <MenuSlot>[];

    // 主菜
    final main = mainDish;
    if (main != null) {
      result.add(main);
    }

    // 副菜（複数可能）
    result.addAll(sideDishes);

    // 主食（主菜がパスタなどの場合は不要な場合も）
    final stapleSlot = staple;
    if (stapleSlot != null) {
      result.add(stapleSlot);
    }

    // 汁物
    final soupSlot = soup;
    if (soupSlot != null) {
      result.add(soupSlot);
    }

    return result;
  }

  TodaysMenu copyWith({
    List<MenuSlot>? slots,
    String? messieComment,
    DateTime? date,
  }) {
    return TodaysMenu(
      slots: slots ?? this.slots,
      messieComment: messieComment ?? this.messieComment,
      date: date ?? this.date,
    );
  }

  /// スロットを更新
  TodaysMenu updateSlot(String slotId, Recipe newRecipe) {
    final newSlots = slots.map((slot) {
      if (slot.id == slotId) {
        return slot.copyWith(recipe: newRecipe);
      }
      return slot;
    }).toList();
    return copyWith(slots: newSlots);
  }

  /// スロットを追加
  TodaysMenu addSlot(MenuSlot slot) {
    return copyWith(slots: [...slots, slot]);
  }

  /// スロットを削除
  TodaysMenu removeSlot(String slotId) {
    return copyWith(slots: slots.where((s) => s.id != slotId).toList());
  }
}
