# 定義

## ハーネスの2軸分類

ハーネスファイルは **導線の種類** と **知識の対象** という直交する2軸で分類される。

### 軸1: 導線の種類（特殊 vs 自然）

**特殊ハーネス** — ツールが組み込みで特別な解釈をし、自動的な導線を持つ。被リンクチェックの対象外。

| ファイル種別 | 導線の仕組み |
|---|---|
| `CLAUDE.md` | セッション開始時に自動読み込み（サブディレクトリも同様） |
| `.claude/rules/**` | `paths:` frontmatter にマッチするファイル編集時に自動参照 |
| `.claude/skills/**` | `description` frontmatter がスキル一覧として自動サーフェス |
| `.claude/hooks/**` | `settings.json` のイベント設定で自動実行 |
| `.claude/settings.json` / `.mcp.json` | 直接参照 |

**自然ハーネス** — 特殊ハーネス以外。任意のフォーマット。特殊ハーネスから明示的に参照されることで初めて到達可能。`check-harness-nav.sh` が Stop 時に導線切れを検出する。

### 軸2: 知識の対象（メタ vs ドメイン）

**メタハーネス** — ハーネス自体の設計・更新・配置に関する知識。

**ドメインハーネス** — 特定タスク群を速く正確に進めるための知識（用語・制約・主要成果物・検証方法など）。

---

## 2×2 マトリクス

|  | メタハーネス | ドメインハーネス |
|---|---|---|
| **特殊ハーネス** | `CLAUDE.md`、`harness-editing.md`（rules）、`improve-harness`（skill） | `verify-done`（skill）、`verification-design.md`（rules） |
| **自然ハーネス** | `harness/meta/definition.md`、`file-routing.md`、`update-policy.md` など | `harness/domains/**/overview.md`、`verification.md`、`sources.md` など |

---

## 記述原則

- 日本語で書く。
- SSoT を守る。
- 一般論は書かない。
- 現行運用に必要な最新情報のみを残す。
- 決定論的検証を優先する。
