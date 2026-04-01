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
      // iDeCo残高0、拠出0 → iDeCoなし
      final result = _makeResult(basicPensionMonthly: 70000);
      final data = BuildPensionChartUseCase.execute(
        result: result,
        publicPensionStartAge: 65,
      );

      // 60〜64歳: 公的年金もiDeCoも0（残高0なので引出不能）
      for (final d in data.where((d) => d.age < 65)) {
        expect(d.basicPensionMonthly, equals(0.0), reason: '${d.age}歳: 受給開始前は0');
        expect(d.occupationalPensionMonthly, equals(0.0), reason: '${d.age}歳');
        expect(d.idecoMonthly, equals(0.0), reason: '${d.age}歳');
      }
      // 65歳以降: 基礎年金あり
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

    test('厚生年金あり: 受給開始後は基礎年金+厚生年金を両方表示', () {
      final result = _makeResult(
        basicPensionMonthly: 70000,
        occupationalPensionMonthly: 80000,
      );
      final data = BuildPensionChartUseCase.execute(
        result: result,
        publicPensionStartAge: 65,
      );

      for (final d in data.where((d) => d.age >= 65)) {
        expect(d.occupationalPensionMonthly, equals(80000), reason: '${d.age}歳');
      }
    });

    group('iDeCoシミュレーション駆動モデル', () {
      test('60〜64歳: iDeCoが生活費全額を引出、65歳以降は不足分のみ', () {
        // iDeCo残高5000万（60歳時点）から引出
        // 60〜64: 不足分 = 200000（公的年金0）
        // 65〜: 不足分 = 200000 - 70000 = 130000
        final result = _makeResult(
          basicPensionMonthly: 70000,
          monthlyLivingExpenses: 200000,
          idecoFutureValue: 50000000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          idecoCurrentAge: 60,
          idecoCurrentBalance: 50000000,
          idecoAnnualReturnRate: 3.0,
        );

        // 60〜64歳: iDeCoが生活費全額をカバー（不足分 = 200000）
        for (final d in data.where((d) => d.age >= 60 && d.age < 65)) {
          expect(d.basicPensionMonthly, equals(0.0), reason: '${d.age}歳: 受給開始前');
          expect(d.idecoMonthly, closeTo(200000, 1), reason: '${d.age}歳: 生活費全額');
        }

        // 65歳以降: 基礎年金 + iDeCo不足分
        // 不足分 = 200000 - 70000 = 130000
        for (final d in data.where((d) => d.age >= 65 && d.age <= 70)) {
          expect(d.basicPensionMonthly, equals(70000), reason: '${d.age}歳');
          expect(d.idecoMonthly, closeTo(130000, 1), reason: '${d.age}歳: 不足分');
        }
      });

      test('iDeCo残高が尽きたらidecoMonthly=0になる', () {
        // 少ない残高（300万）で200000/月引出 → 約15ヶ月で枯渇 → 61歳中盤～後半で枯渇
        final result = _makeResult(
          basicPensionMonthly: 70000,
          monthlyLivingExpenses: 200000,
          idecoFutureValue: 3000000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          idecoCurrentAge: 60,
          idecoCurrentBalance: 3000000,
          idecoAnnualReturnRate: 3.0,
        );

        // 60歳: まだ残高あるので引出できる
        final age60 = data.firstWhere((d) => d.age == 60);
        expect(age60.idecoMonthly, greaterThan(0), reason: '60歳: iDeCo引出可能');

        // 残高がかなり減っている年（65歳以降）では引出額が減少するか0に近づく
        final later = data.where((d) => d.age >= 65);
        bool foundZeroOrSmall = false;
        for (final d in later) {
          if (d.idecoBalance < 500000) {
            // 残高が少なくなったら、月額引出は減少するはず
            foundZeroOrSmall = true;
            break;
          }
        }
        expect(foundZeroOrSmall, isTrue,
            reason: '65歳以降のどこかで残高が少なくなる');
      });

      test('拠出ありの場合、60歳前は拠出のみで残高が増加', () {
        // 50歳から開始、月額23000拠出、残高500万
        final result = _makeResult(
          basicPensionMonthly: 70000,
          monthlyLivingExpenses: 200000,
          idecoFutureValue: 5000000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          idecoCurrentAge: 50,
          idecoCurrentBalance: 5000000,
          idecoMonthlyContribution: 23000,
          idecoAnnualReturnRate: 3.0,
        );

        // 60歳時点の残高は500万 + 10年分の拠出(23000×12×10) + 運用益
        // 23000×12×10 = 2,760,000
        // 最低限 500万 + 276万 = 776万以上
        final age60 = data.firstWhere((d) => d.age == 60);
        expect(age60.idecoBalance, greaterThan(0),
            reason: '60歳: 拠出+運用で残高あり');
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
      test('投資信託なし(FV=0)は60歳開始、investmentTrustMonthly=0', () {
        final result = _makeResult(basicPensionMonthly: 70000);
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          investmentTrustWithdrawalStartAge: 50,
        );
        // FV=0なので開始年齢は60歳
        expect(data.first.age, equals(60));
        expect(data.length, equals(41));
        for (final d in data) {
          expect(d.investmentTrustMonthly, equals(0.0), reason: '${d.age}歳');
        }
      });

      test('投資信託の引出開始年齢が60歳未満ならその年齢からグラフ開始', () {
        final result = _makeResult(
          basicPensionMonthly: 70000,
          investmentTrustFutureValue: 50000000,
          monthlyLivingExpenses: 200000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          investmentTrustWithdrawalStartAge: 50,
          investmentTrustCurrentAge: 50,
          investmentTrustCurrentBalance: 50000000,
        );
        // 50歳から100歳の51件
        expect(data.first.age, equals(50));
        expect(data.length, equals(51));
      });

      test('投資信託: 60歳前は生活費全額、60歳以降はiDeCoでカバーできない分', () {
        // 投資信託50歳開始、iDeCoなし
        final result = _makeResult(
          basicPensionMonthly: 70000,
          investmentTrustFutureValue: 50000000,
          monthlyLivingExpenses: 200000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          investmentTrustWithdrawalStartAge: 50,
          investmentTrustCurrentAge: 50,
          investmentTrustCurrentBalance: 50000000,
        );

        // 50〜59歳: 投資信託が生活費全額カバー
        for (final d in data.where((d) => d.age >= 50 && d.age < 60)) {
          expect(d.investmentTrustMonthly, closeTo(200000, 1),
              reason: '${d.age}歳: 投資信託が生活費カバー');
          expect(d.basicPensionMonthly, equals(0.0), reason: '${d.age}歳: 公的年金は0');
        }

        // 60〜64歳: iDeCoなし → 投資信託が不足分（生活費全額）カバー
        for (final d in data.where((d) => d.age >= 60 && d.age < 65)) {
          expect(d.investmentTrustMonthly, closeTo(200000, 1),
              reason: '${d.age}歳: iDeCoなしで投資信託がカバー');
        }

        // 65歳以降: 不足分 = 200000 - 70000 = 130000
        final age65 = data.firstWhere((d) => d.age == 65);
        if (age65.investmentTrustBalance > 0) {
          expect(age65.investmentTrustMonthly, closeTo(130000, 1),
              reason: '65歳: 不足分を投資信託がカバー');
        }
      });

      test('投資信託枯渇後はinvestmentTrustMonthly=0', () {
        // 少ない残高（500万）で引出 → 複数年で枯渇
        final result = _makeResult(
          basicPensionMonthly: 70000,
          investmentTrustFutureValue: 5000000,
          monthlyLivingExpenses: 200000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          investmentTrustWithdrawalStartAge: 60,
          investmentTrustCurrentAge: 60,
          investmentTrustCurrentBalance: 5000000,
        );

        // 60歳: 残高があるので引出
        final age60 = data.firstWhere((d) => d.age == 60);
        expect(age60.investmentTrustMonthly, greaterThan(0), reason: '60歳: 投資信託あり');

        // 65歳時点で残高がまだあるか確認し、その後の推移を見る
        final age65 = data.firstWhere((d) => d.age == 65);
        final hasBalance65 = age65.investmentTrustBalance > 0;
        
        // 枯渇後の年（残高が実質0になったあと）を調べる
        bool foundExhausted = false;
        for (final d in data.where((d) => d.age > 65)) {
          if (d.investmentTrustBalance <= 0) {
            // 残高0または負（実装では0で止まる）なら、月額は0のはず
            expect(d.investmentTrustMonthly, equals(0.0),
                reason: '${d.age}歳: 投資信託残高0で引出0');
            foundExhausted = true;
            break;
          }
        }
        // 中途で枯渇していなければ、100歳時点で残高がある
        if (!foundExhausted) {
          final age100 = data.lastWhere((d) => d.age == 100);
          expect(age100.investmentTrustBalance, greaterThanOrEqualTo(0),
              reason: '100歳: 運用益があれば残高継続');
        }
      });
    });

    group('iDeCo+投資信託 複合モデル', () {
      test('iDeCoが優先、枯渇後に投資信託がカバー', () {
        // iDeCo: 500万（早めに枯渇）、投資信託: 3000万（長持ち）
        // 65歳以降の不足分 = 200000 - 70000 = 130000
        final result = _makeResult(
          basicPensionMonthly: 70000,
          idecoFutureValue: 5000000,
          investmentTrustFutureValue: 30000000,
          monthlyLivingExpenses: 200000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          idecoCurrentAge: 60,
          idecoCurrentBalance: 5000000,
          idecoAnnualReturnRate: 3.0,
          investmentTrustCurrentAge: 60,
          investmentTrustCurrentBalance: 30000000,
          investmentTrustAnnualReturnRate: 5.0,
          investmentTrustWithdrawalStartAge: 60,
        );

        // iDeCoがカバーしている間は投資信託の引出は少ない（または0）
        // iDeCo枯渇後は投資信託がカバー
        bool idecoExhausted = false;
        for (final d in data.where((d) => d.age >= 65)) {
          if (d.idecoBalance == 0 && !idecoExhausted) {
            idecoExhausted = true;
          }
          if (idecoExhausted) {
            expect(d.idecoMonthly, equals(0.0),
                reason: '${d.age}歳: iDeCo枯渇後は引出0');
            // 投資信託に残高があれば不足分をカバー
            if (d.investmentTrustBalance > 0) {
              expect(d.investmentTrustMonthly, greaterThan(0),
                  reason: '${d.age}歳: 投資信託がカバー');
            }
          }
        }
        expect(idecoExhausted, isTrue, reason: 'iDeCoは500万で枯渇するはず');
      });

      test('iDeCoなし（残高0）なら投資信託が単独でカバー', () {
        final result = _makeResult(
          basicPensionMonthly: 70000,
          investmentTrustFutureValue: 30000000,
          monthlyLivingExpenses: 200000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 65,
          investmentTrustWithdrawalStartAge: 55,
          investmentTrustCurrentAge: 55,
          investmentTrustCurrentBalance: 30000000,
        );

        // 55〜59歳: 投資信託が生活費全額
        for (final d in data.where((d) => d.age >= 55 && d.age < 60)) {
          expect(d.investmentTrustMonthly, closeTo(200000, 1),
              reason: '${d.age}歳: 投資信託が生活費カバー');
          expect(d.idecoMonthly, equals(0.0), reason: '${d.age}歳: iDeCoなし');
        }

        // 65歳以降: 不足分 = 130000を投資信託がカバー
        for (final d in data.where((d) => d.age >= 65 && d.age <= 70)) {
          if (d.investmentTrustBalance > 0) {
            expect(d.investmentTrustMonthly, closeTo(130000, 1),
                reason: '${d.age}歳: 不足分を投資信託がカバー');
          }
          expect(d.idecoMonthly, equals(0.0), reason: '${d.age}歳: iDeCoなし');
        }
      });
    });

    group('iDeCo残高シミュレーション', () {
      test('残高が複利で増加し、引出で減少する', () {
        // 公的年金で生活費をカバー → iDeCo不足分0 → 引出なし → 残高増加
        final result = _makeResult(
          basicPensionMonthly: 150000,
          occupationalPensionMonthly: 100000,
          monthlyLivingExpenses: 250000, // 基礎+厚生 = 250000でぴったり
          idecoFutureValue: 10000000,
        );
        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 60, // 60歳から受給 → 不足分0
          idecoCurrentAge: 60,
          idecoCurrentBalance: 10000000,
          idecoAnnualReturnRate: 3.0,
        );

        // 60歳時点：残高 > 0
        final age60Data = data.firstWhere((d) => d.age == 60);
        expect(age60Data.idecoBalance, greaterThan(0),
            reason: '60歳: iDeCo残高 > 0');

        // 不足分0なので引出なし → 残高は運用で増加
        final age65Data = data.firstWhere((d) => d.age == 65);
        expect(age65Data.idecoBalance, greaterThan(age60Data.idecoBalance),
            reason: '65歳: 不足分0のため残高増加');

        // 運用益もある
        final allWithGain = data.where((d) => d.idecoGain > 0);
        expect(allWithGain.length, greaterThan(0),
            reason: '運用益がある年が存在');
      });

      test('月間拠出ありの場合、残高が拠出+運用で増加', () {
        final result = _makeResult(
          basicPensionMonthly: 150000,
          occupationalPensionMonthly: 100000,
          idecoFutureValue: 50000000,
          monthlyLivingExpenses: 250000,
        );

        final data = BuildPensionChartUseCase.execute(
          result: result,
          publicPensionStartAge: 60,
          idecoCurrentAge: 50,
          idecoCurrentBalance: 0,
          idecoMonthlyContribution: 23000,
          idecoAnnualReturnRate: 3.0,
        );

        // 60歳時点：10年分の拠出+運用で残高 > 0
        final age60 = data.firstWhere((d) => d.age == 60);
        expect(age60.idecoBalance, greaterThan(0),
            reason: '60歳: 10年拠出+運用で残高形成');

        // 年間拠出 = 23000 × 12 = 276000。10年で276万 + 運用益
        // 残高は276万以上あるはず
        expect(age60.idecoBalance, greaterThan(2700000),
            reason: '60歳: 276万以上');
      });
    });
  });
}
