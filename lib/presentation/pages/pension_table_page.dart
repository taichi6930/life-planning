import 'package:flutter/material.dart';

import '../templates/pension_table_template.dart';

/// 年齢別年金額テーブルページ
///
/// Atomic Design の Page 層。
/// Template に処理を委譲し、ルーティングのエントリポイントとなる。
class PensionTablePage extends StatelessWidget {
  const PensionTablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PensionTableTemplate();
  }
}
