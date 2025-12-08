import '../entities/weight_record.dart';

abstract class WeightRepository {
  /// 体重記録を追加
  Future<void> addWeightRecord(WeightRecord record);

  /// 体重記録を更新
  Future<void> updateWeightRecord(WeightRecord record);

  /// 体重記録を削除
  Future<void> deleteWeightRecord(String id);

  /// ユーザーの全体重記録を取得
  Future<List<WeightRecord>> getWeightRecords(String userId);

  /// 指定期間の体重記録を取得
  Future<List<WeightRecord>> getWeightRecordsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// 特定日の体重記録を取得
  Future<WeightRecord?> getWeightRecordByDate(String userId, DateTime date);
}
