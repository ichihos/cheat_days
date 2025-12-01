import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/cheat_memo_provider.dart';

class MemoScreen extends ConsumerStatefulWidget {
  const MemoScreen({super.key});

  @override
  ConsumerState<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends ConsumerState<MemoScreen> {
  final _memoController = TextEditingController();

  void _showAddMemoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('次のチートデイメモ'),
        content: TextField(
          controller: _memoController,
          decoration: const InputDecoration(
            hintText: '例: 焼肉食べ放題に行く',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _memoController.clear();
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_memoController.text.isNotEmpty) {
                ref
                    .read(cheatMemosProvider.notifier)
                    .addMemo(_memoController.text);
                Navigator.of(context).pop();
                _memoController.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memosAsync = ref.watch(cheatMemosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('次のチートデイメモ'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: memosAsync.when(
        data: (memos) {
          if (memos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_add_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '次のチートデイのメモを追加しましょう',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final pendingMemos = memos.where((m) => !m.isCompleted).toList();
          final completedMemos = memos.where((m) => m.isCompleted).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pendingMemos.isNotEmpty) ...[
                const Text(
                  '予定',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...pendingMemos.map((memo) => _MemoCard(
                      memo: memo,
                      onToggle: () {
                        ref
                            .read(cheatMemosProvider.notifier)
                            .toggleMemoCompletion(memo.id);
                      },
                      onDelete: () {
                        ref
                            .read(cheatMemosProvider.notifier)
                            .deleteMemo(memo.id);
                      },
                    )),
              ],
              if (completedMemos.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  '達成済み',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                ...completedMemos.map((memo) => _MemoCard(
                      memo: memo,
                      onToggle: () {
                        ref
                            .read(cheatMemosProvider.notifier)
                            .toggleMemoCompletion(memo.id);
                      },
                      onDelete: () {
                        ref
                            .read(cheatMemosProvider.notifier)
                            .deleteMemo(memo.id);
                      },
                    )),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラー: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMemoDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _MemoCard extends StatelessWidget {
  final dynamic memo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _MemoCard({
    required this.memo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: memo.isCompleted,
          onChanged: (_) => onToggle(),
          activeColor: Colors.orange,
        ),
        title: Text(
          memo.content,
          style: TextStyle(
            decoration: memo.isCompleted ? TextDecoration.lineThrough : null,
            color: memo.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          DateFormat('yyyy/MM/dd HH:mm').format(memo.createdAt),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('削除確認'),
                content: const Text('このメモを削除しますか?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      onDelete();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('削除'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
