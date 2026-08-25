以下は 2026-08-26 時点で確認できた公式情報ベースの整理です。重要な前提として、Reve 公式ヘルプは「Reve API は 2026-08-14 に sunset し、現在利用不可」と明記しています。未使用クレジットは 2026-08-31 までに返金されるとも書かれています。出典: https://help.reve.com/hc/en-us/articles/46837930295316-Reve-API 

一方で、`https://api.reve.com/console` と `https://api.reve.com/console/docs` は検索インデックス上では現在も API ドキュメントとして残っており、Reve 2.1 API の仕様断片が確認できます。したがって、実装判断としては「仕様は残っているが、公式ヘルプ上はサービス終了済み」という扱いが安全です。

**1. APIのベースURL・エンドポイント**

ベースURL: `https://api.reve.com`

公式 API console docs で確認できた主要エンドポイントは以下です。

| 用途 | HTTP | パス | 確認できた説明 |
|---|---:|---|---|
| 新規生成・編集・リミックス統合 | `POST` | `/v2/image/create` | テキストと任意の順序付き参照画像から画像を生成。画像と description layout を返す。出典: https://api.reve.com/console/docs  |
| レイアウト作成・編集 | `POST` | `/v2/image/create_layout` | prompt、ordered mixed references、optional commands から structured layout を作成または編集。JSON のみ返す。出典: https://api.reve.com/console/docs/v2/create_layout  |
| 画像からレイアウト抽出 | `POST` | `/v2/image/extract_layout` | 画像から structured layout を抽出。任意で prompt による誘導が可能。JSON のみ返す。出典: https://api.reve.com/console/docs/v2/extract_layout  |
| レイアウト描画 | 不明 | `render_layout` として言及あり | 公式ブログは layout creation / editing / rendering を分離する experimental endpoints と説明。具体パスは取得できた公式本文断片では未確認。出典: https://blog.reve.com/posts/the-reve-api/  |

Reve 2.1 API は「Ready to use」系と「Full Layout Control」系の 2 カテゴリに分かれると公式ブログにあります。前者は作成・編集用の簡単なエンドポイント、後者は layout creation / editing / rendering を分離する複雑な endpoint 群です。

また、API home の FAQ 断片では「古い Edit / Remix endpoints は新しい Create endpoint に統合された」と確認できます。出典: https://api.reve.com/console 

**2. HTTPメソッド・認証方式**

確認できた公式 curl 断片では、認証は Bearer token 形式です。

```bash
-H "Authorization: Bearer $REVE_API_KEY"
-H "Content-Type: application/json"
```

出典: https://api.reve.com/console/docs 

画像形式を指定する例として、公式 docs の断片に以下も見えます。

```bash
-H "Accept: image/webp"
```

出典: https://api.reve.com/console/docs 

API キーの取得方法は、取得できた公式本文では詳細不明です。コンソール URL は `https://api.reve.com/console` ですが、公式ヘルプは API 終了を明記しているため、新規取得可否も不明です。

**3. リクエストボディのパラメータ**

`POST /v2/image/create`

公式 docs 断片から確認できる範囲:

| パラメータ | 型 | 必須 | 内容 |
|---|---|---:|---|
| `prompt` | string | 不明 | 画像全体を記述するテキスト。公式 curl 断片に `prompt` が含まれる。 |
| `references` | array | 任意とみられる | 順序付き参照画像。create は「optional ordered reference images」を受ける。 |
| 画像形式指定 | header | 任意 | `Accept: image/webp` の例あり。 |
| aspect ratio | 不明 | 不明 | create_layout では確認できるが、create の正式フィールド名は公式断片からは未確認。 |
| negative prompt | 不明 | 不明 | 公式ドキュメント断片に記載なし。 |
| seed / 生成枚数 | 不明 | 不明 | 公式ドキュメント断片に記載なし。 |

`POST /v2/image/create_layout`

