# 調査結果

> **調査基準日：2026年8月18日**
>
> **結論を先に述べると、OpenAIは「Deep research」として、多段階のWeb検索・情報分析・レポート生成を行うAPI機能を提供している。**  
> ただし、`/v1/deep-research` のような専用エンドポイントが存在するわけではない。公式な実装方式は、**Responses APIにDeep research向けモデルと検索ツールを指定する**というものである。
>
> なお、専用モデル `o3-deep-research` と `o4-mini-deep-research` は現在も公式ガイドとモデルページに掲載されている一方、全モデル一覧では **Deprecated（非推奨・廃止予定）** と表示されている。日付付きスナップショットは2026年7月23日に停止済みであり、OpenAIは新規実装の移行先として `gpt-5.6-sol` を案内している。したがって、新規の長期運用システムでは専用モデルを固定的に組み込むべきではない。 ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

---

## 1. OpenAIのDeep Research API/機能が存在するか、正式名称

### 正式名称

公式ドキュメント上の名称は **Deep research** である。

これは独立したAPI製品や専用URLではなく、次の組み合わせで構成される機能である。

1. Responses API
2. Deep research向けモデル
3. Web検索、File SearchまたはRemote MCPなどの情報源
4. 必要に応じてCode Interpreter
5. 長時間処理を安定して実行するためのBackground mode

公式ガイドでは、Deep researchモデルについて「数百の情報源を検索・分析・統合し、リサーチアナリスト水準の包括的なレポートを生成できるモデル」と説明されている。 ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

### 2026年8月18日時点の状態

状態は次のように整理できる。

| 項目 | 状態 |
|---|---|
| Deep research機能・公式ガイド | 存在する |
| Deep research専用APIエンドポイント | 存在しない |
| `o3-deep-research` エイリアス | 公式ページ上は利用仕様・料金・レート制限が掲載されているが、モデル一覧ではDeprecated |
| `o4-mini-deep-research` エイリアス | 同上 |
| `o3-deep-research-2025-06-26` | 2026年7月23日に停止済み |
| `o4-mini-deep-research-2025-06-26` | 2026年7月23日に停止済み |
| OpenAIが案内する移行先 | `gpt-5.6-sol` |

