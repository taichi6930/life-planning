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
    targetAge: 90,
    isIdecoSufficient: true,
    totalPensionMonthly: basicPensionMonthly + occupationalPensionMonthly + idecoMonthly,
    totalPensionAnnual: (basicPensionMonthly + occupationalPensionMonthly + idecoMonthly) * 12,
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

        // Phase 2 (65〜): 公的年金+iDeCo不足分
        for (final d in data.where((d) => d.age >= 65 && d.age < 95)) {
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

        // 75歳以降はiDeCo=0
        for (final d in data.where((d) => d.age >= 75)) {
          expect(d.idecoMonthly, equals(0.0), reason: '${d.age}歳: 枯渇後は0');
        }
        // 65〜74歳はiDeCoあり
        for (final d in data.where((d) => d.age >= 65 && d.age < 75)) {
          expect(d.idecoMonthly, equals(50000), reason: '${d.age}歳: 枯渇前はあり');
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

        // 62歳より前はiDeCoあり (Phase 1なのでidecoMonthly=生活費)
        for (final d in data.where((d) => d.age < 62)) {
          expect(d.idecoMonthly, equals(300000), reason: '${d.age}歳: 枯渇前');
        }
        // 62歳以降はiDeCo=0
        for (final d in data.where((d) => d.age >= 62)) {
          expect(d.idecoMonthly, equals(0.0), reason: '${d.age}歳: 枯渇後');
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
  });
}
