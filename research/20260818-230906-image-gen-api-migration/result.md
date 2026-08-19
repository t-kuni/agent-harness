## 1. OpenAI（Images API）

**モデル**（2026年8月時点）
- 現行フラグシップ：`gpt-image-1.5`（2026年3月以降の主力）。廉価版として `gpt-image-1-mini` も提供。
- 旧モデル `gpt-image-1` は2026年10月23日に廃止予定のため新規利用は非推奨。

**エンドポイント**
- 新規生成：`POST https://api.openai.com/v1/images/generations`
- 編集・画像合成（image-to-image）：`POST https://api.openai.com/v1/images/edits`

**認証**
- HTTPヘッダー `Authorization: Bearer $OPENAI_API_KEY`（Bearerトークン方式）。

**リクエスト形式**
- `generations`：`Content-Type: application/json` のJSONボディ。`model`、`prompt`、`size`（例 `1024x1024`）、`quality`（`low`/`medium`/`high`）、`n`（生成枚数）などを指定。
- `edits`：`multipart/form-data`。複数の参照画像を渡す場合は同じフィールド名 `image[]` を繰り返して複数ファイルを添付する（例：`image[]=@ref1.png` と `image[]=@ref2.png`）。マスクを使う部分編集の場合は `mask=@mask.png` を追加。

**レスポンス形式**
- Base64。JSONレスポンス内の `data[].b64_json` フィールドに画像データが入る（URL形式ではない）。デコードしてファイルに書き出す必要がある。

**課金体系（1枚あたり目安、gpt-image-1系）**
- 低品質：約 $0.02〜$0.011／枚
- 中品質：約 $0.07／枚
- 高品質：約 $0.19〜$0.25／枚
- `gpt-image-1-mini` は約 $0.005／枚からとさらに安価。
- 価格は解像度・品質設定・モデル世代によって変動する。

### curlコマンド例（新規生成）

```bash
curl https://api.openai.com/v1/images/generations \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-image-1.5",
    "prompt": "白いシャム猫が窓辺に座っている写真風イラスト",
    "size": "1024x1024",
    "quality": "high",
    "n": 1
  }' > response.json

# base64をデコードしてPNGとして保存
jq -r '.data[0].b64_json' response.json | base64 -d > output.png
```

### curlコマンド例（複数参照画像を使った編集/合成）

```bash
curl https://api.openai.com/v1/images/edits \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F model="gpt-image-1.5" \
  -F "image[]=@character_ref.png" \
  -F "image[]=@background_ref.png" \
  -F prompt="Image 1はキャラクター設定画、Image 2は背景。キャラクターを背景に自然に合成して" \
  -F size="1024x1024" > response.json

jq -r '.data[0].b64_json' response.json | base64 -d > output.png
```

### 複数参照画像対応
- `edits` エンドポイントが image-to-image（画像編集・合成）に対応しており、`multipart/form-data` で `image[]` を複数回指定することで複数枚の参照画像を渡せる。JSON形式ではなくmultipart必須。Base64エンコードは不要（ファイルをそのままバイナリ添付）。

---

## 2. Google Gemini（Nano Banana系画像生成モデル）

**前提の注意**：Google の旧来の画像生成専用API「Imagen」（`imagen-3.0-generate-002:predict` 等）は2026年8月17日をもって廃止（シャットダウン）される案内が出ており、現行の推奨移行先は Gemini の「Nano Banana」系マルチモーダル画像生成モデルである。

**モデル**（2026年8月時点）
- `gemini-3.1-flash-image`（通称 Nano Banana 2）
- `gemini-3.1-flash-lite-image`（Nano Banana 2 Lite、廉価・高速版、2026年6月登場）
- `gemini-3-pro-image`（Nano Banana Pro、高品質・高解像度対応）
- 旧世代 `gemini-2.5-flash-image` も引き続き利用可能

**エンドポイント**
- 現行の推奨API：`POST https://generativelanguage.googleapis.com/v1beta/interactions`（Interactions API、GA済み）
- 旧来のgenerateContent系エンドポイント（`v1beta/models/{model}:generateContent`）も引き続き画像出力に対応するモデルがあるが、最新機能へは Interactions API が推奨される。

