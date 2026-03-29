/// 厚生年金（企業年金）計算入力パラメータ
/// 
/// 日本の厚生年金保険制度に基づいて、厚生年金額を計算するための入力データを定義。
/// 厚生年金は、民間企業に勤める労働者が加入する強制加入制度。
/// 
/// 【参考資料】
/// - 日本年金機構「厚生年金保険」
///   https://www.nenkin.go.jp/service/kousei-nenkin/kousei-nenkin.html
/// - 厚生労働省「2024年度の年金額改定について」
///   https://www.mhlw.go.jp/steshingi/nenkin/
/// 
/// 【厚生年金の構成】
/// 厚生年金は以下の2つの部分から構成される：
/// 1. **基礎年金部分**: 国民年金と同じ基礎年金（月額 ¥69,308）
/// 2. **報酬比例部分**: 給与・ボーナス（総報酬）に基づく追加部分
/// 
/// 本クラスは報酬比例部分を計算するための入力値を管理する。
/// 
/// 【報酬比例年金額の計算式】
/// 報酬比例年金額 = 平均標準報酬月額 × 加入月数 × 0.005481
///                 + 平均標準報酬額 × 加入月数 × 0.001738
/// 
/// ※ 係数（0.005481, 0.001738）は毎年見直される
/// ※ 2024年時点の簡略化係数（実際は複雑な計算スキーム）
/// 
/// 【加入期間】
/// - 最長: 600月（50年）（20歳～70歳）
/// - 受給開始: 通常65歳（2025年以降段階的に引き上げ予定）
/// 
/// 【納付状況について】
/// - 雇用者: 月給与から保険料を天引きされる（給与の約9.15%程度）
/// - 雇用者が負担する保険料率も同率（従業員負担と同額）
/// - 自営業者は国民年金のみ加入（厚生年金の制度対象外）
class OccupationalPensionInput {
  /// 厚生年金の報酬比例部分の計算係数（月額報酬用）
  /// 
  /// 毎年10月に見直される
  /// 2024年度時点の値
  static const double pensionRateMonthly = 0.005481;

  /// 厚生年金の報酬比例部分の計算係数（ボーナス・賞与用）
  /// 
  /// 毎年10月に見直される
  /// 2024年度時点の値
  static const double pensionRateBonus = 0.001738;

  /// 厚生年金加入ができる最長期間（50年 = 600ヶ月）
  /// 
  /// 20歳～70歳まで加入可能
  /// ただし70歳で加入資格喪失（原則）
  static const int maxEnrollmentMonths = 600;

  /// 厚生年金の標準的な受給開始年齢（2024年現在）
  /// 
  /// 2025年以降、段階的に65歳→66歳→67歳に引き上げ予定
  static const int pensionStartAge = 65;

  /// 現在の年齢
  /// 
  /// 有効範囲: 0～120
  /// 受給開始年齢以降でも値は保持されるが、計算上は受給開始年次として使用
  final int currentAge;

  /// 厚生年金加入月数（フル加入月）
  /// 
  /// 0～600月
  /// 加入期間を正確に記録
  /// 
  /// 【計算例】
  /// - 22歳から現在45歳: (45-22) × 12 = 276月
  /// - ただし、育児休業・就業困難期などで非加入月がある場合は除外
  /// 
  /// 注意: 本フィールドはフル加入月数のみを対象
  /// 加入資格喪失期間（無職期間など）は含めない
  final int enrollmentMonths;

  /// 平均標準報酬月額（1円単位）
  /// 
  /// 月ごとの給与（基本給 + 各種手当含む）の平均
  /// 
  /// 【計算方法】
  /// 加入期間中の月給の合計 / 加入月数
  /// 
  /// 【対象となる給与】
  /// - 基本給
  /// - 家族手当、勤務地手当など固定的な手当
  /// 
  /// 【対象外となる給与】
  /// - 残業手当（変動的）※ただし基本給に含まれる場合は算入
  /// - 3ヶ月以上継続していない手当
  /// - 臨時給与
  /// 
  /// 有効範囲: 0円以上
  /// 単位: 円（小数点以下なし）
  final double averageMonthlyReward;

  /// 平均標準報酬額（ボーナス等、1円単位）
  /// 
  /// 年間賞与・ボーナスの平均
  /// 計算対象月: 賞与支給月（6月、12月等、企業によって異なる）
  /// 
  /// 【計算方法】
  /// 加入期間中の賞与の合計 / (加入月数 / 12)
  /// 
  /// 【対象となるボーナス等】
  /// - 年2回以上同じ形態で支給される賞与
  /// - 夏季手当、冬季手当、賃金
  /// - 功績給（定期的な支給）
  /// 
  /// 【対象外】
  /// - 退職金、解雇予告手当（一時的）
  /// - 3ヶ月以上前に支給された見舞金
  /// 
  /// 有効範囲: 0円以上
  /// 単位: 円（小数点以下なし）
  final double averageBonusReward;

