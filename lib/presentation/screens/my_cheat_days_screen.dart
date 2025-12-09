import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cheat_day_provider.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/cheat_day.dart';
import 'auth/login_screen.dart';
import 'cheat_day_detail_screen.dart';

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
                            .cast<CheatDay>()
                        : <CheatDay>[];
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => CheatDayDetailScreen(
                                    cheatDay: cheatDay,
                                    cheatDays: cheatDays,
                                    initialIndex: index,
                                  ),
                            ),
                          );
                        },
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
