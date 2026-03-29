import 'package:flutter/material.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import '../presentation/molecules/age_input_field.dart';
import '../presentation/molecules/payment_months_input_field.dart';
import '../presentation/molecules/result_card.dart';

List<Story> moleculesStories() => [
  // AgeInputField Stories
  Story(
    name: 'Molecules/AgeInputField - Default',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: AgeInputField(
        label: '現在の年齢',
        hintText: '例: 35',
        onChanged: (age) {
          // Callback
        },
      ),
    ),
  ),
  Story(
    name: 'Molecules/AgeInputField - With Error',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: StatefulBuilder(
        builder: (context, setState) {
          return AgeInputField(
            label: '現在の年齢',
            hintText: '例: 35',
            onChanged: (age) {
              setState(() {});
            },
          );
        },
      ),
    ),
  ),

  // PaymentMonthsInputField Stories
  Story(
    name: 'Molecules/PaymentMonthsInputField - Default',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: PaymentMonthsInputField(
        label: '年金納付月数',
        hintText: '例: 360',
        onChanged: (months) {
          // Callback
        },
      ),
    ),
  ),
  Story(
    name: 'Molecules/PaymentMonthsInputField - Max Validation',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: PaymentMonthsInputField(
        label: '年金納付月数',
        hintText: '例: 360',
        maxMonths: 480,
        onChanged: (months) {
          // Callback
        },
      ),
    ),
  ),

  // ResultCard Stories
  Story(
    name: 'Molecules/ResultCard - Basic Results',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: ResultCard(
        title: '基礎年金計算結果',
        results: {
          '年額': '¥840,960',
          '月額': '¥70,080',
        },
        units: {
          '年額': '円',
          '月額': '円',
        },
      ),
    ),
  ),
  Story(
    name: 'Molecules/ResultCard - Highlight',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: ResultCard(
        title: '主要結果',
        results: {
          '合計年金': '¥1,500,000',
          '毎月支給額': '¥125,000',
        },
        units: {
          '合計年金': '円',
          '毎月支給額': '円',
        },
        isHighlight: true,
      ),
    ),
  ),
  Story(
    name: 'Molecules/ResultCard - Multiple Items',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: ResultCard(
        title: '年金納付状況',
        results: {
          '納付月数': '360',
          '納付率': '75.0%',
          '受給開始年齢': '65',
          '受給期間': '約20年',
        },
        units: {
          '納付月数': '月',
          '納付率': '%',
          '受給開始年齢': '歳',
        },
      ),
    ),
  ),
];
