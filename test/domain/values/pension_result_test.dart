import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/domain/values/pension_result.dart';

/// PensionResult の統合テスト（デシジョンテーブル）
///
/// PensionResult 値オブジェクトの全機能をカバーする仕様書。
///
/// ## テストカバレッジ一覧
/// | グループ | テスト数 | カバレッジ | 説明 |
/// |---------|--------|---------|------|
/// | コンストラクタ | 3 | 100% | オブジェクト生成と初期化 |
/// | toString() | 5 | 100% | フォーマット出力（調整率の表示） |
/// | toDebugString() | 2 | 100% | デバッグ用詳細出力 |
/// | operator== | 5 | 100% | 等値性判定 |
/// | hashCode | 3 | 100% | ハッシュコード生成 |
/// | **合計** | **18** | **100%** | すべてのメソッドと境界値をカバー |
///
void main() {
  group('PensionResult', () {
    group('コンストラクタと初期化', () {
      test('全フィールドが正しく初期化される', () {
        // Arrange
        const basicPensionMonthly = 70608.0;
        const basicPensionAnnual = 847296.0;
        const occupationalPensionMonthly = 150000.0;
        const occupationalPensionAnnual = 1800000.0;
        const totalPensionMonthly = 220608.0;
        const totalPensionAnnual = 2647296.0;
        const adjustmentRate = 1.0;
        const pensionStartAge = 65;

        // Act
        final result = PensionResult(
          basicPensionMonthly: basicPensionMonthly,
          basicPensionAnnual: basicPensionAnnual,
          occupationalPensionMonthly: occupationalPensionMonthly,
          occupationalPensionAnnual: occupationalPensionAnnual,
          totalPensionMonthly: totalPensionMonthly,
          totalPensionAnnual: totalPensionAnnual,
          adjustmentRate: adjustmentRate,
          pensionStartAge: pensionStartAge,
        );

        // Assert
        expect(result.basicPensionMonthly, basicPensionMonthly);
        expect(result.basicPensionAnnual, basicPensionAnnual);
        expect(result.occupationalPensionMonthly, occupationalPensionMonthly);
        expect(result.occupationalPensionAnnual, occupationalPensionAnnual);
        expect(result.totalPensionMonthly, totalPensionMonthly);
        expect(result.totalPensionAnnual, totalPensionAnnual);
        expect(result.adjustmentRate, adjustmentRate);
        expect(result.pensionStartAge, pensionStartAge);
      });

      test('ゼロ値で初期化される', () {
        // Act
        final result = PensionResult(
          basicPensionMonthly: 0.0,
          basicPensionAnnual: 0.0,
          occupationalPensionMonthly: 0.0,
          occupationalPensionAnnual: 0.0,
          totalPensionMonthly: 0.0,
          totalPensionAnnual: 0.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );

        // Assert
        expect(result.basicPensionMonthly, 0.0);
        expect(result.totalPensionMonthly, 0.0);
      });

      test('最大値で初期化される', () {
        // Act
        final result = PensionResult(
          basicPensionMonthly: 100000.0,
          basicPensionAnnual: 1200000.0,
          occupationalPensionMonthly: 500000.0,
          occupationalPensionAnnual: 6000000.0,
          totalPensionMonthly: 600000.0,
          totalPensionAnnual: 7200000.0,
          adjustmentRate: 1.84,
          pensionStartAge: 75,
        );

        // Assert
        expect(result.adjustmentRate, 1.84);
        expect(result.pensionStartAge, 75);
      });
    });

    group('toString() - フォーマット出力', () {
      test('標準受給（調整率 1.0）の場合、「標準」と表示される', () {
        // Arrange
        final result = PensionResult(
          basicPensionMonthly: 70608.0,
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 0.0,
          occupationalPensionAnnual: 0.0,
          totalPensionMonthly: 70608.0,
          totalPensionAnnual: 847296.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );

        // Act
        final output = result.toString();

        // Assert
        expect(output, contains('調整率: 標準 (0.0%)'));
        expect(output, contains('受給開始年齢: 65歳'));
      });

      test('繰上げ受給（調整率 0.76）の場合、「繰上げ」と表示される', () {
        // Arrange
        final result = PensionResult(
          basicPensionMonthly: 53661.84,
          basicPensionAnnual: 643942.08,
          occupationalPensionMonthly: 0.0,
          occupationalPensionAnnual: 0.0,
          totalPensionMonthly: 53661.84,
          totalPensionAnnual: 643942.08,
          adjustmentRate: 0.76,
          pensionStartAge: 60,
        );

        // Act
        final output = result.toString();

        // Assert
        expect(output, contains('調整率: 繰上げ (-24.0%)'));
        expect(output, contains('受給開始年齢: 60歳'));
      });

      test('繰下げ受給（調整率 1.42）の場合、「繰下げ」と表示される', () {
        // Arrange
        final result = PensionResult(
          basicPensionMonthly: 100062.96,
          basicPensionAnnual: 1200755.52,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 250062.96,
          totalPensionAnnual: 3000755.52,
          adjustmentRate: 1.42,
          pensionStartAge: 70,
        );

        // Act
        final output = result.toString();

        // Assert
        expect(output, contains('調整率: 繰下げ (42.0%)'));
        expect(output, contains('受給開始年齢: 70歳'));
      });

      test('最大繰下げ（調整率 1.84）の場合、「繰下げ」と表示される', () {
        // Arrange
        final result = PensionResult(
          basicPensionMonthly: 129919.68,
          basicPensionAnnual: 1559036.16,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 279919.68,
          totalPensionAnnual: 3359036.16,
          adjustmentRate: 1.84,
          pensionStartAge: 75,
        );

        // Act
        final output = result.toString();

        // Assert
        expect(output, contains('調整率: 繰下げ (84.0%)'));
        expect(output, contains('受給開始年齢: 75歳'));
      });

      test('円記号と数値が正しくフォーマットされている', () {
        // Arrange
        final result = PensionResult(
          basicPensionMonthly: 70608.0,
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 220608.0,
          totalPensionAnnual: 2647296.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );

        // Act
        final output = result.toString();

        // Assert
        expect(output, contains('¥70608'));
        expect(output, contains('¥847296'));
        expect(output, contains('¥150000'));
        expect(output, contains('¥1800000'));
        expect(output, contains('¥220608'));
      });
    });

    group('toDebugString() - デバッグ出力', () {
      test('全フィールドをデバッグ形式で出力する', () {
        // Arrange
        final result = PensionResult(
          basicPensionMonthly: 70608.0,
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 220608.0,
          totalPensionAnnual: 2647296.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );

        // Act
        final debug = result.toDebugString();

        // Assert
        expect(debug, contains('basicPensionMonthly: 70608'));
        expect(debug, contains('basicPensionAnnual: 847296'));
        expect(debug, contains('occupationalPensionMonthly: 150000'));
        expect(debug, contains('occupationalPensionAnnual: 1800000'));
        expect(debug, contains('totalPensionMonthly: 220608'));
        expect(debug, contains('totalPensionAnnual: 2647296'));
        expect(debug, contains('adjustmentRate: 1.0'));
        expect(debug, contains('pensionStartAge: 65'));
      });

      test('ゼロ値もデバッグ出力される', () {
        // Arrange
        final result = PensionResult(
          basicPensionMonthly: 0.0,
          basicPensionAnnual: 0.0,
          occupationalPensionMonthly: 0.0,
          occupationalPensionAnnual: 0.0,
          totalPensionMonthly: 0.0,
          totalPensionAnnual: 0.0,
          adjustmentRate: 0.76,
          pensionStartAge: 60,
        );

        // Act
        final debug = result.toDebugString();

        // Assert
        expect(debug, contains('basicPensionMonthly: 0'));
        expect(debug, contains('adjustmentRate: 0.76'));
        expect(debug, contains('pensionStartAge: 60'));
      });
    });

    group('operator== - 等値性判定', () {
      test('同じ値のオブジェクトは等しい', () {
        // Arrange
        final result1 = PensionResult(
          basicPensionMonthly: 70608.0,
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 220608.0,
          totalPensionAnnual: 2647296.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );
        final result2 = PensionResult(
          basicPensionMonthly: 70608.0,
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 220608.0,
          totalPensionAnnual: 2647296.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );

        // Act & Assert
        expect(result1 == result2, isTrue);
        expect(result1, equals(result2));
      });

      test('同じオブジェクトは等しい（identity）', () {
        // Arrange
        final result = PensionResult(
          basicPensionMonthly: 70608.0,
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 220608.0,
          totalPensionAnnual: 2647296.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );

        // Act & Assert
        expect(result == result, isTrue);
      });

      test('異なる basicPensionMonthly では等しくない', () {
        // Arrange
        final result1 = PensionResult(
          basicPensionMonthly: 70608.0,
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 220608.0,
          totalPensionAnnual: 2647296.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );
        final result2 = PensionResult(
          basicPensionMonthly: 80000.0, // 異なる
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 230000.0,
          totalPensionAnnual: 2760000.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );

        // Act & Assert
        expect(result1 == result2, isFalse);
      });

      test('異なる pensionStartAge では等しくない', () {
        // Arrange
        final result1 = PensionResult(
          basicPensionMonthly: 70608.0,
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 220608.0,
          totalPensionAnnual: 2647296.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );
        final result2 = PensionResult(
          basicPensionMonthly: 70608.0,
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 220608.0,
          totalPensionAnnual: 2647296.0,
          adjustmentRate: 1.0,
          pensionStartAge: 70, // 異なる
        );

        // Act & Assert
        expect(result1 == result2, isFalse);
      });

      test('異なる型のオブジェクトは等しくない', () {
        // Arrange
        final result = PensionResult(
          basicPensionMonthly: 70608.0,
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 220608.0,
          totalPensionAnnual: 2647296.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );

        // Act & Assert
        // ignore: unrelated_type_equality_checks
        expect(result == 'not a PensionResult', isFalse);
        // ignore: unrelated_type_equality_checks
        expect(result == 123, isFalse);
      });
    });

    group('hashCode - ハッシュコード生成', () {
      test('同じ値のオブジェクトは同じ hashCode を持つ', () {
        // Arrange
        final result1 = PensionResult(
          basicPensionMonthly: 70608.0,
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 220608.0,
          totalPensionAnnual: 2647296.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );
        final result2 = PensionResult(
          basicPensionMonthly: 70608.0,
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 220608.0,
          totalPensionAnnual: 2647296.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );

        // Act & Assert
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('Set に追加できる（hashCode による一意性）', () {
        // Arrange
        final result1 = PensionResult(
          basicPensionMonthly: 70608.0,
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 220608.0,
          totalPensionAnnual: 2647296.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );
        final result2 = PensionResult(
          basicPensionMonthly: 70608.0,
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 220608.0,
          totalPensionAnnual: 2647296.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );
        final result3 = PensionResult(
          basicPensionMonthly: 80000.0,
          basicPensionAnnual: 960000.0,
          occupationalPensionMonthly: 160000.0,
          occupationalPensionAnnual: 1920000.0,
          totalPensionMonthly: 240000.0,
          totalPensionAnnual: 2880000.0,
          adjustmentRate: 1.0,
          pensionStartAge: 70,
        );

        // Act
        final set = <PensionResult>{result1, result2, result3};

        // Assert
        expect(set.length, 2); // result1 と result2 は同じ値なので1つ
      });

      test('Map のキーとして使用できる', () {
        // Arrange
        final result = PensionResult(
          basicPensionMonthly: 70608.0,
          basicPensionAnnual: 847296.0,
          occupationalPensionMonthly: 150000.0,
          occupationalPensionAnnual: 1800000.0,
          totalPensionMonthly: 220608.0,
          totalPensionAnnual: 2647296.0,
          adjustmentRate: 1.0,
          pensionStartAge: 65,
        );

        // Act
        final map = <PensionResult, String>{
          result: '標準受給',
        };

        // Assert
        expect(map[result], '標準受給');
      });
    });
  });
}