OpenAIの用語では、**Deprecatedは直ちに利用不能という意味ではなく、廃止プロセスに入った状態**を意味する。実際にアクセス不能になる時点はshutdown dateである。ただし、日付付きDeep researchスナップショットはすでに停止している。エイリアスについては公式ガイドと個別モデルページが残っているが、新規システムでの長期利用には注意が必要である。 ([developers.openai.com](https://developers.openai.com/api/docs/deprecations))

---

## 2. 対応モデル名

公式Deep researchガイドに記載されている専用モデルIDは次の2つである。

| モデルID | 位置付け | 2026年8月18日時点の注意点 |
|---|---|---|
| `o3-deep-research` | 高性能なDeep researchモデル | モデル一覧ではDeprecated |
| `o4-mini-deep-research` | 高速・低価格なDeep researchモデル | モデル一覧ではDeprecated |

両モデルとも以下の仕様を持つ。

- コンテキストウィンドウ：200,000トークン
- 最大出力：100,000トークン
- 知識カットオフ：2024年6月1日
- テキスト入出力：対応
- 画像入力：対応
- 音声・動画：非対応
- Function calling：非対応
- Structured Outputs：非対応
- Fine-tuning：非対応
- Streaming：対応 ([developers.openai.com](https://developers.openai.com/api/docs/models/o3-deep-research))

### 日付付きスナップショット

以前は次の固定スナップショットも存在した。

```text
o3-deep-research-2025-06-26
o4-mini-deep-research-2025-06-26
```

しかし、これらは**2026年7月23日にAPIから停止済み**である。現在の実装でこれらをハードコードしてはならない。公式の廃止表では、当該スナップショットからエイリアスを経たうえで、最終的な推奨移行先として `gpt-5.6-sol` が示されている。 ([developers.openai.com](https://developers.openai.com/api/docs/deprecations))

### `gpt-5.6-sol` との関係

`gpt-5.6-sol` は現在のフロンティアモデルで、Web Search、File Search、Function toolsなどに対応し、Deep researchモデルの移行先として案内されている。

ただし、公式Deep researchガイドが定義する従来型ワークフローは、依然として `o3-deep-research` または `o4-mini-deep-research` を指定する形で記載されている。そのため、以下は区別すべきである。

- **従来の専用Deep researchモデルによる実行**
  - `o3-deep-research`
  - `o4-mini-deep-research`
- **現在の汎用フロンティアモデルを使ったDeep research相当の実装**
  - 例：`gpt-5.6-sol` + Responses API + Web Search +高いreasoning設定

後者は専用モデルではなく、汎用モデルとツールを組み合わせて多段階リサーチを行う構成である。 ([developers.openai.com](https://developers.openai.com/api/docs/models?utm_source=openai))

---

## 3. APIエンドポイント

### Deep researchで使用するエンドポイント

公式Deep researchガイドが指定するエンドポイントは、Responses APIである。

```http
POST https://api.openai.com/v1/responses
```

Background modeで開始した処理をポーリングする場合は次を使用する。

```http
GET https://api.openai.com/v1/responses/{response_id}
```

初回の `POST /v1/responses` は、専用の「ジョブ作成API」ではなく、通常のResponses API呼び出しである。`background: true` を付けると、そのResponseオブジェクトが非同期ジョブのように振る舞う。状態が `queued` または `in_progress` の間は取得を繰り返し、`completed` などの終端状態になるまで待機する。 ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

### Chat Completions APIについて

個別モデルページの一般的なエンドポイント互換表には、次も表示されている。

```http
POST /v1/chat/completions
```

しかし、公式Deep researchガイドは明確に、Deep researchを実行するには**Responses APIを使う**よう要求している。また、Deep researchに必要なWeb Search、File Search、Remote MCP、Background mode、途中のツール実行履歴などを統合的に扱うのもResponses APIである。 ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

したがって、実装上の結論は次のとおりである。

- モデルページ上の一般的な互換表示：Chat Completionsも記載される
- **Deep researchワークフローとして正式に使用するAPI：Responses API**
- Chat Completionsで単にモデルIDを指定するだけでは、公式ガイドが定義するDeep research実行とはみなすべきでない

---

## 4. リクエストの主要パラメータ

### 最小構成

Deep researchとして呼び出すには、少なくとも次が必要である。

- `model`
- `input`
- `tools`
- `tools` 内に最低1つの情報源

公式ガイドでは、以下のいずれか最低1つを指定することが必須とされている。

- Web Search
- File Search + Vector Store
- Remote MCP server

Code Interpreterは分析用の追加ツールであり、単独では検索情報源の代わりにならない。 ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

### 基本的なリクエスト例

```json
{
  "model": "o3-deep-research",
  "input": "OpenAIのDeep research APIの仕様と料金を、公式情報だけを使って調査し、日本語のMarkdownレポートとしてまとめてください。",
  "background": true,
  "tools": [
    {
      "type": "web_search_preview"
    }
  ]
}
```

エンドポイントは次である。

```http
POST /v1/responses
```

### 主要パラメータ一覧

| パラメータ | 必須性 | 内容 |
|---|---:|---|
| `model` | 必須 | `o3-deep-research` または `o4-mini-deep-research` |
| `input` | 必須 | 調査プロンプト。文字列またはResponses APIの入力項目配列 |
| `instructions` | 任意 | レポート形式、優先ソース、禁止事項などの上位指示 |
| `tools` | 実質必須 | 最低1つの検索・データソースを指定 |
| `background` | 任意・強く推奨 | `true` で非同期バックグラウンド実行 |
| `max_tool_calls` | 任意 | Web検索・MCP等の総ツール呼び出し回数を制限 |
| `reasoning.summary` | 任意 | 推論過程の要約生成。例：`"auto"` |
| `max_output_tokens` | 任意 | 最大出力トークン数 |
| `store` | 任意 | Responseの保存方法に関係する通常のResponses APIパラメータ |

### Web Search

公式Deep researchガイドのサンプルでは次を使用している。

```json
{
  "type": "web_search_preview"
}
```

2026年時点の一般的なResponses APIでは `web_search` も存在するが、専用Deep researchガイドのコード例は `web_search_preview` を使用している。互換性を重視して従来の専用モデルを使う場合は、公式ガイドと同じ指定を採用するのが安全である。 ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

### File Search

社内資料などをVector Storeから検索する場合は次のように指定する。

```json
{
  "type": "file_search",
  "vector_store_ids": [
    "vs_..."
  ]
}
```

### Code Interpreter

検索結果をPython等で集計・計算・分析させる場合は次を追加できる。

```json
{
  "type": "code_interpreter",
  "container": {
    "type": "auto"
  }
}
```

### Remote MCP

外部・社内データソースをMCP経由で検索する場合は次のように指定する。

```json
{
  "type": "mcp",
  "server_label": "internal_research",
  "server_url": "https://example.com/mcp",
  "require_approval": "never"
}
```

Deep research向けMCPには通常の任意ツールではなく、以下のインターフェースが必要である。

- `search`：検索クエリを受け取り、検索結果を返す
- `fetch`：検索結果IDを受け取り、文書本体を返す

また、Deep researchではMCPの承認設定を次にする必要がある。

```json
{
  "require_approval": "never"
}
```

人間による都度承認は現在サポートされていない。 ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

### Background mode

```json
{
  "background": true
}
```

これは**必須ではない**が、公式ドキュメントでは強く推奨されている。`false` または省略でも実行できるが、HTTP接続やSDKのタイムアウトを十分長く設定する必要がある。 ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

### `max_tool_calls`

```json
{
  "max_tool_calls": 50
}
```

Deep researchのコストと待ち時間を抑える主要な制御パラメータである。指定値は、Web SearchやMCPなどの総ツール呼び出し回数の上限として働く。 ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

### Reasoning設定

公式Deep researchガイドでは、次のような推論要約の指定例がある。

```json
{
  "reasoning": {
    "summary": "auto"
  }
}
```

一方、次のような推論量の指定は、一般的な推論モデルでは利用できる。

```json
{
  "reasoning": {
    "effort": "high"
  }
}
```

ただし、**Deep research専用モデルの公式ガイドでは `reasoning.effort` の対応値が明示されておらず、サンプルも `summary` のみを指定している**。個別モデルページも「configurable reasoning effort」とは説明していない。

したがって、`o3-deep-research` / `o4-mini-deep-research` については次の扱いが安全である。

- `reasoning.summary`: 公式例あり
- `reasoning.effort`: モデル固有の対応範囲が公式Deep researchガイドに明記されていない
- 実装上は必須にせず、使用前に対象プロジェクト・モデルで検証する
- 推論量を明示的に制御したい新規実装では、`gpt-5.6-sol` 等の現行モデルを検討する

### サポートされないツール・機能

Deep research専用モデルでは、次がサポートされない。

- Function calling
- 任意の独自function tool
- Search/Fetch型でない一般的なRemote MCPツール
- Structured Outputs
- Fine-tuning

対応ツールは基本的に次に限定される。

- Web Search
- File Search
- Remote MCPのSearch/Fetch
- Code Interpreter ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

---

## 5. レスポンス形式の特徴

### 基本形式

レスポンス自体は、通常のResponses APIと同じResponseオブジェクトである。

重要なのは `output` 配列で、最終回答だけでなく、調査中に行われたツール実行も含まれる。代表的な出力項目は次のとおりである。

| `type` | 内容 |
|---|---|
| `web_search_call` | Web検索、ページ表示、ページ内検索など |
| `file_search_call` | Vector Store上のファイル検索 |
| `mcp_tool_call` | Remote MCPの検索・取得 |
| `code_interpreter_call` | Code Interpreterによるコード実行 |
| `message` | 最終回答 |
| `reasoning` | 利用可能な場合の推論要約等 |

Web Searchの出力には、単なる「検索した」という記録だけでなく、次のようなアクション種別が含まれる。

- `search`
- `open_page`
- `find_in_page` ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

### 引用・出典情報

最終回答は通常、`message.content[]` 内の `output_text` として返される。

```json
{
  "type": "message",
  "content": [
    {
      "type": "output_text",
      "text": "...引用付きの最終回答...",
      "annotations": [
        {
          "url": "https://example.com/source",
          "title": "Source title",
          "start_index": 123,
          "end_index": 145
        }
      ]
    }
  ]
}
```

主なフィールドは次のとおりである。

| フィールド | 意味 |
|---|---|
| `text` | 最終回答本文 |
| `annotations[].url` | 引用元URL |
| `annotations[].title` | 引用元ページのタイトル |
| `annotations[].start_index` | 引用が対応する本文範囲の開始位置 |
| `annotations[].end_index` | 引用が対応する本文範囲の終了位置 |

ユーザー向けUIでは、これらの引用を**明確に表示し、クリック可能にすること**が公式に求められている。 ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

### Background mode時の状態

バックグラウンド実行では、Responseオブジェクトの `status` が変化する。

代表例：

```text
queued
in_progress
completed
failed
cancelled
```

ポーリングでは、`queued` または `in_progress` の間は待機を続ける。

```http
GET /v1/responses/{response_id}
```

`completed` になった後、`output` またはSDKの `output_text` ヘルパーから結果を取り出す。Webhookの `response.completed` イベントを利用して完了通知を受け取ることもできる。 ([developers.openai.com](https://developers.openai.com/api/docs/guides/background))

---

## 6. 料金体系

以下は2026年8月18日時点で個別モデルページに掲載されている標準価格である。単位はすべて米ドル。

### 6.1 モデルのトークン料金

#### 100万トークン当たり

| モデル | 入力 | キャッシュ入力 | 出力 |
|---|---:|---:|---:|
| `o3-deep-research` | $10.00 | $2.50 | $40.00 |
| `o4-mini-deep-research` | $2.00 | $0.50 | $8.00 |

`o4-mini-deep-research` は、`o3-deep-research` の5分の1のトークン単価である。 ([developers.openai.com](https://developers.openai.com/api/docs/models/o3-deep-research))

### 6.2 Web Search料金

Deep research専用モデルは推論モデルに該当するため、`web_search_preview` の料金は次の構成になる。

| 課金項目 | 料金 |
|---|---:|
| Web Search tool call | $10.00 / 1,000 calls |
| 1回当たり換算 | $0.01 / call |
| 検索結果としてモデルに渡されたテキスト | 使用モデルの入力トークン単価で別途課金 |

したがって、Web検索1回の料金は単純な1セントだけではない。

概念的には次の合計となる。

```text
合計料金
= ユーザー入力等の入力トークン料金
+ 検索コンテンツの入力トークン料金
+ モデル出力・推論トークン料金
+ Web Search呼び出し回数料金
```

特にDeep researchでは何度も検索・ページ表示を行うため、Web Searchの呼び出し料金だけでなく、取得した大量の検索コンテンツが入力トークンとして課金される点に注意が必要である。 ([developers.openai.com](https://developers.openai.com/api/docs/pricing))

### 6.3 File Search料金

| 項目 | 料金 |
|---|---:|
| Vector Storeストレージ | $0.10 / GB / 日 |
| 無料枠 | 1 GB |
| File Search tool call | $2.50 / 1,000 calls |

File Searchでモデルに渡されたコンテンツに関するトークンは、選択したモデルのトークン料金の対象となる。 ([developers.openai.com](https://developers.openai.com/api/docs/pricing))

### 6.4 Code Interpreter料金

2026年8月時点では、Code Interpreterを含むコンテナ料金は20分単位で次のとおりである。

| コンテナ容量 | 20分セッション当たり |
|---:|---:|
| 1 GB | $0.03 |
| 4 GB | $0.12 |
| 16 GB | $0.48 |
| 64 GB | $1.92 |

Code Interpreterを指定しなければ、このコンテナ料金は発生しない。 ([developers.openai.com](https://developers.openai.com/api/docs/pricing))

### 6.5 Remote MCP料金

OpenAIの一般料金表には、Remote MCP呼び出しに対する独立した「MCP tool call料金」は掲載されていない。

ただし、次の費用は発生し得る。

- MCPからモデルへ渡されたデータに伴う入力トークン料金
- MCPサーバー運営者側の独自料金
- 自社MCPサーバーのインフラ費用

したがって、「MCPは完全に無料」という意味ではなく、**OpenAI料金表にWeb SearchやFile SearchのようなMCP専用の呼び出し単価が明記されていない**という意味である。

### 6.6 Background mode・Webhook料金

公式料金表には、以下に対する独立した追加料金は掲載されていない。

- `background: true`
- Responseのポーリング
- Webhook通知

課金の中心はモデルのトークン、検索ツール、File Search、コンテナ等である。

### 6.7 コスト制御で重要なパラメータ

Deep researchでは次の指定が最も直接的なコスト制御となる。

```json
{
  "max_tool_calls": 30
}
```

ただし、これはツール呼び出し回数を制限するものであり、出力トークン数を直接制限するものではない。出力も制限したい場合は、通常のResponses APIと同様に `max_output_tokens` を併用する。 ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

---

## 7. 通常のResponses API／Chat Completions APIとの違い

### 比較表

| 項目 | 一般的なモデル呼び出し | Deep research専用モデル |
|---|---|---|
| API | ResponsesまたはChat Completions | **Responses APIが公式方式** |
| モデル | 任意の対応モデル | `o3-deep-research` / `o4-mini-deep-research` |
| 検索ツール | 任意 | Web Search、File Search、MCPの最低1つが必要 |
| 専用エンドポイント | なし | なし |
| 実行形態 | 通常は同期でも十分 | Background modeを強く推奨 |
| 非同期実行 | 任意 | 必須ではないが実運用上ほぼ推奨 |
| 実行時間 | 数秒程度のことが多い | 数分から数十分 |
| 出力 | 主に最終回答 | 検索、ページ表示、MCP、コード実行、最終回答 |
| 引用 | 必ずしも付かない | Web検索結果への引用annotationsを含む |
| Function calling | 多くの汎用モデルで対応 | 非対応 |
| Structured Outputs | 多くの現行モデルで対応 | 非対応 |
| `max_tool_calls` | 必要に応じて使用 | コスト・時間制御上、特に重要 |
| 明確化質問 | モデル次第 | API版Deep researchは自動で行わない |
| プロンプト書き換え | 通常は行われない | API版にはChatGPT版の自動書き換え工程がない |

### 専用モデルが必要か

従来の公式Deep research機能をそのまま使用する場合は、専用モデルが必要である。

```text
o3-deep-research
o4-mini-deep-research
```

ただし、これらはDeprecatedである。新規実装では、現行のフロンティアモデルとWeb Searchを組み合わせてDeep research相当のエージェントを構成する方法も検討すべきである。

### 専用のツール指定が必要か

必要である。公式ガイドでは、最低1つのデータソースを含めることが要求されている。

有効な例：

```json
{
  "tools": [
    {
      "type": "web_search_preview"
    }
  ]
}
```

無効またはDeep researchとして不十分な例：

```json
{
  "model": "o3-deep-research",
  "input": "調査してください"
}
```

上記には検索情報源がない。

### 非同期実行は必須か

**API仕様上は必須ではない。**

同期的に待機することもできる。ただし公式ガイドでは、Deep researchは数十分かかることがあり、接続切断やHTTPタイムアウトを避けるためBackground modeを強く推奨している。

`background` を使わない場合は、SDKクライアントのタイムアウトを十分に長くする必要がある。公式サンプルでは1時間のタイムアウト設定例も示されている。 ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

### Background modeは必要か

- 必須：いいえ
- 推奨：はい
- 本番環境：原則として利用すべき

推奨構成は次のいずれかである。

1. `background: true` + ポーリング
2. `background: true` + Webhook
3. 必要に応じて途中からストリーミングを再開

### 実行時間の目安

公式ガイドでは、Deep researchモデルは**数十分かかり得る**としている。

短い質問であっても、モデルが次の処理を自律的に繰り返すため、一般的なテキスト生成より大幅に遅くなる可能性がある。

1. 検索クエリの作成
2. Web検索
3. ページの表示
4. ページ内検索
5. 別の検索クエリへの展開
6. 情報間の矛盾確認
7. 必要に応じたコード分析
8. レポート生成 ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

### ChatGPT版Deep Researchとの違い

ChatGPT版は通常、次の3段階で処理する。

1. ユーザー意図の確認・明確化
2. 調査用プロンプトへの書き換え
3. Deep researchモデルでの調査

API版は、このうち1と2を自動では実行しない。Deep researchモデルは不足情報を自分から質問せず、渡されたプロンプトですぐ調査を開始する。

したがって、API統合側で以下を実装するのが望ましい。

- 不足条件の検出
- 必要に応じたユーザーへの確認質問
- 調査プロンプトの具体化
- 出力形式、対象期間、地域、優先ソースの明示

この点は、リサーチスキルに組み込む際に特に重要である。 ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

---

## 8. レート制限や利用上の制約

### `o3-deep-research`

| Usage Tier | RPM | TPM | Batch queue limit |
|---:|---:|---:|---:|
| Free | 非対応 | 非対応 | 非対応 |
| Tier 1 | 500 | 200,000 | 200,000 |
| Tier 2 | 5,000 | 450,000 | 300,000 |
| Tier 3 | 5,000 | 800,000 | 500,000 |
| Tier 4 | 10,000 | 2,000,000 | 2,000,000 |
| Tier 5 | 10,000 | 30,000,000 | 10,000,000 |

([developers.openai.com](https://developers.openai.com/api/docs/models/o3-deep-research))

### `o4-mini-deep-research`

| Usage Tier | RPM | TPM | Batch queue limit |
|---:|---:|---:|---:|
| Free | 非対応 | 非対応 | 非対応 |
| Tier 1 | 1,000 | 200,000 | 200,000 |
| Tier 2 | 2,000 | 2,000,000 | 300,000 |
| Tier 3 | 5,000 | 4,000,000 | 500,000 |
| Tier 4 | 10,000 | 10,000,000 | 2,000,000 |
| Tier 5 | 30,000 | 150,000,000 | 10,000,000 |

([developers.openai.com](https://developers.openai.com/api/docs/models/o4-mini-deep-research))

### レート制限の意味

- **RPM**：Requests Per Minute。1分間のリクエスト数
- **TPM**：Tokens Per Minute。1分間に処理可能なトークン数
- **Batch queue limit**：Batch APIキューに置けるトークン量等の上限

実際の制限はアカウント、組織、プロジェクト、Usage Tierによって異なるため、ダッシュボードのLimits画面も確認する必要がある。

### 無料Tier

両方ともFree Tierではサポートされていない。

### Zero Data Retentionとの関係

Deep researchガイドでは、Background modeはポーリングを可能にするためレスポンスデータを約10分保持し、ZDRとの互換性に注意が必要とされている。

一般Background modeドキュメントでは、ZDRプロジェクトでも `store=false` として一時保存される仕様が説明されている。一方、Deep researchガイドは、厳密なZDRが必要なら `background` を無効にするよう案内している。実運用では、組織に適用されている最新のデータ保持契約・設定を確認すべきである。 ([developers.openai.com](https://developers.openai.com/api/docs/guides/deep-research))

### MCPの制約

- MCPサーバーは `search` と `fetch` を実装する必要がある
- `require_approval` は `never`
- 任意の副作用を伴うMCPツールはDeep research専用モデルでは利用できない
- 外部データとWebデータを同時に使う場合、プロンプトインジェクションとデータ流出に注意が必要

### その他の制約

- Function calling非対応
- Structured Outputs非対応
- Fine-tuning非対応
- 音声・動画非対応
- 日付付きDeep researchスナップショットは停止済み
- 専用モデルエイリアスもDeprecatedであるため、将来の停止に備えたモデル切替機構が必要

---

## 9. 参照した情報源のURL一覧

以下はすべてOpenAI公式ドキュメントまたはOpenAI公式サイトである。

1. **Deep researchガイド**  
   https://developers.openai.com/api/docs/guides/deep-research

2. **`o3-deep-research` モデル仕様**  
   https://developers.openai.com/api/docs/models/o3-deep-research

3. **`o4-mini-deep-research` モデル仕様**  
   https://developers.openai.com/api/docs/models/o4-mini-deep-research

4. **OpenAI API料金表**  
   https://developers.openai.com/api/docs/pricing

5. **全モデル一覧**  
   https://developers.openai.com/api/docs/models/all

6. **Background mode**  
   https://developers.openai.com/api/docs/guides/background

7. **Webhooks**  
   https://developers.openai.com/api/docs/guides/webhooks

8. **Reasoning models**  
   https://developers.openai.com/api/docs/guides/reasoning

9. **APIの廃止・非推奨情報**  
   https://developers.openai.com/api/docs/deprecations

10. **Responses APIの新ツール・Background mode発表**  
    https://openai.com/index/new-tools-and-features-in-the-responses-api/

---

## agent-harnessの`research`スキルに対する実装上の推奨

今回の調査目的に即して整理すると、将来の実装は次のようにするのが安全である。

1. **APIクライアントはResponses APIを使う**
2. **`background: true` をデフォルトにする**
3. `POST /v1/responses` の戻り値からResponse IDを保存する
4. `GET /v1/responses/{id}` またはWebhookで完了を待つ
5. `output` 内の `message` だけでなく、引用annotationsも保存する
6. `max_tool_calls` を設定可能にする
7. モデルIDをコードに固定せず、設定ファイルまたは環境変数で切り替え可能にする
8. 従来互換モードとして `o3-deep-research` / `o4-mini-deep-research` を扱う
9. 新規デフォルト候補として `gpt-5.6-sol` + Web Searchによるリサーチ構成を評価する
10. `o3-deep-research-2025-06-26` 等の日付付きスナップショットは使用しない
11. APIに渡す前に、別モデルまたはClaude Code側で調査プロンプトの明確化・書き換えを行う
12. 最終的な `result.md` には、本文だけでなく出典URL・タイトルも正規化して保存する

特に重要なのは、**「Deep Research API」という独立したAPIを呼び出す設計ではなく、Responses API上で、モデル・検索ツール・Background modeを組み合わせる設計にすること**である。専用モデルが停止しても、汎用モデルと検索ツールへ差し替えられる抽象化が望ましい。
