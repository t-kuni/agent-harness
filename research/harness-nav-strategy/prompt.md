# リサーチ依頼: AIエージェントハーネスのナビゲーション設計改善戦略

## このリポジトリについて

このリポジトリは「AIエージェントハーネス」と呼ぶ自己改善型の知識基盤です。
Claude Code（Anthropic製のAIエージェントCLIツール）がタスクを処理する際に参照する固有知識と運用ルールを管理します。

### ファイル構造

```
CLAUDE.md                    # 毎回必要な短い原則・参照先の導線（セッション開始時に自動参照）
.claude/
  rules/                     # 特定パス限定の規則（対象ファイル編集時に自動参照）
  skills/                    # 再利用可能な手順（明示的に呼び出して使う）
  hooks/                     # セッションイベントで自動実行されるスクリプト
  settings.json              # 権限・フック設定
harness/
  meta/                      # ハーネス設計・更新・配置のメタ知識（必要時だけ手動参照）
  domains/                   # ドメイン固有知識（タスク種別ごと、必要時だけ手動参照）
```

### Claude Code のファイル自動参照の仕組み

Claude Code が自動的にファイルを読み込むタイミングは以下に限られます:

1. **CLAUDE.md**: セッション開始時に常に読み込まれる
2. **`.claude/rules/*.md`**: frontmatter の `paths:` にマッチするファイルを編集するときのみ自動参照される
3. **`.claude/hooks/`**: `settings.json` に定義したイベント（SessionStart、PreToolUse、PostToolUse、Stop など）のタイミングで自動実行される
4. **`.claude/skills/`**: ユーザーが明示的に `/skill-name` と入力した時のみ参照される
5. **`harness/meta/`・`harness/domains/`**: 自動参照の仕組みがなく、CLAUDE.md や skills から「必要時に読む」と指示されて初めて参照される

### 現在の harness/meta/ の各ファイル

| ファイル | 内容 | 用途 |
|---|---|---|
| `definition.md` | ハーネス・メタハーネス・ドメインハーネスの定義 | ハーネス編集時の共通語彙 |
| `file-routing.md` | どの知識をどのファイルへ置くかの判断基準 | ハーネス更新時の配置先決定 |
| `owner-contract.md` | オーナー（人間）からの要求を構造化するテンプレート | タスク開始時の要求整理 |
| `update-policy.md` | ハーネスを更新する条件と方法 | ハーネス改善時の判断基準 |
| `compact-reminder.md` | コンテキスト圧縮後に忘れてはいけない原則 | compaction 後の再注入（フック経由で自動参照済み） |

### 現在の .claude/skills/ の各スキル

| スキル | 用途 | 参照しているハーネスファイル |
|---|---|---|
| `improve-harness` | 直近タスクの遠回りをハーネスへ反映する | `harness/meta/file-routing.md` |
| `bootstrap-domain-harness` | 新しいドメインハーネスを作る | `harness/domains/_template/` |
| `verify-done` | 完了条件を検証して判定する | `harness/domains/**/verification.md` |

### 現在の .claude/rules/ の各ルール

| ルール | 適用パス | 内容 |
|---|---|---|
| `harness-editing.md` | `CLAUDE.md`, `.claude/**`, `harness/**`, `.mcp.json` | ハーネスファイル編集時の規則 |
| `verification-design.md` | （paths記載なし） | 検証設計の規則 |

## 現在の問題

`harness/meta/` の複数ファイルへの「導線」（適切なタイミングで参照される仕組み）が欠落しています。

### 導線が切れているファイル

1. **`harness/meta/owner-contract.md`**
   - 内容: タスク開始時にオーナー要求を構造化するテンプレート（目的・完了条件・非目標・制約・入力・出力・検証・未確定事項）
   - 問題: CLAUDE.md にも skills にも rules にも参照されておらず、存在を知っていなければ使われない

2. **`harness/meta/definition.md`**
   - 内容: 「ハーネス」「メタハーネス」「ドメインハーネス」の定義と記述原則
   - 問題: ハーネス編集時に参照されるべきだが、`harness-editing.md` rules にも `improve-harness` skill にも導線がない

3. **`harness/meta/update-policy.md`**
   - 内容: ハーネスを更新すべき条件・更新しない条件・更新方法・完了後レビュー手順
   - 問題: `improve-harness` skill が `file-routing.md` は参照しているが `update-policy.md` は参照していない

4. **`harness/domains/README.md`**
   - 内容: ドメインハーネスの作り方（ファイル構成、slug 命名規則、運用ルール）
   - 問題: `bootstrap-domain-harness` skill が実質的に同じ内容をカバーしており、README への導線もない。統合すべきかもしれない。

## 質問

以下の3点について、具体的な推奨戦略とその理由を教えてください。

### Q1. 各ファイルの最適な導線戦略

`owner-contract.md`・`definition.md`・`update-policy.md`・`domains/README.md` それぞれについて、ファイルの使用タイミング・頻度・性質を踏まえた最適な導線設計を提案してください。

### Q2. 「必要な時に確実に、不要な時には読まれない」設計の原則

Claude Code の仕組み（CLAUDE.md の常時参照、rules の条件付き参照、hooks のイベント駆動）を最大限活用するための設計原則を教えてください。「常に読む」「特定条件で読む」「手動で読む」の使い分けをどう判断すればよいか。

### Q3. CLAUDE.md の肥大化を防ぎながら導線を整備するバランス

CLAUDE.md に導線を追記すると肥大化するリスクがあります。その一方で、導線が skill や rules の中にしかないと気付きにくくなります。このトレードオフをどう解決するか。

### Q4. 将来の導線切れを防ぐ設計原則

今回は後から導線切れが発覚しました。新しいファイルを `harness/` に追加する際、または新しい skill・rules を追加する際に、導線切れを起こさないための設計原則・チェックリスト・構造的な制約をどう整備すればよいか。

## 期待する出力形式

- 各ファイルについての推奨戦略（箇条書き）
- 変更が必要なファイルと変更内容（具体的に）
- 採用した場合のトレードオフ・副作用
- Q2・Q3・Q4 についての設計指針（各 2〜3 段落）
