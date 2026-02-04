import 'package:cheat_days/features/auth/repository/auth_repository.dart';
import 'package:cheat_days/features/home/data/ai_service.dart';
import 'package:cheat_days/features/pantry/data/pantry_repository.dart';
import 'package:cheat_days/features/pantry/domain/pantry_item.dart';
import 'package:cheat_days/features/records/data/meal_record_repository.dart';
import 'package:cheat_days/features/shopping_list/data/shopping_list_repository.dart';
import 'package:cheat_days/features/shopping_list/domain/shopping_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final shoppingListStreamProvider =
    StreamProvider.autoDispose<List<ShoppingItem>>((ref) {
      final user = ref.watch(authStateProvider).value;
      if (user == null) return Stream.value([]);

      final repository = ref.watch(shoppingListRepositoryProvider);
      return repository.streamItems(user.uid);
    });

final pantryStreamProvider =
    StreamProvider.autoDispose<List<PantryItem>>((ref) {
      final user = ref.watch(authStateProvider).value;
      if (user == null) return Stream.value([]);

      final repository = ref.watch(pantryRepositoryProvider);
      return repository.streamPantry(user.uid);
    });

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('買い物リスト'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '買い物リスト'),
            Tab(text: '冷蔵庫の中身'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ShoppingListTab(userId: user?.uid),
          _FridgeTab(userId: user?.uid),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return FloatingActionButton(
            onPressed: () {
              if (user == null) return;
              if (_tabController.index == 0) {
                _showAddShoppingItemDialog(context, ref, user.uid);
              } else {
                _showAddFridgeItemDialog(context, ref, user.uid);
              }
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  void _showAddShoppingItemDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("アイテムを追加"),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "例: 牛乳"),
              autofocus: true,
              onSubmitted: (_) => _addShoppingItem(context, ref, userId, controller),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("キャンセル"),
              ),
              ElevatedButton(
                onPressed: () => _addShoppingItem(context, ref, userId, controller),
                child: const Text("追加"),
              ),
            ],
          ),
    );
  }

  Future<void> _addShoppingItem(
    BuildContext context,
    WidgetRef ref,
    String userId,
    TextEditingController controller,
  ) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final item = ShoppingItem(
      id: const Uuid().v4(),
      name: text,
      createdAt: DateTime.now(),
    );
    await ref.read(shoppingListRepositoryProvider).addItem(userId, item);
    if (context.mounted) Navigator.pop(context);

    // Trigger AI Suggestions
    if (context.mounted) {
      _fetchAndShowSuggestions(context, ref, userId, text);
    }
  }

  Future<void> _fetchAndShowSuggestions(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String addedItemName,
  ) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Text('メッシーが関連アイテムを考えています...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final currentList = await ref.read(shoppingListStreamProvider.future);
      final pantryItems = await ref
          .read(pantryRepositoryProvider)
          .getPantryItems(userId);
      final recentMeals = await ref
          .read(mealRecordRepositoryProvider)
          .getRecentRecords(userId);

      final suggestions = await ref
          .read(aiServiceProvider)
          .getRelatedShoppingSuggestions(
            addedItemName: addedItemName,
            pantryItems: pantryItems,
            recentMeals: recentMeals,
            currentList: currentList,
          );

      if (suggestions.isNotEmpty && context.mounted) {
        _showSuggestionsSheet(context, ref, userId, suggestions);
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  void _showSuggestionsSheet(
    BuildContext context,
    WidgetRef ref,
    String userId,
    List<ShoppingSuggestion> suggestions,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.orange[50], // Messie Theme
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/messie.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (_, __, ___) => const Text("🦕"),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "これも一緒にどうっシー？",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                suggestion.reason,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.orange,
                          ),
                          onPressed: () {
                            final item = ShoppingItem(
                              id: const Uuid().v4(),
                              name: suggestion.name,
                              isAiSuggested: true,
                              createdAt: DateTime.now(),
                            );
                            ref
                                .read(shoppingListRepositoryProvider)
                                .addItem(userId, item);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${suggestion.name}を追加したっシー'),
                              ),
                            );
                            Navigator.pop(context); // Close sheet after adding
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('今は大丈夫'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddFridgeItemDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    final controller = TextEditingController();
    String selectedAmount = 'ある';

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text("冷蔵庫に追加"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "例: 卵",
                        labelText: "食材名",
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    const Text("残量", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _AmountChip(
                          label: 'ある',
                          isSelected: selectedAmount == 'ある',
                          color: Colors.green,
                          onTap: () => setDialogState(() => selectedAmount = 'ある'),
                        ),
                        _AmountChip(
                          label: '少し',
                          isSelected: selectedAmount == '少し',
                          color: Colors.orange,
                          onTap: () => setDialogState(() => selectedAmount = '少し'),
                        ),
                        _AmountChip(
                          label: 'なし',
                          isSelected: selectedAmount == 'なし',
                          color: Colors.red,
                          onTap: () => setDialogState(() => selectedAmount = 'なし'),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("キャンセル"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) return;

                      final item = PantryItem(
                        id: const Uuid().v4(),
                        ingredientName: text,
                        estimatedAmount: selectedAmount,
                        lastPurchased: selectedAmount != 'なし' ? DateTime.now() : null,
                      );
                      await ref.read(pantryRepositoryProvider).addItem(userId, item);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text("追加"),
                  ),
                ],
              );
            },
          ),
    );
  }
}

