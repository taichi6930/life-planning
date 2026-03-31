---
name: life-planning-dev
description: 'Life Planning アプリ（Flutter）の開発スキル。Use for: 年金計算・iDeCo・Coast FI ドメイン知識の参照、新機能実装、Clean Architecture レイヤー追加、テスト作成、カバレッジ確認、AI-DLC フロー継続、Flutter Widget 実装パターン。年金計算、iDeCoの実装、国民年金、厚生年金、老後資産計算、フィーチャー追加などを行う際に必ず参照すること。'
argument-hint: '実装したい機能や確認したい内容（例: Coast FI値オブジェクト追加, iDeCo計算デバッグ）'
---

# Life Planning Dev — 開発スキル

## このスキルを使うタイミング

- 年金・iDeCo・Coast FI に関するドメインロジックを実装・変更するとき
- 新しい値オブジェクト / ドメインサービス / ユースケースを追加するとき
- Atomic Design ベースの UI コンポーネントを追加するとき
- テストを書く / カバレッジを確認するとき
- AI-DLC のセッションを継続するとき

---

## プロジェクト基本情報

| 項目 | 内容 |
|------|------|
| フレームワーク | Flutter (Web + iOS + Android) |
| Dart SDK | >=3.8.0 <4.0.0 |
| アーキテクチャ | Clean Architecture |
| 状態管理 | flutter_riverpod |
| DI | get_it |
| テスト要件 | **99%以上カバレッジ（CI で強制）** |
| ブランチ戦略 | GitHub Flow (`feature/*` / `copilot/*`) |
| コミット形式 | Conventional Commits |

---

## レイヤー構成

```
lib/
├── domain/          ← ビジネスロジックの中心（フレームワーク依存なし）
│   ├── values/      ← 値オブジェクト（不変、バリデーション付き）
│   ├── services/    ← ドメインサービス（計算ロジック）
│   └── usecases/   ← ドメインユースケース
├── application/     ← アプリケーション層
│   ├── dtos/        ← 画面へのデータ転送オブジェクト
│   └── usecases/   ← アプリケーションユースケース
├── data/            ← インフラ層（ローカルストレージ等）
└── presentation/    ← UI 層（Atomic Design）
    ├── atoms/       ← 最小 UI 部品
    ├── molecules/   ← atoms の組み合わせ
    ├── organisms/   ← 複数 molecules の組み合わせ
    ├── templates/   ← レイアウト骨格
    ├── pages/       ← 画面（Riverpod Provider を使用）
    └── providers/   ← Riverpod プロバイダー
```

---

## ドメイン知識

### 国民年金（基礎年金）

- 対象: 日本在住 20〜60 歳全国民
- 満額基準: 480 月（40 年）納付
- 2026年度 基本月額: **¥70,608**（毎年スライド改定）
- 計算式:
  ```
  基礎年金月額 = 基本月額 × (有効納付月数 / 480) × 調整率
  ```
- 受給開始調整率: 60歳繰上げ（△0.4%/月）〜 75歳繰下げ（+0.7%/月）
- 実装クラス: `NationalPensionInput`, `PensionCalculationService.calculateNationalPension()`

### 厚生年金

- 対象: 企業に雇用される第2号被保険者
- 報酬比例部分（2003年4月以降）:
  ```
  報酬比例額 = 平均標準報酬月額 × 5.481/1000 × 加入月数
  ```
- 賞与分も別途加算
- 実装クラス: `OccupationalPensionInput`, `PensionCalculationService.calculateOccupationalPension()`

### iDeCo（個人型確定拠出年金）

- 積立将来価値（複利）:
  ```
  FV = PMT × ((1 + r_m)^n - 1) / r_m
  r_m = 年利回り / 12, n = 拠出月数
  ```
- 掛金上限（2026年12月改正後）: 自営業 ¥75,000 / 会社員 ¥62,000
- 拠出上限年齢: 70歳（2026年12月改正予定）
- 実装クラス: `IdecoInput`

### Coast FI（未実装・次フィーチャー）

- 概念: 今すぐ投資をやめても、複利成長だけで老後に必要な資産に到達できる「海岸線」
- 計算式:
  ```
  Coast FI 目標額 = 老後必要額 / (1 + 利回り)^(老後まで残り年数)
  ```
- 現在の実装状況: 未着手。`aidlc-docs/` に要件定義予定

---

## 値オブジェクトの実装パターン

```dart
class MyValueObject {
  // フィールドはすべて final（不変）
  final int value;

  // コンストラクタでバリデーション
  MyValueObject({required this.value}) {
    if (value < 0) throw ArgumentError('value must be >= 0');
  }

  // 等値性（equatable パッケージ使用またはオーバーライド）
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyValueObject && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
```

---

## テストの書き方

```dart
// 日本語でグループ・テスト名を記述すること（プロジェクトルール）
group('MyValueObject', () {
  group('コンストラクタ バリデーション', () {
    test('負の値は ArgumentError をスローする', () {
      expect(() => MyValueObject(value: -1), throwsArgumentError);
    });
    test('0 は正常に作成できる', () {
      expect(MyValueObject(value: 0).value, equals(0));
    });
  });
});
```

テスト実行コマンド:
```bash
flutter test                          # 全テスト実行
flutter test --coverage               # カバレッジ付き実行
flutter test test/domain/values/      # 特定フォルダのみ
```

カバレッジ確認（CI と同じロジック）:
```bash
LH=$(grep '^LH:' coverage/lcov.info | tail -1 | cut -d: -f2)
LF=$(grep '^LF:' coverage/lcov.info | tail -1 | cut -d: -f2)
echo "Coverage: $(awk "BEGIN{printf \"%.1f\", ($LH/$LF)*100}")%"
```

---

## 新機能追加の手順

1. `feature/<scope>` または `copilot/<scope>` ブランチを作成
2. Domain 層から実装（値オブジェクト → サービス → ユースケース）
3. 各クラスに対応するテストを `test/` 配下の同構成パスに作成
4. Application 層の DTO / ユースケースを追加
5. Presentation 層（Atomic Design 順）で UI を組む
6. `flutter test --coverage` でカバレッジを確認（99%以上必須）
7. PR を作成して main にマージ

---

## AI-DLC セッション継続

セッションを再開する場合は `aidlc-docs/aidlc-state.md` を確認し、  
`aidlc-docs/audit.md` で前回の作業内容を把握すること。

ルール詳細: `.aidlc-rule-details/common/session-continuity.md`

---

## 参照ドキュメント

- ブランチ戦略: [docs/branch-strategy.md](../../docs/branch-strategy.md)
- デプロイフロー: [docs/deployment-flow.md](../../docs/deployment-flow.md)
- AI-DLC 状態: [aidlc-docs/aidlc-state.md](../../aidlc-docs/aidlc-state.md)
