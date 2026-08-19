## 1. `gpt-image-2` の存在確認

**存在する。** 公式ソース上で確認できた。

- OpenAI公式デベロッパーコミュニティ（Announcementsカテゴリ、OpenAIスタッフによる公式発表投稿）に「Introducing gpt-image-2 - available today in the API and Codex」という投稿があり、2026年4月21日付で公開されている。
  https://community.openai.com/t/introducing-gpt-image-2-available-today-in-the-api-and-codex/1379479
- 公式APIドキュメント `developers.openai.com`（OpenAIの開発者向け公式ドキュメントサイト）にモデルページが存在する。
  https://developers.openai.com/api/docs/models/gpt-image-2
- 正式なモデルID：`gpt-image-2`（デフォルトスナップショットは `gpt-image-2-2026-04-21`）
- リリース発表日：2026年4月21日
- 位置付け：OpenAIによれば「gpt-image-1.5の後継となる最新・最上位の画像生成モデル」で、テキスト描写精度・写実性・指示追従性が向上し、最大2K解像度、思考モード（推論との連携）対応などが追加された。

※注意：この結論は `developers.openai.com` と OpenAI公式コミュニティ投稿という一次情報源に基づくが、`openai.com/index`（公式ブログ）配下での該当プレスリリースは検索・直接確認できなかった。二次情報サイト（GitHubのプロンプト集リポジトリ、Higgsfield、OpenRouter、Wikipedia、LLMReference等）でも言及があるが、これらは参考程度に留め、判断根拠には用いていない。

## 2. `gpt-image-2` のAPI仕様

公式ドキュメント（https://developers.openai.com/api/docs/models/gpt-image-2 、https://developers.openai.com/api/docs/guides/image-generation 、https://developers.openai.com/api/docs/pricing ）に基づく。

- **APIエンドポイント**
  - 画像生成：`POST https://api.openai.com/v1/images/generations`
  - 画像編集（インペインティング対応）：`POST https://api.openai.com/v1/images/edits`
  - バッチ処理：`v1/batch` にも対応
  - Responses API経由（`image_generation` ツールとして）：`POST https://api.openai.com/v1/responses`
- **リクエスト形式**
  - `/images/generations`：JSON形式
  - `/images/edits`：`multipart/form-data`（画像ファイル・マスクを含む）
  - Responses API利用時：JSON形式でツール設定を指定
- **認証方式**：HTTPヘッダー `Authorization: Bearer $OPENAI_API_KEY`（`Content-Type` は用途に応じて `application/json` または `multipart/form-data`）
- **レスポンス形式**：base64エンコードされた画像データ（`b64_json` フィールド）。URL形式の返却には対応せず、出力フォーマットはデフォルト `png`、`jpeg`・`webp` も選択可能。
- **価格**（1Mトークンあたり、Standard料金）
  - テキスト入力：$5.00（キャッシュ時 $1.25）
  - 画像入力：$8.00（キャッシュ時 $2.00）
  - 画像出力：$30.00
  - Batch料金は上記の約50%（例：テキスト入力 $2.50、画像出力 $15.00）
  - 実際の1枚あたりの価格は解像度・品質で変動するトークン量に依存するため、公式の「image generation cost calculator」の利用が案内されている。
- **API利用条件**：Organization Verification（組織確認）の完了が必須と明記されている。

## 3. 2026年8月時点のOpenAI画像生成モデルのラインナップ（公式ドキュメント準拠）

`developers.openai.com/api/docs/guides/image-generation` に基づき、以下の4モデルが現行ラインナップとして列挙されている（新しい順）。

| モデルID | 位置付け | 価格（テキスト入力/画像入力/画像出力、$ per 1Mトークン） |
|---|---|---|
| `gpt-image-2`（デフォルトスナップショット `gpt-image-2-2026-04-21`） | 最新・最上位モデル（2026年4月21日リリース） | $5.00 / $8.00 / $30.00 |
| `gpt-image-1.5` | 前世代の主力モデル（2025年12月16日リリース、公式コミュニティ投稿より。gpt-image-2登場後は非推奨扱いだが2026年12月1日まで利用可能） | $5.00 / $8.00 / $32.00 |
| `gpt-image-1` | 初代モデル | $5.00 / $10.00 / $40.00 |
| `gpt-image-1-mini` | 軽量・低コスト版 | $2.00 / $2.50 / $8.00 |

## 4. 情報が公式ソースで確認できなかった点についての補足

- `openai.com/index` 配下（OpenAI公式ブログのプレスリリース形式ページ）における gpt-image-2 の直接告知記事は、検索クエリ `gpt-image-2 site:openai.com` 等で探したが、ヒットしたのは Wikipedia、OpenAI Developer Community、developers.openai.com のみで、`openai.com/index/...` 形式の記事は確認できなかった。そのため「公式ブログ記事」としての一次ソースは今回確認できていない（存在しないと断定はできず、単に検索で発見できなかったという事実として報告する）。
- 過去のリサーチで「gpt-image-1.5が最新」と結論づけていた点については、今回の調査により誤りであったことが確認された。gpt-image-2は2026年4月21日以降、公式ドキュメント・公式コミュニティ発表上でgpt-image-1.5の後継として明記されている。

## 参照した情報源URL

- https://developers.openai.com/api/docs/models/gpt-image-2
- https://developers.openai.com/api/docs/models/gpt-image-1.5
- https://developers.openai.com/api/docs/guides/image-generation
- https://developers.openai.com/api/docs/guides/images-vision
- https://developers.openai.com/api/docs/pricing
- https://community.openai.com/t/introducing-gpt-image-2-available-today-in-the-api-and-codex/1379479
- https://community.openai.com/t/gpt-image-1-5-rolling-out-in-the-api-and-chatgpt/1369443
- https://platform.openai.com/docs/guides/tools-image-generation（`developers.openai.com/api/docs/pricing` へリダイレクトされることを確認）

（参考として使用したが判断根拠にはしていない二次情報源：https://en.wikipedia.org/wiki/GPT_Image 、https://github.com/YouMind-OpenLab/awesome-gpt-image-2 、https://openrouter.ai/openai/gpt-5.4-image-2 、https://higgsfield.ai/gpt-2 ）
