import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/cheat_day.dart';
import '../../domain/entities/scheduled_cheat_day.dart';
import '../../domain/entities/weight_record.dart';
import '../providers/cheat_day_provider.dart';
import '../providers/scheduled_cheat_day_provider.dart';
import '../providers/weight_provider.dart';
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
                  // 体重グラフボタン
                  IconButton(
                    onPressed: () => _showWeightChart(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.show_chart_rounded,
                        color: Colors.blue,
                      ),
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
                      const SizedBox(height: 12),
                      // 体重記録ボタン
                      if (_selectedDay != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ElevatedButton.icon(
                            onPressed: () => _showWeightRecordDialog(_selectedDay!),
                            icon: const Icon(Icons.monitor_weight_rounded, size: 20),
                            label: const Text('体重を記録'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
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

  /// 体重記録ダイアログを表示
  void _showWeightRecordDialog(DateTime selectedDate) {
    final weightController = TextEditingController();
    final memoController = TextEditingController();

    // 既存の体重記録を取得
    ref.read(weightRecordsProvider.notifier).getWeightRecordByDate(selectedDate).then(
      (existingRecord) {
        if (existingRecord != null && mounted) {
          weightController.text = existingRecord.weight.toString();
          memoController.text = existingRecord.memo ?? '';
        }
      },
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
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
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.monitor_weight_rounded,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '体重を記録',
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
                '体重（kg）',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: weightController,
                decoration: InputDecoration(
                  hintText: '例：65.5',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.monitor_weight_rounded),
                  suffixText: 'kg',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'メモ（任意）',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: memoController,
                decoration: InputDecoration(
                  hintText: '例：朝食前、運動後...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.note_rounded),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final weightText = weightController.text.trim();
                    if (weightText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('体重を入力してください')),
                      );
                      return;
                    }

                    final weight = double.tryParse(weightText);
                    if (weight == null || weight <= 0 || weight > 500) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('正しい体重を入力してください')),
                      );
                      return;
                    }

                    try {
                      await ref.read(weightRecordsProvider.notifier).addWeightRecord(
                        weight: weight,
                        date: selectedDate,
                        memo: memoController.text.trim().isNotEmpty
                            ? memoController.text.trim()
                            : null,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('体重を記録しました！'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('エラー: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    '記録する',
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

  /// 体重グラフを表示
  void _showWeightChart() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '体重の変化',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '過去30日間の記録',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final weightRecordsAsync = ref.watch(weightRecordsProvider);
                  return weightRecordsAsync.when(
                    data: (records) {
                      if (records.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.show_chart_rounded,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '体重の記録がありません',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return _WeightChartWidget(records: records);
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    ),
                    error: (error, stack) => Center(
                      child: Text('エラー: $error'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 体重グラフウィジェット
class _WeightChartWidget extends StatelessWidget {
  final List<WeightRecord> records;

  const _WeightChartWidget({required this.records});

  @override
  Widget build(BuildContext context) {
    // 過去30日間のデータのみを表示
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentRecords = records
        .where((r) => r.date.isAfter(thirtyDaysAgo))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (recentRecords.isEmpty) {
      return const Center(
        child: Text('過去30日間の記録がありません'),
      );
    }

    final minWeight = recentRecords.map((r) => r.weight).reduce((a, b) => a < b ? a : b);
    final maxWeight = recentRecords.map((r) => r.weight).reduce((a, b) => a > b ? a : b);
    final weightDiff = maxWeight - minWeight;
    final yMin = minWeight - (weightDiff * 0.1).clamp(1, 5);
    final yMax = maxWeight + (weightDiff * 0.1).clamp(1, 5);

    final spots = recentRecords.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 統計情報
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: '最新',
                  value: '${recentRecords.last.weight.toStringAsFixed(1)}kg',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: '最高',
                  value: '${maxWeight.toStringAsFixed(1)}kg',
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: '最低',
                  value: '${minWeight.toStringAsFixed(1)}kg',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // グラフ
          Expanded(
            child: LineChart(
              LineChartData(
                minY: yMin,
                maxY: yMax,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.blue,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(0)}kg',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= recentRecords.length) return const Text('');
                        final record = recentRecords[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${record.date.month}/${record.date.day}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade300),
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final record = recentRecords[spot.x.toInt()];
                        return LineTooltipItem(
                          '${record.weight.toStringAsFixed(1)}kg\n${record.date.month}/${record.date.day}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 統計カード
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
