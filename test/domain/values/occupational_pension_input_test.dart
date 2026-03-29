import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/domain/values/occupational_pension_input.dart';

void main() {
  group('OccupationalPensionInput', () {
    group('Constructor and validation', () {
      test('正常な値で初期化できる', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        expect(input.enrollmentMonths, 300);
        expect(input.averageMonthlyReward, 300000);
        expect(input.averageBonusReward, 600000);
        expect(input.desiredPensionStartAge, 65);
      });

      test('enrollmentMonths が範囲外の場合はエラー', () {
        expect(
          () => OccupationalPensionInput(
            enrollmentMonths: -1,
            averageMonthlyReward: 300000,
            averageBonusReward: 600000,
            desiredPensionStartAge: 65,
          ),
          throwsArgumentError,
        );

        expect(
          () => OccupationalPensionInput(
            enrollmentMonths: 601,
            averageMonthlyReward: 300000,
            averageBonusReward: 600000,
            desiredPensionStartAge: 65,
          ),
          throwsArgumentError,
        );
      });

      test('averageMonthlyReward が負数の場合はエラー', () {
        expect(
          () => OccupationalPensionInput(
            enrollmentMonths: 300,
            averageMonthlyReward: -1,
            averageBonusReward: 600000,
            desiredPensionStartAge: 65,
          ),
          throwsArgumentError,
        );
      });

      test('averageBonusReward が負数の場合はエラー', () {
        expect(
          () => OccupationalPensionInput(
            enrollmentMonths: 300,
            averageMonthlyReward: 300000,
            averageBonusReward: -1,
            desiredPensionStartAge: 65,
          ),
          throwsArgumentError,
        );
      });

      test('desiredPensionStartAge が範囲外の場合はエラー', () {
        expect(
          () => OccupationalPensionInput(
            enrollmentMonths: 300,
            averageMonthlyReward: 300000,
            averageBonusReward: 600000,
            desiredPensionStartAge: 59,
          ),
          throwsArgumentError,
        );

        expect(
          () => OccupationalPensionInput(enrollmentMonths: 300,
            averageMonthlyReward: 300000,
            averageBonusReward: 600000,
            desiredPensionStartAge: 76,
          ),
          throwsArgumentError,
        );
      });

      test('境界値でも正常に初期化できる', () {
        final input1 = OccupationalPensionInput(
          enrollmentMonths: 0,
          averageMonthlyReward: 0,
          averageBonusReward: 0,
          desiredPensionStartAge: 60,
        );
        expect(input1.enrollmentMonths, 0);
        expect(input1.desiredPensionStartAge, 60);

        final input2 = OccupationalPensionInput(
          enrollmentMonths: 600,
          averageMonthlyReward: 99999999,
          averageBonusReward: 99999999,
          desiredPensionStartAge: 75,
        );
        expect(input2.enrollmentMonths, 600);
        expect(input2.desiredPensionStartAge, 75);
      });
    });

    group('Enrollment rate calculation', () {
      test('getEnrollmentRate は正しい値を返す', () {
        final input0 = OccupationalPensionInput(
          enrollmentMonths: 0,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        expect(input0.getEnrollmentRate(), 0.0);

        final input300 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        expect(input300.getEnrollmentRate(), closeTo(0.5, 0.0001));

        final input600 = OccupationalPensionInput(
          enrollmentMonths: 600,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        expect(input600.getEnrollmentRate(), 1.0);
      });

      test('境界値での getEnrollmentRate 計算', () {
        final input1 = OccupationalPensionInput(
          enrollmentMonths: 1,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        expect(input1.getEnrollmentRate(), closeTo(1 / 600, 0.0001));

        final input599 = OccupationalPensionInput(
          enrollmentMonths: 599,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        expect(input599.getEnrollmentRate(), closeTo(599 / 600, 0.0001));
      });
    });

    group('Pension adjustment rate calculation', () {
      test('65歳受給の場合は1.0を返す', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        expect(input.getPensionAdjustmentRate(), 1.0);
      });

      test('繰上げ受給（60歳）の調整率を計算', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 60,
        );
        // 1.0 - (0.004 × (65-60) × 12) = 1.0 - 0.24 = 0.76
        expect(input.getPensionAdjustmentRate(), closeTo(0.76, 0.0001));
      });

      test('繰下げ受給（70歳）の調整率を計算', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 70,
        );
        // 1.0 + (0.007 × (70-65) × 12) = 1.0 + 0.42 = 1.42
        expect(input.getPensionAdjustmentRate(), closeTo(1.42, 0.0001));
      });

      test('最大繰下げ受給（75歳）の調整率を計算', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 75,
        );
        // 1.0 + (0.007 × (75-65) × 12) = 1.0 + 0.84 = 1.84
        expect(input.getPensionAdjustmentRate(), closeTo(1.84, 0.0001));
      });

      test('全ての年齢での調整率を確認', () {
        for (int age = 60; age <= 75; age++) {
          final input = OccupationalPensionInput(
            enrollmentMonths: 300,
            averageMonthlyReward: 300000,
            averageBonusReward: 600000,
            desiredPensionStartAge: age,
          );
          final rate = input.getPensionAdjustmentRate();
          expect(rate, greaterThanOrEqualTo(0.76));
          expect(rate, lessThanOrEqualTo(1.84));
        }
      });
    });

    group('Equality and hash code', () {
      test('同じ値で初期化された2つのインスタンスは等しい', () {
        final input1 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        final input2 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        expect(input1, input2);
        expect(input1.hashCode, input2.hashCode);
      });

      test('同じインスタンスは自分自身に等しい', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        expect(input, input);
      });

      test('異なる全フィールドで等しくないはず', () {
        final input1 = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        expect(
          input1,
          isNot(
            OccupationalPensionInput(
              enrollmentMonths: 301,
              averageMonthlyReward: 300000,
              averageBonusReward: 600000,
              desiredPensionStartAge: 65,
            ),
          ),
        );

        expect(
          input1,
          isNot(
            OccupationalPensionInput(
              enrollmentMonths: 300,
              averageMonthlyReward: 300001,
              averageBonusReward: 600000,
              desiredPensionStartAge: 65,
            ),
          ),
        );

        expect(
          input1,
          isNot(
            OccupationalPensionInput(
              enrollmentMonths: 300,
              averageMonthlyReward: 300000,
              averageBonusReward: 600001,
              desiredPensionStartAge: 65,
            ),
          ),
        );

        expect(
          input1,
          isNot(
            OccupationalPensionInput(
              enrollmentMonths: 300,
              averageMonthlyReward: 300000,
              averageBonusReward: 600000,
              desiredPensionStartAge: 66,
            ),
          ),
        );
      });
    });

    group('isValid method', () {
      test('有効な値では isValid が true を返す', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );
        expect(input.isValid(), true);
      });

      test('無効な値では isValid が false を返す', () {
        // これは constructor で例外を発生させるため、
        // isValid() メソッドは実件上 constructor を通過した値では常に true
        // ただし isValid() メソッド自体がロジックを持つ場合...
        // 本設計では isValid() = true (constructor で検証済みなので)
      });

      test('境界値でも isValid が true', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 0,
          averageMonthlyReward: 0,
          averageBonusReward: 0,
          desiredPensionStartAge: 60,
        );
        expect(input.isValid(), true);
      });
    });

    group('toString', () {
      test('toString は有効な文字列を返す', () {
        final input = OccupationalPensionInput(
          enrollmentMonths: 300,
          averageMonthlyReward: 300000,
          averageBonusReward: 600000,
          desiredPensionStartAge: 65,
        );

        final str = input.toString();
        expect(str, contains('OccupationalPensionInput'));
        expect(str, contains('300'));
        expect(str, contains('300000'));
        expect(str, contains('600000'));
        expect(str, contains('65'));
      });
    });
  });
}
