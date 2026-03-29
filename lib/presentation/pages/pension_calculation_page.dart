import 'package:flutter/material.dart';

import '../templates/pension_form_template.dart';

/// 年金計算ページ
/// 
/// PensionFormTemplate をラップした実際のページコンポーネント
class PensionCalculationPage extends StatelessWidget {
  const PensionCalculationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const PensionFormTemplate(
      title: '年金計算シミュレーター',
    );
  }
}
