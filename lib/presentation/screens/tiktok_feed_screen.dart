import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/cheat_day.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/restaurant.dart';
import '../providers/cheat_day_provider.dart';
import '../providers/firebase_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/media_player_widget.dart';

class TikTokFeedScreen extends ConsumerStatefulWidget {
  const TikTokFeedScreen({super.key});

  @override
  ConsumerState<TikTokFeedScreen> createState() => _TikTokFeedScreenState();
}

class _TikTokFeedScreenState extends ConsumerState<TikTokFeedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cheatDaysAsync = ref.watch(cheatDaysProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: cheatDaysAsync.when(
        data: (cheatDays) {
          if (cheatDays.isEmpty) {
            return const Center(
              child: Text('まだ投稿がありません'),
            );
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: cheatDays.length,
            itemBuilder: (context, index) {
              final cheatDay = cheatDays[index];
              return _FeedItem(
                cheatDay: cheatDay,
                isActive: index == _currentPage,
                currentUserId: currentUser.value?.uid ?? '',
                onLike: () => _toggleLike(cheatDay),
                onShare: () => _share(cheatDay),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Future<void> _toggleLike(CheatDay cheatDay) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final repository = ref.read(firebaseCheatDayRepositoryProvider);
    if (repository is dynamic) {
      await repository.toggleLike(cheatDay.id, currentUser.uid);
    }
    ref.invalidate(cheatDaysProvider);
  }

  Future<void> _share(CheatDay cheatDay) async {
    await Share.share(
      'チェック！「${cheatDay.title}」を見てみて！',
      subject: 'チートデイズで共有',
    );

    // 共有カウントを増やす
    final updatedCheatDay = cheatDay.copyWith(
      sharesCount: cheatDay.sharesCount + 1,
    );
    final repository = ref.read(firebaseCheatDayRepositoryProvider);
    await repository.updateCheatDay(updatedCheatDay);
    ref.invalidate(cheatDaysProvider);
  }
}

class _FeedItem extends StatefulWidget {
  final CheatDay cheatDay;
  final bool isActive;
  final String currentUserId;
  final VoidCallback onLike;
  final VoidCallback onShare;

  const _FeedItem({
    required this.cheatDay,
    required this.isActive,
    required this.currentUserId,
    required this.onLike,
    required this.onShare,
  });

  @override
  State<_FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<_FeedItem> {
  bool _isPaused = false;
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.cheatDay.likedBy.contains(widget.currentUserId);

    return GestureDetector(
      onTap: () {
        setState(() {
          _isPaused = !_isPaused;
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // メディア表示
          MediaPlayerWidget(
            cheatDay: widget.cheatDay,
            isActive: widget.isActive,
            isPaused: _isPaused,
          ),

          // グラデーションオーバーレイ
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),

          // 右側のアクションボタン
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                // いいね
                _ActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(widget.cheatDay.likesCount),
                  color: isLiked ? Colors.red : Colors.white,
                  onTap: widget.onLike,
                ),
                const SizedBox(height: 24),

                // コメント
                _ActionButton(
                  icon: Icons.comment_outlined,
                  label: _formatCount(widget.cheatDay.commentsCount),
                  onTap: () => _showComments(context),
                ),
                const SizedBox(height: 24),

                // 共有
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: _formatCount(widget.cheatDay.sharesCount),
                  onTap: widget.onShare,
                ),
                const SizedBox(height: 24),

                // 詳細情報（レシピ・お店）
                if (widget.cheatDay.hasRecipe || widget.cheatDay.hasRestaurant)
                  _ActionButton(
                    icon: Icons.info_outline,
                    label: '詳細',
                    onTap: () {
                      setState(() {
                        _showDetails = !_showDetails;
                      });
                    },
                  ),
              ],
            ),
          ),

          // 下部情報
          Positioned(
            left: 16,
            right: 80,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ユーザー情報
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: widget.cheatDay.userPhotoUrl != null
                          ? NetworkImage(widget.cheatDay.userPhotoUrl!)
                          : null,
                      child: widget.cheatDay.userPhotoUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.cheatDay.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // タイトル
                Text(
                  widget.cheatDay.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 詳細情報パネル
          if (_showDetails)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _DetailsPanel(
                cheatDay: widget.cheatDay,
                onClose: () {
                  setState(() {
                    _showDetails = false,
                  });
                },
              ),
            ),

          // 一時停止アイコン
          if (_isPaused)
            const Center(
              child: Icon(
                Icons.play_arrow,
                size: 80,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  void _showComments(BuildContext context) {
    // コメント画面を表示
    // TODO: コメント機能の実装
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsPanel extends ConsumerWidget {
  final CheatDay cheatDay;
  final VoidCallback onClose;

  const _DetailsPanel({
    required this.cheatDay,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ハンドル
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // タブ
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Colors.orange,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'レシピ'),
                      Tab(text: 'お店情報'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // レシピタブ
                        _RecipeTab(cheatDay: cheatDay),

                        // お店タブ
                        _RestaurantTab(cheatDay: cheatDay),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeTab extends ConsumerWidget {
  final CheatDay cheatDay;

  const _RecipeTab({required this.cheatDay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    if (!cheatDay.hasRecipe) {
      return const Center(child: Text('レシピ情報なし'));
    }

    // TODO: 実際のレシピデータを取得して表示
    // 現在はダミーデータで表示
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'レシピ情報',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: Center(child: Text('レシピの詳細情報が表示されます')),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: currentUser != null
                  ? () => _saveRecipeToWishlist(context, ref, currentUser.uid)
                  : null,
              icon: const Icon(Icons.bookmark_add),
              label: const Text('レシピを保存リストに追加'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRecipeToWishlist(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      // TODO: 実際のレシピデータを使用
      // 現在はダミーデータで保存
      final recipe = Recipe(
        id: '${cheatDay.id}_recipe',
        cheatDayId: cheatDay.id,
        title: cheatDay.title,
        ingredients: ['材料1', '材料2'],
        steps: ['手順1', '手順2'],
        cookingTimeMinutes: 30,
        servings: 2,
      );

      await ref.read(wishlistNotifierProvider.notifier).addRecipeToWishlist(
            recipe: recipe,
            thumbnailUrl: cheatDay.mediaPath,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レシピを保存リストに追加しました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }
}

class _RestaurantTab extends ConsumerWidget {
  final CheatDay cheatDay;

  const _RestaurantTab({required this.cheatDay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    if (!cheatDay.hasRestaurant) {
      return const Center(child: Text('お店情報なし'));
    }

    // TODO: 実際のレストランデータを取得して表示
    // 現在はダミーデータで表示
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'お店情報',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: Center(child: Text('お店の詳細情報が表示されます')),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: currentUser != null
                  ? () => _saveRestaurantToWishlist(context, ref, currentUser.uid)
                  : null,
              icon: const Icon(Icons.bookmark_add),
              label: const Text('お店を保存リストに追加'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRestaurantToWishlist(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      // TODO: 実際のレストランデータを使用
      // 現在はダミーデータで保存
      final restaurant = Restaurant(
        id: '${cheatDay.id}_restaurant',
        cheatDayId: cheatDay.id,
        name: cheatDay.title,
        address: '住所情報',
        tags: [],
      );

      await ref.read(wishlistNotifierProvider.notifier).addRestaurantToWishlist(
            restaurant: restaurant,
            thumbnailUrl: cheatDay.mediaPath,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('お店を保存リストに追加しました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }
}
