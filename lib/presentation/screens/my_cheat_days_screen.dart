import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/cheat_day_provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';

class MyCheatDaysScreen extends ConsumerWidget {
  const MyCheatDaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cheatDaysAsync = ref.watch(cheatDaysProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // プロフィールヘッダー
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // プロフィール画像
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8F5C)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            image:
                                currentUser.value?.photoUrl != null
                                    ? DecorationImage(
                                      image: NetworkImage(
                                        currentUser.value!.photoUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              currentUser.value?.photoUrl == null
                                  ? const Icon(
                                    Icons.person_rounded,
                                    size: 40,
                                    color: Color(0xFFFF6B35),
                                  )
                                  : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ユーザー名
                    Text(
                      currentUser.value?.displayName ?? 'ゲスト',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUser.value?.email ?? 'ログインしてダイエット記録を始めよう',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 統計カード
                    cheatDaysAsync.when(
                      data: (allCheatDays) {
                        final cheatDays =
                            currentUser.value != null
                                ? allCheatDays
                                    .where(
                                      (cd) =>
                                          cd.userId == currentUser.value!.uid,
                                    )
                                    .toList()
                                : <dynamic>[];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(
                                count: cheatDays.length,
                                label: '投稿',
                                icon: Icons.photo_library_rounded,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade200,
                              ),
                              _StatItem(
                                count: cheatDays.fold<int>(
                                  0,
                                  (sum, item) => sum + (item.likesCount as int),
                                ),
                                label: 'いいね',
                                icon: Icons.favorite_rounded,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade200,
                              ),
                              _StatItem(
                                count: _countThisMonth(cheatDays),
                                label: '今月',
                                icon: Icons.calendar_today_rounded,
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                    const SizedBox(height: 16),
                    // ログアウト/ログインボタン
                    if (currentUser.value != null)
                      TextButton.icon(
                        onPressed: () {
                          ref.read(authNotifierProvider.notifier).signOut();
                        },
                        icon: Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        label: Text(
                          'ログアウト',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('ログイン'),
                      ),
                  ],
                ),
              ),
            ),
            // セクションヘッダー
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.grid_view_rounded,
                      size: 20,
                      color: Color(0xFFFF6B35),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'マイチートデイ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    cheatDaysAsync.when(
                      data:
                          (cheatDays) => Text(
                            '${cheatDays.length}件',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
            // グリッド
            cheatDaysAsync.when(
              data: (allCheatDays) {
                final cheatDays =
                    currentUser.value != null
                        ? allCheatDays
                            .where((cd) => cd.userId == currentUser.value!.uid)
                            .toList()
                        : <dynamic>[];
                if (cheatDays.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 40,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'まだ投稿がありません',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '次のチートデイで最初の投稿をしよう！',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final cheatDay = cheatDays[index];
                      return GestureDetector(
                        onTap:
                            () => _showCheatDayDetail(context, ref, cheatDay),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(cheatDay.mediaPath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    }, childCount: cheatDays.length),
                  ),
                );
              },
              loading:
                  () => const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ),
              error:
                  (error, stack) => SliverFillRemaining(
                    child: Center(child: Text('エラー: $error')),
                  ),
            ),
            // 下部の余白
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  int _countThisMonth(List cheatDays) {
    final now = DateTime.now();
    return cheatDays
        .where((c) => c.date.year == now.year && c.date.month == now.month)
        .length;
  }

  void _showCheatDayDetail(
    BuildContext context,
    WidgetRef ref,
    dynamic cheatDay,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    cheatDay.mediaPath,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cheatDay.description,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('yyyy年M月d日').format(cheatDay.date),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                size: 16,
                                color: Color(0xFFFF6B35),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${cheatDay.likesCount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteConfirmation(context, ref, cheatDay);
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                            ),
                            label: const Text(
                              '削除',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('閉じる'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    dynamic cheatDay,
  ) {
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
                  Navigator.pop(context);
                  ref
                      .read(cheatDaysProvider.notifier)
                      .deleteCheatDay(cheatDay.id);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('削除'),
              ),
            ],
          ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.count,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFFF6B35)),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
