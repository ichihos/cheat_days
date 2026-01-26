import 'package:cheat_days/features/auth/data/user_repository.dart';
import 'package:cheat_days/features/auth/domain/user_settings.dart';
import 'package:cheat_days/features/auth/repository/auth_repository.dart';
import 'package:cheat_days/features/pantry/data/pantry_repository.dart';
import 'package:cheat_days/features/pantry/domain/pantry_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _dislikedInputController =
      TextEditingController();
  final Map<String, TextEditingController> _pantryControllers = {};

  int _currentPage = 0;
  bool _isSubmitting = false;

  // Step 1: Serving size
  int _servingSize = 2;

  // Step 2: Disliked ingredients
  final Set<String> _dislikedIngredients = {};
  static const List<String> _commonDisliked = [
    'パクチー',
    'セロリ',
    'レバー',
    '牡蠣',
    '納豆',
    '生魚',
    'しいたけ',
    'グリーンピース',
    'にんじん',
    'ピーマン',
  ];

  // Step 3: Pantry items
  final Set<String> _selectedPantryItems = {};
  // Mutable copy for display
  final Map<String, List<String>> _displayedPantryItems = {};

  static const Map<String, List<String>> _initialPantryCategories = {
    '肉類': ['鶏もも肉', '鶏むね肉', '豚バラ肉', '豚こま肉', '牛肉', 'ひき肉'],
    '野菜': ['玉ねぎ', 'にんじん', 'キャベツ', 'じゃがいも', 'もやし', 'ねぎ', 'にんにく'],
    '卵・乳製品': ['卵', '牛乳', 'バター', 'チーズ'],
    '豆腐・加工品': ['豆腐', '油揚げ', 'ウインナー', 'ベーコン', 'ハム'],
    '調味料': ['醤油', '味噌', '酒', 'みりん', '砂糖', '塩', 'マヨネーズ', 'ケチャップ'],
  };

  @override
  void initState() {
    super.initState();
    // Initialize mutable pantry items
    _initialPantryCategories.forEach((key, value) {
      _displayedPantryItems[key] = List.from(value);
      _pantryControllers[key] = TextEditingController();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dislikedInputController.dispose();
    for (var controller in _pantryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _nextPage() {
    if (_isSubmitting) return;

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      // Save user settings
      final settings = UserSettings(
        servingSize: _servingSize,
        dislikedIngredients: _dislikedIngredients.toList(),
        isOnboardingComplete: true,
        totalRecordsCount: 0,
        lastFridgeCheckAt: DateTime.now(),
      );

      await ref.read(userRepositoryProvider).updateSettings(user.uid, settings);

      if (!mounted) return;

      // Save pantry items
      final pantryRepo = ref.read(pantryRepositoryProvider);

      // Batch writes would be better, but loop is okay for now
      for (final itemName in _selectedPantryItems) {
        await pantryRepo.addItem(
          user.uid,
          PantryItem(
            id: '',
            ingredientName: itemName,
            estimatedAmount: 'ある',
            lastPurchased: DateTime.now(),
          ),
        );
      }

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      debugPrint('Onboarding error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color:
                            index <= _currentPage
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildDislikedPage(),
                  _buildPantryPage(),
                ],
              ),
            ),

            // Next button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(_currentPage < 2 ? '次へ' : '始める！'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/messie.png',
            width: 150,
            height: 150,
            errorBuilder:
                (_, __, ___) =>
                    const Text("🦕", style: TextStyle(fontSize: 100)),
          ),
          const SizedBox(height: 24),
          Text(
            'ようこそ！',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            '「メッシーっシー！\n一緒に今日のごはん決めるっシー」',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 40),
          const Text(
            '何人分の食事を作る？',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                [1, 2, 3].map((size) {
                  final isSelected = _servingSize == size;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ChoiceChip(
                      label: Text(size == 3 ? '3人以上' : '$size人'),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _servingSize = size),
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDislikedPage() {
    // Separate custom items from common items
    final customSelected =
        _dislikedIngredients
            .where((item) => !_commonDisliked.contains(item))
            .toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            '苦手な食材ある？',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('「避けて提案するっシー」', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Common Items
                  const Text(
                    "よくある苦手なもの",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        _commonDisliked.map((ingredient) {
                          final isSelected = _dislikedIngredients.contains(
                            ingredient,
                          );
                          return FilterChip(
                            label: Text(ingredient),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _dislikedIngredients.add(ingredient);
                                } else {
                                  _dislikedIngredients.remove(ingredient);
                                }
                              });
                            },
                            selectedColor: Colors.red[100],
                            checkmarkColor: Colors.red,
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Custom Input
                  const Text(
                    "その他（自由入力）",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dislikedInputController,
                          decoration: const InputDecoration(
                            hintText: '例: オクラ',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (_) => _addCustomDisliked(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addCustomDisliked,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),

                  if (customSelected.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          customSelected.map((item) {
                            return InputChip(
                              label: Text(item),
                              onDeleted: () {
                                setState(() {
                                  _dislikedIngredients.remove(item);
                                });
                              },
                              deleteIcon: const Icon(Icons.close, size: 16),
                              backgroundColor: Colors.red[50],
                            );
                          }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '選択: ${_dislikedIngredients.length}個',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  void _addCustomDisliked() {
    final text = _dislikedInputController.text.trim();
    if (text.isNotEmpty && !_dislikedIngredients.contains(text)) {
      setState(() {
        _dislikedIngredients.add(text);
        _dislikedInputController.clear();
      });
    }
  }

  Widget _buildPantryPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            '冷蔵庫にあるもの',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('「今の冷蔵庫の中身を教えてっシー！」', style: TextStyle(color: Colors.grey[600])),

          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children:
                  _displayedPantryItems.keys.map((category) {
                    final items = _displayedPantryItems[category]!;
                    final controller = _pantryControllers[category]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              items.map((item) {
                                final isSelected = _selectedPantryItems
                                    .contains(item);
                                return FilterChip(
                                  label: Text(item),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedPantryItems.add(item);
                                      } else {
                                        _selectedPantryItems.remove(item);
                                      }
                                    });
                                  },
                                  selectedColor: Colors.green[100],
                                  checkmarkColor: Colors.green,
                                );
                              }).toList(),
                        ),

                        // Category input
                        Padding(
                          padding: const EdgeInsets.only(top: 8, right: 40),
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: '$categoryに追加...',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 8,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  _addPantryItem(category, controller);
                                },
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            onSubmitted:
                                (_) => _addPantryItem(category, controller),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '選択: ${_selectedPantryItems.length}個',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  void _addPantryItem(String category, TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        if (!_displayedPantryItems[category]!.contains(text)) {
          _displayedPantryItems[category]!.add(text);
        }
        _selectedPantryItems.add(text); // Auto select added item
        controller.clear();
      });
    }
  }
}
