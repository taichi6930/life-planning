import 'dart:io';

import 'package:life_planning/domain/services/pension_simulation_service.dart';
import 'package:life_planning/domain/values/investment_trust_input.dart';
import 'package:life_planning/domain/values/national_pension_input.dart';
import 'package:life_planning/domain/values/occupational_pension_input.dart';
import 'package:life_planning/domain/values/pension_result.dart';

/// ペンション計算シミュレーターのCLIツール
/// 
/// Domain層（PensionSimulationService）の動作を直接検証できます。
/// 任意のパラメータでシミュレーションを実行し、年齢別の結果を表示します。
/// 
/// 使用方法:
/// ```bash
/// # pension_simulation_input.txtから読み込んで実行
/// dart run bin/pension_simulator.dart
/// 
/// # 対話的に実行
/// dart run bin/pension_simulator.dart --interactive
/// 
/// # 環境変数でパラメータ指定
/// IDECO_CURRENT_BALANCE=5000000 dart run bin/pension_simulator.dart
/// ```
void main(List<String> args) {
  print('\n╔════════════════════════════════════════════════════════════════╗');
  print('║     ペンション計算シミュレーター (CLI - Domain層検証用)      ║');
  print('╚════════════════════════════════════════════════════════════════╝\n');

  final isInteractive = args.contains('--interactive');
  
  // パラメータ取得（ファイル > 環境変数 > デフォルト）
  Map<String, dynamic> params;
  
  if (isInteractive) {
    params = _getInputParameters();
  } else if (File('pension_simulation_input.txt').existsSync()) {
    // ファイルから読み込み
    params = _getParametersFromFile();
    print('📂 pension_simulation_input.txt から設定を読み込みました\n');
  } else {
    // 環境変数またはデフォルト
    params = _getParametersFromEnvironmentOrDefaults();
  }

  print('📊 シミュレーション実行中...\n');

  // PensionResult生成（公的年金値）
  final result = PensionResult(
    basicPensionMonthly: params['basicPensionMonthly'] as double,
    basicPensionAnnual: (params['basicPensionMonthly'] as double) * 12,
    occupationalPensionMonthly: params['occupationalPensionMonthly'] as double,
    occupationalPensionAnnual: (params['occupationalPensionMonthly'] as double) * 12,
    idecoMonthly: 0,
    idecoAnnual: 0,
    monthlyLivingExpenses: params['monthlyLivingExpenses'] as double,
    monthlyShortfall: 0,
    idecoFutureValue: 0,
    idecoExhaustionAge: 0,
    investmentTrustMonthly: 0,
    investmentTrustAnnual: 0,
    investmentTrustFutureValue: 0,
    investmentTrustExhaustionAge: 0,
    targetAge: 100,
    isIdecoSufficient: true,
    totalPensionMonthly: 0,
    totalPensionAnnual: 0,
    adjustmentRate: 1.0,
    pensionStartAge: params['publicPensionStartAge'] as int,
  );

  // シミュレーション実行
  final chartData = PensionSimulationService.simulateFromCurrentAgeToMaxAge(
    result: result,
    publicPensionStartAge: params['publicPensionStartAge'] as int,
    idecoCurrentAge: params['idecoCurrentAge'] as int,
    idecoCurrentBalance: params['idecoCurrentBalance'] as double,
    idecoMonthlyContribution: params['idecoMonthlyContribution'] as int,
    idecoAnnualReturnRate: params['idecoAnnualReturnRate'] as double,
    investmentTrustCurrentAge: params['investmentTrustCurrentAge'] as int,
    investmentTrustCurrentBalance: params['investmentTrustCurrentBalance'] as double,
    investmentTrustMonthlyContribution: params['investmentTrustMonthlyContribution'] as int,
    investmentTrustAnnualReturnRate: params['investmentTrustAnnualReturnRate'] as double,
    investmentTrustWithdrawalStartAge: params['investmentTrustWithdrawalStartAge'] as int,
  );

  // 結果表示
  _displayResults(chartData, params);

  // CSVに保存（月ごと）
  _saveAsCsv(chartData, params);

  // ファイルに保存
  _saveToFile(chartData, params);

  print('\n✅ シミュレーションを終了します。\n');
}

