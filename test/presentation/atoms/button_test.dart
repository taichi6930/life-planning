import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/presentation/atoms/button.dart';

void main() {
  Widget buildTestWidget({
    String label = 'テスト',
    VoidCallback? onPressed,
    bool isLoading = false,
    ButtonVariant variant = ButtonVariant.primary,
    ButtonSize size = ButtonSize.medium,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Button(
          label: label,
          onPressed: onPressed,
          isLoading: isLoading,
          variant: variant,
          size: size,
        ),
      ),
    );
  }

  group('Button Atom Tests', () {
    /// デシジョンテーブル: ボタン状態
    ///
    /// | # | onPressed | isLoading | 期待結果                  |
    /// |---|-----------|-----------|-------------------------|
    /// | 1 | あり      | false     | タップ可能、ラベル表示      |
    /// | 2 | null      | false     | タップ不可（disabled）     |
    /// | 3 | あり      | true      | タップ不可、インジケータ表示 |
    /// | 4 | null      | true      | タップ不可、インジケータ表示 |

    testWidgets('ケース1: onPressed あり + 非ローディング → タップ可能', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildTestWidget(
        label: '計算する',
        onPressed: () => tapped = true,
      ));

      await tester.tap(find.text('計算する'));
      expect(tapped, isTrue);
    });

    testWidgets('ケース2: onPressed null → disabled', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        label: '計算する',
        onPressed: null,
      ));

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('ケース3: isLoading=true → インジケータ表示、タップ不可', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildTestWidget(
        label: '計算する',
        onPressed: () => tapped = true,
        isLoading: true,
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('計算する'), findsNothing);

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isFalse);
    });

    /// デシジョンテーブル: バリアント別スタイル
    ///
    /// | # | variant    | 背景色                   |
    /// |---|-----------|-------------------------|
    /// | 1 | primary   | Theme.primaryColor       |
    /// | 2 | secondary | Colors.grey.shade200     |
    /// | 3 | danger    | Colors.red              |

    testWidgets('secondary バリアントが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        label: 'キャンセル',
        onPressed: () {},
        variant: ButtonVariant.secondary,
      ));

      expect(find.text('キャンセル'), findsOneWidget);
    });

    testWidgets('danger バリアントが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        label: '削除',
        onPressed: () {},
        variant: ButtonVariant.danger,
      ));

      expect(find.text('削除'), findsOneWidget);
    });

    /// デシジョンテーブル: サイズ別の高さ
    ///
    /// | # | size   | height |
    /// |---|--------|--------|
    /// | 1 | small  | 32     |
    /// | 2 | medium | 44     |
    /// | 3 | large  | 56     |

    testWidgets('small サイズの高さは32', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        onPressed: () {},
        size: ButtonSize.small,
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 32);
    });

    testWidgets('medium サイズの高さは44', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        onPressed: () {},
        size: ButtonSize.medium,
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 44);
    });

    testWidgets('large サイズの高さは56', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        onPressed: () {},
        size: ButtonSize.large,
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 56);
    });
  });
}
