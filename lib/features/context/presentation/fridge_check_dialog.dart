import 'package:cheat_days/features/auth/data/user_repository.dart';
import 'package:cheat_days/features/auth/domain/user_settings.dart';
import 'package:cheat_days/features/auth/repository/auth_repository.dart';
import 'package:cheat_days/features/context/data/user_context_provider.dart';
import 'package:cheat_days/features/pantry/data/pantry_repository.dart';
import 'package:cheat_days/features/pantry/domain/pantry_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 冷蔵庫確認ダイアログ
/// 2週間に1回、ユーザーに冷蔵庫の中身を確認してもらう
class FridgeCheckDialog extends ConsumerStatefulWidget {
  const FridgeCheckDialog({super.key});

  /// 冷蔵庫確認が必要か判定（最終確認から14日以上経過）
  static bool needsCheck(UserSettings settings) {
    if (settings.lastFridgeCheckAt == null) return true;
    final daysSinceCheck =
        DateTime.now().difference(settings.lastFridgeCheckAt!).inDays;
    return daysSinceCheck >= 14;
  }

  @override
  ConsumerState<FridgeCheckDialog> createState() => _FridgeCheckDialogState();
}

class _FridgeCheckDialogState extends ConsumerState<FridgeCheckDialog> {
  final Map<String, String> _fridgeStatus = {};
  bool _isLoading = true;
  bool _isSaving = false;

  // カテゴリー別の食材リスト
  static const Map<String, List<String>> _categories = {
    '肉・魚': ['鶏肉', '豚肉', '牛肉', 'ひき肉', '魚', 'ツナ缶'],
    '野菜': ['玉ねぎ', 'にんじん', 'じゃがいも', 'キャベツ', '白菜', 'もやし', 'トマト', 'きゅうり'],
    '卵・乳製品': ['卵', '牛乳', 'チーズ', 'バター', 'ヨーグルト'],
    '調味料': ['醤油', '味噌', '酒', 'みりん', '砂糖', '塩', 'マヨネーズ', 'ケチャップ'],
    '主食': ['米', 'パン', '麺類', '豆腐'],
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    try {
      // UserContextから推測状態を読み込む
      final context = await ref.read(userContextProvider.future);
      if (context != null && mounted) {
        setState(() {
          for (final entry in context.fridgeStatus.entries) {
            _fridgeStatus[entry.key] = entry.value.amount;
          }
          // まだ登録されていない食材はデフォルト値を設定
          for (final category in _categories.values) {
            for (final item in category) {
              _fridgeStatus.putIfAbsent(item, () => 'なし');
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      // フォールバック: 全てなしにする
      if (mounted) {
        setState(() {
          for (final category in _categories.values) {
            for (final item in category) {
              _fridgeStatus.putIfAbsent(item, () => 'なし');
            }
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAndClose() async {
    setState(() => _isSaving = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        setState(() => _isSaving = false);
        return;
      }

      final pantryRepo = ref.read(pantryRepositoryProvider);

      // パントリーを更新（存在すれば更新、なければ作成）
      for (final entry in _fridgeStatus.entries) {
        await pantryRepo.upsertByName(
          user.uid,
          PantryItem(
            id: '', // upsertByNameでは使用しない
            ingredientName: entry.key,
            estimatedAmount: entry.value,
            lastPurchased: entry.value != 'なし' ? DateTime.now() : null,
          ),
        );
      }

      // 最終確認日時を更新
      final userRepo = ref.read(userRepositoryProvider);
      final currentSettings = await ref.read(userSettingsProvider.future);
      await userRepo.updateSettings(
        user.uid,
        currentSettings.copyWith(lastFridgeCheckAt: DateTime.now()),
      );

      // userContextProviderをリフレッシュ
      ref.invalidate(userContextProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存中にエラーが発生しました: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/messie.png',
                    width: 40,
                    height: 40,
                    errorBuilder:
                        (_, __, ___) =>
                            const Text('🦕', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '冷蔵庫チェック',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '今ある食材を教えてっシー',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              _categories.entries.map((category) {
                                return _buildCategory(
                                  category.key,
                                  category.value,
                                );
                              }).toList(),
                        ),
                      ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving
                              ? null
                              : () => Navigator.of(context).pop(false),
                      child: const Text('スキップ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAndClose,
                      child:
                          _isSaving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('確認完了'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(String name, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => _buildItemChip(item)).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildItemChip(String item) {
    final status = _fridgeStatus[item] ?? 'なし';

    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'ある':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case '少し':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade600;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          // サイクル: なし -> ある -> 少し -> なし
          switch (status) {
            case 'なし':
              _fridgeStatus[item] = 'ある';
              break;
            case 'ある':
              _fridgeStatus[item] = '少し';
              break;
            case '少し':
              _fridgeStatus[item] = 'なし';
              break;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: textColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item, style: TextStyle(color: textColor, fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              status == 'なし' ? '✕' : (status == 'ある' ? '◎' : '△'),
              style: TextStyle(color: textColor, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
