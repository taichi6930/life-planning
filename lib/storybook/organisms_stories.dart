import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import '../presentation/organisms/pension_form.dart';
import '../presentation/organisms/pension_result_display.dart';

List<Story> organismsStories() => [
  // PensionForm Stories
  Story(
    name: 'Organisms/PensionForm - Default',
    builder: (context) => ProviderScope(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: PensionForm(
            onSubmit: (values) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('計算開始: 年齢=${values.currentAge}, 納付月数=${values.paymentMonths}, 厚生年金月数=${values.occupationalPaymentMonths}, 給与=${values.monthlySalary}, 賞与=${values.bonus}, 受給開始年齢=${values.desiredPensionStartAge}, iDeCo=${values.idecoMonthlyContribution}, 投資信託=${values.investmentTrustMonthlyContribution}'),
                ),
              );
            },
          ),
        ),
      ),
    ),
  ),
  Story(
    name: 'Organisms/PensionForm - Loading',
    builder: (context) => ProviderScope(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: PensionForm(
            isLoading: true,
            onSubmit: (values) {},
          ),
        ),
      ),
    ),
  ),

  // PensionResultDisplay Stories
  Story(
    name: 'Organisms/PensionResultDisplay - Empty',
    builder: (context) => const ProviderScope(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: PensionResultDisplay(),
      ),
    ),
  ),
  Story(
    name: 'Organisms/PensionResultDisplay - With Results',
    builder: (context) => const ProviderScope(
      child: Padding(
        padding: EdgeInsets.all(16),
        // PensionResultDisplay は provider から自律的にデータを取得するため、
        // 結果を表示するには ProviderScope 内で計算を実行する必要がある。
        child: PensionResultDisplay(),
      ),
    ),
  ),
  Story(
    name: 'Organisms/PensionResultDisplay - Loading',
    builder: (context) => const ProviderScope(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: PensionResultDisplay(
          isLoading: true,
        ),
      ),
    ),
  ),
];
