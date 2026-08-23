---
name: agy
description: >
  what: Antigravity CLI（コマンド `agy`。旧Gemini CLIの後継）を非対話（headless）で起動する方法の知識
  when: オーナーが agy／Antigravity CLI／Gemini CLI をコマンドとして実行するよう指示した時に参照する
---

# Antigravity CLI（agy）

Google の Antigravity CLI。旧 Gemini CLI の後継であり、コマンド名は `agy`。

## 起動方法

* `agy -p` はBashツール経由で起動し、`run_in_background: true` を指定する
* 理由：実行に10分以上かかることがあるため

* 契約プランは Google AI Pro（個人向け有料プラン）を前提とする
* 調査・実機確認時点のバージョン: `1.1.16`

## 非対話（headless）実行

* `agy -p "プロンプト"`（`-p` は `--print` / `--prompt` の短縮形）で単発の非対話実行ができる
* 対話版 `agy` で事前にログイン済みでないと、headless実行時に認証待ちにならずエラーになる
* 既定のタイムアウトは5分。`--print-timeout` で変更できる
* `--output-format` で `text`（既定）・`json`・`stream-json` を選べる
* `--input-format stream-json` にすると、stdinから1行1メッセージのNDJSONを読み込み、行ごとにターンを実行する。この場合 `--output-format stream-json` が必須
* `--json-schema` で構造化出力用のJSONスキーマ（文字列またはファイルパス）を強制できる
* `--dangerously-skip-permissions` を付けると、ツール権限確認をすべて自動承認する。非対話実行でツール権限の確認待ちにより停止させたくない場合はこのフラグが必要になる

```bash
cd /absolute/path/to/workspace
agy -p "このリポジトリを要約して" --output-format json
```

## サンドボックス・ファイルシステムアクセス制限

* `--sandbox`（設定ファイルでは `enableTerminalSandbox: true`）は、エージェントが起動するローカルのterminalコマンドをOSレベルの隔離機構（Linux: nsjail、macOS: sandbox-exec、Windows: AppContainer）で実行する機能。ツール実行の隔離であり、`agy` プロセス自体の隔離ではない
* `agy sandbox` という専用サブコマンドは存在しない（`--sandbox` はトップレベルフラグのみ）
* `--add-dir <path>` で、現在の作業ディレクトリ（workspace）に加えてアクセス許可するディレクトリを追加できる（繰り返し指定可）
* 設定ファイルの `allowNonWorkspaceAccess`（既定 `false`）で、ファイルのread/writeがworkspace外に出ることを許可するかどうかを制御する
* 「起動した `agy` プロセス全体を、指定したディレクトリ以外を一切参照できない状態にする」専用オプション（`--workspace` でルートを固定するような機能）は存在しない。プロセス全体を隔離したい場合は、`agy` 自体をコンテナ内で起動する構成が必要になる

```bash
cd /absolute/path/to/workspace
agy -p "テストを実行して失敗を要約して" --sandbox --add-dir /path/to/extra/dir
```

## 推論力（reasoning effort）

* `--effort` オプションで指定する
* 選択肢は `low` / `medium` / `high` の3種類

```bash
agy -p "キャッシュ導入の実装計画を作って" --effort high
```

## モデル指定

* `--model` オプションでモデルを指定する
* `agy models` で、現在ログインしているアカウント（契約プラン）で利用可能なモデルのslug一覧を取得できる
* モデルslugには推論レベルが埋め込まれている（例: `gemini-3.7-flash-high` はGemini 3.7 Flashのhigh推論）。`--model` と `--effort` を併用した場合の優先関係は未確認
* モデル一覧は契約プランや時期によって変わるため、都度 `agy models` を実行して確認する（固定リストはここに書かない）
* 一覧に表示されることと、実行時にquota上の制約なく使えることは別軸であり、後者は未検証

```bash
agy models
agy -p "この関数の境界条件をレビューして" --model gemini-3.7-flash-high
```

## Web検索・Webアクセスの許可

* Web検索を有効化する専用のトップレベルフラグは存在しない（`agy --help` 全体で確認済み）
* 設定ファイルの `permissions.allow` に `read_url(*)`（ページ本文の読み取り）・`execute_url(*)`（Webページ操作まで）を追加することで、事前に許可しておく
* Web browsingの既定動作はAsk（都度確認）であり、headless実行では対話的に承認できないため、事前にpermissions設定で許可しておく必要がある

```json
{
  "permissions": {
    "allow": [
      "read_url(*)"
    ]
  }
}
```

```bash
agy -p "Webで最新の公式ドキュメントを確認し、URL付きで要約して" --output-format json
```

## その他のサブコマンド

* `agy agent` / `agy agents`: 利用可能なagent一覧を表示
* `agy mcp add/remove/list/enable/disable`: MCPサーバーの管理
* `agy plugin` / `agy plugins`: プラグインの管理
* `agy changelog`: 変更履歴の表示
* `agy update`: CLI自体の更新
* `--continue` / `-c`: 直近の会話を継続
* `--conversation <id>`: 指定IDの会話を再開
* `--mode accept-edits|plan`: エージェントの実行モードを指定

## 未確認事項

* `--sandbox` と `allowNonWorkspaceAccess: false` を組み合わせても、`agy` プロセス自体（設定・認証情報の読み込み等）が指定ディレクトリ以外を一切参照できなくなるかどうかは未確認
* `agy models` の一覧に表示されるサードパーティ系モデル（Claude・GPT-OSS等）が、Google AI Pro契約で実行時にquota制約なく使えるかどうかは未確認
