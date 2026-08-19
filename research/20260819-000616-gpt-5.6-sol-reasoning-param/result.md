## 出力

### 1. `gpt-5.6-sol` モデルページの記載

`developers.openai.com/api/docs/models/gpt-5.6-sol` によれば、`gpt-5.6-sol` は reasoning tokens をサポートするモデルであり、`gpt-5.6` エイリアスは `gpt-5.6-sol` にルーティングされる。料金は入力 $5 / 出力 $30（100万トークンあたり）。コンテキストウィンドウ 1,050,000、最大出力 128,000 トークン。

推論量パラメータそのものの詳細（列挙値・デフォルト値）はモデルページ単体には明記されておらず、共通ガイド「Reasoning models」（`developers.openai.com/api/docs/guides/reasoning`）に集約されている。同ガイドでは以下のように明記されている。

- 指定可能な値：`none`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`（"Supported values are model-dependent and can include none, minimal, low, medium, high, xhigh, and max."）
- デフォルト値：モデル依存。ガイド内の例では `gpt-5.5` は `medium` がデフォルトと明記されている。`gpt-5.6-sol` 自体の既定値をピンポイントで明言する記述は確認できなかった（`gpt-5.6` ファミリーの標準的なデフォルトは `medium` である可能性が高いが、公式に `gpt-5.6-sol` 単体でのデフォルト値表記は見つけられず「不確か」）。
- `gpt-5.6-sol` 固有の追加値として `max` と `ultra`（サブエージェントを用いたマルチエージェント推論モード）が新設されている。公式プレビュー記事（`openai.com/index/previewing-gpt-5-6-sol/`）に「with GPT-5.6, OpenAI is introducing a new max reasoning effort」「ultra mode goes beyond the capabilities of a single agent by leveraging subagents」との記載があり、`ultra`・`max` は Sol のみがサポートし、Terra・Luna は標準の reasoning effort（`none`〜`xhigh`）のみ対応、との記述がある。

### 2. Responses API リファレンスにおける `reasoning` パラメータ

`developers.openai.com/api/docs/api-reference/responses`（および `/create` サブページ）を直接取得したが、リクエストボディ側の `reasoning` パラメータのスキーマ（型・サブフィールド定義）を明示したセクションは、今回参照できたページ内容からは確認できなかった。取得できたのはレスポンス出力アイテムとしての `reasoning` オブジェクト（`id`, `summary`, `type`, `content`, `encrypted_content`, `status` 等）であり、これは推論トークンの出力表現であってリクエストパラメータの仕様ではない。

一方、ガイドページ「Reasoning models」（`developers.openai.com/api/docs/guides/reasoning`）には、リクエストパラメータとしての `reasoning.effort` のサンプルが明記されている。

```bash
curl https://api.openai.com/v1/responses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "gpt-5.6",
    "reasoning": {"effort": "low"},
    "input": [{"role": "user", "content": "Write a bash script..."}]
  }'
