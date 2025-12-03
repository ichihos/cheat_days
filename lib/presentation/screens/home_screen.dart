import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/scheduled_cheat_day_provider.dart';
import '../widgets/cheat_day_countdown_dialog.dart';
import 'tiktok_feed_screen.dart';
import 'my_cheat_days_screen.dart';
import 'calendar_screen.dart';
import 'wishlist_screen.dart';
import 'upload_screen.dart';
import 'recipe_form_screen.dart';
import 'restaurant_form_screen.dart';
import 'auth/login_screen.dart';
import 'schedule_cheat_day_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _dialogShown = false;

  final List<Widget> _screens = [
    const TikTokFeedScreen(),
    const CalendarScreen(),
    const SizedBox(), // Placeholder for post button
    const WishlistScreen(),
    const MyCheatDaysScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 起動時にダイアログを表示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dialogShown) {
        _dialogShown = true;
        showCheatDayCountdownDialog(context);
      }
    });
  }

  void _onItemTapped(int index) {
    final authState = ref.read(authStateProvider);
    final isLoggedIn = authState.value != null;

    // 投稿ボタン
    if (index == 2) {
      if (!isLoggedIn) {
        _showLoginPrompt('投稿');
      } else {
        _showPostOptions();
      }
      return;
    }

    // カレンダー、保存リスト、マイページはログイン必須
    if (index != 0 && !isLoggedIn) {
      _showLoginPrompt(_getTabName(index));
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  String _getTabName(int index) {
    switch (index) {
      case 1:
        return 'カレンダー';
      case 3:
        return '保存リスト';
      case 4:
        return 'マイページ';
      default:
        return '';
    }
  }

  void _showPostOptions() {
    final isTodayCheatDay = ref.read(isTodayCheatDayProvider);
    final nextCheatDay = ref.read(nextCheatDayProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
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

                // チートデイかどうかで表示を分岐
                if (isTodayCheatDay) ...[
                  // 今日がチートデイ！
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8F5C)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '今日はチートデイ！',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (nextCheatDay?.planTitle != null)
                                Text(
                                  nextCheatDay!.planTitle!,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'チートデイを記録',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _PostOptionTile(
                    icon: Icons.camera_alt_rounded,
                    iconColor: const Color(0xFFFF6B35),
                    title: '写真・動画を投稿',
                    subtitle: '今日の食事をシェア',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UploadScreen(),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  // チートデイじゃない日
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.lock_clock_rounded,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '今日はチートデイじゃないよ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextCheatDay != null
                              ? '次のチートデイまであと${nextCheatDay.daysUntil}日！'
                              : 'チートデイを登録しよう！',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '写真投稿はチートデイだけ 📸\nその代わり、思いっきり楽しもう！',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PostOptionTile(
                    icon: Icons.calendar_month_rounded,
                    iconColor: const Color(0xFFFF6B35),
                    title: 'チートデイを登録',
                    subtitle: '次のチートデイを決めよう',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScheduleCheatDayScreen(),
                        ),
                      );
                    },
                  ),
                ],

                const Divider(),

                // レシピ・お店登録はいつでもOK
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '以下はいつでも登録できます',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
                _PostOptionTile(
                  icon: Icons.restaurant_menu_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  title: 'レシピを登録',
                  subtitle: '自作レシピを保存',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecipeFormScreen(),
                      ),
                    );
                  },
                ),
                _PostOptionTile(
                  icon: Icons.storefront_rounded,
                  iconColor: const Color(0xFF2196F3),
                  title: 'お店を登録',
                  subtitle: 'お気に入りのお店を追加',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RestaurantFormScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLoginPrompt(String feature) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: Color(0xFFFF6B35),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$featureにはログインが必要です',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ログインして全ての機能を楽しもう！',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'ログイン / 新規登録',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'あとで',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: [
          _screens[0],
          _screens[1],
          _screens[0], // Placeholder
          _screens[3],
          _screens[4],
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.local_fire_department_rounded,
                  label: 'みんなの',
                  isSelected: _currentIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
                _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'カレンダー',
                  isSelected: _currentIndex == 1,
                  onTap: () => _onItemTapped(1),
                ),
                _CenterPostButton(onTap: () => _onItemTapped(2)),
                _NavItem(
                  icon: Icons.bookmark_rounded,
                  label: '保存リスト',
                  isSelected: _currentIndex == 3,
                  onTap: () => _onItemTapped(3),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'マイページ',
                  isSelected: _currentIndex == 4,
                  onTap: () => _onItemTapped(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PostOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color:
                  isSelected ? const Color(0xFFFF6B35) : Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color:
                    isSelected ? const Color(0xFFFF6B35) : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterPostButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CenterPostButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8F5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}
