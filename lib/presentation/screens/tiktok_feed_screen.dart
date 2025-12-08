import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/cheat_day.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/restaurant.dart';
import '../providers/cheat_day_provider.dart';
import '../providers/firebase_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/comment_provider.dart';
import '../widgets/media_player_widget.dart';
import '../../data/repositories/firebase_cheat_day_repository.dart';

class TikTokFeedScreen extends ConsumerStatefulWidget {
  const TikTokFeedScreen({super.key});

  @override
  ConsumerState<TikTokFeedScreen> createState() => _TikTokFeedScreenState();
}

class _TikTokFeedScreenState extends ConsumerState<TikTokFeedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 自動スワイプ
  Timer? _autoSwipeTimer;
  bool _isAutoPlaying = true;

  // タイマー機能
  bool _isTimerActive = false;
  int _timerDurationMinutes = 5;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startAutoSwipe();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoSwipeTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startAutoSwipe() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isAutoPlaying) return;

      final cheatDays = ref.read(cheatDaysProvider).value ?? [];
      if (cheatDays.isEmpty) return;

      final nextPage = (_currentPage + 1) % cheatDays.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _toggleAutoPlay() {
    setState(() {
      _isAutoPlaying = !_isAutoPlaying;
    });
  }

  void _startTimer(int minutes) {
    setState(() {
      _isTimerActive = true;
      _timerDurationMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _isAutoPlaying = true;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _stopTimer();
        _showTimerCompleteDialog();
      }
    });
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _isTimerActive = false;
      _remainingSeconds = 0;
    });
  }

  void _showTimerCompleteDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Text('🎉 ', style: TextStyle(fontSize: 24)),
                Text('お疲れさま！'),
              ],
            ),
            content: Text(
              '$_timerDurationMinutes分間我慢できた！ダイエット継続中🔥\nこの調子で頑張ろう💪',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showTimerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '飯テロタイマー',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'ダイエットモチベーションタイマー',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _TimerButton(
                      minutes: 5,
                      onTap: () {
                        Navigator.pop(context);
                        _startTimer(5);
                      },
                    ),
                    _TimerButton(
                      minutes: 10,
                      onTap: () {
                        Navigator.pop(context);
                        _startTimer(10);
                      },
                    ),
                    _TimerButton(
                      minutes: 15,
                      onTap: () {
                        Navigator.pop(context);
                        _startTimer(15);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SafeArea(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cheatDaysAsync = ref.watch(cheatDaysProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // メインフィード
          cheatDaysAsync.when(
            data: (cheatDays) {
              if (cheatDays.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.restaurant_rounded,
                          size: 50,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'まだ投稿がありません',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '最初のチートデイを投稿しよう！',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
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
            loading:
                () => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF6B35),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'おいしい投稿を読み込み中...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
            error:
                (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'エラー: $error',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
          ),

          // ヘッダー（ロゴ＆ステータス）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // 再生/一時停止ボタン
                      GestureDetector(
                        onTap: _toggleAutoPlay,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isAutoPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // タイトル or タイマー表示
                      if (_isTimerActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatTime(_remainingSeconds),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                color: Color(0xFFFF6B35),
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'みんなのチートデイ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      // タイマーボタン
                      GestureDetector(
                        onTap: _isTimerActive ? _stopTimer : _showTimerDialog,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                _isTimerActive
                                    ? Colors.red.withOpacity(0.8)
                                    : Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isTimerActive
                                ? Icons.stop_rounded
                                : Icons.timer_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(CheatDay cheatDay) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final repository = ref.read(firebaseCheatDayRepositoryProvider);
    if (repository is FirebaseCheatDayRepository) {
      await repository.toggleLike(cheatDay.id, currentUser.uid);
    }
    ref.invalidate(cheatDaysProvider);
  }

  Future<void> _share(CheatDay cheatDay) async {
    await Share.share('チェック！「${cheatDay.title}」を見てみて！', subject: 'チートデイズで共有');

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
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),

          // 右側のアクションボタン
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              children: [
                // いいね
                _ActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(widget.cheatDay.likesCount),
                  color: isLiked ? Colors.red : Colors.white,
                  onTap: widget.onLike,
                ),
                const SizedBox(height: 20),

                // コメント
                _ActionButton(
                  icon: Icons.comment_outlined,
                  label: _formatCount(widget.cheatDay.commentsCount),
                  onTap: () => _showComments(context),
                ),
                const SizedBox(height: 20),

                // 保存
                _ActionButton(
                  icon: Icons.bookmark_border_rounded,
                  label: '保存',
                  onTap: widget.onShare,
                ),
                const SizedBox(height: 20),

                // シェア
                _ActionButton(
                  icon: Icons.send_rounded,
                  label: 'シェア',
                  onTap: widget.onShare,
                ),

                // 詳細情報（レシピ・お店）
                if (widget.cheatDay.hasRecipe ||
                    widget.cheatDay.hasRestaurant) ...[
                  const SizedBox(height: 20),
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
              ],
            ),
          ),

          // 下部情報
          Positioned(
            left: 16,
            right: 72,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ユーザー情報
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          widget.cheatDay.userPhotoUrl != null
                              ? NetworkImage(widget.cheatDay.userPhotoUrl!)
                              : null,
                      child:
                          widget.cheatDay.userPhotoUrl == null
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
                    _showDetails = false;
                  });
                },
              ),
            ),

          // 一時停止アイコン
          if (_isPaused)
            const Center(
              child: Icon(Icons.play_arrow, size: 80, color: Colors.white70),
            ),
        ],
      ),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(cheatDay: widget.cheatDay),
    );
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

  const _DetailsPanel({required this.cheatDay, required this.onClose});

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
                    tabs: const [Tab(text: 'レシピ'), Tab(text: 'お店情報')],
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
          const Expanded(child: Center(child: Text('レシピの詳細情報が表示されます'))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  currentUser != null
                      ? () =>
                          _saveRecipeToWishlist(context, ref, currentUser.uid)
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
        createdAt: DateTime.now(),
      );

      await ref
          .read(wishlistProvider.notifier)
          .addRecipeToWishlist(
            recipe: recipe,
            thumbnailUrl: cheatDay.mediaPath,
            cheatDayId: cheatDay.id,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('レシピを保存リストに追加しました')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $e')));
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
          const Expanded(child: Center(child: Text('お店の詳細情報が表示されます'))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  currentUser != null
                      ? () => _saveRestaurantToWishlist(
                        context,
                        ref,
                        currentUser.uid,
                      )
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
        createdAt: DateTime.now(),
      );

      await ref
          .read(wishlistProvider.notifier)
          .addRestaurantToWishlist(
            restaurant: restaurant,
            thumbnailUrl: cheatDay.mediaPath,
            cheatDayId: cheatDay.id,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('お店を保存リストに追加しました')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    }
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  final CheatDay cheatDay;

  const _CommentsSheet({required this.cheatDay});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.cheatDay.id));
    final currentUser = ref.watch(currentUserProvider).value;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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

          // ヘッダー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'コメント',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                commentsAsync.when(
                  data:
                      (comments) => Text(
                        '${comments.length}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),

          const Divider(),

          // コメント一覧
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(
                    child: Text('まだコメントがありません\n最初のコメントを投稿しよう！'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isOwner = currentUser?.uid == comment.userId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // アバター
                          CircleAvatar(
                            radius: 18,
                            backgroundImage:
                                comment.userPhotoUrl != null
                                    ? NetworkImage(comment.userPhotoUrl!)
                                    : null,
                            child:
                                comment.userPhotoUrl == null
                                    ? const Icon(Icons.person, size: 18)
                                    : null,
                          ),
                          const SizedBox(width: 12),

                          // コメント内容
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment.userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTime(comment.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.content,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),

                          // 削除ボタン（自分のコメントのみ）
                          if (isOwner)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: Colors.grey.shade600,
                              onPressed: () => _deleteComment(comment.id),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('エラー: $error')),
            ),
          ),

          const Divider(height: 1),

          // コメント入力欄
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'コメントを入力...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _postComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _postComment,
                    icon: const Icon(Icons.send),
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ログインしてください')));
      return;
    }

    try {
      await ref
          .read(commentsProvider(widget.cheatDay.id).notifier)
          .addComment(
            content,
            currentUser.uid,
            currentUser.displayName ?? 'Unknown',
            currentUser.photoUrl,
          );

      _commentController.clear();

      // スクロールを最下部に
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('コメントを削除'),
            content: const Text('このコメントを削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('削除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(commentsProvider(widget.cheatDay.id).notifier)
            .deleteComment(commentId);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('コメントを削除しました')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('エラー: $e')));
        }
      }
    }
  }
}

class _TimerButton extends StatelessWidget {
  final int minutes;
  final VoidCallback onTap;

  const _TimerButton({required this.minutes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8F5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$minutes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '分',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
