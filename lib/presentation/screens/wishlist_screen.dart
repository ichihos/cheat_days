import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/wishlist_item.dart';
import '../providers/wishlist_provider.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wishlistAsync = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('食べたいものリスト'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'すべて'),
            Tab(text: 'レシピ'),
            Tab(text: 'お店'),
          ],
        ),
      ),
      body: wishlistAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '保存したアイテムがありません',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '気になるレシピやお店を保存しましょう',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildWishlistView(items),
              _buildWishlistView(items.where((item) => item.isRecipe).toList()),
              _buildWishlistView(items.where((item) => item.isRestaurant).toList()),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildWishlistView(List<WishlistItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'このカテゴリに保存されたアイテムはありません',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final pendingItems = items.where((item) => !item.isCompleted).toList();
    final completedItems = items.where((item) => item.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pendingItems.isNotEmpty) ...[
          const Text(
            '行きたい・作りたい',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...pendingItems.map((item) => _WishlistItemCard(
                item: item,
                onToggle: () {
                  ref.read(wishlistProvider.notifier).toggleCompletion(item.id);
                },
                onDelete: () {
                  _showDeleteConfirmation(item);
                },
              )),
        ],
        if (completedItems.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            '達成済み',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          ...completedItems.map((item) => _WishlistItemCard(
                item: item,
                onToggle: () {
                  ref.read(wishlistProvider.notifier).toggleCompletion(item.id);
                },
                onDelete: () {
                  _showDeleteConfirmation(item);
                },
              )),
        ],
      ],
    );
  }

  void _showDeleteConfirmation(WishlistItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('「${item.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(wishlistProvider.notifier).removeItem(item.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}

class _WishlistItemCard extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _WishlistItemCard({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: item.thumbnailUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.thumbnailUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildDefaultIcon(),
                ),
              )
            : _buildDefaultIcon(),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? Colors.grey : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null) ...[
              const SizedBox(height: 4),
              Text(
                item.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: item.isCompleted ? Colors.grey : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  item.isRecipe ? Icons.restaurant_menu : Icons.store,
                  size: 14,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  item.isRecipe ? 'レシピ' : 'お店',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('yyyy/MM/dd').format(item.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: item.isCompleted,
              onChanged: (_) => onToggle(),
              activeColor: Colors.orange,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        item.isRecipe ? Icons.restaurant_menu : Icons.store,
        color: Colors.orange,
        size: 32,
      ),
    );
  }
}