/// ユーザーからパラメータを入力受け取る
Map<String, dynamic> _getInputParameters() {
  print('▼ パラメータを入力してください\n');

  // 公的年金
  print('=== 公的年金 ===');
  final basicPension = _getDoubleInput('基礎年金（月額、円）', 70000);
  final occupationalPension = _getDoubleInput('厚生年金（月額、円）', 0);
  final publicPensionStartAge = _getIntInput('公的年金受給開始年齢', 65);
  final monthlyLivingExpenses = _getDoubleInput('生活費（月額、円）', 200000);

  // iDeCo
  print('\n=== iDeCo ===');
  final idecoCurrentAge = _getIntInput('iDeCo現在年齢', 30);
  final idecoCurrentBalance = _getDoubleInput('iDeCo現在残高（円）', 0);
  final idecoMonthlyContribution = _getIntInput('iDeCo月額拠出（円）', 0);
  final idecoAnnualReturnRate = _getDoubleInput('iDeCo年利回り（%）', 3.0);

  // 投資信託
  print('\n=== 投資信託 ===');
  final itCurrentAge = _getIntInput('投資信託現在年齢', 30);
  final itCurrentBalance = _getDoubleInput('投資信託現在残高（円）', 0);
  final itMonthlyContribution = _getIntInput('投資信託月額拠出（円）', 0);
  final itAnnualReturnRate = _getDoubleInput('投資信託年利回り（%）', 5.0);
  final itWithdrawalStartAge = _getIntInput('投資信託引出開始年齢', InvestmentTrustInput.defaultWithdrawalStartAge);

  return {
    'basicPensionMonthly': basicPension,
    'occupationalPensionMonthly': occupationalPension,
    'publicPensionStartAge': publicPensionStartAge,
    'monthlyLivingExpenses': monthlyLivingExpenses,
    'idecoCurrentAge': idecoCurrentAge,
    'idecoCurrentBalance': idecoCurrentBalance,
    'idecoMonthlyContribution': idecoMonthlyContribution,
    'idecoAnnualReturnRate': idecoAnnualReturnRate,
    'investmentTrustCurrentAge': itCurrentAge,
    'investmentTrustCurrentBalance': itCurrentBalance,
    'investmentTrustMonthlyContribution': itMonthlyContribution,
    'investmentTrustAnnualReturnRate': itAnnualReturnRate,
    'investmentTrustWithdrawalStartAge': itWithdrawalStartAge,
  };
}