```

`reasoning` はオブジェクト型で、少なくとも `effort`（列挙値、上記参照）というサブフィールドを持つ。`reasoning.summary` サブフィールドについても存在は示唆されているが、今回参照したページからは指定可能値の一覧までは確認できなかった（不確か）。

### 3. 推論量による料金（単価）への影響

公式モデルページ・料金情報（`gpt-5.6-sol`: 入力 $5 / 出力 $30 per 1M tokens）には、`reasoning.effort` の値によって**トークン単価が変わる**という記載は確認できなかった。単価は effort に関わらず固定であり、`effort` を上げると生成される reasoning tokens（内部的に output tokens として課金される）の量が増えるため、実質的な総コストが増加する、という構造である。

ガイドページの記述「Lower effort favors speed and lower token usage, while at higher effort the model thinks more completely to provide higher quality responses.」も、単価変化ではなくトークン消費量の変化として説明している。したがって「単価固定、トークン消費量（コスト）が変動する」という理解で公式情報と整合する。

### 4. レイテンシ・応答品質への影響（公式記載）

ガイドページ「Reasoning models」に、effort レベル別の用途・トレードオフが明記されている。

- `none`：レイテンシ最優先（音声入力や高速情報取得向け）
- `low`：ツール使用・簡単な計画は必要だが速度重視
- `medium`：品質と信頼性のバランス型（既定値）
- `high`：複雑なデバッグや深い計画が必要な場合
- `xhigh`：非同期・長時間実行ワークフロー向け
- `max`：最も複雑なタスク向け（Sol のみ）

移行ガイダンスとしても「GPT-5.5やGPT-5.4から移行する場合は現状のeffortをベースラインとして維持し、1段階下げたものと比較検討せよ」「noneはレイテンシ基準として維持しつつ、ツール使用や推論が有効なワークフローではlowも試すこと」「maxとxhighは品質・レイテンシ・コストのトレードオフを比較して選ぶこと」といった記述がある。

### 5. `gpt-5.6-sol` 固有の推奨設定（Deep Research的な多段階自律調査向け）

OpenAI公式プレビュー記事（`openai.com/index/previewing-gpt-5-6-sol/`）には、タスク特性に応じた使い分けの指針が示されている。

- 単一の長い論理推論チェーンが必要なタスク（複雑なアルゴリズム設計など）には `max` reasoning effort が推奨される
- 複数の比較的独立したサブタスクに分解できるタスクには `ultra` モード（サブエージェントによる並列協調推論、Sol専用）が推奨される

`research` スキルが想定するような「多段階の自律的Web調査」は、後者（複数の独立した調査サブタスクへの分解が可能なタスク）に近い性質を持つため、公式記事の分類上は `ultra` モードが候補になりうる。ただし、これは記事内の一般的なタスク分類の説明であり、「Deep Research用途にはこの設定を使え」という名指しの推奨文言ではない点に留意が必要（不確か・要一次資料での再確認）。

### 6. 確認できなかった項目・参照した検索クエリの概要

- Responses API公式リファレンス内での `reasoning` リクエストパラメータの厳密なJSON Schema定義（`effort` の型、`summary` の指定可能値一覧、`reasoning.effort` の `gpt-5.6-sol` 個別デフォルト値の明記）は、今回取得したページ内容からは確認できなかった。`developers.openai.com/api/docs/api-reference/responses` および `/create`、`developers.openai.com/api/reference/resources/responses/methods/create` を取得したが、いずれもリクエストパラメータとしての `reasoning` の詳細スキーマ記載は見当たらなかった（ページ内の別セクションやSDK型定義に存在する可能性はあるが未確認）。
- 検索クエリ「`gpt-5.6-sol` reasoning effort」「`gpt-5.6-sol` pricing reasoning effort token price」「`gpt-5.6-sol` ultra mode deep research subagents recommended reasoning effort openai」により、OpenAI公式ブログ（`openai.com/index/`）、モデルページ（`developers.openai.com/api/docs/models/`）、ガイド（`developers.openai.com/api/docs/guides/reasoning`）が上位に確認でき、これらは一次情報として扱った。一方、`artificialanalysis.ai`、`openrouter.ai`、`eesel.ai`、`edenai.co` 等は二次情報サイトであり、料金・ベンチマークの補足的傍証としてのみ参照し、断定根拠には用いていない。

## 参照した情報源URL

- https://developers.openai.com/api/docs/models/gpt-5.6-sol
- https://developers.openai.com/api/docs/guides/reasoning
- https://openai.com/index/previewing-gpt-5-6-sol/
- https://openai.com/index/gpt-5-6/
- https://developers.openai.com/api/docs/guides/latest-model
- https://developers.openai.com/api/docs/api-reference/responses
- https://developers.openai.com/api/reference/resources/responses/methods/create

(参考・二次情報源、公式情報とは区別)
- https://artificialanalysis.ai/models/gpt-5-6-sol
- https://openrouter.ai/openai/gpt-5.6-sol
- https://www.eesel.ai/blog/gpt-5-6-pricing
- https://www.eesel.ai/blog/gpt-5-6-sol-ultra
