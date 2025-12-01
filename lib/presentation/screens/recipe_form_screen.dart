import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/recipe.dart';
import '../providers/firebase_providers.dart';

class RecipeFormScreen extends ConsumerStatefulWidget {
  final String? cheatDayId;
  final Recipe? existingRecipe;

  const RecipeFormScreen({
    super.key,
    this.cheatDayId,
    this.existingRecipe,
  });

  @override
  ConsumerState<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends ConsumerState<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cookingTimeController = TextEditingController();
  final _servingsController = TextEditingController();

  final List<TextEditingController> _ingredientControllers = [];
  final List<TextEditingController> _stepControllers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecipe != null) {
      _titleController.text = widget.existingRecipe!.title;
      _cookingTimeController.text = widget.existingRecipe!.cookingTimeMinutes.toString();
      _servingsController.text = widget.existingRecipe!.servings.toString();

      for (var ingredient in widget.existingRecipe!.ingredients) {
        final controller = TextEditingController(text: ingredient);
        _ingredientControllers.add(controller);
      }

      for (var step in widget.existingRecipe!.steps) {
        final controller = TextEditingController(text: step);
        _stepControllers.add(controller);
      }
    } else {
      // Start with one empty ingredient and step
      _ingredientControllers.add(TextEditingController());
      _stepControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cookingTimeController.dispose();
    _servingsController.dispose();
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientControllers[index].dispose();
      _ingredientControllers.removeAt(index);
    });
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    setState(() {
      _stepControllers[index].dispose();
      _stepControllers.removeAt(index);
    });
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.cheatDayId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投稿に紐付けてレシピを登録してください')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ingredients = _ingredientControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final steps = _stepControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (ingredients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('材料を1つ以上入力してください')),
        );
        return;
      }

      if (steps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('手順を1つ以上入力してください')),
        );
        return;
      }

      final recipe = Recipe(
        id: widget.existingRecipe?.id ??
            '${widget.cheatDayId}_recipe_${DateTime.now().millisecondsSinceEpoch}',
        cheatDayId: widget.cheatDayId!,
        title: _titleController.text,
        ingredients: ingredients,
        steps: steps,
        cookingTimeMinutes: int.parse(_cookingTimeController.text),
        servings: int.parse(_servingsController.text),
        createdAt: widget.existingRecipe?.createdAt ?? DateTime.now(),
      );

      final repository = ref.read(recipeRepositoryProvider);

      if (widget.existingRecipe != null) {
        await repository.updateRecipe(recipe);
      } else {
        await repository.addRecipe(recipe);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レシピを保存しました')),
        );
        Navigator.pop(context, recipe);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRecipe != null ? 'レシピ編集' : 'レシピ登録'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveRecipe,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // タイトル
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'レシピ名',
                hintText: '例: ジューシー唐揚げ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'レシピ名を入力してください';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // 調理時間
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cookingTimeController,
                    decoration: const InputDecoration(
                      labelText: '調理時間（分）',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '調理時間を入力してください';
                      }
                      if (int.tryParse(value) == null) {
                        return '数字を入力してください';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    decoration: const InputDecoration(
                      labelText: '人数（人前）',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '人数を入力してください';
                      }
                      if (int.tryParse(value) == null) {
                        return '数字を入力してください';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 材料
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '材料',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add_circle),
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._ingredientControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: '例: 鶏もも肉 300g',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          prefixIcon: Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}.',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_ingredientControllers.length > 1)
                      IconButton(
                        onPressed: () => _removeIngredient(index),
                        icon: const Icon(Icons.remove_circle),
                        color: Colors.red,
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // 手順
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '手順',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add_circle),
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._stepControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: '例: 鶏肉を一口大に切る',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          prefixIcon: Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}.',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                    ),
                    if (_stepControllers.length > 1)
                      IconButton(
                        onPressed: () => _removeStep(index),
                        icon: const Icon(Icons.remove_circle),
                        color: Colors.red,
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
