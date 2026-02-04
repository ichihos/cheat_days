import 'package:cheat_days/features/admin/data/admin_ai_service.dart';
import 'package:cheat_days/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiRecipeGeneratorScreen extends ConsumerStatefulWidget {
  const AiRecipeGeneratorScreen({super.key});

  @override
  ConsumerState<AiRecipeGeneratorScreen> createState() =>
      _AiRecipeGeneratorScreenState();
}

class _AiRecipeGeneratorScreenState
    extends ConsumerState<AiRecipeGeneratorScreen> {
  final _recipeNamesController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isGenerating = false;
  RecipeGenerationProgress? _progress;
  String _currentStatus = '';

  @override
  void dispose() {
    _recipeNamesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _parseRecipeNames() {
    return _recipeNamesController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _startGeneration() async {
    final recipeNames = _parseRecipeNames();
    if (recipeNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('レシピ名を入力してください')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _progress = null;
      _currentStatus = '準備中...';
    });

    final service = ref.read(adminAiServiceProvider);

    await for (final progress in service.generateMultipleRecipes(recipeNames)) {
      if (mounted) {
        setState(() {
          _progress = progress;
          _currentStatus = progress.currentTask;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isGenerating = false;
      });

      // リストを更新
      ref.invalidate(recipeListProvider);

      // 結果ダイアログを表示
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    if (_progress == null) return;

    final successCount = _progress!.results.where((r) => r.success).length;
    final errorCount = _progress!.results.where((r) => !r.success).length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          errorCount == 0 ? '✅ 生成完了' : '⚠️ 一部エラーあり',
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('成功: $successCount件'),
              if (errorCount > 0)
                Text(
                  '失敗: $errorCount件',
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              const Text('結果:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _progress!.results.length,
                  itemBuilder: (context, index) {
                    final result = _progress!.results[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        result.success ? Icons.check_circle : Icons.error,
                        color: result.success ? Colors.green : Colors.red,
                      ),
                      title: Text(result.name),
                      subtitle: result.error != null
                          ? Text(
                              result.error!,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.red),
                            )
                          : null,
                      trailing: result.recipe?.imageUrl.isNotEmpty == true
                          ? SizedBox(
                              width: 40,
                              height: 40,
                              child: Image.network(
                                result.recipe!.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_not_supported),
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipeNames = _parseRecipeNames();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI レシピ一括生成'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左側: 入力エリア
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'レシピ名を入力（1行に1つ）',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '例:\n肉じゃが\n味噌汁\nサバの味噌煮\n...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TextField(
                          controller: _recipeNamesController,
                          maxLines: null,
                          expands: true,
                          enabled: !_isGenerating,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'レシピ名を入力...',
                            alignLabelWithHint: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            '${recipeNames.length}件のレシピ',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _isGenerating ? null : _startGeneration,
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(
                              _isGenerating ? '生成中...' : 'AI生成開始',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // 右側: 進捗表示
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '生成進捗',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_progress != null) ...[
                        LinearProgressIndicator(
                          value: _progress!.progress,
                          backgroundColor: Colors.grey[200],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_progress!.completed}/${_progress!.total} 完了',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        _currentStatus,
                        style: TextStyle(
                          color: _isGenerating
                              ? Colors.deepPurple
                              : Colors.grey[600],
                          fontWeight: _isGenerating
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        '生成結果',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _progress?.results.isEmpty ?? true
                            ? Center(
                                child: Text(
                                  _isGenerating
                                      ? '生成を開始しました...'
                                      : 'レシピ名を入力して「AI生成開始」を押してください',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                itemCount: _progress!.results.length,
                                itemBuilder: (context, index) {
                                  final result = _progress!.results[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: result.recipe?.imageUrl
                                                  .isNotEmpty ==
                                              true
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                result.recipe!.imageUrl,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: result.success
                                                    ? Colors.green[50]
                                                    : Colors.red[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                result.success
                                                    ? Icons.check
                                                    : Icons.error_outline,
                                                color: result.success
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                      title: Text(result.name),
                                      subtitle: result.success
                                          ? Text(
                                              '${result.recipe?.ingredients.length ?? 0}材料 / ${result.recipe?.steps.length ?? 0}手順',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            )
                                          : Text(
                                              result.error ?? 'エラー',
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                              ),
                                            ),
                                      trailing: Icon(
                                        result.success
                                            ? Icons.check_circle
                                            : Icons.error,
                                        color: result.success
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
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
