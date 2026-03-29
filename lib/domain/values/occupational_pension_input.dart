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
/// 厚生年金は以下の3つの部分から構成される：
/// 1. **基礎年金部分**: 国民年金と同じ基礎年金（月額 ¥70,608）
/// 2. **報酬比例部分**: 給与・ボーナス（総報酬）に基づく追加部分
/// 3. **加給年金**: 配偶者・子がいる場合の加算部分
///
/// 本クラスは報酬比例部分および加給年金を計算するための入力値を管理する。
///
/// 【報酬比例年金額の計算式】
/// ■ 平成15年4月以降の期間：
///   報酬比例年金 = 平均標準報酬額 × 加入月数 × 5.481/1000
///
/// ■ 平成15年3月以前の期間（昭和21年4月2日以降生まれ）：
///   報酬比例年金 = 平均標準報酬月額 × 加入月数 × 7.125/1000
///
/// ■ 定額部分（特別支給の老齢厚生年金用）：
///   定額部分 = 1,635円 × 昭和36年4月以降で20歳以上60歳未満の被保険者月数
///             ÷ (加入可能年数×12) × 率
///   ※ 昭和31年4月2日以後生まれの場合、基準額＝1,635円、率＝1.0
///
/// ■ 経過的加算部分（昭和31年4月2日以後生まれ）：
///   経過的加算 = (定額部分として計算した額 - 831,700円)
///               × (昭和36年4月以降で20歳以上60歳未満の被保険者月数)
///               ÷ (加入可能年数×12)
///   ※ 定額部分から老齢基礎年金相当額を差し引いたもの
///
/// ■ 加給年金：
///   配偶者がいる場合: +¥230,100（令和8年度）
///   1番目と2番目の子: 各 +¥76,700
///   3番目以降の子: 各 +¥25,600
///
/// 【係数について】
/// - 報酬比例部分の係数は毎年10月に見直される
/// - 加給年金額は毎年度4月に改定される
/// - 本実装は令和8年度（2026年4月～）基準である
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
  /// 2025年度時点の値（2024年10月改定）
  static const double pensionRateMonthly = 0.005481;

  /// 厚生年金の報酬比例部分の計算係数（ボーナス・賞与用）
  ///
  /// 毎年10月に見直される
  /// 2025年度時点の値（2024年10月改定）
  static const double pensionRateBonus = 0.001738;

  /// 厚生年金の報酬比例部分の計算係数（平成15年3月以前用）
  ///
  /// 昭和21年4月2日以降に生まれた被保険者に適用
  /// この係数は固定値（法定値）
  static const double pensionRateBefore2003 = 0.007125;

  /// 定額部分の計算基準額（昭和31年4月2日以後生まれ用）令和8年度
  ///
  /// 特別支給の老齢厚生年金の定額部分を計算する際の基準額
  /// 毎年度4月に改定される
  static const double fixedPartBaseAmount = 1635.0;

  /// 経過的加算の基準額（昭和31年4月2日以後生まれ用）令和8年度
  ///
  /// 定額部分から差し引く老齢基礎年金相当額（昭和36年の基準）
  /// 定額部分として計算した額からこの額を差し引いて経過的加算とする
  static const double transitionalAdjustmentAmount = 831700.0;

  /// 昭和31年4月2日以後生まれの定額部分計算に用いる率
  ///
  /// 1.0で固定
  static const double fixedPartRateSince1946 = 1.0;

  /// 加入可能年数（厚生年金）
  ///
  /// 標準的には20歳～60歳までの40年（480月）
  /// ただし、より長く加入する場合は最大70歳（600月）
  /// 定額部分計算では40年（加入可能年数）を基準とする
  static const int standardInsurableYears = 40;

  /// 加給年金額（配偶者分）令和8年度
  ///
  /// 生計を維持する配偶者がいる場合に加算される
  /// 毎年度4月に改定される
  static const double spousalSupplementMonthly = 230100.0 / 12.0;  // 月額換算

  /// 加給年金額（第1子・第2子分）令和8年度
  ///
  /// 1番目及び2番目の子がいる場合に加算される（1人あたり）
  /// 毎年度4月に改定される
  static const double childSupplementFirst2ndMonthly = 76700.0 / 12.0;  // 月額換算

  /// 加給年金額（第3子以降分）令和8年度
  ///
  /// 3番目以降の子がいる場合に加算される（1人あたり）
  /// 毎年度4月に改定される
  static const double childSupplementThirdMonthly = 25600.0 / 12.0;  // 月額換算

  /// 厚生年金加入ができる最長期間（50年 = 600ヶ月）
  ///
  /// 20歳～70歳まで加入可能
  /// ただし70歳で加入資格喪失（原則）
  static const int maxEnrollmentMonths = 600;

  /// 厚生年金の標準的な受給開始年齢（2024年現在）
  ///
  /// 2025年以降、段階的に65歳→66歳→67歳に引き上げ予定
  static const int pensionStartAge = 65;

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

  /// 平均標準報酬月額（平成15年3月以前分）
  ///
  /// 平成15年3月以前の加入期間における標準報酬月額の平均
  /// 現在加入者の方は少ないが、経過給付の計算に必要
  ///
  /// 【計算方法】
  /// = 平成15年3月以前の報酬合計 / 加入月数
  ///
  /// 【デフォルト】
  /// 加入がない場合は 0 を指定
  final double averageMonthlyRewardBefore2003;

  /// 平成15年3月以前の加入期間月数
  ///
  /// 有効範囲: 0～600月（通常は限定的）
  ///
  /// 【背景】
  /// 2003年4月に厚生年金の計算方法が変更された
  /// 2003年4月以前の期間は旧計算式（7.125/1000）を使用
  ///
  /// 【対象者】
  /// 2003年4月以前から加入していた方のみ
  final int enrollmentMonthsBefore2003;

  /// 昭和36年4月以降で20歳以上60歳未満の加入期間月数
  ///
  /// 有効範囲: 0～600月
  ///
  /// 【背景】
  /// 定額部分と経過的加算を計算する際に使用される基準期間
  /// 昭和36年4月に現在の厚生年金制度が成立したことが起源
  ///
  /// 【計算例】
  /// - 1970年(昭和45年)4月に20歳で加入、1990年3月に退職→20年(240月)
  /// - 現在55歳で、2003年以降ずっと加入→20年と8ヶ月(248月)
  ///
  /// 【用途】
  /// 定額部分: = 1,635円 × 本フィールド / (加入可能年数×12)
  /// 経過的加算: 複雑な計算式で使用（定額部分から831,700円を差し引く）
  final int insuredMonthsSince1961;

  /// 配偶者がいるか
  ///
  /// true の場合: 加給年金（配偶者分）が加算される
  /// false の場合: 加給年金なし
  ///
  /// 【条件】
  /// - 配偶者が生計を維持されていること
  /// - 配偶者が一定の収入基準以下であること
  final bool hasSpouse;

  /// 子の人数
  ///
  /// 有効範囲: 0～（通常は4人程度が上限実務値）
  ///
  /// 【加給年金計算】
  /// - 第1子・第2子（各 +¥76,700/年 ≈ +¥6,391.67/月）
  /// - 第3子以降（各 +¥25,600/年 ≈ +¥2,133.33/月）
  ///
  /// 【条件】
  /// - 被保険者と生計を共にする子
  /// - 一定の収入基準などを満たすこと
  final int numberOfChildren;

  OccupationalPensionInput({
    required this.enrollmentMonths,
    required this.averageMonthlyReward,
    required this.averageBonusReward,
    required this.desiredPensionStartAge,
    this.averageMonthlyRewardBefore2003 = 0.0,
    this.enrollmentMonthsBefore2003 = 0,
    this.insuredMonthsSince1961 = 0,
    this.hasSpouse = false,
    this.numberOfChildren = 0,
  }) {
    _validate();
  }

  /// 入力値の妥当性をチェック
  ///
  /// 検証項目:
  /// 1. enrollmentMonths: 0～600
  /// 2. enrollmentMonthsBefore2003: 0～600
  /// 3. insuredMonthsSince1961: 0～600（定額部分計算用）
  /// 4. 報酬額（月額・賞与）: >= 0
  /// 5. 報酬額（平成15年3月以前分）: >= 0
  /// 6. desiredPensionStartAge: 60～75
  /// 7. numberOfChildren: >= 0
  ///
  /// 不正な値の場合は ArgumentError をスロー
  void _validate() {

    if (enrollmentMonths < 0 || enrollmentMonths > maxEnrollmentMonths) {
      throw ArgumentError(
        'enrollmentMonths must be between 0 and $maxEnrollmentMonths, '
        'got $enrollmentMonths',
      );
    }

    if (enrollmentMonthsBefore2003 < 0 ||
        enrollmentMonthsBefore2003 > maxEnrollmentMonths) {
      throw ArgumentError(
        'enrollmentMonthsBefore2003 must be between 0 and $maxEnrollmentMonths, '
        'got $enrollmentMonthsBefore2003',
      );
    }

    if (insuredMonthsSince1961 < 0 ||
        insuredMonthsSince1961 > maxEnrollmentMonths) {
      throw ArgumentError(
        'insuredMonthsSince1961 must be between 0 and $maxEnrollmentMonths, '
        'got $insuredMonthsSince1961',
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

    if (averageMonthlyRewardBefore2003 < 0) {
      throw ArgumentError(
        'averageMonthlyRewardBefore2003 must be >= 0, '
        'got $averageMonthlyRewardBefore2003',
      );
    }

    if (desiredPensionStartAge < 60 || desiredPensionStartAge > 75) {
      throw ArgumentError(
        'desiredPensionStartAge must be between 60 and 75, '
        'got $desiredPensionStartAge',
      );
    }

    if (numberOfChildren < 0) {
      throw ArgumentError(
        'numberOfChildren must be >= 0, got $numberOfChildren',
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

  /// 報酬比例部分（平成15年4月以降分）を計算
  ///
  /// 計算式: 平均標準報酬額 × 加入月数 × 5.481/1000
  ///
  /// 戻り値: 報酬比例年金月額（円）
  ///
  /// 【計算例】
  /// averageMonthlyReward = 400,000円、enrollmentMonths = 400月
  /// → 400,000 × 400 × 0.005481 = 876,480円
  double getProportionalPensionAfter2003() {
    return averageMonthlyReward * enrollmentMonths * pensionRateMonthly +
        averageBonusReward * enrollmentMonths * pensionRateBonus;
  }

  /// 報酬比例部分（平成15年3月以前分）を計算
  ///
  /// 計算式: 平均標準報酬月額 × 加入月数 × 7.125/1000
  ///
  /// 戻り値: 報酬比例年金月額（円）
  ///
  /// 【計算例】
  /// averageMonthlyRewardBefore2003 = 300,000円、enrollmentMonthsBefore2003 = 100月
  /// → 300,000 × 100 × 0.007125 = 213,750円
  double getProportionalPensionBefore2003() {
    return averageMonthlyRewardBefore2003 *
        enrollmentMonthsBefore2003 *
        pensionRateBefore2003;
  }

  /// 定額部分を計算（特別支給の老齢厚生年金計算用）
  ///
  /// 計算式: 1,635円 × insuredMonthsSince1961 / (加入可能年数×12) × 1.0
  ///
  /// 戻り値: 定額部分月額（円）
  ///
  /// 【計算例】
  /// insuredMonthsSince1961 = 240月（20年）
  /// → 1,635 × 240 / (40×12) = 1,635 × 240 / 480 = 817.5円
  ///
  /// 【補足】
  /// 昭和31年4月2日以後生まれの場合：
  /// - 基準額 = 1,635円
  /// - 率 = 1.0
  double getFixedPart() {
    final ratio =
        insuredMonthsSince1961 / (standardInsurableYears * 12).toDouble();
    return fixedPartBaseAmount * ratio * fixedPartRateSince1946;
  }

  /// 経過的加算額を計算（昭和31年4月2日以後生まれ用）
  ///
  /// 計算式：
  /// = (定額部分として計算した額 - 831,700円)
  ///   × insuredMonthsSince1961 / (加入可能年数×12)
  ///
  /// 戻り値: 経過的加算月額（円）
  ///
  /// 【計算例】
  /// insuredMonthsSince1961 = 248月
  /// 定額部分 = 2,120円
  /// → (2,120 - 831,700) × 248 / 480 = (負の値) → 0円（最小額）
  /// ※通常は負の値になるため0円、または定額部分が831,700より大きい場合のみ加算される
  ///
  /// 【背景】
  /// 特別支給制度から通常の老齢厚生年金への移行時に、給付を調整する仕組み
  /// 定額部分から老齢基礎年金相当額（831,700円が基準）を差し引いたもの
  double getTransitionalAddition() {
    final fixedPartAmount = getFixedPart();
    final baseAmount = fixedPartAmount - transitionalAdjustmentAmount;
    final ratio =
        insuredMonthsSince1961 / (standardInsurableYears * 12).toDouble();
    final result = baseAmount * ratio;
    return result.clamp(0, double.infinity);
  }

  /// 経過的加算額を計算（簡略版・基礎年金額を直接使用）
  ///
  /// 計算式：
  /// = (定額部分として計算した額 - 基礎年金月額)
  ///   × insuredMonthsSince1961 / (加入可能年数×12)
  ///
  /// 戻り値: 経過的加算月額（円）
  ///
  /// このメソッドは基礎年金月額（国民年金基本額）を直接パラメータとして受け取る
  /// より正確な計算が必要な場合に使用します
  double getTransitionalAdditionWithBasicPension(
      double basicPensionMonthlyAmount) {
    final fixedPartAmount = getFixedPart();
    final baseAmount = fixedPartAmount - basicPensionMonthlyAmount;
    final ratio =
        insuredMonthsSince1961 / (standardInsurableYears * 12).toDouble();
    final result = baseAmount * ratio;
    return result.clamp(0, double.infinity);
  }

  /// 加給年金額を計算
  ///
  /// 戻り値: 加給年金月額（円）
  ///
  /// 【計算例】
  /// hasSpouse = true、numberOfChildren = 2
  /// → 配偶者分: ¥19,175（年額230,100円）
  ///    + 第1子: ¥6,391.67（年額76,700円）
  ///    + 第2子: ¥6,391.67（年額76,700円）
  ///    = 月額約¥31,958
  double getSupplementalPension() {
    double supplement = 0.0;

    // 配偶者がいる場合
    if (hasSpouse) {
      supplement += spousalSupplementMonthly;

      // 配偶者がいる場合のみ子の加給年金を加算
      if (numberOfChildren > 0) {
        // 第1子と第2子は各 +¥76,700/年
        final firstTwoChildren = numberOfChildren < 2 ? numberOfChildren : 2;
        supplement += firstTwoChildren * childSupplementFirst2ndMonthly;

        // 第3子以降は各 +¥25,600/年
        if (numberOfChildren > 2) {
          final thirdAndAfter = numberOfChildren - 2;
          supplement += thirdAndAfter * childSupplementThirdMonthly;
        }
      }
    }

    return supplement;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OccupationalPensionInput &&
          enrollmentMonths == other.enrollmentMonths &&
          averageMonthlyReward == other.averageMonthlyReward &&
          averageBonusReward == other.averageBonusReward &&
          desiredPensionStartAge == other.desiredPensionStartAge &&
          averageMonthlyRewardBefore2003 == other.averageMonthlyRewardBefore2003 &&
          enrollmentMonthsBefore2003 == other.enrollmentMonthsBefore2003 &&
          hasSpouse == other.hasSpouse &&
          numberOfChildren == other.numberOfChildren;

  @override
  int get hashCode => Object.hash(
        enrollmentMonths,
        averageMonthlyReward,
        averageBonusReward,
        desiredPensionStartAge,
        averageMonthlyRewardBefore2003,
        enrollmentMonthsBefore2003,
        hasSpouse,
        numberOfChildren,
      );

  @override
  String toString() =>
      'OccupationalPensionInput('
      'enrollmentMonths: $enrollmentMonths, '
      'averageMonthlyReward: $averageMonthlyReward, '
      'averageBonusReward: $averageBonusReward, '
      'desiredPensionStartAge: $desiredPensionStartAge, '
      'averageMonthlyRewardBefore2003: $averageMonthlyRewardBefore2003, '
      'enrollmentMonthsBefore2003: $enrollmentMonthsBefore2003, '
      'hasSpouse: $hasSpouse, '
      'numberOfChildren: $numberOfChildren)';
}
