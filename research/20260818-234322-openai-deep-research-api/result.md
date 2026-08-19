## 出力

### 1. Deep Researchの提供有無・提供形態

OpenAIは2026年8月時点で「Deep Research」を実行できるAPIを**公式に提供している**ことを確認した。公式ドキュメント `platform.openai.com/docs/guides/deep-research`（現在は `developers.openai.com/api/docs/guides/deep-research` にリダイレクト）およびCookbook（`developers.openai.com/cookbook/examples/deep_research_api/introduction_to_deep_research_api`）に明記されている。

提供形態は、**専用エンドポイントではなく、既存の Responses API (`POST https://api.openai.com/v1/responses`) のモデル指定・ツール指定を用いる形式**である。専用の「Deep Research API」というURLパスが別途あるわけではなく、`model` パラメータに専用モデルID（`o3-deep-research`／`o4-mini-deep-research`）を指定し、`web_search_preview` 等のツールを組み合わせることで「Deep Research」的な多段階の自律調査タスクを実行する仕組みになっている。Agents SDK経由でも同様に利用できる旨のCookbook（`developers.openai.com/cookbook/examples/deep_research_api/introduction_to_deep_research_api_agents`）も存在する。

OpenAI Developer Communityの公式アナウンス（2025年6月26日付、`community.openai.com/t/deep-research-in-the-api-webhooks-and-web-search-with-o3/1299919`）でも、「ChatGPTで使われているDeep Researchモデル（o3-deep-research、o4-mini-deep-research）をAPIで直接使えるようになった」と告知されている。

### 2. モデルID・エンドポイント・リクエスト形式・認証・レスポンス形式

**モデルID**
- `o3-deep-research`（スナップショット: `o3-deep-research-2025-06-26`）
- `o4-mini-deep-research`（スナップショット: `o4-mini-deep-research-2025-06-26`）

**エンドポイント**
```
POST https://api.openai.com/v1/responses
```

**必須パラメータ**
- `model`: `"o3-deep-research"` または `"o4-mini-deep-research"`
- `input`: 研究タスクの指示文（テキスト、または `role`/`content` 構造の配列）
- 少なくとも1つのデータソースツール（`web_search_preview` は実質必須、`file_search`、リモート`mcp` のいずれか）

**推奨パラメータ**
- `background: true`（長時間実行のため推奨）
- `reasoning: {"summary": "auto"}` （または `"detailed"`）
- `max_tool_calls`（ツール呼び出し数を制限してコスト・レイテンシを抑制）

**ツール指定**
```json
{"type": "web_search_preview"}
{"type": "file_search", "vector_store_ids": ["vs_xxxxx", "vs_yyyyy"]}
{"type": "code_interpreter", "container": {"type": "auto"}}
```
（vector storeは最大2つまで同時接続可能）

**公式サンプル（cURL）**（`developers.openai.com/api/docs/guides/deep-research` より引用）
```bash
curl https://api.openai.com/v1/responses \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "o3-deep-research",
    "input": "Research the economic impact of semaglutide...",
    "background": true,
    "tools": [
      {"type": "web_search_preview"},
      {
        "type": "file_search",
        "vector_store_ids": ["vs_68870b8868b88191894165101435eef6"]
      },
      {"type": "code_interpreter", "container": {"type": "auto"}}
    ]
  }'
```

**公式Python SDK例**
```python
from openai import OpenAI

client = OpenAI(timeout=3600)

response = client.responses.create(
    model="o3-deep-research",
    input="Research the economic impact of semaglutide...",
    background=True,
    tools=[
        {"type": "web_search_preview"},
        {"type": "file_search", "vector_store_ids": ["<vector_store_id>"]},
        {"type": "code_interpreter", "container": {"type": "auto"}},
    ],
)
print(response.output_text)
```

**認証方式**
標準のResponses APIと同一で、HTTPヘッダー `Authorization: Bearer <OPENAI_API_KEY>` を使用する。

**レスポンス形式（同期／非同期）**
- 標準では**同期**（リクエストが完了するまでコネクションを保持、数分〜十数分かかる場合がある）。
- `background: true` を指定すると**非同期実行**になり、レスポンスIDに対してポーリングするか、Webhook通知で完了を検知できる。公式は「Deep Researchはエージェント的で多段階のため、完了まで数十分かかることがある」としており、background modeとwebhook併用を推奨している。
- background実行時のレスポンス保持期間は約10分間との記載がある。

**出力・引用（citation）の形式**
レスポンスの `output` 配列には、`web_search_call`（検索アクション）、`code_interpreter_call`、`file_search_call`、`mcp_tool_call` などの中間ステップと、最終的な `message` オブジェクトが含まれる。最終回答（`output[-1]`、`response.output_text`）内のテキストには `annotations` 配列でインライン引用が付与され、各注釈には `url`、`title`、`start_index`、`end_index`（引用箇所の文字位置）が含まれる。

### 3. 料金体系

`developers.openai.com/api/docs/models/o3-deep-research` および `.../o4-mini-deep-research` の公式モデルページより。

| モデル | 入力（$/1Mトークン） | キャッシュ入力（$/1Mトークン） | 出力（$/1Mトークン） |
|---|---|---|---|
| o3-deep-research | $10.00 | $2.50 | $40.00 |
| o4-mini-deep-research | $2.00 | $0.50 | $8.00 |

- コンテキストウィンドウ: 両モデルとも200,000トークン、最大出力100,000トークン。

