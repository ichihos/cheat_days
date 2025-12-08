import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/cheat_day.dart';
import '../../domain/entities/scheduled_cheat_day.dart';
import '../providers/cheat_day_provider.dart';
import '../providers/scheduled_cheat_day_provider.dart';
import 'schedule_cheat_day_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<CheatDay>> _cheatDaysByDate = {};
  final Map<DateTime, List<ScheduledCheatDay>> _scheduledByDate = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _updateCheatDaysByDate(List<CheatDay> cheatDays) {
    _cheatDaysByDate.clear();
    for (var cheatDay in cheatDays) {
      final date = DateTime(
        cheatDay.date.year,
        cheatDay.date.month,
        cheatDay.date.day,
      );
      if (_cheatDaysByDate[date] == null) {
        _cheatDaysByDate[date] = [];
      }
      _cheatDaysByDate[date]!.add(cheatDay);
    }
  }

  void _updateScheduledByDate(List<ScheduledCheatDay> scheduled) {
    _scheduledByDate.clear();
    for (var item in scheduled) {
      final date = DateTime(
        item.scheduledDate.year,
        item.scheduledDate.month,
        item.scheduledDate.day,
      );
      if (_scheduledByDate[date] == null) {
        _scheduledByDate[date] = [];
      }
      _scheduledByDate[date]!.add(item);
    }
  }

  List<CheatDay> _getCheatDaysForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _cheatDaysByDate[date] ?? [];
  }

  List<ScheduledCheatDay> _getScheduledForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _scheduledByDate[date] ?? [];
  }

  /// カレンダーにマーカーを表示するためのイベントローダー
  List<dynamic> _getEventsForDay(DateTime day) {
    final cheatDays = _getCheatDaysForDay(day);
    final scheduled = _getScheduledForDay(day);
    return [...cheatDays, ...scheduled];
  }

  /// 前回のチートデイからの日数を計算
  int? _getDaysSinceLastCheatDay(List<CheatDay> cheatDays) {
    if (cheatDays.isEmpty) return null;

    final sortedDays = List<CheatDay>.from(cheatDays)
      ..sort((a, b) => b.date.compareTo(a.date));
    final lastCheatDay = sortedDays.first.date;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .difference(
          DateTime(lastCheatDay.year, lastCheatDay.month, lastCheatDay.day),
        )
        .inDays;
  }

  /// 前回のチートデイからの日数に応じたメッセージを生成
  Widget _buildEmptyStateMessage(List<CheatDay> cheatDays) {
    final daysSinceLast = _getDaysSinceLastCheatDay(cheatDays);

    String title;
    String subtitle;
    IconData icon;

    if (daysSinceLast == null) {
      title = 'この日の投稿はありません';
      subtitle = '';
      icon = Icons.calendar_today_rounded;
    } else if (daysSinceLast == 0) {
      title = '今日はチートデイ！';
      subtitle = '今日は思いっきり食べよう！🎉';
      icon = Icons.celebration_rounded;
    } else {
      title = 'ダイエット${daysSinceLast}日目！偉い！💪';
      subtitle = '';
      icon = Icons.restaurant_rounded;
    }

    // 選択した日が未来かどうかをチェック
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate =
        _selectedDay != null
            ? DateTime(
              _selectedDay!.year,
              _selectedDay!.month,
              _selectedDay!.day,
            )
            : null;
    final canSchedule = selectedDate != null && !selectedDate.isBefore(today);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 36, color: const Color(0xFFFF6B35)),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
        // 登録ボタン（未来の日付の場合のみ表示）
        if (canSchedule) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showQuickScheduleDialog(_selectedDay!),
            icon: const Icon(Icons.add_rounded),
            label: const Text('この日をチートデイにする'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  void _showQuickScheduleDialog(DateTime selectedDate) {
    final planController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.celebration_rounded,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'チートデイを登録',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${selectedDate.month}月${selectedDate.day}日',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '何を食べる？（任意）',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: planController,
                    decoration: InputDecoration(
                      hintText: '例：焼肉、ケーキ、ラーメン...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.restaurant_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(scheduledCheatDayNotifierProvider.notifier)
                              .addScheduledCheatDay(
                                scheduledDate: selectedDate,
                                planTitle:
                                    planController.text.isNotEmpty
                                        ? planController.text
                                        : null,
                              );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('チートデイを登録しました！🎉'),
                                backgroundColor: Color(0xFFFF6B35),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('エラー: $e')));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'チートデイを登録',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _confirmDeleteScheduled(ScheduledCheatDay scheduled) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('削除確認'),
            content: Text('「${scheduled.planTitle ?? 'チートデイ予定'}」を削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref
                      .read(scheduledCheatDayNotifierProvider.notifier)
                      .deleteScheduledCheatDay(scheduled.id);
                },
                child: const Text('削除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cheatDaysAsync = ref.watch(cheatDaysProvider);
    final scheduledAsync = ref.watch(scheduledCheatDaysProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScheduleCheatDayScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFFFF6B35),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('チートデイを登録', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // カスタムヘッダー
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'チートデイカレンダー',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ダイエットの軌跡を確認',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: cheatDaysAsync.when(
                data: (cheatDays) {
                  _updateCheatDaysByDate(cheatDays);
                  // スケジュールされたチートデイも更新
                  final scheduled = scheduledAsync.value ?? [];
                  _updateScheduledByDate(scheduled);

                  final selectedDayCheatDays =
                      _selectedDay != null
                          ? _getCheatDaysForDay(_selectedDay!)
                          : <CheatDay>[];
                  final selectedDayScheduled =
                      _selectedDay != null
                          ? _getScheduledForDay(_selectedDay!)
                          : <ScheduledCheatDay>[];

                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TableCalendar(
                          firstDay: DateTime(2020, 1, 1),
                          lastDay: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDay, day);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: Color(0xFFFF6B35),
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: BoxDecoration(
                              color: const Color(0xFFFF6B35),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            markersMaxCount: 3,
                            outsideDaysVisible: false,
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            leftChevronIcon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                color: Colors.grey,
                              ),
                            ),
                            rightChevronIcon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          eventLoader: _getEventsForDay,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedDay != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  DateFormat('M/d').format(_selectedDay!),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('EEEE', 'ja').format(_selectedDay!),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              // 登録済みチートデイのバッジ
                              if (selectedDayScheduled.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.event_available_rounded,
                                        size: 14,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '予定',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // 投稿数バッジ
                              if (selectedDayCheatDays.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF6B35,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${selectedDayCheatDays.length}件投稿',
                                    style: const TextStyle(
                                      color: Color(0xFFFF6B35),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      // 選択日の内容表示
                      Expanded(
                        child:
                            (selectedDayCheatDays.isEmpty &&
                                    selectedDayScheduled.isEmpty)
                                ? SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: _buildEmptyStateMessage(cheatDays),
                                  ),
                                )
                                : ListView(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  children: [
                                    // スケジュールされたチートデイ
                                    ...selectedDayScheduled.map(
                                      (scheduled) => Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(
                                              0.3,
                                            ),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(
                                            12,
                                          ),
                                          leading: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.event_available_rounded,
                                              color: Colors.green,
                                              size: 28,
                                            ),
                                          ),
                                          title: Text(
                                            scheduled.planTitle ?? 'チートデイ予定',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle:
                                              scheduled.memo != null
                                                  ? Text(
                                                    scheduled.memo!,
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  )
                                                  : const Text(
                                                    '登録済みのチートデイ',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.grey,
                                            ),
                                            onPressed:
                                                () => _confirmDeleteScheduled(
                                                  scheduled,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // 投稿されたチートデイ
                                    ...selectedDayCheatDays.map(
                                      (cheatDay) => Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(
                                            12,
                                          ),
                                          leading: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.file(
                                              File(cheatDay.imagePath),
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          title: Text(
                                            cheatDay.description,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Row(
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 14,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat(
                                                  'HH:mm',
                                                ).format(cheatDay.date),
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: const Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.grey,
                                          ),
                                          onTap:
                                              () => _showCheatDayDetail(
                                                context,
                                                cheatDay,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ],
                  );
                },
                loading:
                    () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                error: (error, stack) => Center(child: Text('エラー: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheatDayDetail(BuildContext context, CheatDay cheatDay) {
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
                  child: Image.file(
                    File(cheatDay.imagePath),
                    height: 250,
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
                            DateFormat('yyyy年M月d日 HH:mm').format(cheatDay.date),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('閉じる'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
