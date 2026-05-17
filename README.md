# ハーネスエンジニアリング テンプレート

Claude Code を用いて、あらゆるタスクに適応可能なハーネスエンジニアリングの土台となるリポジトリテンプレート。

## このリポジトリの目的

- オーナーが「やりたい事」と「完了条件」を与えると、AIエージェントがタスク遂行とハーネス自己改善を継続する
- 完了条件を決定論的に検証できる仕組みを優先して整備する
- タスクを重ねるごとに、次回以降の最短手が蓄積されていく

## 新規プロジェクトの開始

`PROJECT_NAME` にプロジェクト名を指定して実行する：

```bash
PROJECT_NAME=myproject bash <(curl -fsSL https://raw.githubusercontent.com/t-kuni/agent-harness/main/scripts/init-project.sh)
```

その後、初期セットアップを実行する：

```bash
cd myproject
bash scripts/setup.sh
```

`init-project.sh` は以下を自動実行する：

1. このリポジトリをクローン
2. クローン時点のコミットハッシュを `.harness-version` に記録
3. `.git` を削除して独自リポジトリとして初期化

## このリポジトリの更新を取り込む

このリポジトリに更新が入った場合、派生先リポジトリで以下を実行する：

```bash
bash scripts/update-harness.sh
```

`/tmp` に一時クローンして差分を生成し、現在のブランチにコミットする。

## 使い方

1. 上記コマンドでテンプレートを取得する
2. Claude Code を起動する
3. オーナーが「やりたい事」と「完了条件」を伝える
4. エージェントがドメインハーネスを構築・更新しながらタスクを遂行する

## ファイル構成

```
.
├── CLAUDE.md                          # 毎セッション読む短い運用原則
├── .gitignore
├── .mcp.json                          # 外部システム接続（初期は空）
├── research/                          # 外部AIへのリサーチ依頼・結果の蓄積
└── .claude/
    ├── settings.json                  # フックと実行時制御
    ├── agents/
    │   └── web-researcher.md          # Web検索専用サブエージェント定義
    ├── hooks/
    │   ├── suggest-improve-harness.sh # タスク完了後のハーネス改善示唆
    │   └── strictly-enforced-rules.md # フック経由で強制されるルール
    └── skills/
        ├── bootstrap-domain-harness/  # ドメインハーネス作成・更新手順
        ├── harness-guide/             # ハーネス概念・配置先・更新ポリシー
        ├── improve-harness/           # タスク完了後のハーネス改善手順
        ├── random-word/               # ランダム単語取得（アイデア出し用）
        ├── research-guide/            # Web検索のルール・手順
        ├── research-prompt/           # 外部AIへのリサーチ依頼プロンプト生成
        └── verify-done/               # 完了条件の検証手順
```

ドメインハーネスはタスクに応じた任意のフォルダ・ファイルとして作成する（固定構造なし）。

## ハーネスとは

AIエージェントがタスクを処理するのに必要な固有知識と、自己改善可能な運用知識の総体。詳細は `/harness-guide` スキルを参照。

## タスク処理機構

オーナーが明示的に指示した場合のみ使用する。以下の2つの仕組みから構成される。

**タスクキュー（TASK.md）**
処理待ちのタスクを管理するファイル。「〇〇をタスクキューに追加して」と指示すると追記される。上から順に処理され、完了したタスクは削除される。

**タスクエージェント（scripts/task-agent.sh）**
タスクキューを監視し、タスクを1件ずつ自動処理するスクリプト。「タスクエージェントを起動して」と指示すると起動する。

## playwright-cliを使用する手順

chromeで `chrome://inspect/#remote-debugging` を開き、リモートデバッグを許可する

```
# インストール
npm install -g @playwright/cli@latest
playwright-cli install --skills
# ブラウザに接続
playwright-cli attach --cdp=chrome
```