**認証**
- HTTPヘッダー `x-goog-api-key: $GEMINI_API_KEY`（Bearerではなく専用ヘッダー）。APIキーは Google AI Studio で発行。

**リクエスト形式**
- JSONボディ（`Content-Type: application/json`）。主なフィールド：
  - `model`：使用モデル名
  - `input`：テキストと画像（Base64エンコードした `inline_data` またはファイル参照）を混在させた配列
  - `response_format`：出力形式・解像度指定

**レスポンス形式**
- Base64。生成画像は `interaction.output_image.data` にBase64文字列として格納される（URL形式ではない）。

**複数参照画像対応（上限）**
- `gemini-3.1-flash-lite-image`：合計最大14枚の参照画像
- `gemini-3.1-flash-image`：オブジェクト画像最大10枚＋キャラクター一貫性用最大4枚＋スタイル参照最大3枚
- `gemini-3-pro-image`：オブジェクト画像最大6枚＋キャラクター画像最大5枚
- 参照画像はリクエストJSON内にBase64エンコードして埋め込む方式（multipart/form-dataではなくJSON+Base64）。

**課金体系（出力トークン単価ベース）**
- 画像出力は $60.00／100万出力トークンが基本単価で、解像度によりトークン消費量が変わるため実質1枚あたりの価格が変動する。
- Nano Banana 2（`gemini-3.1-flash-image`）：約 $0.045（0.5K相当）〜$0.151（4K相当）／枚。Batch APIは50%割引。
- Nano Banana Pro（`gemini-3-pro-image`）：1024×1024で約 $0.039／枚、1K〜2Kで約 $0.134／枚、4K（4096×4096）で約 $0.24／枚。Batch APIは半額。
- Nano Banana 2 Lite（`gemini-3.1-flash-lite-image`）：1K出力のみ対応、約 $0.0336／枚（Standardティア）。

### curlコマンド例（新規生成）

```bash
curl https://generativelanguage.googleapis.com/v1beta/interactions \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-3.1-flash-image",
    "input": [
      {"type": "text", "text": "白いシャム猫が窓辺に座っている写真風イラスト"}
    ],
    "response_format": {"type": "image", "resolution": "1K"}
  }' > response.json

jq -r '.output_image.data' response.json | base64 -d > output.png
```

### curlコマンド例（複数参照画像を使った合成）

```bash
IMG1_B64=$(base64 -w0 character_ref.png)
IMG2_B64=$(base64 -w0 background_ref.png)

curl https://generativelanguage.googleapis.com/v1beta/interactions \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d @- <<EOF > response.json
{
  "model": "gemini-3.1-flash-image",
  "input": [
    {"type": "image", "inline_data": {"mime_type": "image/png", "data": "$IMG1_B64"}},
    {"type": "image", "inline_data": {"mime_type": "image/png", "data": "$IMG2_B64"}},
    {"type": "text", "text": "1枚目はキャラクター設定画、2枚目は背景。キャラクターを背景に自然に合成して"}
  ],
  "response_format": {"type": "image", "resolution": "1K"}
}
EOF

jq -r '.output_image.data' response.json | base64 -d > output.png
```

（注：巨大なBase64文字列をシェル変数に格納しコマンドラインへ展開する方式はプロセスリストや履歴に画像データ自体が残るリスクがあるため、実運用では一時ファイル経由や `jq --rawfile` 等でファイルから読み込む方式が望ましい。）

### 複数参照画像対応
- Interactions API はJSONの `input` 配列内に複数の `image`（Base64埋め込み）を含めることで、画像編集・合成（image-to-image）に対応する。multipart/form-dataではなくJSON＋Base64必須。モデルごとに枚数上限あり（上記参照）。

---

## 3. その他の広く使われているプロバイダについて（補足）

- **Stability AI（Stable Diffusion系API）**、**Black Forest Labs（FLUX/FLUX.2系API）**なども広く利用されているが、本調査では上記2社ほど詳細な一次情報の確認ができていない。FLUX系は `multipart/form-data` または JSON+Base64で画像入力を受け付ける形式が一般的、というのが業界内の一般的傾向として観測されるが、この記述は根拠を明確なドキュメントで確認できておらず**不確か**である。必要であれば別途公式ドキュメント（Stability AI Platform docs、Black Forest Labs API docs）の確認を推奨する。

