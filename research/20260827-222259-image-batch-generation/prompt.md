# このリポジトリについて

このリポジトリは「ハーネス」と呼ばれる、AIエージェント（Claude Code）が参照する知識ファイル群を管理するリポジトリである。
`.claude/skills/<スキル名>/SKILL.md` に各スキルの手順書があり、`.claude/skills/<スキル名>/scripts/` に付随するスクリプトが置かれている。

このリポジトリには `image-gen` というスキルがあり、画像生成を行う。以下の4通りの実行方式を持つ。

1. **OpenAI方式（デフォルト）**：OpenAIの画像生成API（モデル名 `gpt-image-2`）を、Pythonスクリプト `generate_image.py` から直接HTTP呼び出しする。エンドポイントは参照画像なしの場合 `/v1/images/generations`、参照画像ありの場合 `/v1/images/edits`。
2. **codex方式**：OpenAIのコーディングエージェントCLIである `codex exec` を経由して画像生成を行う（内部で同様の画像生成APIを呼んでいると推測される）。
3. **Gemini API方式（通称 nano banana2）**：Googleの画像生成モデル（モデルID `gemini-3.1-flash-image`）を、Interactions API（`POST /v1beta/interactions`）経由でPythonスクリプト `generate_image_gemini.py` から直接HTTP呼び出しする。
4. **MiniMax API方式**：MiniMax社の画像生成モデル（モデル名 `image-01`）を、公式API（`POST https://api.minimax.io/v1/image_generation`）経由でPythonスクリプト `generate_image_minimax.py` から直接HTTP呼び出しする。

いずれの方式も現状は1回のAPIリクエストにつき1枚の画像を生成する実装になっている。

# 問い

上記4つの画像生成モデル・APIそれぞれについて、1回のAPIリクエストで複数枚の画像を同時に生成できるパラメータは存在するか。存在する場合、その仕様の詳細を明らかにせよ。

- OpenAI画像生成API（モデル `gpt-image-2`。`/v1/images/generations` および `/v1/images/edits` エンドポイント）
- codex CLI（`codex exec` による画像生成。内部で使用している画像生成APIやCLIオプションに複数枚生成に関するものがあるか）
- Google Gemini API（モデル `gemini-3.1-flash-image`、Interactions API `/v1beta/interactions` エンドポイント）
- MiniMax公式画像生成API（モデル `image-01`、`/v1/image_generation` エンドポイント）

# 出力要件

各モデル・APIごとに、以下を明らかにすること。

- 複数枚同時生成を指定するパラメータが存在するか（存在しない場合はその旨を明記）
- 存在する場合のパラメータ名（リクエストボディのフィールド名、またはCLIオプション名）
- 指定可能な値の範囲（最小値・最大値、デフォルト値）
- 複数枚生成した場合の料金への影響（1枚あたりの単価がそのまま乗算されるのか、複数枚生成による割引や追加コストがあるのか）
- レスポンス形式（複数枚生成時にレスポンスボディがどのような構造になるか。画像データの配列がどう返るか）
- 参照画像を使った編集（image-to-image、キャラクター一貫性用途）と組み合わせた場合に、同じ複数枚生成パラメータが使えるか

出力は日本語で、モデル・API単位の見出しを立てて整理すること。
前提知識を持たない読者にも理解できるよう、専門用語は簡潔に補足すること。
公式ドキュメントを情報源として優先し、参照したURLを併記すること。
