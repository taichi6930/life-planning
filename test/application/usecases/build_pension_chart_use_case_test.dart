import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/application/usecases/build_pension_chart_use_case.dart';
import 'package:life_planning/domain/values/pension_result.dart';

/// PensionResult のテスト用ファクトリ
PensionResult _makeResult({
  double basicPensionMonthly = 0,
  double occupationalPensionMonthly = 0,
  double idecoMonthly = 0,
  double idecoFutureValue = 0,
  double idecoExhaustionAge = 0,
  double investmentTrustMonthly = 0,
  double investmentTrustFutureValue = 0,
  double investmentTrustExhaustionAge = 0,
  double monthlyLivingExpenses = 0,
}) {
  return PensionResult(
    basicPensionMonthly: basicPensionMonthly,
    basicPensionAnnual: basicPensionMonthly * 12,
    occupationalPensionMonthly: occupationalPensionMonthly,
    occupationalPensionAnnual: occupationalPensionMonthly * 12,
    idecoMonthly: idecoMonthly,
    idecoAnnual: idecoMonthly * 12,
    monthlyLivingExpenses: monthlyLivingExpenses,
    monthlyShortfall: 0,
    idecoFutureValue: idecoFutureValue,
    idecoExhaustionAge: idecoExhaustionAge,
    investmentTrustMonthly: investmentTrustMonthly,
    investmentTrustAnnual: investmentTrustMonthly * 12,
    investmentTrustFutureValue: investmentTrustFutureValue,
    investmentTrustExhaustionAge: investmentTrustExhaustionAge,
    targetAge: 100,
    isIdecoSufficient: true,
    totalPensionMonthly: basicPensionMonthly + occupationalPensionMonthly + idecoMonthly + investmentTrustMonthly,
    totalPensionAnnual: (basicPensionMonthly + occupationalPensionMonthly + idecoMonthly + investmentTrustMonthly) * 12,
    adjustmentRate: 1.0,
    pensionStartAge: 65,
  );
}

