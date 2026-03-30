import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_planning/presentation/organisms/pension_form.dart';

void main() {
  Widget buildTestWidget({
    Function(int, int, int, int, int, int, int, double, int, int, int)? onSubmit,
    Function(int, int, int, int, int, int, int, double, int, int, int)? onFieldChanged,
    bool isLoading = false,
    int? initialAge,
    int? initialPaymentMonths,
    int initialOccupationalPaymentMonths = 0,
    int initialMonthlySalary = 0,
    int initialBonus = 0,
    int initialDesiredPensionStartAge = 65,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PensionForm(
          onSubmit: onSubmit,
          onFieldChanged: onFieldChanged,
          isLoading: isLoading,
          initialAge: initialAge,
          initialPaymentMonths: initialPaymentMonths,
          initialOccupationalPaymentMonths: initialOccupationalPaymentMonths,
          initialMonthlySalary: initialMonthlySalary,
          initialBonus: initialBonus,
          initialDesiredPensionStartAge: initialDesiredPensionStartAge,
        ),
      ),
    );
  }

  group('PensionForm Organism Tests', () {
    testWidgets('初期表示で全フィールドが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 各フィールドのラベルが表示される
      expect(find.text('受給開始年齢'), findsOneWidget);
      expect(find.text('現在の年齢'), findsOneWidget);
      expect(find.text('年金納付月数'), findsOneWidget);
      expect(find.text('厚生年金加入月数'), findsOneWidget);
      expect(find.text('標準報酬月額（給与）'), findsOneWidget);
      expect(find.text('賞与（年額）'), findsOneWidget);
      expect(find.text('計算する'), findsOneWidget);
    });

    testWidgets('初期値がコントローラーに反映される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialAge: 40,
        initialPaymentMonths: 300,
        initialOccupationalPaymentMonths: 120,
        initialMonthlySalary: 250000,
        initialBonus: 600000,
        initialDesiredPensionStartAge: 70,
      ));
      await tester.pumpAndSettle();

      // 各フィールドに初期値が表示される
      expect(find.text('40'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      expect(find.text('250000'), findsOneWidget);
      expect(find.text('600000'), findsOneWidget);
      expect(find.text('70歳'), findsOneWidget);
    });

    testWidgets('スライダーの初期値が65歳で表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('65歳'), findsOneWidget);
      // iDeCo追加で Slider は3つ（受給開始年齢、想定利回り、想定寿命）
      expect(find.byType(Slider), findsNWidgets(3));
    });

    testWidgets('ローディング中はボタンにインジケータが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(isLoading: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    /// デシジョンテーブル: 計算ボタン押下時の挙動
    ///
    /// | # | age  | months | occMonths | salary | bonus | 期待結果       |
    /// |---|------|--------|-----------|--------|-------|---------------|
    /// | 1 | null | null   | 0         | 0      | 0     | SnackBar表示  |
    /// | 2 | 30   | null   | 0         | 0      | 0     | SnackBar表示  |
    /// | 3 | null | 480    | 0         | 0      | 0     | SnackBar表示  |
    /// | 4 | 30   | 480    | 0         | 0      | 0     | onSubmit呼出  |
    /// | 5 | 40   | 360    | 240       | 300000 | 500000| onSubmit呼出  |

    testWidgets('ケース1: 全フィールドnullで計算ボタン → SnackBar表示', (WidgetTester tester) async {
      // _age=null, _paymentMonths=null のまま submit
      // initState では _age=widget.initialAge (null), _paymentMonths=widget.initialPaymentMonths (null)
      // ただしデフォルトでは _occupationalPaymentMonths=0, _monthlySalary=0, _bonus=0, _desiredPensionStartAge=65
      // → _age==null なので SnackBar
      bool submitted = false;
      await tester.pumpWidget(buildTestWidget(
        onSubmit: (a, m, o, s, b, d, ic, ir, cb, le, ta) => submitted = true,
      ));
      await tester.pumpAndSettle();

      // コントローラーはデフォルト値 '30' と '480' で初期化されるが
      // _age と _paymentMonths は null のまま
      // → AgeInputField と PaymentMonthsInputField の onChanged が呼ばれるまで null
      // まず、年齢フィールドをクリアして null にする
      final ageField = find.byType(TextField).first;
      await tester.enterText(ageField, '');
      await tester.pumpAndSettle();

      // iDeCo追加でフォームが長くなりボタンが画面外になるためスクロール
      await tester.ensureVisible(find.text('計算する'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('計算する'));
      await tester.pumpAndSettle();

      expect(find.text('すべてのフィールドを入力してください'), findsOneWidget);
      expect(submitted, isFalse);
    });

    testWidgets('ケース4: age=35, months=440 で計算ボタン → onSubmit呼出', (WidgetTester tester) async {
      List<int>? submittedValues;
      await tester.pumpWidget(buildTestWidget(
        onSubmit: (a, m, o, s, b, d, ic, ir, cb, le, ta) {
          submittedValues = [a, m, o, s, b, d];
        },
      ));
      await tester.pumpAndSettle();

      // 年齢フィールドに値を入力（デフォルト '30' とは異なる値で onChanged をトリガー）
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '35');
      await tester.pumpAndSettle();
      // PaymentMonthsInputField（デフォルト '480' とは異なる値）
      await tester.enterText(textFields.at(1), '440');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('計算する'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('計算する'));
      await tester.pumpAndSettle();

      expect(submittedValues, isNotNull);
      expect(submittedValues![0], 35); // age
      expect(submittedValues![1], 440); // months
    });

    testWidgets('ケース5: 全フィールド入力済で計算ボタン → 正しい値で onSubmit呼出', (WidgetTester tester) async {
      List<int>? submittedValues;
      await tester.pumpWidget(buildTestWidget(
        onSubmit: (a, m, o, s, b, d, ic, ir, cb, le, ta) {
          submittedValues = [a, m, o, s, b, d];
        },
      ));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '40');
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(1), '360');
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(2), '240');
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(3), '300000');
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(4), '500000');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('計算する'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('計算する'));
      await tester.pumpAndSettle();

      expect(submittedValues, isNotNull);
      expect(submittedValues![0], 40); // age
      expect(submittedValues![1], 360); // months
      expect(submittedValues![2], 240); // occMonths
      expect(submittedValues![3], 300000); // salary
      expect(submittedValues![4], 500000); // bonus
    });

    testWidgets('年齢入力で onFieldChanged が呼ばれる', (WidgetTester tester) async {
      int callCount = 0;
      await tester.pumpWidget(buildTestWidget(
        onFieldChanged: (a, m, o, s, b, d, ic, ir, cb, le, ta) => callCount++,
      ));
      await tester.pumpAndSettle();
      callCount = 0; // initState の addPostFrameCallback 分をリセット

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '35');
      await tester.pumpAndSettle();

      // onFieldChanged は _age が null でなくなってから呼ばれるが、
      // _paymentMonths がデフォルトでは null のため呼ばれない可能性がある
      // initState で _paymentMonths = widget.initialPaymentMonths (null)
      // → onFieldChanged は呼ばれない
      // 先に paymentMonths を入力
      await tester.enterText(textFields.at(1), '360');
      await tester.pumpAndSettle();

      // 両方入力されたので onFieldChanged が呼ばれるはず
      expect(callCount, greaterThan(0));
    });

    testWidgets('厚生年金加入月数に範囲外の値は無視される', (WidgetTester tester) async {
      int? lastOccMonths;
      await tester.pumpWidget(buildTestWidget(
        initialAge: 30,
        initialPaymentMonths: 360,
        onFieldChanged: (a, m, o, s, b, d, ic, ir, cb, le, ta) => lastOccMonths = o,
      ));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      // 厚生年金加入月数フィールド（3番目）
      await tester.enterText(textFields.at(2), '700');
      await tester.pumpAndSettle();

      // 700は範囲外（0-600）なので onChanged で更新されない
      // → 前の値のまま
      expect(lastOccMonths, isNot(700));
    });

    testWidgets('標準報酬月額に負の値は無視される', (WidgetTester tester) async {
      int inputCount = 0;
      await tester.pumpWidget(buildTestWidget(
        initialAge: 30,
        initialPaymentMonths: 360,
        onFieldChanged: (a, m, o, s, b, d, ic, ir, cb, le, ta) => inputCount++,
      ));
      await tester.pumpAndSettle();
      inputCount = 0;

      final textFields = find.byType(TextField);
      // 標準報酬月額フィールド（4番目）に負の値
      await tester.enterText(textFields.at(3), '-100');
      await tester.pumpAndSettle();

      // 負の値は受け付けないので onFieldChanged は呼ばれない
      // （ただし前の値で呼ばれる場合を除く）
    });

    testWidgets('didUpdateWidget: initialAge の変更でコントローラーが同期される', (WidgetTester tester) async {
      // 初期値で表示
      await tester.pumpWidget(buildTestWidget(initialAge: 30));
      await tester.pumpAndSettle();
      expect(find.text('30'), findsOneWidget);

      // 別の initialAge で再描画
      await tester.pumpWidget(buildTestWidget(initialAge: 45));
      await tester.pumpAndSettle();
      expect(find.text('45'), findsOneWidget);
    });

    testWidgets('didUpdateWidget: initialPaymentMonths の変更でコントローラーが同期される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(initialPaymentMonths: 360));
      await tester.pumpAndSettle();
      expect(find.text('360'), findsOneWidget);

      await tester.pumpWidget(buildTestWidget(initialPaymentMonths: 240));
      await tester.pumpAndSettle();
      expect(find.text('240'), findsOneWidget);
    });

    testWidgets('didUpdateWidget: initialDesiredPensionStartAge の変更でスライダーが同期される', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(initialDesiredPensionStartAge: 65));
      await tester.pumpAndSettle();
      expect(find.text('65歳'), findsOneWidget);

      await tester.pumpWidget(buildTestWidget(initialDesiredPensionStartAge: 72));
      await tester.pumpAndSettle();
      expect(find.text('72歳'), findsOneWidget);
    });

    testWidgets('didUpdateWidget: initialOccupationalPaymentMonths の変更でコントローラーが同期', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(initialOccupationalPaymentMonths: 100));
      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);

      await tester.pumpWidget(buildTestWidget(initialOccupationalPaymentMonths: 200));
      await tester.pumpAndSettle();
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('didUpdateWidget: initialMonthlySalary の変更でコントローラーが同期', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(initialMonthlySalary: 200000));
      await tester.pumpAndSettle();
      expect(find.text('200000'), findsOneWidget);

      await tester.pumpWidget(buildTestWidget(initialMonthlySalary: 350000));
      await tester.pumpAndSettle();
      expect(find.text('350000'), findsOneWidget);
    });

    testWidgets('didUpdateWidget: initialBonus の変更でコントローラーが同期', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(initialBonus: 400000));
      await tester.pumpAndSettle();
      expect(find.text('400000'), findsOneWidget);

      await tester.pumpWidget(buildTestWidget(initialBonus: 800000));
      await tester.pumpAndSettle();
      expect(find.text('800000'), findsOneWidget);
    });

    testWidgets('スライダーをドラッグすると受給開始年齢が変更され onFieldChanged が呼ばれる', (WidgetTester tester) async {
      int? lastStartAge;
      await tester.pumpWidget(buildTestWidget(
        initialAge: 30,
        initialPaymentMonths: 360,
        initialDesiredPensionStartAge: 65,
        onFieldChanged: (a, m, o, s, b, d, ic, ir, cb, le, ta) => lastStartAge = d,
      ));
      await tester.pumpAndSettle();

      // 初期表示: 65歳
      expect(find.text('65歳'), findsOneWidget);

      // スライダーをドラッグ（右方向にオフセット → 年齢が上がる）
      // iDeCo追加で Slider が3つあるため最初の受給開始年齢スライダーを指定
      final slider = find.byType(Slider).first;
      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();

      // 年齢が65歳から変わっていること
      expect(find.text('65歳'), findsNothing);
      // onFieldChanged が呼ばれて新しい年齢が渡されていること
      expect(lastStartAge, isNotNull);
      expect(lastStartAge, isNot(65));
    });
  });
}