| パラメータ | 型 | 必須 | 内容 |
|---|---|---:|---|
| `prompt` | string | 条件付き | 最大 4000 文字。`prompt` または `references` の少なくとも一方が必要。出典: https://api.reve.com/console/docs/v2/create_layout  |
| `references` | array | 条件付き | 最大 8 件の ordered compound references。各 entry は optional image / layout / description を含む。出典: https://api.reve.com/console/docs/v2/create_layout  |
| `commands` | array | 任意 | prompt と references の上に適用する ordered imperative edits。各 command は `op` と op-specific fields を持つ。出典: https://api.reve.com/console/docs  |
| `aspect_ratio` | string | 任意 | `auto` ではモデルが適切な比率を選ぶ。選択肢として `4:1`, `3:1`, `21:9`, `2:1`, `17:9` などが確認できる。出典: https://api.reve.com/console/docs/v2/create_layout  |

参照画像の渡し方:

公式 docs 断片では、compound reference の image は次のような形式です。

```json
{ "image": { "data": "<base64>" } }
```

または保存済み参照として:

```json
{ "ref": "id:<uuid>" }
```

出典: https://api.reve.com/console/docs/v2/create_layout 

画像入力の総制限として、1 回の呼び出しで最大 `50,331,648` pixels、base64 decode 後の画像データ合計 `100 MB` まで、という制限が確認できます。出典: https://api.reve.com/console/docs 

固定解像度指定について:

公式ブログは Reve 2.1 が native 4K x 4K、約 16MP を生成すると説明していますが、`WIDTHxHEIGHT` のような任意ピクセル指定パラメータは確認できませんでした。  
確認できるのは `aspect_ratio` 方式です。サイズクラス、任意幅高さ指定、16 の倍数制約などは公式断片に記載なしです。

**4. レスポンスボディの構造**

`/v2/image/create` は「画像と description layout を返す」と公式 docs 断片で確認できます。出典: https://api.reve.com/console/docs 

ただし、JSON の完全なレスポンススキーマ、画像が Base64 か URL か、`Accept: image/webp` 指定時に raw binary が返るのか、layout がどのフィールドに入るのかは、取得できた公式本文では不明です。

layout 系 endpoint では、`create_layout` と `extract_layout` が「Returns JSON only」と説明されています。出典: https://api.reve.com/console/docs/v2/create_layout 、https://api.reve.com/console/docs/v2/extract_layout 

`create_layout` のレスポンス断片として、以下のフィールドが確認できます。

| フィールド | 型 | 内容 |
|---|---|---|
| `id` | string | request の一意 ID |
| `credits_used` | number | この request で使った credits |
| `credits_remaining` | number | 残り credits |

出典: https://api.reve.com/console/docs/v2/create_layout 

**5. レート制限**

公式 docs 断片で `429 Rate limit` は確認できます。出典: https://api.reve.com/console/docs 

ただし、リクエスト数上限、時間窓、同時実行数、`RateLimit-*` / `Retry-After` のような通知ヘッダー仕様は、取得できた公式ドキュメントでは不明です。

**6. 料金体系**

公式 pricing ページの検索断片で確認できた内容:

| 項目 | 価格・credits |
|---|---:|
| 最小購入額 | `$10` |
| `$10` で得られる credits | `7,500 credits` |
| `v2 Create` | `150 credits` |
| `v2 Create Layout` | `80 credits`、約 `$0.11` |
| `v2 Render` | `80 credits`、約 `$0.11` と読める断片あり |

出典: https://api.reve.com/console/pricing 、

`v2 Create` の説明は「1 prompt + optional reference images → 1 image + layout」です。出典: https://api.reve.com/console/pricing 

無料枠の有無、返金条件、成功時のみ課金かどうか、enterprise pricing は、公式断片からは不明です。公式ブログには high-volume enterprise workflows は sales team に連絡とあります。

**7. エラーレスポンス**

公式 docs 断片で確認できた代表的なエラー:

| HTTP status | 意味 |
|---:|---|
| `404` | Not found。endpoint または resource が存在しない。 |
| `422` | Unprocessable content。入力を理解できなかった。 |
| `429` | Rate limit。 |

出典: https://api.reve.com/console/docs 

エラーレスポンス JSON の完全な形式、`error.code` / `error.message` のようなフィールド名、認証失敗時の `401` 形式などは、取得できた公式ドキュメントでは不明です。