/// ファイルからパラメータを読み込み
Map<String, dynamic> _getParametersFromFile() {
  try {
    final fileContent = File('pension_simulation_input.txt').readAsStringSync();
    
    // 行ごとに処理
    final lines = fileContent.split('\n');
    
    // デフォルト値
    var currentAge = 30;
    var basicPensionMonths = 480;
    var basicPensionStartAge = 65;        // ← 基礎年金用に分離
    var occupationalPensionMonths = 360;
    var occupationalPensionStartAge = 65; // ← 厚生年金用に分離
    var monthlyLivingExpenses = 200000.0;
    var idecoCurrentBalance = 0.0;
    var idecoMonthlyContribution = 0;
    var idecoAnnualReturnRate = 3.0;              // デフォルト値
    var itCurrentBalance = 0.0;
    var itMonthlyContribution = 0;
    var itAnnualReturnRate = 5.0;                 // デフォルト値
    var itWithdrawalStartAge = InvestmentTrustInput.defaultWithdrawalStartAge;  // Domain層から取得
    
    // セクション識別用
    String currentSection = '';
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      // セクション判定
      if (trimmed == '【共通】') {
        currentSection = 'common';
      } else if (trimmed == '【基礎年金】') {
        currentSection = 'basicPension';
      } else if (trimmed == '【厚生年金】') {
        currentSection = 'occupationalPension';
      } else if (trimmed == '【iDeCo】') {
        currentSection = 'ideco';
      } else if (trimmed == '【投資信託】') {
        currentSection = 'investmentTrust';
      } else if (trimmed.isEmpty || trimmed.startsWith('===')) {
        // スキップ
      } else {
        // セクション内の値を解析
        if (currentSection == 'common') {
          if (trimmed.contains('現在年齢/歳:')) {
            currentAge = _parseAge(trimmed) ?? 30;
          } else if (trimmed.contains('生活費/円/月:')) {
            monthlyLivingExpenses = _parseAmount(trimmed) ?? 200000.0;
          }
        } else if (currentSection == 'basicPension') {
          if (trimmed.contains('基礎年金納付年数/ヶ月:')) {
            basicPensionMonths = _parseIntAmount(trimmed) ?? 480;
          } else if (trimmed.contains('受給開始年齢/歳:')) {
            basicPensionStartAge = _parseAge(trimmed) ?? 65;
          }
        } else if (currentSection == 'occupationalPension') {
          if (trimmed.contains('厚生年金納付年数/ヶ月:')) {
            occupationalPensionMonths = _parseIntAmount(trimmed) ?? 360;
          } else if (trimmed.contains('受給開始年齢/歳:')) {
            occupationalPensionStartAge = _parseAge(trimmed) ?? 65;
          }
        } else if (currentSection == 'ideco') {
          if (trimmed.contains('現在残高/円:')) {
            idecoCurrentBalance = _parseAmount(trimmed) ?? 0.0;
          } else if (trimmed.contains('月額拠出/円:')) {
            idecoMonthlyContribution = _parseIntAmount(trimmed) ?? 0;
          } else if (trimmed.contains('年利回り/%:')) {
            idecoAnnualReturnRate = _parsePercent(trimmed) ?? 3.0;
          }
        } else if (currentSection == 'investmentTrust') {
          if (trimmed.contains('現在残高/円:')) {
            itCurrentBalance = _parseAmount(trimmed) ?? 0.0;
          } else if (trimmed.contains('月額拠出/円:')) {
            itMonthlyContribution = _parseIntAmount(trimmed) ?? 0;
          } else if (trimmed.contains('年利回り/%:')) {
            itAnnualReturnRate = _parsePercent(trimmed) ?? 5.0;
          } else if (trimmed.contains('引出開始年齢/歳:')) {
            itWithdrawalStartAge = _parseAge(trimmed) ?? 60;
          }
        }
      }
    }

    // 基礎年金と厚生年金の月額を計算
    // 基礎年金：NationalPensionInput.basicPensionMonthlyAmount から取得
    final basicPension = (basicPensionMonths / NationalPensionInput.fullContributionMonths) * NationalPensionInput.basicPensionMonthlyAmount;
    // 厚生年金：OccupationalPensionInput の係数から計算
    // 報酬比例年金 = 標準報酬月額 × (加入月数 / 12) × 報酬比例係数 × 12
    // = 標準報酬月額 × (加入月数) × 報酬比例係数
    // ただし、加入月数は月単位で保持されているため、年数に変換してから月額係数を適用
    const double standardMonthlyWage = 200000.0;  // 標準報酬月額（仮定値）
    final occupationalYears = occupationalPensionMonths / 12.0;
    final occupationalPension = standardMonthlyWage * OccupationalPensionInput.pensionRateMonthly * occupationalYears;

    return {
      'basicPensionMonthly': basicPension,
      'occupationalPensionMonthly': occupationalPension,
      'publicPensionStartAge': basicPensionStartAge,  // ← 基礎年金の開始年齢を使用
      'monthlyLivingExpenses': monthlyLivingExpenses,
      'idecoCurrentAge': currentAge,
      'idecoCurrentBalance': idecoCurrentBalance,
      'idecoMonthlyContribution': idecoMonthlyContribution,
      'idecoAnnualReturnRate': idecoAnnualReturnRate,
      'investmentTrustCurrentAge': currentAge,
      'investmentTrustCurrentBalance': itCurrentBalance,
      'investmentTrustMonthlyContribution': itMonthlyContribution,
      'investmentTrustAnnualReturnRate': itAnnualReturnRate,
      'investmentTrustWithdrawalStartAge': itWithdrawalStartAge,
    };
  } catch (e) {
    print('⚠️  ファイル読み込みエラー: $e');
    return _getParametersFromEnvironmentOrDefaults();
  }
}

