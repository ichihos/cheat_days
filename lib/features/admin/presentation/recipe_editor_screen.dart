import 'dart:convert';
import 'dart:typed_data';
import 'package:cheat_days/features/recipes/data/recipe_repository.dart';
import 'package:cheat_days/features/recipes/domain/recipe.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class RecipeEditorScreen extends ConsumerStatefulWidget {
  final Recipe? recipe;
  const RecipeEditorScreen({super.key, this.recipe});

  @override
  ConsumerState<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends ConsumerState<RecipeEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(text: 'main');

  // Lists
  List<Ingredient> _ingredients = [];
  List<String> _steps = [];

  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      final r = widget.recipe!;
      _nameCtrl.text = r.name;
      _imageUrlCtrl.text = r.imageUrl;
      _timeCtrl.text = r.timeMinutes.toString();
      _costCtrl.text = r.costYen.toString();
      _categoryCtrl.text = r.category;
      _ingredients = List.from(r.ingredients);
      _steps = List.from(r.steps);
    } else {
      // Init with one empty item so valid can run? No, empty lists ok
    }
  }

  // AI JSON Import (Paste)
  void _importJson(String jsonStr) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      // Basic mapping
      setState(() {
        _nameCtrl.text = data['name'] ?? _nameCtrl.text;
        _timeCtrl.text = data['timeMinutes']?.toString() ?? _timeCtrl.text;
        _costCtrl.text = data['costYen']?.toString() ?? _costCtrl.text;
        // ... parse ingredients ...
        if (data['ingredients'] != null) {
          _ingredients =
              (data['ingredients'] as List)
                  .map(
                    (i) => Ingredient(
                      name: i['name'],
                      amount: i['amount']?.toString() ?? '',
                      unit: i['unit'] ?? '',
                      isMain: i['isMain'] ?? false,
                    ),
                  )
                  .toList();
        }
        if (data['steps'] != null) {
          _steps = List<String>.from(data['steps']);
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("JSON Imported!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("JSON Error: $e")));
    }
  }

  // Image Upload
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    // pickImage returns XFile.
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        Uint8List data = await image.readAsBytes();
        String fileName = 'recipes/${const Uuid().v4()}.jpg';
        Reference ref = FirebaseStorage.instance.ref().child(fileName);

        // Metadata
        await ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
        String url = await ref.getDownloadURL();

        setState(() {
          _imageUrlCtrl.text = url;
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload Failed: $e")));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newRecipe = Recipe(
        id: widget.recipe?.id ?? const Uuid().v4(), // Use existing ID if edit
        name: _nameCtrl.text,
        imageUrl: _imageUrlCtrl.text,
        category: _categoryCtrl.text,
        cuisine: 'japanese', // hardcoded or add field
        timeMinutes: int.tryParse(_timeCtrl.text) ?? 30,
        costYen: int.tryParse(_costCtrl.text) ?? 500,
        ingredients: _ingredients,
        steps: _steps,
        createdAt: widget.recipe?.createdAt ?? DateTime.now(),
        difficulty: 1,
        seasons: [],
        tags: [],
        calories: 0,
      );

      // We need a repository that supports update/add logic cleanly.
      // For now using addRecipe (which calls set or add).
      // If editing, we want to SET with specific ID.
      // Let's modify Repo or just call Firestore directly in repo.
      // Let's assume repo.addRecipe handles overwrite if ID exists?
      // RecipeRepository.addRecipe uses .add(recipe.toMap()) which generates NEW ID.
      // To support edit, we need repo.updateRecipe or setRecipe.
      // I will add `setRecipe` to repo later or manually do it here.
      // For now, let's create a NEW one if adding, but wait..
      // Admin needs to Edit.
      // I will add `setRecipe` implementation in next step.

      await ref
          .read(recipeRepositoryProvider)
          .saveRecipe(newRecipe); // I will alias 'save' to set

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? "Add Recipe" : "Edit Recipe"),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () {
              // Show dialog to paste JSON
              final c = TextEditingController();
              showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: const Text("Paste JSON"),
                      content: TextField(controller: c, maxLines: 10),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            _importJson(c.text);
                            Navigator.pop(context);
                          },
                          child: const Text("Import"),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // --- Basic Info ---
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Recipe Name",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _timeCtrl,
                    decoration: const InputDecoration(labelText: "Docs (min)"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _costCtrl,
                    decoration: const InputDecoration(labelText: "Cost (¥)"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // --- Image ---
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _imageUrlCtrl,
                    decoration: const InputDecoration(labelText: "Image URL"),
                  ),
                ),
                IconButton(
                  onPressed: _isUploading ? null : _pickAndUploadImage,
                  icon: const Icon(Icons.image_search),
                ),
                IconButton(
                  tooltip: 'Generate Image Prompt',
                  onPressed: () {
                    final prompt =
                        "次の料理の画像をイラスト風に生成してください。指定以外のメニューは描かず。美味しそうに。\n${_nameCtrl.text}";
                    Clipboard.setData(ClipboardData(text: prompt));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Image prompt copied to clipboard!"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
            if (_isUploading) const LinearProgressIndicator(),
            if (_imageUrlCtrl.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: 150,
                  child: Image.network(_imageUrlCtrl.text),
                ),
              ),

            const Divider(height: 32),

            // --- Ingredients ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Ingredients",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    setState(
                      () => _ingredients.add(
                        Ingredient(
                          name: '',
                          amount: '',
                          unit: '',
                          isMain: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle),
                ),
              ],
            ),
            ..._ingredients.asMap().entries.map((entry) {
              int idx = entry.key;
              Ingredient i = entry.value;
              return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: i.name,
                      onChanged: (v) => _ingredients[idx] = i.copyWith(name: v),
                      decoration: const InputDecoration(hintText: "Name"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: i.amount,
                      onChanged:
                          (v) => _ingredients[idx] = i.copyWith(amount: v),
                      decoration: const InputDecoration(hintText: "Amt"),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() => _ingredients.removeAt(idx));
                    },
                  ),
                ],
              );
            }),

            const Divider(height: 32),

            // --- Steps ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Steps",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _steps.add(''));
                  },
                  icon: const Icon(Icons.add_circle),
                ),
              ],
            ),
            ..._steps.asMap().entries.map((entry) {
              int idx = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Text("${idx + 1}."),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: entry.value,
                        onChanged: (v) => _steps[idx] = v,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() => _steps.removeAt(idx));
                      },
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: _isSaving ? null : _save,
              child:
                  _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Recipe"),
            ),
          ],
        ),
      ),
    );
  }
}
