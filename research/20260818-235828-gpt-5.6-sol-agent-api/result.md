## 出力

### 1. マルチターン自律ツール呼び出しループの説明有無、および実現手段

公式の `developers.openai.com/api/docs/models/gpt-5.6-sol` モデルページには「Supported tools」として `web_search, file_search, image_generation, code_interpreter, hosted_shell, apply_patch, skills, computer_use, mcp, tool_search` が列挙されているが、`deep_research` という専用ツール名や「エージェントループ」「自動継続」に関する記述は確認できなかった。

一方、Responses API自体の位置づけとして、公式ブログ「Why we built the Responses API」（developers.openai.com/blog/responses-api）は「The Responses API is an agentic loop, allowing the model to call multiple tools...within the span of one API request」と説明しているが、この記事内には**ループの自動継続の仕組みそのものを具体的に説明したコード例は含まれていなかった**。

より詳細な仕組みは `developers.openai.com/api/docs/guides/agents`（Agents SDKガイド）と `developers.openai.com/api/docs/guides/function-calling`（Function calling ガイド）で確認できた。結論として、

- **組み込み（ホスト型）ツール**（`web_search`, `file_search`, `code_interpreter`, `mcp` など）は、Responses APIのサーバー側で実行され、1回のAPIリクエスト内で複数回自動的に呼び出される。
- **カスタムfunction calling**（開発者が定義する独自関数）は自動継続されず、Agentsガイドの説明の通り「Your application receives function calls, executes them, returns their output, and calls the model again」という形で、**呼び出し側が手動でループを実装する必要がある**。
- Agents SDK（`openai-agents`）は、複数エージェントの使い分けや「the SDK to manage the agent loop and recurring orchestration such as repeated tool calls or branching」が必要な場合に推奨される、Responses APIより上位の別レイヤーのフレームワークである。Responses API単体でも `web_search` 等のホスト型ツールに限れば1リクエスト内でエージェント的ループは成立するが、Agents SDKはそれをより高度に抽象化・管理するものであり、必須ではない。

`gpt-5.6-sol` を明示的な主語として上記の仕組みを解説した公式記述は見つからなかった（Function callingガイドのサンプルコードは `model="gpt-5.6"` を使用しており、`gpt-5.6-sol` 固有の記載ではない）。

### 2. 具体的なAPI呼び出し方法

公式ドキュメント（`developers.openai.com/api/docs/guides/function-calling`）に掲載されているサンプル（Responses API、エンドポイントは `POST https://api.openai.com/v1/responses` 相当、Python SDK経由）は以下の通り。

```python
# ステップ1〜2: ツール定義付きでリクエスト、モデルがtool callを返す
response = client.responses.create(
    model="gpt-5.6",
    input=input_list,
    tools=tools
)

# ステップ3〜4: アプリ側でツールを実行し、結果を送り返す
for item in response.output:
    if item.type == "function_call":
        sign = json.loads(item.arguments)["sign"]
        horoscope = get_horoscope(sign)

        input_list.append({
            "type": "function_call_output",
            "call_id": item.call_id,
            "output": horoscope
        })

# ステップ5: 最終応答を取得
response = client.responses.create(
    model="gpt-5.6",
    tools=tools,
    input=input_list
)
```

Deep Research用の旧サンプル（`developers.openai.com/cookbook/examples/deep_research_api/introduction_to_deep_research_api`、ただし`o3-deep-research`ベースで`gpt-5.6-sol`への言及なし）は以下の形式。

```python
response = client.responses.create(
  model="o3-deep-research-2025-06-26",
  input=[...],
  reasoning={"summary": "auto"},
  tools=[{"type": "web_search_preview"}]
)
```

curl形式のサンプルコードは、参照した公式ページ内には掲載されていなかった。

### 3. 「1回のAPI呼び出しで自動継続」か「手動ループ」か

ツール種別により挙動が異なることが公式ガイドから確認できた。