/// 金額をパース (¥123000 または 123000 を抽出)
double? _parseAmount(String line) {
  // コロン以降を取得
  final parts = line.split(':');
  if (parts.length < 2) return null;
  
  final value = parts[1].trim();
  
  // ¥記号がある場合
  final regex = RegExp(r'¥([0-9,]+)');
  var match = regex.firstMatch(value);
  if (match != null) {
    return double.tryParse(match.group(1)?.replaceAll(',', '') ?? '0');
  }
  
  // ¥記号がない場合（単純な数値）
  final numRegex = RegExp(r'([0-9,]+)');
  match = numRegex.firstMatch(value);
  if (match != null) {
    return double.tryParse(match.group(1)?.replaceAll(',', '') ?? '0');
  }
  
  return null;
}

/// 整数金額をパース
int? _parseIntAmount(String line) {
  final amount = _parseAmount(line);
  return amount?.toInt();
}

/// 年齢をパース (70 または 70歳 から 70 を抽出)
int? _parseAge(String line) {
  // コロン以降を取得
  final parts = line.split(':');
  if (parts.length < 2) return null;
  
  final value = parts[1].trim();
  
  // 「xx歳」形式の場合
  var regex = RegExp(r'([0-9]+)歳');
  var match = regex.firstMatch(value);
  if (match != null) {
    return int.tryParse(match.group(1) ?? '0');
  }
  
  // 「xx」形式の場合（単純な数値）
  regex = RegExp(r'([0-9]+)');
  match = regex.firstMatch(value);
  if (match != null) {
    return int.tryParse(match.group(1) ?? '0');
  }
  
  return null;
}

/// パーセンテージをパース (3.0% から 3.0 を抽出)
double? _parsePercent(String line) {
  final regex = RegExp(r'([0-9.]+)%');
  final match = regex.firstMatch(line);
  if (match != null) {
    return double.tryParse(match.group(1) ?? '0');
  }
  return null;
}

/// 環境変数またはデフォルト値からパラメータを取得（非対話的）
Map<String, dynamic> _getParametersFromEnvironmentOrDefaults() {
  final env = Platform.environment;
  
  final basicPension = double.tryParse(env['BASIC_PENSION'] ?? '70000') ?? 70000;
  final occupationalPension = double.tryParse(env['OCCUPATIONAL_PENSION'] ?? '0') ?? 0;
  final publicPensionStartAge = int.tryParse(env['PUBLIC_PENSION_START_AGE'] ?? '65') ?? 65;
  final monthlyLivingExpenses = double.tryParse(env['MONTHLY_LIVING_EXPENSES'] ?? '200000') ?? 200000;

  final idecoCurrentAge = int.tryParse(env['IDECO_CURRENT_AGE'] ?? '30') ?? 30;
  final idecoCurrentBalance = double.tryParse(env['IDECO_CURRENT_BALANCE'] ?? '0') ?? 0;
  final idecoMonthlyContribution = int.tryParse(env['IDECO_MONTHLY_CONTRIBUTION'] ?? '0') ?? 0;
  final idecoAnnualReturnRate = double.tryParse(env['IDECO_ANNUAL_RETURN_RATE'] ?? '3.0') ?? 3.0;

  final itCurrentAge = int.tryParse(env['IT_CURRENT_AGE'] ?? '30') ?? 30;
  final itCurrentBalance = double.tryParse(env['IT_CURRENT_BALANCE'] ?? '0') ?? 0;
  final itMonthlyContribution = int.tryParse(env['IT_MONTHLY_CONTRIBUTION'] ?? '0') ?? 0;
  final itAnnualReturnRate = double.tryParse(env['IT_ANNUAL_RETURN_RATE'] ?? '5.0') ?? 5.0;
  final itWithdrawalStartAge = int.tryParse(env['IT_WITHDRAWAL_START_AGE'] ?? '60') ?? 60;

  return {
    'basicPensionMonthly': basicPension,
    'occupationalPensionMonthly': occupationalPension,
    'publicPensionStartAge': publicPensionStartAge,
    'monthlyLivingExpenses': monthlyLivingExpenses,
    'idecoCurrentAge': idecoCurrentAge,
    'idecoCurrentBalance': idecoCurrentBalance,
    'idecoMonthlyContribution': idecoMonthlyContribution,
    'idecoAnnualReturnRate': idecoAnnualReturnRate,
    'investmentTrustCurrentAge': itCurrentAge,
    'investmentTrustCurrentBalance': itCurrentBalance,
    'investmentTrustMonthlyContribution': itMonthlyContribution,
    'investmentTrustAnnualReturnRate': itAnnualReturnRate,
    'investmentTrustWithdrawalStartAge': itWithdrawalStartAge,
  };
}

