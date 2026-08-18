---
name: research
description: リサーチを実行し、結果を research/ に保存する。Web検索が必要な情報収集はこのスキルを使う
---

## ルール

- 実行方式は2種類ある。指定がなければ「codex方式」を使う。オーナーが明示的にサブエージェントの利用を指示した場合のみ「サブエージェント方式」を使う
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

### codex方式（デフォルト）

- `codex exec` は `Bash` ツールの `run_in_background: true` で起動する。`TaskCreate` による非同期実行は禁止
  - リサーチはWeb検索を多数回行うため長時間かかることがあり、フォアグラウンド実行では `timeout` の最大値（600000ms＝10分）でも打ち切られることがある
  - 完了はタスク通知で検知する。手動でのポーリング（`sleep` 等）は行わない
- `codex exec` がエラーになった場合（クォータ到達・認証エラー・コマンド不在等）、オーナーへの確認なしに下記「フォールバック: OpenAI Deep Research API直接呼び出し」に自動的に切り替えてよい

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

### フォールバック: OpenAI Deep Research API直接呼び出し

- `codex exec` がエラーになった場合に、`scripts/deep_research_api.sh` を使ってOpenAIのResponses API（モデル `gpt-5.6-sol`、`reasoning.effort: medium`、`web_search_preview` ツール）を直接呼び出す
- APIキー（`OPENAI_API_KEY`）はスクリプト内部でのみ環境変数として参照する。AIエージェント自身が `echo $OPENAI_API_KEY` 等でキーの値を参照・存在確認することは禁止
- スクリプトの標準出力・標準エラー出力・実行結果の報告に、APIキーの値を含めない（含まれる出力があった場合はマスクする）
- Web検索を多数回行い長時間かかることがあるため、`Bash` ツールの `run_in_background: true` で起動する。`TaskCreate` による非同期実行は禁止
  - 完了はタスク通知で検知する。手動でのポーリング（`sleep` 等）は行わない

```bash
bash /home/kuni/Documents/agent-harness/.claude/skills/research/scripts/deep_research_api.sh \
  <PROMPT_PATH> \
  <RESULT_PATH>
```

スクリプトが `<RESULT_PATH>` に結果テキストを直接保存するため、保存後に内容を確認し、「出力」セクションの内容を報告する。

### サブエージェント方式（オーナーが明示的に指示した場合のみ）

- `Agent` ツールで `subagent_type: "web-researcher"` を指定して起動する
  - `web-researcher` は `tools: WebSearch, WebFetch` に限定されたカスタムサブエージェント（`.claude/agents/web-researcher.md`）
  - `prompt` には `<PROMPT_PATH>` の内容（生成したプロンプト）をそのまま渡す
- サブエージェントはバックグラウンドで実行され、完了は通知で検知する。手動でのポーリング（`sleep` 等）は行わない
- 完了したらサブエージェントの最終報告を `<RESULT_PATH>` に保存する

## エラー時の対応

codex方式・フォールバック（API直接呼び出し）・サブエージェント方式のいずれも、失敗した場合（認証エラー・コマンド不在・その他）に代替手段（WebSearch・WebFetchの直接使用など）で自己解決しない。
オーナーにエラー内容を報告し、どう対応するか指示を仰ぐ。エラー内容を報告する際もAPIキーの値は含めない。

## 出力

- 保存先パス（prompt.md・result.md）
- リサーチ結果の要約（何が分かったか1〜2行）
- codex方式を使った場合、codex方式・フォールバック（API直接呼び出し）のどちらで実行したか
