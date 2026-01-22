import 'package:cheat_days/features/auth/repository/auth_repository.dart';
import 'package:cheat_days/features/records/data/meal_record_repository.dart';
import 'package:cheat_days/features/records/domain/meal_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final recordsStreamProvider = StreamProvider.autoDispose<List<MealRecord>>((
  ref,
) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  final repository = ref.watch(mealRecordRepositoryProvider);
  return repository.streamRecords(user.uid);
});

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final recordsAsync = ref.watch(recordsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ごはんの記録')),
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: selectedDate,
            currentDay: DateTime.now(),
            calendarFormat: CalendarFormat.week,
            headerStyle: const HeaderStyle(formatButtonVisible: false),
            selectedDayPredicate: (day) => isSameDay(selectedDate, day),
            onDaySelected: (selected, focused) {
              ref.read(selectedDateProvider.notifier).state = selected;
            },
            eventLoader: (day) {
              return recordsAsync.value
                      ?.where((r) => isSameDay(r.date, day))
                      .toList() ??
                  [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        events.take(3).map((_) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                  ),
                );
              },
            ),
          ),

          const Divider(),

          // List of records for selected day
          Expanded(
            child: recordsAsync.when(
              data: (records) {
                final dayRecords =
                    records
                        .where((r) => isSameDay(r.date, selectedDate))
                        .toList();

                if (dayRecords.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.no_meals,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "${DateFormat('M/d').format(selectedDate)}の記録はありません",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayRecords.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final record = dayRecords[index];
                    return Card(
                      child: ListTile(
                        leading:
                            record.imageUrl != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    record.imageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : const Icon(Icons.restaurant),
                        title: Text(record.recipeName),
                        subtitle: Text(
                          record.mealType.toUpperCase(),
                        ), // Translate later
                        trailing: Text(DateFormat('HH:mm').format(record.date)),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddRecordDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedMealType = 'dinner';
    final selectedDate = ref.read(selectedDateProvider);

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('ごはんを記録'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '料理名',
                          hintText: '例: チキン南蛮',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedMealType,
                        decoration: const InputDecoration(
                          labelText: '食事タイプ',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'breakfast',
                            child: Text('朝食'),
                          ),
                          DropdownMenuItem(value: 'lunch', child: Text('昼食')),
                          DropdownMenuItem(value: 'dinner', child: Text('夕食')),
                          DropdownMenuItem(value: 'snack', child: Text('おやつ')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedMealType = value);
                          }
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('キャンセル'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;

                        final user = ref.read(authStateProvider).value;
                        if (user == null) return;

                        final record = MealRecord(
                          id: '', // Will be generated by Firestore
                          recipeName: nameController.text.trim(),
                          mealType: selectedMealType,
                          date: selectedDate,
                          createdAt: DateTime.now(),
                        );

                        await ref
                            .read(mealRecordRepositoryProvider)
                            .addRecord(user.uid, record);

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('記録する'),
                    ),
                  ],
                ),
          ),
    );
  }
}