/// 整数入力を取得
int _getIntInput(String prompt, int defaultValue) {
  print('$prompt [$defaultValue]: ');
  final input = stdin.readLineSync() ?? '';
  if (input.isEmpty) return defaultValue;
  return int.tryParse(input) ?? defaultValue;
}

/// 浮動小数点数入力を取得
double _getDoubleInput(String prompt, double defaultValue) {
  print('$prompt [$defaultValue]: ');
  final input = stdin.readLineSync() ?? '';
  if (input.isEmpty) return defaultValue;
  return double.tryParse(input) ?? defaultValue;
}

/// 結果をテーブル形式で表示
void _displayResults(
  List<dynamic> chartData,
  Map<String, dynamic> params,
) {
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📊 シミュレーション結果');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  print('\n【入力パラメータ】');
  print(
    '基礎年金: ¥${(params['basicPensionMonthly'] as double).toInt()}/月 | '
    '厚生年金: ¥${(params['occupationalPensionMonthly'] as double).toInt()}/月 | '
    '受給開始: ${params['publicPensionStartAge']}歳',
  );
  print(
    'iDeCo残高: ¥${(params['idecoCurrentBalance'] as double).toInt()} '
    '(年利${params['idecoAnnualReturnRate']}%) | '
    '拠出: ¥${params['idecoMonthlyContribution']}/月',
  );
  print(
    '投資信託残高: ¥${(params['investmentTrustCurrentBalance'] as double).toInt()} '
    '(年利${params['investmentTrustAnnualReturnRate']}%) | '
    '拠出: ¥${params['investmentTrustMonthlyContribution']}/月',
  );
  print('生活費: ¥${(params['monthlyLivingExpenses'] as double).toInt()}/月');

  print('\n【基礎年金と厚生年金の計算結果】\n');
  print(
    '年齢 │ 基礎年金      │ 厚生年金      │   合計      │ 生活費      │  不足額',
  );
  print(
    '────┼──────────────┼──────────────┼─────────────┼─────────────┼──────────────',
  );

  final monthlyLivingExpenses = params['monthlyLivingExpenses'] as double;
  final sampleAges = [60, 65, 70, 75, 80, 85, 90, 95, 100];

  for (final targetAge in sampleAges) {
    final data = chartData.cast<dynamic>().firstWhere(
      (d) => d.age == targetAge,
      orElse: () => null as dynamic,
    );

    if (data != null) {
      final basicPension = data.basicPensionMonthly;
      final occPension = data.occupationalPensionMonthly;
      final totalPension = basicPension + occPension;
      final shortfall = monthlyLivingExpenses - totalPension;

      print(
        '${data.age.toString().padLeft(3)} │ '
        '¥${basicPension.toInt().toString().padLeft(10)}/月 │ '
        '¥${occPension.toInt().toString().padLeft(10)}/月 │ '
        '¥${totalPension.toInt().toString().padLeft(9)}/月 │ '
        '¥${monthlyLivingExpenses.toInt().toString().padLeft(9)}/月 │ '
        '¥${shortfall.toInt().toString().padLeft(10)}',
      );
    }
  }

  print(
    '────┼──────────────┼──────────────┼─────────────┼─────────────┼──────────────',
  );

  print('\n【年齢別詳細データ（iDeCo・投資信託を含む）】\n');
  print(
    '年齢 │ 基礎年金      │ 厚生年金      │ iDeCo        │ 投資信託      │ '
    'iDeCo残高         │ IT残高',
  );
  print(
    '────┼──────────────┼──────────────┼──────────────┼──────────────┼'
    '──────────────────┼──────────────',
  );

  // 60, 65, 70, 75, 80, 85, 90, 95, 100歳の結果を表示
  for (final targetAge in sampleAges) {
    final data = chartData.cast<dynamic>().firstWhere(
      (d) => d.age == targetAge,
      orElse: () => null as dynamic,
    );

    if (data != null) {
      final basicPension = data.basicPensionMonthly;
      final occPension = data.occupationalPensionMonthly;
      final idecoPension = data.idecoMonthly;
      final itPension = data.investmentTrustMonthly;
      final idecoBalance = data.idecoBalance;
      final itBalance = data.investmentTrustBalance;

      print(
        '${data.age.toString().padLeft(3)} │ '
        '¥${basicPension.toInt().toString().padLeft(10)}/月 │ '
        '¥${occPension.toInt().toString().padLeft(10)}/月 │ '
        '¥${idecoPension.toInt().toString().padLeft(10)}/月 │ '
        '¥${itPension.toInt().toString().padLeft(10)}/月 │ '
        '¥${idecoBalance.toInt().toString().padLeft(14)} │ '
        '¥${itBalance.toInt().toString().padLeft(10)}',
      );
    }
  }

  print(
    '────┼──────────────┼──────────────┼──────────────┼──────────────┼'
    '──────────────────┼──────────────',
  );

  // サマリー統計
  print('\n【統計情報】');
  final age60Data = chartData.cast<dynamic>().firstWhere((d) => d.age == 60);
  final age100Data = chartData.cast<dynamic>().lastWhere((d) => d.age <= 100);

  print('60歳時点: iDeCo ¥${age60Data.idecoBalance.toInt()}, 投資信託 ¥${age60Data.investmentTrustBalance.toInt()}');
  print('100歳時点: iDeCo ¥${age100Data.idecoBalance.toInt()}, 投資信託 ¥${age100Data.investmentTrustBalance.toInt()}');

  // iDeCo枯渇年齢を推定
  final idecoExhaustedAge = chartData.cast<dynamic>().firstWhere(
    (d) => d.idecoBalance <= 0 && d.age > 60,
    orElse: () => null as dynamic,
  );
  if (idecoExhaustedAge != null) {
    print('iDeCo枯渇年齢: ${idecoExhaustedAge.age}歳');
  } else {
    print('iDeCo枯渇年齢: 100歳以降（終生残高あり）');
  }

  // 投資信託枯渇年齢を推定
  final itExhaustedAge = chartData.cast<dynamic>().firstWhere(
    (d) => d.investmentTrustBalance <= 0 && d.age > 60,
    orElse: () => null as dynamic,
  );
  if (itExhaustedAge != null) {
    print('投資信託枯渇年齢: ${itExhaustedAge.age}歳');
  } else {
    print('投資信託枯渇年齢: 100歳以降（終生残高あり）');
  }
}