---

## 4. 秘密情報（APIキー）をシェル環境変数を使わずに渡す方法

CLAUDE.mdの「環境変数の参照禁止（存在確認も禁止）」という制約下で、AIエージェント（Claude Code）がAPIキーをコマンドに渡す一般的な方法を列挙する。

### (a) 秘密情報を書いたファイルをコマンドから読み込ませる
- 例：`curl -H "Authorization: Bearer $(cat ~/.secrets/openai_api_key)"` のように、ファイルの中身をコマンド置換で読み込む。あるいは `curl --header @header_file.txt` のようにcurl自体がファイル読み込みオプションを持つ場合はそれを使う。
- 利点：環境変数を経由しないため「環境変数の参照」ルールに抵触しない。ファイルのパーミッション（`chmod 600`）で保護できる。
- 欠点：ファイルパスやキー自体がBashの引数・プロセスリスト（`ps aux`）に一瞬でも露出しうる（`cat` の出力をコマンド置換で埋め込む場合は特に、シェル履歴やプロセス引数に平文が残る可能性がある）。AIエージェントがファイル内容を直接読み取れてしまう（`Read`ツール等でキーそのものを閲覧できてしまう）リスクもある。

### (b) `curl` の `--config`（`-K`）オプションや `netrc` ファイルを使う
- `curl -K curlrc_with_header` や `curl --netrc-file ~/.netrc` のように、認証情報を含む設定ファイルをcurlに直接読み込ませる。
- 利点：コマンドライン引数やプロセスリストにキーそのものが出現しない（curlがファイルを内部で読むため）。
- 欠点：設定ファイル自体の管理・パーミッション管理が必要。AIエージェントがファイル内容を閲覧できてしまう構成だと秘匿性が保てない。

### (c) OSのキーチェーン／シークレットマネージャーを使う
- 例：Linuxの `secret-tool`（GNOME Keyring）、macOSの `security find-generic-password`（Keychain）、あるいはクラウドの Secrets Manager（AWS Secrets Manager、Google Secret Manager等）をCLIから呼び出し、標準出力やプロセス置換でcurlに渡す。
- 利点：キー自体が平文ファイルとしてディスクに常時存在しない。アクセス制御・監査ログが利用できる場合がある。
- 欠点：セットアップの複雑さが増す。ローカル開発機にキーチェーンが必須。クラウドシークレットマネージャーの場合はそのAPI呼び出し自体にも別途認証が必要になり循環的な構成になりうる。AIエージェントに実行権限を与えた場合、結局キー取得コマンドをAIが実行できてしまう点は環境変数方式と同様のリスクが残る。

### (d) 標準入力（stdin）経由でキーを渡す
- 例：`echo "$KEY" | some-command --key-from-stdin` のように、シェルの環境変数展開ではなくパイプでプロセス間伝達する。curl自体には「APIキーをstdinから読む」機能は標準搭載されていないため、ラッパースクリプトが必要になることが多い。
- 利点：コマンドライン引数やプロセスリストにキーが露出しない。
- 欠点：ラッパースクリプトの実装が必要。パイプの前段（`echo`や`cat`）で結局キーの出どころ（ファイルや変数）が必要になる。

### (e) 設定ファイル（YAML/JSON/INI等）に直書きしてアプリケーション側で読み込む
- 例：`config.json` に `{"api_key": "sk-..."}` と記述し、curlの `-d @config.json` やスクリプト内で `jq` を使いキーを取り出す。
- 利点：構成管理がシンプル。バージョン管理から除外（`.gitignore`）すれば運用上扱いやすい。
- 欠点：ファイルが平文であるため、アクセス制御（パーミッション、リポジトリへの誤コミット）に注意が必要。AIエージェントがそのファイルを直接読める環境では、結局キーがエージェントに見える。

### (f) OSレベルの認証情報ヘルパー・プロキシ経由
- 例：リバースプロキシ（社内APIゲートウェイ等）を用意し、そのプロキシ側でAPIキーを保持・付与し、AIエージェント側は無認証もしくは別の一時トークンでプロキシにアクセスする。
- 利点：AIエージェントの実行環境からは実キーが完全に隠蔽される。キーのローテーションも一元管理できる。
- 欠点：プロキシの構築・運用コストが発生する。

