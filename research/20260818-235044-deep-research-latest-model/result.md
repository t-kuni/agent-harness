# 出力

## 前提：情報の性質について

本調査は WebFetch/WebSearch 経由の自動要約結果に基づいている。同一ページに対する複数回のフェッチで内容に食い違い（後述）が生じたため、断定できる部分と断定できない部分を明確に分けて記述する。

## 1. o3-deep-research / o4-mini-deep-research より新しいDeep Researchモデルの有無

**公式Deprecationsページ（`https://developers.openai.com/api/docs/deprecations`）**の「Past deprecations」セクションに、以下の表が確認できた（2回のフェッチで内容は一致）。

| Shutdown date | Model snapshot | Recommended replacement |
|---|---|---|
| 2026年7月23日 | `o3-deep-research-2025-06-26` / `o3-deep-research` | `gpt-5.6-sol` |
| 2026年7月23日 | `o4-mini-deep-research-2025-06-26` / `o4-mini-deep-research` | `gpt-5.6-sol` |

- `o3-deep-research` `o4-mini-deep-research` はどちらも `2025-06-26` スナップショットに固定されたエイリアスのままであり、これ以降新しい日付のスナップショットにエイリアス先が更新された事実は確認できなかった。
- 「Deep Research」という名称を冠した新モデル（例："gpt-5.6-deep-research"のような専用モデル）は、少なくとも今回参照できた公式ページ上では見当たらなかった。かわりに、汎用フラグシップモデルである `gpt-5.6-sol`（2026年7月9日リリースの GPT-5.6 ファミリーの一つ、Changelogの2026-07-09エントリで確認）が代替先として指定されている。
- ただし、公式のモデル個別ページ `https://developers.openai.com/api/docs/models/o3-deep-research` を直接フェッチした際には、deprecatedやshutdownを示すバッジ・注記は見当たらず、スナップショット `2025-06-26` のまま「Our most powerful deep research model」として現行モデルであるかのように表示されていた。同様に、Deep Researchガイド（`https://developers.openai.com/api/docs/guides/deep-research`）でも `o3-deep-research` `o4-mini-deep-research` が引き続き推奨モデルとして記載されており、非推奨の注記は見当たらなかった。
- この2つの情報源（Deprecationsページ vs モデル個別ページ／ガイドページ）の間で内容が食い違っており、**「実際に2026年7月23日付けで廃止（シャットダウン）済みなのか、それとも廃止予定として告知されているだけで現時点でも稼働中なのか」は今回の調査だけでは断定できなかった**。

## 2. Deep Research関連モデルのラインナップ（モデルID・コンテキストウィンドウ・料金）

公式モデル一覧（`platform.openai.com/docs/models` は `developers.openai.com/api/docs/models` へ301リダイレクト）を確認したところ、「Specialized models」内に「Deep research」というカテゴリ見出しはあるが、これはガイドページへのリンクであり、モデル一覧テーブルとしての個別行（モデルID・コンテキストウィンドウ・料金）は列挙されていなかった。

個別ページから確認できたのは以下2モデルのみで、これらの詳細な料金・コンテキストウィンドウの数値は今回のフェッチでは十分に取得できなかった（モデルIDとスナップショット、'Responses/Batch API対応'という記載は確認できたが、具体的な単価テーブルは要約に含まれなかった）。

- `o3-deep-research`（スナップショット `o3-deep-research-2025-06-26`）
- `o4-mini-deep-research`（スナップショット `o4-mini-deep-research-2025-06-26`）

代替先とされる `gpt-5.6-sol` については、モデルページ（`https://developers.openai.com/api/docs/models/gpt-5.6-sol`）から以下を確認した。

- モデルID: `gpt-5.6-sol`
- 知識カットオフ: 2026年2月16日
- コンテキストウィンドウ: 1,050,000トークン（最大入力922,000トークン、最大出力128,000トークン）
- 料金（100万トークンあたり）: 入力 $5／キャッシュ入力 $0.5／出力 $30
- ただし、このページ上には「Deep Research」ツールとの互換性についての明記は無く、対応ツールとして列挙されていたのは `web_search`、`file_search`、`image_generation`、`code_interpreter`、`hosted_shell`、`apply_patch`、`skills`、`computer_use`、`mcp`、`tool_search` であった（`deep_research` という専用ツール名は列挙されていなかった）。

**注意**：`gpt-5.6-sol` が Deep Research用途（多段階自律調査、web_search等の組み合わせ）に正式対応しているのか、それとも単に「後継の汎用フラグシップモデル」として案内されているだけなのかは、今回参照できたページからは明確に判別できなかった。