/// 月ごとのCSVデータを保存（基礎年金のみ）
void _saveAsCsv(
  List<dynamic> chartData,
  Map<String, dynamic> params,
) {
  try {
    final currentAge = params['idecoCurrentAge'] as int;
    final maxAge = 100;
    final totalYears = maxAge - currentAge + 1; // +1 で最後の年も含める
    final totalMonths = totalYears * 12;
    
    final csvBuffer = StringBuffer();
    
    // CSVヘッダー
    csvBuffer.writeln('月数,日付,年齢,基礎年金');
    
    // 開始年月日（2026年4月1日から開始）
    int startYear = 2026;
    int startMonth = 4;
    int startDay = 1;
    
    // currentAge～100歳までのデータを月別で生成
    for (int month = 0; month < totalMonths; month++) {
      // 月数から年と月を計算
      final totalMonthCount = (startYear * 12 + startMonth - 1) + month;
      final adjustedYear = totalMonthCount ~/ 12;
      final adjustedMonth = (totalMonthCount % 12) + 1;
      
      // 年齢計算
      final ageYears = month ~/ 12;
      final currentYearAge = currentAge + ageYears;
      
      // 基礎年金受給開始年齢に達しているか判定
      final pensionStartAge = params['publicPensionStartAge'] as int;
      final basicPensionMonthly = params['basicPensionMonthly'] as double;
      
      final pensionAmount = currentYearAge >= pensionStartAge 
          ? basicPensionMonthly.toInt()
          : 0;
      
      // 日付をISO形式で出力
      final dateStr = '$adjustedYear-${adjustedMonth.toString().padLeft(2, '0')}-${startDay.toString().padLeft(2, '0')}';
      
      csvBuffer.writeln('${month + 1},$dateStr,$currentYearAge,$pensionAmount');
    }
    
    // ペンション基礎年金月ごと.csv として保存
    File('pension_basic_monthly.csv').writeAsStringSync(csvBuffer.toString());
    print('💾 月ごとのCSVを保存: pension_basic_monthly.csv');
  } catch (e) {
    print('⚠️  CSV保存エラー: $e');
  }
}

