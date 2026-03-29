import 'package:flutter/material.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import '../presentation/atoms/button.dart';
import '../presentation/atoms/input_field.dart';
import '../presentation/atoms/label.dart';
import '../presentation/atoms/result_text.dart';

List<Story> atomsStories() => [
  // Button Stories
  Story(
    name: 'Atoms/Button - Primary',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Button(
        label: 'Primary Button',
        onPressed: () {},
        variant: ButtonVariant.primary,
        size: ButtonSize.medium,
      ),
    ),
  ),
  Story(
    name: 'Atoms/Button - Secondary',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Button(
        label: 'Secondary Button',
        onPressed: () {},
        variant: ButtonVariant.secondary,
        size: ButtonSize.medium,
      ),
    ),
  ),
  Story(
    name: 'Atoms/Button - Danger',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Button(
        label: 'Delete',
        onPressed: () {},
        variant: ButtonVariant.danger,
        size: ButtonSize.medium,
      ),
    ),
  ),
  Story(
    name: 'Atoms/Button - Loading',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Button(
        label: 'Processing...',
        onPressed: () {},
        isLoading: true,
        variant: ButtonVariant.primary,
        size: ButtonSize.medium,
      ),
    ),
  ),
  Story(
    name: 'Atoms/Button - All Sizes',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Button(
            label: 'Small',
            onPressed: () {},
            size: ButtonSize.small,
          ),
          const SizedBox(height: 16),
          Button(
            label: 'Medium',
            onPressed: () {},
            size: ButtonSize.medium,
          ),
          const SizedBox(height: 16),
          Button(
            label: 'Large',
            onPressed: () {},
            size: ButtonSize.large,
          ),
        ],
      ),
    ),
  ),

  // InputField Stories
  Story(
    name: 'Atoms/InputField - Default',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: InputField(
        label: 'Username',
        hintText: 'Enter your username',
      ),
    ),
  ),
  Story(
    name: 'Atoms/InputField - With Error',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: InputField(
        label: 'Email',
        hintText: 'your.email@example.com',
        errorText: 'Invalid email format',
      ),
    ),
  ),
  Story(
    name: 'Atoms/InputField - Number Input',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: InputField(
        label: 'Age',
        hintText: '30',
        keyboardType: TextInputType.number,
      ),
    ),
  ),

  // Label Stories
  Story(
    name: 'Atoms/Label - Sizes',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Label(
            'Small Label',
            size: LabelSize.small,
          ),
          const SizedBox(height: 16),
          Label(
            'Medium Label',
            size: LabelSize.medium,
          ),
          const SizedBox(height: 16),
          Label(
            'Large Label',
            size: LabelSize.large,
          ),
        ],
      ),
    ),
  ),
  Story(
    name: 'Atoms/Label - Colors',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Label(
            'Primary Color',
            color: LabelColor.primary,
          ),
          const SizedBox(height: 12),
          Label(
            'Secondary Color',
            color: LabelColor.secondary,
          ),
          const SizedBox(height: 12),
          Label(
            'Error Color',
            color: LabelColor.error,
          ),
          const SizedBox(height: 12),
          Label(
            'Success Color',
            color: LabelColor.success,
          ),
        ],
      ),
    ),
  ),

  // ResultText Stories
  Story(
    name: 'Atoms/ResultText - Default',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: ResultText(
        label: 'Annual Pension',
        value: '¥840,960',
        unit: 'per year',
      ),
    ),
  ),
  Story(
    name: 'Atoms/ResultText - Highlight',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: ResultText(
        label: 'Total Amount',
        value: '¥5,000,000',
        unit: 'JPY',
        isHighlight: true,
      ),
    ),
  ),
  Story(
    name: 'Atoms/ResultText - All Sizes',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResultText(
            label: 'Small',
            value: '¥100,000',
            size: ResultTextSize.small,
          ),
          const SizedBox(height: 16),
          ResultText(
            label: 'Medium',
            value: '¥500,000',
            size: ResultTextSize.medium,
          ),
          const SizedBox(height: 16),
          ResultText(
            label: 'Large',
            value: '¥1,000,000',
            size: ResultTextSize.large,
          ),
        ],
      ),
    ),
  ),
];