いずれの方式も「環境変数（`export`して`$VAR`参照）を使わない」という制約は満たせるが、「AIエージェント自身がキーの中身を閲覧できてしまうかどうか」は別軸の懸念であり、上記のいずれの方式を採っても、AIエージェントに与えたBashツールの権限次第ではキー内容の読み取りが可能になりうる点は共通の留意事項である。

---

## 5. レートリミット・エラーレスポンス・リトライ時の注意点

### OpenAI
- 認証エラー：HTTP `401 Unauthorized`、レスポンスJSONに `error.type: "invalid_request_error"` や `"invalid_api_key"` 等のコードが入る。
- クォータ超過／レート制限：HTTP `429 Too Many Requests`。レスポンスヘッダーに `retry-after` が含まれる場合があり、これに従った待機が推奨される。
- 一般的なエラーJSON構造：`{"error": {"message": "...", "type": "...", "param": null, "code": "..."}}`。
- リトライ時の注意：429や5xx系のエラーに対しては指数バックオフ（exponential backoff）でのリトライが一般的に推奨される。画像生成は課金対象の処理であるため、タイムアウト時に「実際には課金され画像が生成されたが応答が届かなかった」ケースを考慮し、無条件の即時リトライは二重課金のリスクがある点に注意が必要。

### Google Gemini
- 認証エラー：HTTP `401`または`403`。APIキーが無効・権限不足の場合。
- クォータ超過：HTTP `429 RESOURCE_EXHAUSTED`。Google APIの一般的なエラーレスポンス形式（`{"error": {"code": 429, "message": "...", "status": "RESOURCE_EXHAUSTED"}}`）に従う。
- リトライ時の注意：Google Cloud系API共通の作法として、429や503系エラーには指数バックオフ＋ジッター付きのリトライが推奨される。Batch APIを使う場合は同期リクエストと異なりレート制限の扱いが異なる（24時間以内の非同期処理となり、価格も半額になる代わりに即時性がない）点に留意。

なお、具体的なレート制限の数値（RPM/TPM等の上限）はプラン・ティア（無料枠か有料枠か、組織の利用実績）によって変動するため、正確な数値は各社のダッシュボードやレートリミットページで確認する必要がある。

---

## 参照した情報源URL

- [Image generation | OpenAI API (developers.openai.com)](https://developers.openai.com/api/docs/guides/image-generation)
- [Introducing our latest image generation model in the API | OpenAI](https://openai.com/index/image-generation-api/)
- [GPT Image API Pricing 2026 — Real Cost per Image | Price Per Token](https://pricepertoken.com/gpt-image-pricing)
- [OpenAI Image Generation API Pricing in 2026 | AI Free API](https://www.aifreeapi.com/en/posts/openai-image-generation-api-pricing)
- [OpenAI Image Generation API cURL | AI Free API](https://www.aifreeapi.com/en/posts/openai-image-generation-api-curl)
- [GPT Image 1: Complete Specifications, Pricing, API Access & Use Cases | Gate.AI](https://gate.ai/blog/gpt-image-1-openai-specs-pricing-api-use-cases)
- [Gemini API | Google AI for Developers - image-generation](https://ai.google.dev/gemini-api/docs/image-generation)
- [Generate images using Imagen | Gemini API | Google AI for Developers](https://ai.google.dev/gemini-api/docs/imagen)
- [Gemini API reference | Google AI for Developers](https://ai.google.dev/api)
- [Nano Banana API Pricing (2026): Every Plan & Per-Image Cost](https://www.myarchitectai.com/blog/nano-banana-api-pricing)
- [Nano Banana Pro (Gemini 3 Pro Image Preview) API Pricing 2026 | Price Per Token](https://pricepertoken.com/pricing-page/model/google-gemini-3-pro-image-preview)
- [AI Image Pricing 2026: Google Gemini vs. OpenAI GPT Cost Analysis | IntuitionLabs](https://intuitionlabs.ai/articles/ai-image-generation-pricing-google-openai)

なお、一部（Stability AI／Black Forest Labsに関する記述）は根拠となる一次情報を確認できておらず不確かである旨、本文中に明記した。
