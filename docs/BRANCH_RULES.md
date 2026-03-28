# ブランチ規約

## ブランチ命名規則

- **Copilot ブランチ**: `copilot/xxx` 形式
  - AI エージェントによる作業用
  - 例: `copilot/inception-planning`, `copilot/unit1-implementation`

- **機能ブランチ**: `feature/xxx` 形式
  - 手動開発用

- **修正ブランチ**: `fix/xxx` 形式
  - バグ修正用

- **ドキュメント**: `docs/xxx` 形式
  - ドキュメント更新用

## マージルール

- **main ブランチへの直接プッシュ**: ❌ **禁止**
- **すべての変更は PR 経由**: ✅ **必須**
- **コミットメッセージ**: 日本語で記述（例：`feat: Unit 1 の要件分析を完了`）

---

詳細な開発ワークフローは `.github/copilot-instructions.md` の AI-DLC ワークフローを参照してください。
