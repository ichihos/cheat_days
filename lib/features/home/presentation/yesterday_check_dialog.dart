import 'package:cheat_days/features/auth/data/user_repository.dart';

import 'package:cheat_days/features/auth/repository/auth_repository.dart';
import 'package:cheat_days/features/home/data/ai_service.dart';
import 'package:cheat_days/features/pantry/data/pantry_repository.dart';
import 'package:cheat_days/features/records/data/meal_record_repository.dart';
import 'package:cheat_days/features/records/domain/meal_record.dart';
import 'package:cheat_days/features/recipes/data/recipe_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class YesterdayCheckDialog extends ConsumerStatefulWidget {
  const YesterdayCheckDialog({super.key});

  @override
  ConsumerState<YesterdayCheckDialog> createState() =>
      _YesterdayCheckDialogState();
}

class _YesterdayCheckDialogState extends ConsumerState<YesterdayCheckDialog> {
  final TextEditingController _mealController = TextEditingController();
  String _selectedMealType = 'dinner';
  bool _isLoading = false;

  Future<void> _recordMeal() async {
    if (_mealController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final recipeName = _mealController.text.trim();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    final record = MealRecord(
      id: '',
      recipeName: recipeName,
      mealType: _selectedMealType,
      date: yesterday,
      createdAt: DateTime.now(),
    );

    await ref.read(mealRecordRepositoryProvider).addRecord(user.uid, record);

    // Update record count
    await _incrementRecordCount();

    // Get AI feedback
    await _showRecipeFeedback(recipeName);

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _incrementRecordCount() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      final currentSettings = await ref.read(userSettingsProvider.future);
      final newCount = currentSettings.totalRecordsCount + 1;

      final updatedSettings = currentSettings.copyWith(
        totalRecordsCount: newCount,
        lastRecordDate: DateTime.now(),
      );

      await ref
          .read(userRepositoryProvider)
          .updateSettings(user.uid, updatedSettings);
    } catch (e) {
      debugPrint('Failed to update record count: $e');
    }
  }

  Future<void> _showRecipeFeedback(String recipeName) async {
    try {
      final aiService = ref.read(aiServiceProvider);
      final recipes = await ref.read(recipeRepositoryProvider).getAllRecipes();

      if (mounted) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );
      }

      final feedback = await aiService.getRecipeFeedback(
        recipeName: recipeName,
        availableRecipes: recipes,
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        if (feedback != null) {
          showDialog(
            context: context,
            builder: (ctx) => FeedbackDialog(initialFeedback: feedback),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading on error
      debugPrint('Failed to get recipe feedback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Image.asset(
            'assets/images/messie.png',
            width: 40,
            height: 40,
            errorBuilder:
                (_, __, ___) =>
                    const Text("🦕", style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('昨日何食べたっシー？', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _mealController,
            decoration: const InputDecoration(
              labelText: '料理名',
              hintText: '例: チキン南蛮',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedMealType,
            decoration: const InputDecoration(
              labelText: '食事タイプ',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'breakfast', child: Text('朝食')),
              DropdownMenuItem(value: 'lunch', child: Text('昼食')),
              DropdownMenuItem(value: 'dinner', child: Text('夕食')),
            ],
            onChanged:
                _isLoading
                    ? null
                    : (value) {
                      if (value != null)
                        setState(() => _selectedMealType = value);
                    },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('外食した'),
        ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('スキップ'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _recordMeal,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('記録する'),
        ),
      ],
    );
  }
}

class FeedbackDialog extends ConsumerStatefulWidget {
  final RecipeFeedback initialFeedback;

  const FeedbackDialog({super.key, required this.initialFeedback});

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  late RecipeFeedback _currentFeedback;
  final TextEditingController _questionController = TextEditingController();
  bool _isAsking = false;
  String? _chatResponse;

  @override
  void initState() {
    super.initState();
    _currentFeedback = widget.initialFeedback;
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() => _isAsking = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        final settings = await ref.read(userSettingsProvider.future);
        final pantry = await ref
            .read(pantryRepositoryProvider)
            .getPantryItems(user.uid);
        final recent = await ref
            .read(mealRecordRepositoryProvider)
            .getRecentRecords(user.uid);

        final response = await ref
            .read(aiServiceProvider)
            .chatWithMessie(
              message: question,
              settings: settings,
              pantryItems: pantry,
              recentMeals: recent,
            );

        setState(() {
          _chatResponse = response;
          _questionController.clear();
        });
      }
    } catch (e) {
      debugPrint('Chat error: $e');
    } finally {
      if (mounted) setState(() => _isAsking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Image.asset(
            'assets/images/messie.png',
            width: 40,
            height: 40,
            errorBuilder:
                (_, __, ___) =>
                    const Text("🦕", style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('メッシーより')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Messie's Main Comment
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _chatResponse ?? _currentFeedback.comment,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 16),

            if (_chatResponse == null) ...[
              // Suggestion
              if (_currentFeedback.similarRecipeName != null) ...[
                const Text(
                  '📌 次のおすすめ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentFeedback.similarRecipeName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_currentFeedback.similarRecipeReason != null)
                        Text(
                          _currentFeedback.similarRecipeReason!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tip
              const Text(
                '💡 豆知識',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentFeedback.arrangement,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Question Input
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'メッシーに質問する...',
                suffixIcon: IconButton(
                  icon:
                      _isAsking
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.send),
                  onPressed: _isAsking ? null : _askQuestion,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _askQuestion(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

/// Check if we should show yesterday's meal dialog
Future<bool> shouldShowYesterdayCheck(WidgetRef ref) async {
  final user = ref.read(authStateProvider).value;
  if (user == null) return false;

  try {
    // Get yesterday's records
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final records = await ref
        .read(mealRecordRepositoryProvider)
        .getRecentRecords(user.uid, days: 2);

    // Check if there's any record from yesterday
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
