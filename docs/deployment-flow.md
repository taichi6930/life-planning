# デプロイメントフロー

_本ドキュメントは作成予定です。以下の内容が記載されます：_

## デプロイメント戦略

- **フレームワーク**: Flutter (Web + iOS + Android 統一)
- **main ブランチへのマージ**: Staging 環境へのデプロイ
- **Git Tag 作成**: Production 環境へのデプロイ
- **Version 管理**: Semantic Versioning (v1.0.0, v1.1.0, v1.0.1 等)
- **Rollback 手順**: Production デプロイ時のロールバック対応

## 環境

### Staging 環境
- 本番前の最終検証用
- main ブランチへのマージで自動デプロイ
- 品質確認・ユーザーテスト実施

### Production 環境
- 本番環境（顧客向け）
- Git Tag 作成で自動デプロイ
- 厳密なバージョン管理

## デプロイメント プラットフォーム

### Web (Flutter Web)
- ホスティング: Cloudflare
- デプロイ トリガー: (未定)
- **ローカルテスト環境ポート**: 30000（固定）
  - ローカルテスト起動コマンド: `./run-local-test.sh` または `flutter run -d chrome --web-port 30000`

### iOS (Flutter iOS)
- ホスティング: AppStore
- デプロイ トリガー: (未定)

### Android (Flutter Android)
- ホスティング: Google Play
- デプロイ トリガー: (未定)

## デプロイメント パイプライン

```mermaid
%%{init: { 'theme': 'auto', 'themeVariables': { 'primaryColor': '#e8f5e9', 'primaryBorderColor': '#4caf50', 'primaryTextColor': '#2e7d32', 'darkMode': 'true' }}}%%
flowchart TD
    A["feature/* or copilot/* ブランチで実装"] --> B["PR & Code Review"]
    B --> C["main へマージ"]
    C --> D["Staging 環境へ自動デプロイ"]
    D --> E["QA テスト & ユーザーテスト"]
    E -->|OK| F["Git Tag (v1.0.0)"]
    E -->|NG| G["Issue 修正"]
    G --> H["PR & Review"]
    H --> C
    F --> I["Production へ自動デプロイ"]
    I --> J["監視・ログ確認"]
    J -->|異常検出| K["Rollback 実行"]
    K --> L["原因分析 & 修正"]
    J -->|正常| M["本番リリース完了"]
```

### CI/CD Tool
- **Web**: Cloudflare Pages (自動デプロイ)
- **iOS**: GitHub Actions + AppStore Connect
- **Android**: GitHub Actions + Google Play Console

### デプロイ トリガー
- **Staging**: main ブランチへのマージで自動トリガー
- **Production**: Git Tag 作成で自動トリガー

### ロールバック 手順
- 本番デプロイ後は即座に監視を開始
- 異常検出時は自動/手動ロールバック実行
- 前バージョンへの復帰手順（Cloudflare / AppStore 側の機能活用）

### 監視・アラート
- Application Insights: エラーログ、パフォーマンス監視
- Slack 通知: デプロイ完了・エラー検出時の通知
- ログ分析: 本番環境の動作確認

---

**Status**: Web デプロイ実装済み (iOS/Android TBD)
