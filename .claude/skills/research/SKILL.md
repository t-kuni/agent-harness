---
name: research
description: リサーチを実行し、結果を research/ に保存する。Web検索が必要な情報収集はこのスキルを使う
---

## ルール

- 実行方式は2種類ある。指定がなければ「サブエージェント方式」を使う。オーナーが明示的にcodexの利用を指示した場合のみ「codex方式」を使う
- メインエージェントは WebSearch・WebFetch を直接使用しない
- 公式ドキュメントを最優先で参照する
- ツールのバージョン差異に注意し、対象バージョンを確認する
- 英語圏の信頼性の高い情報源を優先する

## 手順

1. リサーチ課題を明確化する。
   - 何を明らかにしたいか（問い）
   - なぜそれが必要か（背景）
   - どんな答えが欲しいか（出力要件）
2. 課題に関連するリポジトリ固有知識を抽出する。
   - 関連するドメインハーネスの内容
   - 関連する `CLAUDE.md` の原則
   - 関連するコード・設定ファイルの断片
   - Claude Code の仕組みのうち、外部AIが知らないと回答できない部分（hooks イベント種別、rules の自動参照条件など）
3. プロンプトを生成する。
   - 冒頭に「このリポジトリについて」セクションでリポジトリ構造と参照の仕組みを自己完結させる
   - 問いを明確に1つ立てる
   - 期待する出力形式を指定する
   - 出力言語は日本語で行うよう明記する
   - 前提知識を持たない読者でも理解できる粒度にする
   - 作成者が検討した選択肢・仮説・好みは含めない。現状の事実だけを記述する（選択肢を提示すると外部AIの回答がその選択肢に縛られる）
   - オーナーが指示していない、リサーチの自由度を減らす情報をプロンプトに追加しない
4. `research/<YYYYMMDD-HHMMSS-slug>/prompt.md` に保存する。
   - `YYYYMMDD-HHMMSS` は `$(date +%Y%m%d-%H%M%S)` で取得した実行時刻
   - `slug` はリサーチ課題を表す短い名詞句（単数・kebab-case）
   - フォルダ名例：`20260530-153042-claude-hooks`
5. 実行方式に応じてリサーチを実行し、標準出力（またはサブエージェントの最終報告）を `research/<YYYYMMDD-HHMMSS-slug>/result.md` に保存する。
   `<PROMPT_PATH>` と `<RESULT_PATH>` は実際の絶対パスに置き換える。

### サブエージェント方式（デフォルト）

- `Agent` ツールで `subagent_type: "web-researcher"` を指定して起動する
  - `web-researcher` は `tools: WebSearch, WebFetch` に限定されたカスタムサブエージェント（`.claude/agents/web-researcher.md`）
  - `prompt` には `<PROMPT_PATH>` の内容（生成したプロンプト）をそのまま渡す
- サブエージェントはバックグラウンドで実行され、完了は通知で検知する。手動でのポーリング（`sleep` 等）は行わない
- 完了したらサブエージェントの最終報告を `<RESULT_PATH>` に保存する

### codex方式（オーナーが明示的に指示した場合のみ）

- `codex exec` は `Bash` ツールの `run_in_background: true` で起動する。`TaskCreate` による非同期実行は禁止
  - リサーチはWeb検索を多数回行うため長時間かかることがあり、フォアグラウンド実行では `timeout` の最大値（600000ms＝10分）でも打ち切られることがある
  - 完了はタスク通知で検知する。手動でのポーリング（`sleep` 等）は行わない

```bash
WORKDIR="$(mktemp -d /tmp/agent-harness-research.XXXXXX)"
(codex exec \
  --model gpt-5.5 \
  --sandbox read-only \
  --ephemeral \
  --skip-git-repo-check \
  --config 'approval_policy="never"' \
  --config 'model_reasoning_effort="high"' \
  --config 'web_search="live"' \
  "$(cat <PROMPT_PATH>)" \
  > <RESULT_PATH> 2>"$WORKDIR/stderr.log"; rm -rf "$WORKDIR")
```

タスク通知で完了を検知したら、`<RESULT_PATH>` の内容を確認し、「出力」セクションの内容を報告する。

## エラー時の対応

サブエージェント方式・codex方式のいずれも、失敗した場合（認証エラー・コマンド不在・その他）に代替手段（WebSearch・WebFetchの直接使用など）で自己解決しない。
オーナーにエラー内容を報告し、どう対応するか指示を仰ぐ。

## 出力

- 保存先パス（prompt.md・result.md）
- リサーチ結果の要約（何が分かったか1〜2行）
