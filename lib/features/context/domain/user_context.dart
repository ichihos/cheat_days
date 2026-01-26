import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザーの冷蔵庫状況と背景情報を統合したコンテキスト
class UserContext {
  final Map<String, FridgeItemStatus> fridgeStatus;
  final List<String> recentlyUsedIngredients;
  final List<String> recentlyBoughtIngredients;
  final List<String> plannedPurchases;
  final String currentSeason;
  final String dayOfWeek;
  final DateTime lastUpdated;

  UserContext({
    required this.fridgeStatus,
    required this.recentlyUsedIngredients,
    required this.recentlyBoughtIngredients,
    required this.plannedPurchases,
    required this.currentSeason,
    required this.dayOfWeek,
    required this.lastUpdated,
  });

  /// AIプロンプト用のサマリーを生成
  String toPromptSummary() {
    final buffer = StringBuffer();

    // 冷蔵庫の状況
    buffer.writeln('## 冷蔵庫の状況');
    final available =
        fridgeStatus.entries
            .where((e) => e.value.amount == 'ある' || e.value.amount == '少し')
            .toList();
    final missing =
        fridgeStatus.entries.where((e) => e.value.amount == 'なし').toList();

    if (available.isNotEmpty) {
      buffer.writeln(
        '- ありそうなもの: ${available.map((e) => "${e.key}(${e.value.amount})").join(', ')}',
      );
    }
    if (missing.isNotEmpty) {
      buffer.writeln('- なさそうなもの: ${missing.map((e) => e.key).join(', ')}');
    }

    // 最近の動き
    if (recentlyBoughtIngredients.isNotEmpty) {
      buffer.writeln('- 最近購入: ${recentlyBoughtIngredients.take(5).join(', ')}');
    }
    if (recentlyUsedIngredients.isNotEmpty) {
      buffer.writeln('- 最近使用: ${recentlyUsedIngredients.take(5).join(', ')}');
    }

    // 買い物予定
    if (plannedPurchases.isNotEmpty) {
      buffer.writeln('- 買い物リスト: ${plannedPurchases.take(5).join(', ')}');
    }

    buffer.writeln('- 季節: $currentSeason、曜日: $dayOfWeek');

    return buffer.toString();
  }

  /// 代替食材の提案用リストを取得
  List<String> getAvailableAlternatives(String missingIngredient) {
    // 簡易的な代替グループ
    const alternativeGroups = {
      '玉ねぎ': ['長ネギ', '白菜', 'キャベツ'],
      '長ネギ': ['玉ねぎ', 'ニラ', '万能ネギ'],
      '鶏肉': ['豚肉', 'ツナ', '豆腐'],
      '豚肉': ['鶏肉', 'ベーコン', 'ウインナー'],
      '牛乳': ['豆乳', 'ヨーグルト'],
      'マヨネーズ': ['ヨーグルト', 'クリームチーズ'],
      'キャベツ': ['白菜', 'レタス', 'もやし'],
      '白菜': ['キャベツ', '小松菜', 'チンゲン菜'],
      'じゃがいも': ['さつまいも', '里芋', '大根'],
      'にんじん': ['パプリカ', 'かぼちゃ'],
    };

    final alternatives = alternativeGroups[missingIngredient] ?? [];
    return alternatives.where((alt) {
      final status = fridgeStatus[alt];
      return status != null && status.amount != 'なし';
    }).toList();
  }
}

/// 個別食材の状態
class FridgeItemStatus {
  final String amount; // "ある", "少し", "なし"
  final DateTime? lastConfirmed;
  final String source; // "onboarding", "cooking", "shopping", "inferred"

  FridgeItemStatus({
    required this.amount,
    this.lastConfirmed,
    required this.source,
  });

  factory FridgeItemStatus.fromMap(Map<String, dynamic> map) {
    return FridgeItemStatus(
      amount: map['amount'] ?? 'ある',
      lastConfirmed:
          map['lastConfirmed'] != null
              ? (map['lastConfirmed'] as Timestamp).toDate()
              : null,
      source: map['source'] ?? 'onboarding',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'lastConfirmed':
          lastConfirmed != null ? Timestamp.fromDate(lastConfirmed!) : null,
      'source': source,
    };
  }

  FridgeItemStatus copyWith({
    String? amount,
    DateTime? lastConfirmed,
    String? source,
  }) {
    return FridgeItemStatus(
      amount: amount ?? this.amount,
      lastConfirmed: lastConfirmed ?? this.lastConfirmed,
      source: source ?? this.source,
    );
  }
}
