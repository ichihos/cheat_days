import 'package:cheat_days/features/auth/data/user_repository.dart';
import 'package:cheat_days/features/auth/repository/auth_repository.dart';
import 'package:cheat_days/features/context/data/user_context_provider.dart';
import 'package:cheat_days/features/context/presentation/fridge_check_dialog.dart';
import 'package:cheat_days/features/home/presentation/yesterday_check_dialog.dart';
import 'package:cheat_days/features/records/data/meal_record_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// インラインプロンプトの状態
class InlinePromptsState {
  final bool showYesterdayPrompt;
  final bool showFridgePrompt;
  final bool isDismissedForSession;

  const InlinePromptsState({
    this.showYesterdayPrompt = false,
    this.showFridgePrompt = false,
    this.isDismissedForSession = false,
  });

  InlinePromptsState copyWith({
    bool? showYesterdayPrompt,
    bool? showFridgePrompt,
    bool? isDismissedForSession,
  }) {
    return InlinePromptsState(
      showYesterdayPrompt: showYesterdayPrompt ?? this.showYesterdayPrompt,
      showFridgePrompt: showFridgePrompt ?? this.showFridgePrompt,
      isDismissedForSession: isDismissedForSession ?? this.isDismissedForSession,
    );
  }
}

/// インラインプロンプトのプロバイダー
class InlinePromptsNotifier extends StateNotifier<InlinePromptsState> {
  final Ref _ref;

  InlinePromptsNotifier(this._ref) : super(const InlinePromptsState()) {
    _checkPrompts();
  }

  Future<void> _checkPrompts() async {
    try {
      // 昨日の食事チェック
      final shouldShowYesterday = await _shouldShowYesterdayCheck();

      // 冷蔵庫チェック（14日に1回に変更）
      final shouldShowFridge = await _shouldShowFridgeCheck();

      state = state.copyWith(
        showYesterdayPrompt: shouldShowYesterday,
        showFridgePrompt: shouldShowFridge,
      );
    } catch (e) {
      // エラーは無視
    }
  }

  Future<bool> _shouldShowYesterdayCheck() async {
    try {
      final user = _ref.read(authRepositoryProvider).currentUser;
      if (user == null) return false;

      final records = await _ref.read(mealRecordRepositoryProvider).getRecentRecords(user.uid, days: 7);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      final hasYesterdayRecord = records.any((r) {
        return r.date.year == yesterday.year &&
            r.date.month == yesterday.month &&
            r.date.day == yesterday.day;
      });
      return !hasYesterdayRecord;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _shouldShowFridgeCheck() async {
    try {
      final settings = await _ref.read(userSettingsProvider.future);
      // 14日に変更（元は7日）
      if (settings.lastFridgeCheckAt == null) return true;
      return DateTime.now().difference(settings.lastFridgeCheckAt!).inDays >= 14;
    } catch (e) {
      return false;
    }
  }

  void dismissYesterdayPrompt() {
    state = state.copyWith(showYesterdayPrompt: false);
  }

  void dismissFridgePrompt() {
    state = state.copyWith(showFridgePrompt: false);
  }

  void dismissAllForSession() {
    state = state.copyWith(isDismissedForSession: true);
  }

  void refresh() {
    _checkPrompts();
  }
}

final inlinePromptsProvider =
    StateNotifierProvider<InlinePromptsNotifier, InlinePromptsState>((ref) {
  return InlinePromptsNotifier(ref);
});

/// インラインプロンプトカードウィジェット
class InlinePromptCards extends ConsumerWidget {
  const InlinePromptCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inlinePromptsProvider);

    if (state.isDismissedForSession) {
      return const SizedBox.shrink();
    }

    final prompts = <Widget>[];

    if (state.showYesterdayPrompt) {
      prompts.add(_YesterdayPromptCard(
        onDismiss: () => ref.read(inlinePromptsProvider.notifier).dismissYesterdayPrompt(),
        onTap: () => _showYesterdayDialog(context, ref),
      ));
    }

    if (state.showFridgePrompt) {
      prompts.add(_FridgePromptCard(
        onDismiss: () => ref.read(inlinePromptsProvider.notifier).dismissFridgePrompt(),
        onTap: () => _showFridgeDialog(context, ref),
      ));
    }

    if (prompts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ...prompts,
        const SizedBox(height: 8),
      ],
    );
  }

  void _showYesterdayDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const YesterdayCheckDialog(),
    ).then((_) {
      ref.read(inlinePromptsProvider.notifier).dismissYesterdayPrompt();
    });
  }

  void _showFridgeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const FridgeCheckDialog(),
    ).then((_) {
      ref.read(inlinePromptsProvider.notifier).dismissFridgePrompt();
      ref.invalidate(userContextProvider);
    });
  }
}

class _YesterdayPromptCard extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _YesterdayPromptCard({
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: Colors.orange[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange[200]!),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🍽️', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '昨日何食べた？',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                      Text(
                        'タップして記録',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.orange[400], size: 20),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FridgePromptCard extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _FridgePromptCard({
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: Colors.blue[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue[200]!),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🧊', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '冷蔵庫の中身を確認',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      Text(
                        'より良い提案のために',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.blue[400], size: 20),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
