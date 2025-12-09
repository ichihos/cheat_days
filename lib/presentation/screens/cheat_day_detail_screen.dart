import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/cheat_day.dart';
import '../providers/cheat_day_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/comment_provider.dart';
import '../widgets/media_player_widget.dart';
import '../../data/repositories/firebase_cheat_day_repository.dart';
import '../providers/firebase_providers.dart';

/// マイチートデイからの詳細表示画面（フィード風UI）
class CheatDayDetailScreen extends ConsumerStatefulWidget {
  final CheatDay cheatDay;
  final List<CheatDay> cheatDays;
  final int initialIndex;

  const CheatDayDetailScreen({
    super.key,
    required this.cheatDay,
    required this.cheatDays,
    required this.initialIndex,
  });

  @override
  ConsumerState<CheatDayDetailScreen> createState() =>
      _CheatDayDetailScreenState();
}

class _CheatDayDetailScreenState extends ConsumerState<CheatDayDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // メインコンテンツ（縦スワイプ可能）
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.cheatDays.length,
            itemBuilder: (context, index) {
              final cheatDay = widget.cheatDays[index];
              return _DetailFeedItem(
                cheatDay: cheatDay,
                isActive: index == _currentIndex,
                currentUserId: currentUser.value?.uid ?? '',
                onLike: () => _toggleLike(cheatDay),
                onShare: () => _share(cheatDay),
                onDelete: () => _showDeleteConfirmation(cheatDay),
              );
            },
          ),

          // 戻るボタン
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.cheatDays.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // バランス用
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

    final currentCheatDays = ref.read(cheatDaysProvider).value ?? [];
    final isLiked = cheatDay.likedBy.contains(currentUser.uid);
    final updatedLikedBy =
        isLiked
            ? cheatDay.likedBy.where((id) => id != currentUser.uid).toList()
            : [...cheatDay.likedBy, currentUser.uid];
    final updatedCheatDay = cheatDay.copyWith(
      likedBy: updatedLikedBy,
      likesCount: updatedLikedBy.length,
    );

    final updatedList =
        currentCheatDays
            .map((day) => day.id == cheatDay.id ? updatedCheatDay : day)
            .toList();
    ref.read(cheatDaysProvider.notifier).updateLocalState(updatedList);

    final repository = ref.read(firebaseCheatDayRepositoryProvider);
    if (repository is FirebaseCheatDayRepository) {
      await repository.toggleLike(cheatDay.id, currentUser.uid);
    }
  }

  Future<void> _share(CheatDay cheatDay) async {
    await Share.share(
      'チェック！「${cheatDay.title}」を見てみて！',
      subject: 'チートデイズで共有',
    );

    final currentCheatDays = ref.read(cheatDaysProvider).value ?? [];
    final updatedCheatDay = cheatDay.copyWith(
      sharesCount: cheatDay.sharesCount + 1,
    );
    final updatedList =
        currentCheatDays
            .map((day) => day.id == cheatDay.id ? updatedCheatDay : day)
            .toList();
    ref.read(cheatDaysProvider.notifier).updateLocalState(updatedList);

    final repository = ref.read(firebaseCheatDayRepositoryProvider);
    await repository.updateCheatDay(updatedCheatDay);
  }

  void _showDeleteConfirmation(CheatDay cheatDay) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('削除確認'),
            content: const Text('この投稿を削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // ダイアログを閉じる
                  ref
                      .read(cheatDaysProvider.notifier)
                      .deleteCheatDay(cheatDay.id);
                  // 削除後に画面を閉じる
                  if (widget.cheatDays.length <= 1) {
                    Navigator.pop(context); // 詳細画面を閉じる
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('削除'),
              ),
            ],
          ),
    );
  }
}

class _DetailFeedItem extends ConsumerStatefulWidget {
  final CheatDay cheatDay;
  final bool isActive;
  final String currentUserId;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _DetailFeedItem({
    required this.cheatDay,
    required this.isActive,
    required this.currentUserId,
    required this.onLike,
    required this.onShare,
    required this.onDelete,
  });

  @override
  ConsumerState<_DetailFeedItem> createState() => _DetailFeedItemState();
}

class _DetailFeedItemState extends ConsumerState<_DetailFeedItem> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final isInWishlist = await ref
        .read(wishlistProvider.notifier)
        .isInWishlist(widget.cheatDay.id);
    if (mounted) {
      setState(() {
        _isSaved = isInWishlist;
      });
    }
  }

  Future<void> _saveToWishlist() async {
    if (_isSaved) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('既に保存済みです')));
      return;
    }

    if (widget.currentUserId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ログインしてください')));
      return;
    }

    try {
      await ref
          .read(wishlistProvider.notifier)
          .addCheatDayToWishlist(
            cheatDayId: widget.cheatDay.id,
            title: widget.cheatDay.title,
            thumbnailUrl: widget.cheatDay.mediaPath,
            description: '${widget.cheatDay.userName}の投稿',
          );

      setState(() {
        _isSaved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('食べたいものリストに保存しました！')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.cheatDay.likedBy.contains(widget.currentUserId);

    return Stack(
      fit: StackFit.expand,
      children: [
        // メディア表示
        MediaPlayerWidget(
          cheatDay: widget.cheatDay,
          isActive: widget.isActive,
          isPaused: false,
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
                stops: const [0.5, 1.0],
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
                icon:
                    _isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                label: _isSaved ? '保存済' : '保存',
                color: _isSaved ? const Color(0xFFFF6B35) : Colors.white,
                onTap: _saveToWishlist,
              ),
              const SizedBox(height: 20),

              // シェア
              _ActionButton(
                icon: Icons.send_rounded,
                label: 'シェア',
                onTap: widget.onShare,
              ),
              const SizedBox(height: 20),

              // 削除
              _ActionButton(
                icon: Icons.delete_outline_rounded,
                label: '削除',
                color: Colors.red.shade300,
                onTap: widget.onDelete,
              ),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cheatDay.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('yyyy年M月d日').format(widget.cheatDay.date),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
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
      ],
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