void main() {
  group('BuildPensionChartUseCase', () {
    test('60歳から100歳の41件を返す', () {
      final result = _makeResult(basicPensionMonthly: 70000);
      final data = BuildPensionChartUseCase.execute(
        result: result,
        publicPensionStartAge: 65,
      );

      expect(data.length, equals(41));
      expect(data.first.age, equals(60));
      expect(data.last.age, equals(100));
    });

    test('iDeCoなし・公的年金65歳開始: 60〜64歳は全ゼロ、65歳以降は基礎年金あり', () {
      // FV=0 なので iDeCo なし
      final result = _makeResult(basicPensionMonthly: 70000);
      final data = BuildPensionChartUseCase.execute(
        result: result,
        publicPensionStartAge: 65,
      );

      // Phase 1 (60〜64): 公的年金もiDeCoも0
      for (final d in data.where((d) => d.age < 65)) {
        expect(d.basicPensionMonthly, equals(0.0), reason: '${d.age}歳: 受給開始前は0');
        expect(d.occupationalPensionMonthly, equals(0.0), reason: '${d.age}歳');
        expect(d.idecoMonthly, equals(0.0), reason: '${d.age}歳');
      }
      // Phase 2 (65〜): 基礎年金あり
      for (final d in data.where((d) => d.age >= 65)) {
        expect(d.basicPensionMonthly, equals(70000), reason: '${d.age}歳');
      }
    });

    test('公的年金70歳開始: 60〜69歳は公的年金0円、70歳以降あり', () {
      final result = _makeResult(basicPensionMonthly: 90000);
      final data = BuildPensionChartUseCase.execute(
        result: result,
        publicPensionStartAge: 70,
      );

      for (final d in data.where((d) => d.age < 70)) {
        expect(d.basicPensionMonthly, equals(0.0), reason: '${d.age}歳: 受給前は0');
      }
      for (final d in data.where((d) => d.age >= 70)) {
        expect(d.basicPensionMonthly, equals(90000), reason: '${d.age}歳');
      }
    });

    test('厚生年金あり: Phase 2で基礎年金+厚生年金を両方表示', () {
      final result = _makeResult(
        basicPensionMonthly: 70000,
        occupationalPensionMonthly: 80000,
      );
      final data = BuildPensionChartUseCase.execute(
        result: result,
        publicPensionStartAge: 65,
      );

      // 65歳以降で厚生年金が含まれる
      for (final d in data.where((d) => d.age >= 65)) {
        expect(d.occupationalPensionMonthly, equals(80000), reason: '${d.age}歳');
      }
    });

    group('2段階iDeCoモデル', () {
      test('Phase 1(60〜64歳): iDeCoが生活費を表示、公的年金は0', () {
        // 大きなFVでPhase 1を乗り越えられる条件
        final result = _makeResult(
          basicPensionMonthly: 70000,
          idecoMonthly: 50000,   // Phase 2不足分
          idecoFutureValue: 50000000, // 十分大きなFV
          idecoExhaustionAge: 95,     // 余裕で持つ
          monthlyLivingExpenses: 200000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
        );

        // Phase 1 (60〜64): iDeCoは生活費全額、公的年金は0
        for (final d in data.where((d) => d.age < 65)) {
          expect(d.basicPensionMonthly, equals(0.0), reason: '${d.age}歳: Phase 1 基礎年金0');
          expect(d.idecoMonthly, equals(200000), reason: '${d.age}歳: Phase 1 生活費表示');
        }

        // Phase 2: 100歳から逆方向に埋める
        // iDeCo coverage = 95 - 65 = 30年 → カバー範囲: 70〜100歳
        // 65〜69歳: 公的年金のみ（iDeCoなし）
        for (final d in data.where((d) => d.age >= 65 && d.age < 70)) {
          expect(d.basicPensionMonthly, equals(70000), reason: '${d.age}歳: Phase 2 基礎年金');
          expect(d.idecoMonthly, equals(0.0), reason: '${d.age}歳: カバー範囲外');
        }
        // 70〜100歳: 公的年金+iDeCo不足分
        for (final d in data.where((d) => d.age >= 70)) {
          expect(d.basicPensionMonthly, equals(70000), reason: '${d.age}歳: Phase 2 基礎年金');
          expect(d.idecoMonthly, equals(50000), reason: '${d.age}歳: Phase 2 iDeCo不足分');
        }
      });

      test('iDeCo枯渇後はidecoMonthly=0', () {
        final result = _makeResult(
          basicPensionMonthly: 70000,
          idecoMonthly: 50000,
          idecoFutureValue: 10000000,
          idecoExhaustionAge: 75.0, // 75歳で枯渇
          monthlyLivingExpenses: 200000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
        );

        // 100歳から逆方向に埋める
        // iDeCo coverage = 75 - 65 = 10年 → カバー範囲: 90〜100歳
        // 65〜89歳: iDeCo=0（カバー範囲外）
        for (final d in data.where((d) => d.age >= 65 && d.age < 90)) {
          expect(d.idecoMonthly, equals(0.0), reason: '${d.age}歳: カバー範囲外');
        }
        // 90〜100歳: iDeCoあり
        for (final d in data.where((d) => d.age >= 90)) {
          expect(d.idecoMonthly, equals(50000), reason: '${d.age}歳: 100歳から逆埋め');
        }
      });

      test('Phase 1中にiDeCo枯渇: 枯渇年齢以降はiDeCo=0', () {
        final result = _makeResult(
          basicPensionMonthly: 70000,
          idecoMonthly: 0,
          idecoFutureValue: 500000,  // 小さいFV
          idecoExhaustionAge: 62.0,  // Phase 1中(60〜64)で枯渇
          monthlyLivingExpenses: 300000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
        );

        // 受給開始年齢(65)から逆方向に埋める
        // iDeCo coverage = 2年（60,61の2歳分）→ カバー範囲: 63〜64歳
        // 60〜62歳: カバー範囲外
        for (final d in data.where((d) => d.age >= 60 && d.age < 63)) {
          expect(d.idecoMonthly, equals(0.0), reason: '${d.age}歳: カバー範囲外');
        }
        // 63〜64歳: iDeCo表示（65歳から逆方向に2年分）
        for (final d in data.where((d) => d.age >= 63 && d.age < 65)) {
          expect(d.idecoMonthly, equals(300000), reason: '${d.age}歳: Phase 1 逆埋め');
        }
        // 65歳以降はiDeCo=0 (idecoMonthly=0)
        for (final d in data.where((d) => d.age >= 65)) {
          expect(d.idecoMonthly, equals(0.0), reason: '${d.age}歳: Phase 2 idecoMonthly=0');
        }
      });
    });

    test('monthlyLivingExpenses が各データに引き継がれる', () {
      final result = _makeResult(
        basicPensionMonthly: 70000,
        monthlyLivingExpenses: 180000,
      );
      final data = BuildPensionChartUseCase.execute(
        result: result,
        publicPensionStartAge: 65,
      );

      for (final d in data) {
        expect(d.monthlyLivingExpenses, equals(180000), reason: '${d.age}歳');
      }
    });

    group('投資信託モデル', () {
      test('投資信託なし(FV=0)は従来通ら60歳開始、investmentTrustMonthly=0', () {
        final result = _makeResult(basicPensionMonthly: 70000);
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          investmentTrustWithdrawalStartAge: 50,
        );
        // FV=0なので開始年齢は60歳のくま
        expect(data.first.age, equals(60));
        expect(data.length, equals(41));
        for (final d in data) {
          expect(d.investmentTrustMonthly, equals(0.0), reason: '${d.age}歳');
        }
      });

      test('投資信託の引出開始年齢が60歳未満ならその年齢からグラフ開始', () {
        final result = _makeResult(
          basicPensionMonthly: 70000,
          investmentTrustMonthly: 30000,
          investmentTrustFutureValue: 5000000,
          monthlyLivingExpenses: 200000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          investmentTrustWithdrawalStartAge: 50,
        );
        // 50歳から100歳の51件
        expect(data.first.age, equals(50));
        expect(data.length, equals(51));
      });

      test('Phase 1(50〜64歳): 投資信託引出開始年齢以降は生活費表示', () {
        final result = _makeResult(
          basicPensionMonthly: 70000,
          investmentTrustMonthly: 30000,
          investmentTrustFutureValue: 5000000,
          monthlyLivingExpenses: 200000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          investmentTrustWithdrawalStartAge: 50,
        );

        // 50〜64歳: 投資信託が生活費全額
        for (final d in data.where((d) => d.age >= 50 && d.age < 65)) {
          expect(d.investmentTrustMonthly, equals(200000), reason: '${d.age}歳: Phase 1 投資信託');
          expect(d.basicPensionMonthly, equals(0.0), reason: '${d.age}歳: 公的年金は0');
        }
      });

      test('Phase 2(65歳以降): 投資信託は不足分補填額を表示', () {
        final result = _makeResult(
          basicPensionMonthly: 70000,
          investmentTrustMonthly: 30000,
          investmentTrustFutureValue: 5000000,
          monthlyLivingExpenses: 200000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          investmentTrustWithdrawalStartAge: 50,
        );

        // 65歳以降: 投資信託は不足分補填額
        for (final d in data.where((d) => d.age >= 65)) {
          expect(d.investmentTrustMonthly, equals(30000), reason: '${d.age}歳: Phase 2 投資信託');
          expect(d.basicPensionMonthly, equals(70000), reason: '${d.age}歳: 基礎年金');
        }
      });

      test('投資信託枯溈年齢以降はinvestmentTrustMonthly=0', () {
        final result = _makeResult(
          basicPensionMonthly: 70000,
          investmentTrustMonthly: 30000,
          investmentTrustFutureValue: 5000000,
          investmentTrustExhaustionAge: 80,
          monthlyLivingExpenses: 200000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          investmentTrustWithdrawalStartAge: 60,
        );

        // 100歳から逆方向に埋める
        // IT coverage = 80 - 65 = 15年 → カバー範囲: 85〜100歳
        // 65〜84歳: IT=0（カバー範囲外）
        for (final d in data.where((d) => d.age >= 65 && d.age < 85)) {
          expect(d.investmentTrustMonthly, equals(0.0), reason: '${d.age}歳: カバー範囲外');
        }
        // 85〜100歳: ITあり
        for (final d in data.where((d) => d.age >= 85)) {
          expect(d.investmentTrustMonthly, equals(30000), reason: '${d.age}歳: 100歳から逆埋め');
        }
      });

      test('引出開始年齢が65歳ならPhase 1なし、Phase 2から引き出す', () {
        final result = _makeResult(
          basicPensionMonthly: 70000,
          investmentTrustMonthly: 30000,
          investmentTrustFutureValue: 5000000,
          monthlyLivingExpenses: 200000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          investmentTrustWithdrawalStartAge: 65,
        );

        // 60歠から開始（65歳以前は投資信託0）
        expect(data.first.age, equals(60));
        for (final d in data.where((d) => d.age < 65)) {
          expect(d.investmentTrustMonthly, equals(0.0), reason: '${d.age}歳: 引出前は0');
        }
        // 65歳以降は補填額
        for (final d in data.where((d) => d.age >= 65)) {
          expect(d.investmentTrustMonthly, equals(30000), reason: '${d.age}歳: Phase 2のみ');
        }
      });
    });

    group('iDeCo+投資信託 複合モデル', () {
      test('Phase 1: iDeCoが60歳以降優先、ITは60歳未満のみ表示', () {
        // iDeCo FV=50M（枯渇95歳）、IT FV=5M（引出開始55歳）
        // Phase 1: 55-59→IT表示、60-64→iDeCo表示（排他的）
        final result = _makeResult(
          basicPensionMonthly: 70000,
          idecoMonthly: 50000,
          idecoFutureValue: 50000000,
          idecoExhaustionAge: 95,
          investmentTrustMonthly: 50000,
          investmentTrustFutureValue: 5000000,
          monthlyLivingExpenses: 200000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          investmentTrustWithdrawalStartAge: 55,
        );

        // 55-59歳: IT表示、iDeCo=0
        for (final d in data.where((d) => d.age >= 55 && d.age < 60)) {
          expect(d.investmentTrustMonthly, equals(200000),
              reason: '${d.age}歳: ITが生活費カバー');
          expect(d.idecoMonthly, equals(0.0),
              reason: '${d.age}歳: iDeCoはまだ利用不可');
        }
        // 60-64歳: iDeCo表示、IT=0
        for (final d in data.where((d) => d.age >= 60 && d.age < 65)) {
          expect(d.idecoMonthly, equals(200000),
              reason: '${d.age}歳: iDeCoが生活費カバー');
          expect(d.investmentTrustMonthly, equals(0.0),
              reason: '${d.age}歳: iDeCo優先のためIT=0');
        }
      });

      test('Phase 2: iDeCoカバー中はIT=0、iDeCo枯渇後にIT表示', () {
        // iDeCo枯渇75歳、IT枯渇90歳
        // 100歳から逆方向に埋める:
        //   iDeCo coverage = 75-65 = 10年 → 90〜100歳
        //   IT coverage = 90-75 = 15年 → 75〜89歳
        //   65〜74歳: 公的年金のみ（カバー範囲外）
        final result = _makeResult(
          basicPensionMonthly: 70000,
          idecoMonthly: 50000,
          idecoFutureValue: 10000000,
          idecoExhaustionAge: 75,
          investmentTrustMonthly: 50000,
          investmentTrustFutureValue: 5000000,
          investmentTrustExhaustionAge: 90,
          monthlyLivingExpenses: 200000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          investmentTrustWithdrawalStartAge: 55,
        );

        // 65〜74歳: カバー範囲外（公的年金のみ）
        for (final d in data.where((d) => d.age >= 65 && d.age < 75)) {
          expect(d.idecoMonthly, equals(0.0),
              reason: '${d.age}歳: カバー範囲外');
          expect(d.investmentTrustMonthly, equals(0.0),
              reason: '${d.age}歳: カバー範囲外');
        }
        // 75〜89歳: IT表示、iDeCo=0
        for (final d in data.where((d) => d.age >= 75 && d.age < 90)) {
          expect(d.idecoMonthly, equals(0.0),
              reason: '${d.age}歳: iDeCoカバー範囲外');
          expect(d.investmentTrustMonthly, equals(50000),
              reason: '${d.age}歳: IT補填表示');
        }
        // 90〜100歳: iDeCo表示、IT=0
        for (final d in data.where((d) => d.age >= 90)) {
          expect(d.idecoMonthly, equals(50000),
              reason: '${d.age}歳: iDeCo補填表示');
          expect(d.investmentTrustMonthly, equals(0.0),
              reason: '${d.age}歳: iDeCoカバー中はIT=0');
        }
      });

      test('Phase 2: iDeCoなし（idecoMonthly=0）ならIT単独表示', () {
        // iDeCoが存在しないケース: IT単独で補填
        final result = _makeResult(
          basicPensionMonthly: 70000,
          investmentTrustMonthly: 30000,
          investmentTrustFutureValue: 5000000,
          monthlyLivingExpenses: 200000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          investmentTrustWithdrawalStartAge: 55,
        );

        // 65歳以降: IT単独表示（iDeCoなし）
        for (final d in data.where((d) => d.age >= 65)) {
          expect(d.investmentTrustMonthly, equals(30000),
              reason: '${d.age}歳: IT単独補填');
          expect(d.idecoMonthly, equals(0.0), reason: '${d.age}歳');
        }
      });
    });
  });
}
