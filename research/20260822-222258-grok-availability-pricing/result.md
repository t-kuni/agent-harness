1. **概要**

取得日時点: **2026-08-22（JST）**。  
Grok は、xAI の公式提供として **API、MCP関連機能、CLI** のいずれも確認できる。  
API は `https://api.x.ai/v1` の REST API / OpenAI互換APIとして提供され、モデル別の従量課金。  
MCP は「GrokをMCPサーバーとして呼ぶ」形ではなく、公式 **Docs MCPサーバー** と、Grokから外部MCPサーバーへ接続する機能がある。  
CLI は公式の **Grok Build CLI** があり、ターミナル上のAIコーディングエージェントとして使える。

2. **利用方式（API / MCP / CLI）**

| 利用方式 | 提供有無 | 概要 |
|---|---:|---|
| API | あり | 開発者向けAPI。`/v1/responses`、`/v1/chat/completions` などを使う。xAI公式は REST API を「OpenAI REST API互換」と説明しており、OpenAI SDKでも `base_url` を `https://api.x.ai/v1` に変えて利用できる。クイックスタートでは APIキー作成後、`curl https://api.x.ai/v1/responses` の例が示されている。([docs.x.ai](https://docs.x.ai/developers/rest-api-reference?utm_source=openai)) ([docs.x.ai](https://docs.x.ai/developers/quickstart)) |
| MCP | 部分的にあり | MCP（Model Context Protocol）は、AIが外部ツールやデータソースを統一的に使うためのプロトコル。xAI公式の **Docs MCP Server** は存在し、エンドポイントは `https://docs.x.ai/api/mcp`。これはxAIドキュメント参照用で、Grok推論APIそのものをMCPサーバー化したものではない。加えて Grok / xAI API は外部MCPサーバーに接続する **Custom MCP connectors / Remote MCP Tools** をサポートする。([docs.x.ai](https://docs.x.ai/developers/docs-mcp)) ([docs.x.ai](https://docs.x.ai/grok/connectors)) |
| CLI | あり | 公式CLIとして **Grok Build** が提供される。`curl -fsSL https://x.ai/cli/install.sh \| bash` で導入し、`grok` でTUI、`grok -p "..."` でヘッドレス実行ができる。CLIリファレンスには `grok login`、`grok models`、`grok mcp <list/add/remove/doctor>` などが掲載されている。([docs.x.ai](https://docs.x.ai/build/overview)) ([docs.x.ai](https://docs.x.ai/build/cli/reference)) |

3. **料金体系の詳細**

**サブスクリプション**

| プラン | 料金 | 主な内容 |
|---|---:|---|
| Free | $0/月 | Grokを無料枠で利用。リアルタイムWeb/X検索、Voice mode、Connectors 等が掲載されている。([x.ai](https://x.ai/pricing)) |
| SuperGrok | $30/月 | Grok 4.6、Connectors、全機能の高い利用上限、Expert、画像・動画生成など。([x.ai](https://x.ai/pricing)) |
| SuperGrok Plus | $100/月 | SuperGrokに加え、Grok Bot、1080p動画生成、Chat / Imagine / Voice / Build の大幅に高い利用量、ピーク時優先など。([x.ai](https://x.ai/pricing)) |
| SuperGrok Lite / SuperGrok Heavy | 公式価格ページ上に名称あり | 公開ページの比較表には名称があるが、取得時点のアクセス可能な本文では料金が明示されていない。([x.ai](https://x.ai/pricing)) |
| Business | $30/月/ユーザー | 小〜中規模チーム向け。Grok 4.6、Imagine、Voice、RBAC、チーム/シート管理、統合請求、No training、Connectors、Grok Build 等。([x.ai](https://x.ai/grok/business)) |
| Enterprise | 要問い合わせ | 大規模組織向け。SSO、SCIM、カスタムRBAC、監査、専用データプレーン、カスタマー管理暗号鍵、専用オンボーディング等。([x.ai](https://x.ai/grok/business)) |

補足: X Premium経由でもGrok利用上限が増える。X公式ヘルプでは、Premium が Grok の利用上限増加、Premium+ がさらに高いGrok上限を含むとし、米国Web価格は Basic $3/月 or $32/年、Premium $8/月 or $84/年、Premium+ $40/月 or $395/年から、としている。([help.x.com](https://help.x.com/en/using-x/x-premium))

**API従量課金**

用語: **トークン**はAIが処理するテキストの単位。**cached tokens** は以前の入力をキャッシュから再利用した分で、通常の入力より安い。**context** は一度に扱える入力長。

テキストAPIの主要モデル料金は以下。価格は **100万トークンあたりUSD**。長文コンテキストは、プロンプトがしきい値以上になると全トークンに長文料金が適用される。([docs.x.ai](https://docs.x.ai/developers/pricing))

| モデル | コンテキスト | 通常入力 | cached | 出力 | 長文入力 | 長文cached | 長文出力 |
|---|---:|---:|---:|---:|---:|---:|---:|
| `grok-4.6` | 500k | $2.00 | $0.50 | $6.00 | $4.00 | $1.00 | $12.00 |
| `grok-build-0.1` | 256k | $1.00 | $0.20 | $2.00 | $2.00 | $0.40 | $4.00 |
| `grok-4.5` | 500k | $2.00 | $0.30 | $6.00 | $4.00 | $0.60 | $12.00 |
| `grok-4.3` | 1M | $1.25 | $0.20 | $2.50 | $2.50 | $0.40 | $5.00 |
| `grok-4.20` 系 | 1M | $1.25 | $0.20 | $2.50 | $2.50 | $0.40 | $5.00 |

`Grok 4 Fast`、`Grok 4.1 Fast`、`grok-4-0709`、`grok-3` などは、公式移行ページで **2026-05-15以降 retired** とされ、現在は `grok-4.3` 等へリダイレクトされる。したがって、取得時点の現行料金表では `grok-4.3` 料金が実質的な参照先になる。([docs.x.ai](https://docs.x.ai/developers/migration/may-15-retirement))

画像・動画・音声APIの例:

| API | 料金例 |
|---|---|
| Imagine Image | `grok-imagine-image`: 入力画像 $0.002/枚、出力 $0.02/枚。`grok-imagine-image-2.0`: 入力画像 $0.01/枚、出力 $0.04〜$0.08/枚。([docs.x.ai](https://docs.x.ai/developers/pricing)) |
| Imagine Video | `grok-imagine-video`: 480p $0.05/秒、720p $0.07/秒。`grok-imagine-video-1.5`: 480p $0.08/秒、720p $0.14/秒、1080p $0.25/秒。([docs.x.ai](https://docs.x.ai/developers/pricing)) |
| Voice API | Speech-to-Speech 2.0 は $0.08/分 + テキスト入力 $0.004、Speech-to-Text は REST $0.10/時 / Streaming $0.20/時、Text-to-Speech は $15/100万文字。([docs.x.ai](https://docs.x.ai/developers/pricing)) |

ツール利用料金:

| ツール | 料金 |
|---|---:|
| Web Search / X Search / Code Execution | $5 / 1,000 calls |
| File Attachments | $10 / 1,000 calls |
| Collections Search | $2.50 / 1,000 calls |
| Remote MCP Tools | ツール呼び出し自体は課金されず、使用トークン分のみ課金 |

Remote MCP Tools は、外部MCPサーバーのツールをGrokから使う機能で、課金はトークンベースと明記されている。([docs.x.ai](https://docs.x.ai/developers/pricing))

無料枠について:

- Grokアプリ/サイトには **Free $0/月** プランがある。
- APIは無料Consoleアカウントと無料Playgroundはあるが、実API利用は通常、プリペイドクレジットまたは月次請求で支払う方式。Quickstart でも「アカウント作成後、creditsをロードしてAPIを使う」と説明されている。([x.ai](https://x.ai/api?utm_source=openai)) ([docs.x.ai](https://docs.x.ai/developers/quickstart))
- 2024年のAPI Public Betaでは $25/月の無料APIクレジットがあったが、公式記事上では「2024年末まで」のプログラムとして説明されており、取得時点の恒常無料API枠とは扱わない。([x.ai](https://x.ai/news/api?utm_source=openai))

4. **参照した情報源のURL一覧**

- https://x.ai/pricing
- https://x.ai/grok/business
- https://x.ai/api
- https://docs.x.ai/developers/quickstart
- https://docs.x.ai/developers/models
- https://docs.x.ai/developers/pricing
- https://docs.x.ai/developers/docs-mcp
- https://docs.x.ai/grok/connectors
- https://docs.x.ai/build/overview
- https://docs.x.ai/build/cli/reference
- https://docs.x.ai/developers/migration/may-15-retirement
- https://help.x.com/en/using-x/x-premium
- https://x.ai/news/api
