import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/scheduled_cheat_day_provider.dart';
import '../providers/auth_provider.dart';

class CheatDayCountdownDialog extends ConsumerWidget {
  const CheatDayCountdownDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final nextCheatDay = ref.watch(nextCheatDayProvider);
    final daysUntil = ref.watch(daysUntilCheatDayProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8F5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // アイコン
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                size: 45,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // タイトル
            const Text(
              'チートデイズ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '〜食べるためのダイエット〜',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // カウントダウン表示
            if (currentUser.value != null && nextCheatDay != null) ...[
              _buildCountdownContent(daysUntil!, nextCheatDay.planTitle),
            ] else if (currentUser.value != null) ...[
              _buildNoCheatDayContent(),
            ] else ...[
              _buildGuestContent(),
            ],

            const SizedBox(height: 24),

            // ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'みんなのチートデイを見る',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownContent(int daysUntil, String? planTitle) {
    if (daysUntil == 0) {
      return Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          const Text(
            '今日はチートデイ！',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '今日はダイエットお休み！思いっきり食べよう！',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          if (planTitle != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '今日の計画: $planTitle',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      children: [
        const Text(
          '次のチートデイまで',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'あと',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$daysUntil',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '日',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'ご褒美まであと少し！今日もダイエット頑張ろう💪',
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildNoCheatDayContent() {
    return Column(
      children: [
        const Icon(Icons.calendar_month_rounded, size: 48, color: Colors.white),
        const SizedBox(height: 12),
        const Text(
          'チートデイを登録しよう！',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '次のご褒美を設定して\nダイエットのモチベーションUP！',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildGuestContent() {
    return Column(
      children: [
        const Text('🍕🍔🍰🍜', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 12),
        const Text(
          'ようこそ！',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'みんなのチートデイを\nのぞいてみよう',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
        ),
      ],
    );
  }
}

/// 起動時にダイアログを表示（1日1回のみ）
Future<void> showCheatDayCountdownDialog(BuildContext context) async {
  const String lastShownKey = 'countdown_dialog_last_shown';

  final prefs = await SharedPreferences.getInstance();
  final lastShown = prefs.getString(lastShownKey);
  final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD

  // 今日既に表示済みならスキップ
  if (lastShown == today) {
    return;
  }

  // 今日表示したことを記録
  await prefs.setString(lastShownKey, today);

  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CheatDayCountdownDialog(),
    );
  }
}
