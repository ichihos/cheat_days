import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/cheat_day.dart';
import '../providers/cheat_day_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<CheatDay>> _cheatDaysByDate = {};

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

  List<CheatDay> _getCheatDaysForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _cheatDaysByDate[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final cheatDaysAsync = ref.watch(cheatDaysProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('チートデイカレンダー'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: cheatDaysAsync.when(
        data: (cheatDays) {
          _updateCheatDaysByDate(cheatDays);
          final selectedDayCheatDays =
              _selectedDay != null
                  ? _getCheatDaysForDay(_selectedDay!)
                  : <CheatDay>[];

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime(2020, 1, 1),
                lastDay: DateTime.now(),
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
                    color: Colors.orange.shade200,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                eventLoader: _getCheatDaysForDay,
              ),
              const SizedBox(height: 16),
              if (_selectedDay != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    DateFormat('yyyy年MM月dd日').format(_selectedDay!),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child:
                    selectedDayCheatDays.isEmpty
                        ? const Center(
                          child: Text(
                            'この日のチートデイはありません',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: selectedDayCheatDays.length,
                          itemBuilder: (context, index) {
                            final cheatDay = selectedDayCheatDays[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
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
                                subtitle: Text(
                                  DateFormat('HH:mm').format(cheatDay.date),
                                ),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => Dialog(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.file(
                                                File(cheatDay.imagePath),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  16.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      cheatDay.description,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      DateFormat(
                                                        'yyyy/MM/dd HH:mm',
                                                      ).format(cheatDay.date),
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed:
                                                        () =>
                                                            Navigator.of(
                                                              context,
                                                            ).pop(),
                                                    child: const Text('閉じる'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }
}
