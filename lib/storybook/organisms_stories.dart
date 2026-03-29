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
            onSubmit: (age, months) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('計算開始: 年齢=$age, 納付月数=$months'),
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
            onSubmit: (age, months) {},
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
        child: PensionResultDisplay(
          nationalPensionYearly: '¥840,960',
          nationalPensionMonthly: '¥70,080',
          contributionRate: 0.75,
        ),
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
