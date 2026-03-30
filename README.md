# Life Planning App - MVP

老後資産計画アプリケーション（Flutter Web版 MVP）

## プロジェクト構造

Clean Architecture に基づいた階層構造：

```
lib/
├── domain/                    # ドメイン層（ビジネスロジック）
│   ├── entities/              # ビジネスオブジェクト
│   │   ├── financial_plan.dart
│   │   ├── coast_fi_scenario.dart
│   │   ├── national_pension_profile.dart
│   │   └── basic_pension_calculation.dart
│   ├── repositories/          # リポジトリインターフェース
│   │   ├── financial_plan_repository.dart
│   │   ├── coast_fi_repository.dart
│   │   └── national_pension_repository.dart
│   ├── usecases/              # ユースケース（ビジネスロジック実装）
│   │   ├── calculate_coast_fi_usecase.dart
│   │   ├── financial_plan_usecase.dart
│   │   └── national_pension_usecase.dart
│   ├── failures/              # エラーハンドリング
│   │   └── failure.dart
│   └── values/                # Value Objects
│       ├── coast_fi_input.dart
│       └── national_pension_input.dart
│
├── application/               # アプリケーション層
│   ├── dtos/                  # DTOs（UI向け）
│   │   ├── coast_fi_result_dto.dart
│   │   ├── financial_plan_dto.dart
│   │   └── basic_pension_result_dto.dart
│   └── presenters/            # プレゼンター
│       ├── coast_fi_presenter.dart
│       ├── financial_plan_presenter.dart
│       └── basic_pension_presenter.dart
│
├── data/                      # データ層（実装予定）
│   ├── datasources/
│   ├── repositories/
│   └── models/
│
└── presentation/              # プレゼンテーション層（実装予定）
    ├── pages/
    ├── widgets/
    └── state_management/
```

## 階層の説明

### Domain層
- **ビジネスロジックの中枢**
- フレームワークに依存しない純粋なDart コード
- 計算ロジック（Coast FI計算）を実装

**エンティティ**:
- `FinancialPlan` - ユーザーの財務情報
- `CoastFiScenario` - Coast FI計算結果

**ユースケース**:
- `CalculateCoastFiUsecase` - Coast FI計算を実行
- `CreateFinancialPlanUsecase` - 財務計画を作成
- `GetFinancialPlanUsecase` - 財務計画を取得

### Application層
- **Domain層と Presentation層の仲介役**
- DTO（Data Transfer Object）でUI向けデータフォーマット
- Presenter で usecase を呼び出し

### Data層（実装予定）
- **データ永続化の実装**
- `Repository` インターフェースの実装
- LocalStorage/SQLite への保存

### Presentation層（実装予定）
- **UI コンポーネント**
- State管理（Provider）
- ユーザーインタラクション

---

## 機能（MVP Phase 1 & 1.5）

### Coast FI 計算
**数式**:
```
yearsToGoal = LOG(targetAsset / currentSavings) / LOG(1 + annualReturnRate)
ageAtGoal = currentAge + yearsToGoal
```

**入力**:
- 現在の年齢
- 現在の貯蓄額
- 年間貯蓄額
- 目標資産額
- 年利回り（%）

**出力**:
- 目標達成までの年数
- 目標達成時の年齢
- 退職年齢(65歳)までに達成可能かの判定

### 基礎年金計算（拡張）
**数式**:
```
基礎年金額（年額） = 基本額 × (納付月数 / 480)
基礎年金額（月額） = 年額 / 12
```

**入力**:
- 現在の年齢
- 年金納付月数（0～480月）
- 免除期間の有無

**出力**:
- 基礎年金額（年額・月額）
- 受給開始までの年数
- 納付率

### データ永続化（localStorage）
ユーザーが入力したフォームデータを自動的にブラウザのローカルストレージに保存します。

**保存される情報**:
- 現在の年齢
- 年金納付月数
- 厚生年金納付月数
- 月額给与
- ボーナス額（年額）
- 希望する年金受給開始年齢

**機能**:
- フォーム送信時に自動保存
- アプリ再起動時に前回の入力値を自動復元
- ローカルストレージのクリア機能（アプリ内）

**実装詳細**:
- `shared_preferences` パッケージを使用
- `PensionStorage` ユーティリティクラスで統一管理
- `PensionFormTemplate` で初期化時に自動読み込み

---

## テスト実行

```bash
# ユニットテスト実行
flutter test

# カバレッジ確認
flutter test --coverage
```

## ローカル環境テスト

```bash
# ローカルテスト環境でアプリを起動（ポート30000で固定）
flutter run -d chrome --web-port 30000

# または、スクリプトを使用
./run-test.sh  # または ./run-production.sh

# ブラウザで http://localhost:30000 にアクセス
```

---

## 今後のフェーズ

| フェーズ | 内容 | ブランチ |
|---|---|---|
| **Phase 1** | Domain + Usecase 層 | `feature/domain-usecase-layer` |
| **Phase 2** | Repository 実装 + Data層 | `feature/data-layer` |
| **Phase 3** | Presentation層（UI/State） | `feature/presentation-layer` |
| **Phase 4** | ユニット・ウィジェットテスト | `feature/testing` |

---

## 依存関係

```yaml
dependencies:
  # State Management
  provider: ^6.0.0
  
  # Entity & Value Objects
  equatable: ^2.0.5
  
  # Dependency Injection
  get_it: ^7.6.0
  
  # Logging
  logger: ^2.0.0
```

---

## セキュリティ・デプロイメント

**現状**: MVP段階 - セキュリティは最小限
**今後対応**: フェーズ2以降で暗号化・セキュリティヘッダー追加予定

---

## 開発チェックリスト

- [x] プロジェクト初期化
- [x] Domain層スケルトン（Coast FI + 基礎年金）
- [x] Usecase層実装（Coast FI + 基礎年金）
- [x] Application層（DTO/Presenter）
- [x] Presentation層実装（Atomic Design + Riverpod）
  - [x] 国民年金計算UI
  - [x] 厚生年金計算UI
  - [x] 年金受給開始年齢スライダー
  - [x] 生涯年金額グラフ表示
  - [x] **データ永続化（localStorage）**
- [x] テスト実装（224 tests passing）
- [ ] Cloudflare デプロイ