/// 結果とパラメータをテキストファイルに保存
void _saveToFile(
  List<dynamic> chartData,
  Map<String, dynamic> params,
) {
  try {
    // ※ pension_simulation_input.txt は上書きしない
    // ファイルは Flutterアプリで生成された値を保持したままにする

    // 結果をファイルに保存
    final resultBuffer = StringBuffer();
    resultBuffer.writeln('=== ペンション計算シミュレーター - 計算結果 ===');
    resultBuffer.writeln('実行日時: ${DateTime.now().toIso8601String()}');
    resultBuffer.writeln('');
    resultBuffer.writeln('【年齢別データ（40年間）】');
    resultBuffer.writeln('');
    resultBuffer.writeln(
      '年齢 │ 基礎年金      │ 厚生年金      │ iDeCo        │ 投資信託      │ '
      'iDeCo残高         │ IT残高',
    );
    resultBuffer.writeln(
      '────┼──────────────┼──────────────┼──────────────┼──────────────┼'
      '──────────────────┼──────────────',
    );

    for (final data in chartData.cast<dynamic>()) {
      final basicPension = data.basicPensionMonthly;
      final occPension = data.occupationalPensionMonthly;
      final idecoPension = data.idecoMonthly;
      final itPension = data.investmentTrustMonthly;
      final idecoBalance = data.idecoBalance;
      final itBalance = data.investmentTrustBalance;

      resultBuffer.writeln(
        '${data.age.toString().padLeft(3)} │ '
        '¥${basicPension.toInt().toString().padLeft(10)}/月 │ '
        '¥${occPension.toInt().toString().padLeft(10)}/月 │ '
        '¥${idecoPension.toInt().toString().padLeft(10)}/月 │ '
        '¥${itPension.toInt().toString().padLeft(10)}/月 │ '
        '¥${idecoBalance.toInt().toString().padLeft(14)} │ '
        '¥${itBalance.toInt().toString().padLeft(10)}',
      );
    }

    resultBuffer.writeln(
      '────┼──────────────┼──────────────┼──────────────┼──────────────┼'
      '──────────────────┼──────────────',
    );

    // サマリー統計
    resultBuffer.writeln('');
    resultBuffer.writeln('【統計情報】');
    final age60Data = chartData.cast<dynamic>().firstWhere((d) => d.age == 60);
    final age100Data = chartData.cast<dynamic>().lastWhere((d) => d.age <= 100);

    resultBuffer.writeln('60歳時点: iDeCo ¥${age60Data.idecoBalance.toInt()}, 投資信託 ¥${age60Data.investmentTrustBalance.toInt()}');
    resultBuffer.writeln('100歳時点: iDeCo ¥${age100Data.idecoBalance.toInt()}, 投資信託 ¥${age100Data.investmentTrustBalance.toInt()}');

    final idecoExhaustedAge = chartData.cast<dynamic>().firstWhere(
      (d) => d.idecoBalance <= 0 && d.age > 60,
      orElse: () => null as dynamic,
    );
    if (idecoExhaustedAge != null) {
      resultBuffer.writeln('iDeCo枯渇年齢: ${idecoExhaustedAge.age}歳');
    } else {
      resultBuffer.writeln('iDeCo枯渇年齢: 100歳以降（終生残高あり）');
    }

    final itExhaustedAge = chartData.cast<dynamic>().firstWhere(
      (d) => d.investmentTrustBalance <= 0 && d.age > 60,
      orElse: () => null as dynamic,
    );
    if (itExhaustedAge != null) {
      resultBuffer.writeln('投資信託枯渇年齢: ${itExhaustedAge.age}歳');
    } else {
      resultBuffer.writeln('投資信託枯渇年齢: 100歳以降（終生残高あり）');
    }

    File('pension_simulation_result.txt').writeAsStringSync(resultBuffer.toString());

    print('💾 計算結果を保存: pension_simulation_result.txt');
  } catch (e) {
    print('⚠️  ファイル保存エラー: $e');
  }
}
