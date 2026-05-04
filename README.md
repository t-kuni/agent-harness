# ハーネスエンジニアリング テンプレート

Claude Code を用いて、あらゆるタスクに適応可能なハーネスエンジニアリングの土台となるリポジトリテンプレート。

## このリポジトリの目的

- オーナーが「やりたい事」と「完了条件」を与えると、AIエージェントがタスク遂行とハーネス自己改善を継続する
- 完了条件を決定論的に検証できる仕組みを優先して整備する
- タスクを重ねるごとに、次回以降の最短手が蓄積されていく

## 使い方

1. このリポジトリを clone またはテンプレートとして新規リポジトリを作成する
2. Claude Code を起動する
3. オーナーが「やりたい事」と「完了条件」を伝える
4. エージェントが `harness/meta/owner-contract.md` のテンプレートへ要求を正規化し、ドメインハーネスを構築・更新しながらタスクを遂行する

## ファイル構成

```
.
├── CLAUDE.md                          # 毎セッション読む短い運用原則
├── .gitignore
├── .mcp.json                          # 外部システム接続（初期は空）
├── .claude/
│   ├── settings.json                  # フックと実行時制御
│   ├── hooks/
│   │   └── rehydrate-context.sh       # compaction後の文脈再注入
│   ├── rules/
│   │   ├── harness-editing.md         # ハーネス文書編集時のルール
│   │   └── verification-design.md    # 検証設計時のルール
│   └── skills/
│       ├── bootstrap-domain-harness/  # ドメインハーネス作成・更新手順
│       ├── improve-harness/           # タスク完了後のハーネス改善手順
│       └── verify-done/               # 完了条件の検証手順
└── harness/
    ├── meta/                          # メタハーネス本体
    │   ├── definition.md              # ハーネスの定義
    │   ├── file-routing.md            # ファイル配置の判断基準
    │   ├── update-policy.md           # ハーネス更新ポリシー
    │   ├── owner-contract.md          # オーナー要求の正規化テンプレート
    │   └── compact-reminder.md        # compaction後の再注入内容
    └── domains/                       # ドメインハーネス本体
        ├── README.md                  # ドメインハーネスの作り方
        └── _template/                 # 新規ドメイン作成時のひな型
            ├── overview.md
            ├── verification.md
            └── sources.md
```

## ハーネスとは

AIエージェントがタスクを処理するのに必要な固有知識と、自己改善可能な運用知識の総体。定義・分類・記述原則は `harness/meta/definition.md` を参照。