## 3. 非推奨・廃止予定の告知の有無

上記1で述べた通り、`https://developers.openai.com/api/docs/deprecations` の「Past deprecations」セクションに、`o3-deep-research` `o4-mini-deep-research` の両方について

- シャットダウン日: 2026年7月23日
- 推奨移行先: `gpt-5.6-sol`

という記載が確認できた。これは公式のDeprecationsページであり、情報源としての信頼性は高いと考えられる。一方で、同じ公式ドメイン内のモデル個別ページ・Deep Researchガイドページでは非推奨の注記が見当たらず矛盾していたため、**現時点（2026年8月18日）で実際にAPI呼び出しが失敗する状態なのか、移行期間中で併存稼働しているのかは確認できなかった**。

なお検索過程で、あるWebFetch要約が移行先モデル名を「gpt-5.4-Pro」と回答した結果もあったが、これはOpenAI Developer Communityのユーザー投稿（非公式）からの引用であり、公式Deprecationsページの記載（`gpt-5.6-sol`）と矛盾する。ユーザー投稿はOpenAIスタッフの公式回答ではなく、投稿時点の古い情報である可能性、あるいはWebFetch要約の誤りである可能性があり、**公式情報として採用できるのは `developers.openai.com/api/docs/deprecations` に記載の `gpt-5.6-sol` のみ**である。

## 4. 確認できなかった項目

- `o3-deep-research` `o4-mini-deep-research` が実際に2026年7月23日時点でAPI的に完全シャットダウンされたのか、あるいは告知のみで現在も動作しているのかは、公式ページ間の記載矛盾のため確認できなかった。追加確認には、実際にAPIを呼び出してエラーの有無を検証する、または `https://help.openai.com/en/articles/9624314-model-release-notes`（OpenAI Help Center Model Release Notes）を精査する必要がある。
- `gpt-5.6-sol`（またはGPT-5.6ファミリーの他バリアント Terra／Luna）がDeep Research専用ツール（多段階自律調査ワークフロー、`web_search`ツールとの組み合わせによるレポート生成）に正式対応しているかどうかは、参照したモデルページ・Changelogのみでは確認できなかった。Deep Researchガイドページ自体は依然として`o3-deep-research`/`o4-mini-deep-research`を案内しており、`gpt-5.6-sol`をDeep Research用途で使う具体的な手順の記載は確認できていない。
- モデル一覧ページにおけるDeep Research関連モデルの料金テーブル（入力／キャッシュ入力／出力の単価）を、`o3-deep-research`・`o4-mini-deep-research`本体について具体的な数値で取得することはできなかった。

検索クエリ・参照結果の概要：
- `deep-research model site:platform.openai.com` → `o3-deep-research`/`o4-mini-deep-research`の個別ページとDeep Researchガイド、モデル一覧ページがヒット。
- `o3-deep-research o4-mini-deep-research deprecated 2026` → 公式Deprecationsページ、OpenAI Developer Communityの廃止告知スレッドがヒット。
- `"gpt-5.6-sol" OR "gpt-5.4-pro" openai deep-research deprecation` → `gpt-5.6-sol`が実在するモデルであることを確認（GPT-5.6ファミリーのフラグシップ）。
- `openai deep research API model update August 2026 gpt-5.6` → GPT-5.6ファミリー（Sol/Terra/Luna）のリリース経緯とAugust 2026時点の周辺アップデート（Ultrafastティア等）を確認。ただしDeep Research専用の後継モデルという名称の発表は確認できなかった。

## 参照した情報源URL一覧

- https://developers.openai.com/api/docs/deprecations（公式・Deprecationsページ）
- https://developers.openai.com/api/docs/models/o3-deep-research（公式・モデルページ）
- https://developers.openai.com/api/docs/models（公式・モデル一覧ページ、`platform.openai.com/docs/models`からのリダイレクト先）
- https://developers.openai.com/api/docs/models/gpt-5.6-sol（公式・モデルページ）
- https://developers.openai.com/api/docs/guides/deep-research（公式・Deep Researchガイド、`platform.openai.com/docs/guides/deep-research`からのリダイレクト先）
- https://developers.openai.com/api/docs/changelog（公式・Changelog）
- https://openai.com/index/gpt-5-6/（公式ブログ、GPT-5.6発表）
- https://community.openai.com/t/o4-mini-deep-research-o3-deep-research-deprecation/1379560（非公式・OpenAI Developer Communityのユーザー投稿、参考情報として区別して扱った）
