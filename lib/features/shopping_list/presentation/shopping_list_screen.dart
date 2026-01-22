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

final shoppingSuggestionsProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];

  // Wait for existing list to be loaded
  final currentList = await ref.watch(shoppingListStreamProvider.future);

  // Get supporting data
  final pantryItems = await ref
      .read(pantryRepositoryProvider)
      .getPantryItems(user.uid);
  final recentMeals = await ref
      .read(mealRecordRepositoryProvider)
      .getRecentRecords(user.uid);

  // Call AI
  return ref
      .read(aiServiceProvider)
      .getShoppingSuggestions(
        pantryItems: pantryItems,
        recentMeals: recentMeals,
        currentList: currentList,
      );
});

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingListStreamProvider);
    final suggestionsAsync = ref.watch(shoppingSuggestionsProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('買い物リスト')),
      body: Column(
        children: [
          // AI Suggestions Area
          if (suggestionsAsync.valueOrNull != null &&
              suggestionsAsync.valueOrNull!.isNotEmpty)
            _buildSuggestionsArea(
              context,
              ref,
              suggestionsAsync.value!,
              user?.uid,
            ),

          // Main Listing
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty &&
                    (suggestionsAsync.valueOrNull?.isEmpty ?? true)) {
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

  Widget _buildSuggestionsArea(
    BuildContext context,
    WidgetRef ref,
    List<String> suggestions,
    String? userId,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.orange[50], // Messie color accent
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/messie.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Text("🦕"),
              ),
              const SizedBox(width: 8),
              const Text(
                "これも買うっシー？",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.brown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                suggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion),
                    backgroundColor: Colors.white,
                    elevation: 1,
                    onPressed: () {
                      if (userId == null) return;
                      final item = ShoppingItem(
                        id: const Uuid().v4(),
                        name: suggestion,
                        createdAt: DateTime.now(),
                      );
                      ref
                          .read(shoppingListRepositoryProvider)
                          .addItem(userId, item);
                      // Refresh suggestions to remove added item (optional, purely UI update)
                      // In a real app we might remove it from the local list or re-fetch
                    },
                  );
                }).toList(),
          ),
        ],
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("キャンセル"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    final item = ShoppingItem(
                      id: const Uuid().v4(),
                      name: controller.text.trim(),
                      createdAt: DateTime.now(),
                    );
                    ref
                        .read(shoppingListRepositoryProvider)
                        .addItem(userId, item);
                    Navigator.pop(context);
                  }
                },
                child: const Text("追加"),
              ),
            ],
          ),
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
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            color: item.isChecked ? Colors.grey : Colors.black87,
          ),
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
