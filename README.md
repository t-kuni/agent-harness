# ハーネスエンジニアリング テンプレート

Claude Code を用いて、あらゆるタスクに適応可能なハーネスエンジニアリングの土台となるリポジトリテンプレート。

## このリポジトリの目的

- オーナーが「やりたい事」と「完了条件」を与えると、AIエージェントがタスク遂行とハーネス自己改善を継続する
- 完了条件を決定論的に検証できる仕組みを優先して整備する
- タスクを重ねるごとに、次回以降の最短手が蓄積されていく

## 新規プロジェクトの開始

```bash
git clone https://github.com/t-kuni/agent-harness [プロジェクト名]
cd [プロジェクト名]
rm -rf .git
git init
```

## 使い方

1. 上記コマンドでテンプレートを取得する
2. Claude Code を起動する
3. オーナーが「やりたい事」と「完了条件」を伝える
4. エージェントが `/owner-contract` スキルで要求を正規化し、ドメインハーネスを構築・更新しながらタスクを遂行する

## ファイル構成

```
.
├── CLAUDE.md                          # 毎セッション読む短い運用原則
├── .gitignore
├── .mcp.json                          # 外部システム接続（初期は空）
└── .claude/
    ├── settings.json                  # フックと実行時制御
    ├── hooks/
    │   └── suggest-improve-harness.sh # タスク完了後のハーネス改善示唆
    ├── rules/
    │   ├── harness-editing.md         # ハーネス文書編集時のルール
    │   └── verification-design.md    # 検証設計時のルール
    └── skills/
        ├── bootstrap-domain-harness/  # ドメインハーネス作成・更新手順
        ├── harness-guide/             # ハーネス概念・配置先・更新ポリシー
        ├── improve-harness/           # タスク完了後のハーネス改善手順
        ├── owner-contract/            # オーナー要求の正規化テンプレート
        ├── research-prompt/           # 外部AIへのリサーチ依頼プロンプト生成
        └── verify-done/               # 完了条件の検証手順
```

ドメインハーネスはタスクに応じた任意のフォルダ・ファイルとして作成する（固定構造なし）。

## ハーネスとは

AIエージェントがタスクを処理するのに必要な固有知識と、自己改善可能な運用知識の総体。詳細は `/harness-guide` スキルを参照。
