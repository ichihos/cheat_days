import 'package:cheat_days/features/auth/repository/auth_repository.dart';
import 'package:cheat_days/features/home/data/ai_service.dart';
import 'package:cheat_days/features/pantry/data/pantry_repository.dart';
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

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingListStreamProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('買い物リスト')),
      body: Column(
        children: [
          // Main Listing
          Expanded(
            child: itemsAsync.when(
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
                        (item) =>
                            _ShoppingListItem(item: item, userId: user?.uid),
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
                        (item) =>
                            _ShoppingListItem(item: item, userId: user?.uid),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (user == null) return;
          _showAddItemDialog(context, ref, user.uid);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref, String userId) {
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
              onSubmitted: (_) => _addItem(context, ref, userId, controller),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("キャンセル"),
              ),
              ElevatedButton(
                onPressed: () => _addItem(context, ref, userId, controller),
                child: const Text("追加"),
              ),
            ],
          ),
    );
  }

  Future<void> _addItem(
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