  /// 希望する年金受給開始年齢（ユーザー指定）
  /// 
  /// 有効範囲: 60～75歳
  /// 
  /// 【制度】
  /// - 繰上げ受給（60～64歳）: 月0.4%減額
  /// - 標準受給（65歳）: 減額なし
  /// - 繰下げ受給（66～75歳）: 月0.7%増額
  /// 
  /// 国民年金と同じ調整率が適用される
  final int desiredPensionStartAge;

  OccupationalPensionInput({
    required this.currentAge,
    required this.enrollmentMonths,
    required this.averageMonthlyReward,
    required this.averageBonusReward,
    required this.desiredPensionStartAge,
  }) {
    _validate();
  }

  /// 入力値の妥当性をチェック
  /// 
  /// 検証項目:
  /// 1. currentAge: 0～120
  /// 2. enrollmentMonths: 0～600
  /// 3. 報酬額（月額・賞与）: >= 0
  /// 4. desiredPensionStartAge: 60～75
  /// 
  /// 不正な値の場合は ArgumentError をスロー
  void _validate() {
    if (currentAge < 0 || currentAge > 120) {
      throw ArgumentError(
        'currentAge must be between 0 and 120, got $currentAge',
      );
    }

    if (enrollmentMonths < 0 || enrollmentMonths > maxEnrollmentMonths) {
      throw ArgumentError(
        'enrollmentMonths must be between 0 and $maxEnrollmentMonths, '
        'got $enrollmentMonths',
      );
    }

    if (averageMonthlyReward < 0) {
      throw ArgumentError(
        'averageMonthlyReward must be >= 0, got $averageMonthlyReward',
      );
    }

    if (averageBonusReward < 0) {
      throw ArgumentError(
        'averageBonusReward must be >= 0, got $averageBonusReward',
      );
    }

    if (desiredPensionStartAge < 60 || desiredPensionStartAge > 75) {
      throw ArgumentError(
        'desiredPensionStartAge must be between 60 and 75, '
        'got $desiredPensionStartAge',
      );
    }
  }

  /// 入力値の妥当性をチェック
  /// 
  /// 検証項目:
  /// 1. 全フィールドが有効範囲内
  /// 
  /// 戻り値: true = 有効, false = 不正な値
  bool isValid() {
    try {
      _validate();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 加入期間に基づく加入率を計算
  /// 
  /// 計算式: enrollmentMonths / maxEnrollmentMonths
  /// 
  /// 戻り値: 0.0～1.0 の割合
  /// 
  /// 【例】
  /// - enrollmentMonths = 0 → 0.0 (0%)
  /// - enrollmentMonths = 300 → 0.5 (50%)
  /// - enrollmentMonths = 600 → 1.0 (100%)
  double getEnrollmentRate() {
    return enrollmentMonths / maxEnrollmentMonths;
  }

  /// 受給開始の遅延・早期受給に基づく調整率を計算
  /// 
  /// 戻り値: 0.76～1.42 の範囲の倍率
  /// 
  /// 【計算式】
  /// - 繰上げ受給（60～64歳）: 1.0 - (0.004 × (65 - desiredPensionStartAge) × 12)
  /// - 標準受給（65歳）: 1.0
  /// - 繰下げ受給（66～75歳）: 1.0 + (0.007 × (desiredPensionStartAge - 65) × 12)
  /// 
  /// 国民年金と同じロジック
  double getPensionAdjustmentRate() {
    const double earlyReductionPerMonth = 0.004;
    const double delayIncreasePerMonth = 0.007;

    final months = (desiredPensionStartAge - pensionStartAge) * 12;
    final perMonth = desiredPensionStartAge < pensionStartAge
        ? earlyReductionPerMonth
        : delayIncreasePerMonth;

    return 1.0 + (perMonth * months);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OccupationalPensionInput &&
          currentAge == other.currentAge &&
          enrollmentMonths == other.enrollmentMonths &&
          averageMonthlyReward == other.averageMonthlyReward &&
          averageBonusReward == other.averageBonusReward &&
          desiredPensionStartAge == other.desiredPensionStartAge;

  @override
  int get hashCode => Object.hash(
        currentAge,
        enrollmentMonths,
        averageMonthlyReward,
        averageBonusReward,
        desiredPensionStartAge,
      );

  @override
  String toString() =>
      'OccupationalPensionInput(currentAge: $currentAge, '
      'enrollmentMonths: $enrollmentMonths, '
      'averageMonthlyReward: $averageMonthlyReward, '
      'averageBonusReward: $averageBonusReward, '
      'desiredPensionStartAge: $desiredPensionStartAge)';
}