- **ホスト型ツール（`web_search`, `file_search`, `code_interpreter`, `mcp` 等）**：Responses APIが1回のリクエスト内でサーバー側で複数回自動的に呼び出しを継続する（＝クライアントが都度結果を送り返す必要はない）。
- **カスタムfunction calling**：モデルがツール呼び出しを要求した時点でAPI応答が一旦返り、開発者（クライアント）が実行結果を `function_call_output` として次のリクエストの `input` に追加し、再度APIを呼び出す必要がある（手動ループ）。これはFunction callingガイドの「five high level steps」として明記されている。

`gpt-5.6-sol` が `web_search` などのホスト型ツールのみを使う場合は、原理上1リクエスト内で自動継続するエージェント的ループが成立すると考えられるが、これを `gpt-5.6-sol` に固有の挙動として明示した公式記述は確認できなかった。

### 4. Deep Research用途の専用パラメータ（`reasoning.effort`、`max_tool_calls` 等）

`gpt-5.6-sol` に紐づけて `reasoning.effort` や `max_tool_calls` の推奨値を記載した公式ドキュメントは見つからなかった。参照した唯一のDeep Research公式サンプル（cookbook記事）は依然として `o3-deep-research-2025-06-26` / `o4-mini-deep-research-2025-06-26` をモデルとして使用しており、パラメータも `reasoning.summary`（`"auto"` または `"detailed"`）と `require_approval: "never"`（MCPツール用）のみが記載されていた。`gpt-5.6-sol` への言及、および `reasoning.effort` や `max_tool_calls` という語自体、このページには存在しなかった。

### 5. 確認できなかった項目・情報源間の矛盾

- `gpt-5.6-sol` を主語として「エージェントループの自動継続」を明示的に解説した公式ページは見つからなかった。
- Deep Research用途向けの `gpt-5.6-sol` 専用パラメータ（`reasoning.effort`、`max_tool_calls`）は、参照した公式cookbook記事・モデルページのいずれにも記載がなく、確認できなかった。
- Deep Research公式cookbook記事（`developers.openai.com/cookbook/examples/deep_research_api/introduction_to_deep_research_api`）が依然として `o3-deep-research` を用いた内容のままであり、`gpt-5.6-sol` への移行に関する更新がされていない状態を確認した。これは以前の調査で判明していた「モデル個別ページ・Deep Researchガイドページで旧モデルが依然として現行として案内されている」という矛盾と整合する。
- `openai.com/index/previewing-gpt-5-6-sol/` は取得時にHTTP 403 Forbiddenとなり、内容を直接確認できなかった。検索結果のスニペット（サードパーティ記事経由）では「embedded autonomous reasoning loop」「multi-agent architecture」といった記述が見られたが、これは二次情報源（mlhive.com、rpabotsworld.com等）経由であり、公式記述として直接確認できたものではない。
- 検索クエリ `"gpt-5.6-sol" deep research agent loop` の結果は大半が非公式ブログ（kie.ai、explainx.ai、mlhive.com、rpabotsworld.com等）であり、公式情報として採用しなかった。

## 参照した情報源URL

- https://developers.openai.com/api/docs/models/gpt-5.6-sol
- https://developers.openai.com/blog/responses-api
- https://developers.openai.com/api/docs/guides/agents
- https://developers.openai.com/api/docs/guides/function-calling
- https://developers.openai.com/cookbook/examples/deep_research_api/introduction_to_deep_research_api
- https://openai.com/index/previewing-gpt-5-6-sol/（403のため内容未確認、検索結果スニペットのみ参照）
- https://openai.github.io/openai-agents-python/（検索結果として言及、直接内容取得はしていない）
- https://platform.openai.com/docs/guides/migrate-to-responses（検索結果として言及、直接内容取得はしていない）

(参考・二次情報源、公式情報とは区別)
- https://mlhive.com/2026/07/inside-gpt-5-6-sol-agentic-reasoning-release
- https://rpabotsworld.com/gpt-5-6-agent-builders-sol-terra-luna/
- https://9to5mac.com/2026/08/13/openai-previews-ultrafast-gpt-5-6-sol-running-up-to-14-times-faster/
