import 'package:flutter/material.dart';

import 'presentation/pages/pension_calculation_page.dart';

/// メインアプリウィジェット
class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Planning App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const PensionCalculationPage(),
      // 将来的にNavigationやRoutingを追加する場合はここに記述
    );
  }
}