class _ShoppingListTab extends ConsumerWidget {
  final String? userId;

  const _ShoppingListTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingListStreamProvider);

    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text(
              "買い物リストは空です\n[+]ボタンで追加",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final unpurchased = items.where((i) => !i.isChecked).toList();
        final purchased = items.where((i) => i.isChecked).toList();

        return ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            if (unpurchased.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  "買うもの",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...unpurchased.map(
                (item) => _ShoppingListItem(item: item, userId: userId),
              ),
            ],

            if (purchased.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  "購入済み",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...purchased.map(
                (item) => _ShoppingListItem(item: item, userId: userId),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _FridgeTab extends ConsumerWidget {
  final String? userId;

  const _FridgeTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pantryAsync = ref.watch(pantryStreamProvider);

    return pantryAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/messie.png',
                  width: 80,
                  height: 80,
                  errorBuilder: (_, __, ___) => const Text("🦕", style: TextStyle(fontSize: 60)),
                ),
                const SizedBox(height: 16),
                const Text(
                  "冷蔵庫の中身が登録されていません\n[+]ボタンで追加すると\nメッシーがより良い提案ができます",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Group by amount
        final available = items.where((i) => i.estimatedAmount == 'ある').toList();
        final low = items.where((i) => i.estimatedAmount == '少し').toList();
        final empty = items.where((i) => i.estimatedAmount == 'なし').toList();

        return ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            // Info card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/messie.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) => const Text("🦕"),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "冷蔵庫の中身を登録すると、メッシーがより適切な献立を提案できるっシー！",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.brown,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (available.isNotEmpty) ...[
              _buildSectionHeader("ある", Colors.green, available.length),
              ...available.map((item) => _FridgeItem(item: item, userId: userId)),
            ],

            if (low.isNotEmpty) ...[
              _buildSectionHeader("少し", Colors.orange, low.length),
              ...low.map((item) => _FridgeItem(item: item, userId: userId)),
            ],

            if (empty.isNotEmpty) ...[
              _buildSectionHeader("なし", Colors.red, empty.length),
              ...empty.map((item) => _FridgeItem(item: item, userId: userId)),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSectionHeader(String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            "($count)",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FridgeItem extends ConsumerWidget {
  final PantryItem item;
  final String? userId;

  const _FridgeItem({required this.item, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(item.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        if (userId != null) {
          ref.read(pantryRepositoryProvider).deleteItem(userId!, item.id);
        }
      },
      child: ListTile(
        leading: _getAmountIcon(item.estimatedAmount),
        title: Text(item.ingredientName),
        subtitle: item.lastPurchased != null
            ? Text(
                "最終購入: ${_formatDate(item.lastPurchased!)}",
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              )
            : null,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (userId == null) return;
            final updatedItem = item.copyWith(estimatedAmount: value);
            await ref.read(pantryRepositoryProvider).updateItem(userId!, updatedItem);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'ある', child: Text('ある')),
            const PopupMenuItem(value: '少し', child: Text('少し')),
            const PopupMenuItem(value: 'なし', child: Text('なし')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getAmountColor(item.estimatedAmount).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getAmountColor(item.estimatedAmount).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.estimatedAmount,
                  style: TextStyle(
                    color: _getAmountColor(item.estimatedAmount),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: _getAmountColor(item.estimatedAmount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getAmountIcon(String amount) {
    switch (amount) {
      case 'ある':
        return const Icon(Icons.check_circle, color: Colors.green);
      case '少し':
        return const Icon(Icons.warning_amber_rounded, color: Colors.orange);
      case 'なし':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  Color _getAmountColor(String amount) {
    switch (amount) {
      case 'ある':
        return Colors.green;
      case '少し':
        return Colors.orange;
      case 'なし':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}";
  }
}

class _ShoppingListItem extends ConsumerWidget {
  final ShoppingItem item;
  final String? userId;

  const _ShoppingListItem({required this.item, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(item.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        if (userId != null) {
          ref.read(shoppingListRepositoryProvider).deleteItem(userId!, item.id);
        }
      },
      child: CheckboxListTile(
        value: item.isChecked,
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  decoration:
                      item.isChecked ? TextDecoration.lineThrough : null,
                  color: item.isChecked ? Colors.grey : Colors.black87,
                ),
              ),
            ),
            if (item.isAiSuggested)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/messie.png',
                      width: 16,
                      height: 16,
                      errorBuilder: (_, __, ___) => const Text("🦕"),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Messie',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.brown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        onChanged: (val) {
          if (userId != null && val != null) {
            ref
                .read(shoppingListRepositoryProvider)
                .toggleCheck(userId!, item.id, item.isChecked);
          }
        },
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _AmountChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
