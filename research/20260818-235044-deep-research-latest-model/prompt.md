# このリポジトリについて

これは Claude Code（Anthropic製CLIエージェント）向けの「ハーネス」を管理するリポジトリである。ハーネスとは、AIエージェントが参照する知識ファイル群の総称で、`.claude/skills/<スキル名>/SKILL.md` の形式でスキルが定義される。このリポジトリには汎用的なWebリサーチを行う `research` スキルがあり、OpenAIの「Deep Research」機能をAPI経由で呼び出す方式への対応を検討している。

過去に行った別のリサーチで、OpenAIのDeep Research APIは Responses API (`POST https://api.openai.com/v1/responses`) 上で `model` に `o3-deep-research`（スナップショット `o3-deep-research-2025-06-26`）または `o4-mini-deep-research`（スナップショット `o4-mini-deep-research-2025-06-26`）を指定して利用する方式であることが判明した。ただしこれらのモデルは2025年6月26日付のスナップショットであり、2026年8月時点では古い可能性がある。

# 問い

2026年8月時点で、OpenAIのDeep Research API（Responses API経由で `web_search` 等のツールと組み合わせて多段階の自律調査を行う機能）において、`o3-deep-research` `o4-mini-deep-research` よりも新しいモデル・スナップショットが公式にリリースされているか。以下を明らかにせよ。

1. OpenAIの公式ドキュメント（platform.openai.com、developers.openai.com、openai.com/index の公式ブログ・公式Changelog）において、`o3-deep-research` `o4-mini-deep-research` 以降にリリースされたDeep Research用モデル（例：GPT-5系のDeep Research版、新しいスナップショット日付を持つo3/o4-mini-deep-researchの更新版、あるいは全く別の名称のモデル）が存在するか。存在する場合、正式なモデルID文字列・リリース日・エイリアスの解決先（例：`o3-deep-research` が最新の特定スナップショットに自動的に解決されるか）を明記する。
2. 2026年8月時点でOpenAIの公式モデル一覧ページ（`platform.openai.com/docs/models` または `developers.openai.com/api/docs/models` 等）に掲載されているDeep Research関連モデルのラインナップ全体を、モデルID・コンテキストウィンドウ・料金（入力/キャッシュ入力/出力のトークン単価）とともに列挙する。
3. `o3-deep-research` `o4-mini-deep-research` に非推奨（deprecated）や廃止予定（sunset）の告知が公式に出ていないか確認する。出ている場合は移行先の推奨モデルを明記する。
4. 公式情報で確認できない項目があれば、その旨と、確認のために参照したURL・検索クエリの結果概要を明記する。

# 出力要件

- 日本語で記述すること。
- 公式ドキュメント・公式ブログ・公式Changelogを最優先で参照し、URLを明記すること。二次情報サイトを使う場合はその旨を明記し、公式情報と区別すること。
- 「最新である」「最新ではない」を推測ではなく、実際に参照できたソースの日付・内容に基づいて明言すること。断定できない場合は「確認できなかった」と明記すること。
- 参照した公式ドキュメント・情報源のURLをすべて出力の末尾に列挙すること。
- 選択肢の提示や好み・推奨の表明は不要。事実の確認結果のみを記述すること。