**Web検索ツール自体の課金**（`developers.openai.com/api/docs/pricing` より）
- 推論モデル（`gpt-5`、o-series等）向け `web_search_preview`: **$10.00 / 1,000呼び出し** ＋ 検索コンテンツトークンはモデルのトークン単価で別途課金。
- 非推論モデル向け `web_search_preview`: $25.00 / 1,000呼び出し（この場合、検索コンテンツトークンは無料）。

Deep Researchモデルはo系推論モデルのため前者（$10/1,000呼び出し + トークン従量課金）が適用されると考えられるが、公式ページ上でDeep Research専用の明示的な区分記載は確認できなかった（不確か）。

1回のDeep Researchリクエストあたりの想定トークン消費量・コスト目安について、公式ドキュメント上に具体的な数値例は見つからなかった。二次情報（CometAPI等）では「$10〜$40/1000コール」等の記載があったが、公式のトークン単価表からの推定値とみられ、一次情報としては確認できていない。

### 4. 事前準備・実行制約

**レート制限**（公式モデルページより、デフォルトのUsage Tier別）

o3-deep-research:
| Tier | RPM | TPM | バッチキュー制限 |
|---|---|---|---|
| Tier 1 | 500 | 200,000 | 200,000 |
| Tier 2 | 5,000 | 450,000 | 300,000 |
| Tier 3 | 5,000 | 800,000 | 500,000 |
| Tier 4 | 10,000 | 2,000,000 | 2,000,000 |
| Tier 5 | 10,000 | 30,000,000 | 10,000,000 |

o4-mini-deep-research:
| Tier | RPM | TPM | バッチキュー制限 |
|---|---|---|---|
| Tier 1 | 1,000 | 200,000 | 200,000 |
| Tier 2 | 2,000 | 2,000,000 | 300,000 |
| Tier 3 | 5,000 | 4,000,000 | 500,000 |
| Tier 4 | 10,000 | 10,000,000 | 2,000,000 |
| Tier 5 | 30,000 | 150,000,000 | 10,000,000 |

利用ティアはAPI利用量・支払い実績に応じて自動的に上昇する一般的なOpenAI APIの階層制度であり、Deep Research専用の申請・審査プロセスがあるという記載は公式ドキュメント上で確認できなかった。

**実行時間**
公式ガイドでは「Deep Researchモデルはエージェント的で多段階の調査を行うため、完了まで数十分かかることがある」とされている。具体的な上限時間（タイムアウト値）は明記されていないが、SDK利用時は `timeout=3600`（1時間）など長めのタイムアウト設定が公式サンプルで推奨されている。

**非同期実行の要否**
`background: true` は必須ではなく同期実行も可能だが、長時間タスクのため公式ドキュメントは`background: true`とWebhook併用を強く推奨している。ただし `background: true` は Zero Data Retention（ZDR）設定と非互換であり、ZDR組織では省略が必要という注記がある。

**その他の準備事項**
- `max_tool_calls` パラメータでツール呼び出し回数の上限を設定し、コスト・実行時間を抑制することが推奨されている。
- `web_search_preview` などのデータソースツールを最低1つ指定しないとリクエストが成立しない。

### 5. 公式情報で確認できなかった項目

- **1回のリクエストあたりの想定トークン消費量・コスト目安の具体的な公式数値**：公式ドキュメント・料金ページに明示的な記載は見当たらなかった。二次情報（CometAPI、aibase等）では目安が示されていたが一次情報としては確認できていない。
- **Deep Researchツール呼び出し（web_search_preview）料金区分がo系推論モデルの区分に該当するかの明示的な記載**：文脈上はo系推論モデルなので推論モデル向け区分が適用されると推測されるが、明示的な紐付け記載は見つけられなかった。
- **専用の利用ティア制限や事前審査の要否**：一般的なOpenAI APIのUsage Tier制度に従うとみられるが、Deep Research専用の追加審査プロセスがあるかどうかは公式ドキュメント上で明示的な記載を見つけられなかった。
- **タイムアウトの具体的な上限秒数**：「数十分かかることがある」という記述はあるが、システム側のハードなタイムアウト上限値は公式ドキュメントに明記されていなかった。

検索に使用した主なクエリ：「OpenAI deep research API o3-deep-research platform.openai.com」「OpenAI "deep research" API model id pricing site:openai.com」「"deep research" API rate limit tier background webhooks OpenAI community developer」。いずれも上記の公式ソースに到達でき、Deep Research APIの存在自体は明確に確認できたが、上記4点の詳細な数値は非公式記事以外で裏付けが取れなかった。

---

### 参照した情報源URL

- https://developers.openai.com/api/docs/guides/deep-research （platform.openai.com/docs/guides/deep-research からリダイレクト、公式）
- https://developers.openai.com/cookbook/examples/deep_research_api/introduction_to_deep_research_api （cookbook.openai.com からリダイレクト、公式Cookbook）
- https://developers.openai.com/cookbook/examples/deep_research_api/introduction_to_deep_research_api_agents （公式Cookbook、Agents SDK版）
- https://developers.openai.com/api/docs/models/o3-deep-research （公式モデルページ）
- https://developers.openai.com/api/docs/models/o4-mini-deep-research （公式モデルページ）
- https://developers.openai.com/api/docs/pricing （公式料金ページ）
- https://community.openai.com/t/deep-research-in-the-api-webhooks-and-web-search-with-o3/1299919 （OpenAI公式Developer Community告知投稿）
- https://community.openai.com/t/facing-rate-limit-issues-with-o4-mini-deep-research-model/1343078 （Developer Communityでのユーザー報告、参考情報）
- https://www.aibase.com/news/19300 （二次情報、参考として使用のみ、料金目安の記述に注意）
- https://www.cometapi.com/o3-deep-research-api/ （二次情報、参考として使用のみ）
