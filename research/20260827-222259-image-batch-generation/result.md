調査日: 2026-08-27。公式ドキュメント優先で確認しました。

## OpenAI 画像生成 API: `gpt-image-2`

**結論: あります。**  
`/v1/images/generations` と `/v1/images/edits` の両方で `n` を使えます。

- **パラメータ名**: `n`
- **意味**: 1リクエストで生成する最終画像の枚数
- **範囲**: `1` 以上 `10` 以下
- **デフォルト**: 1枚
- **対象**:
  - 新規生成: `POST /v1/images/generations`
  - 参照画像あり編集: `POST /v1/images/edits`

OpenAI API リファレンスでは generation の `n` は “number of images to generate” で `1..10`、edit の `n` は “number of edited images to generate” で `1..10` とされています。`partial_images` という別パラメータもありますが、これはストリーミング時の途中経過画像であり、複数の最終画像を作る指定ではありません。

**レスポンス形式**:  
`ImagesResponse` の `data` が配列になります。GPT Image 系は通常 `b64_json`、つまり Base64 エンコードされた画像データが各要素に入ります。

```json
{
  "created": 1713833628,
  "data": [
    { "b64_json": "..." },
    { "b64_json": "..." }
  ]
}
```

**料金**:  
`gpt-image-2` は画像出力トークン課金です。公式料金は、標準 API で画像入力 $8.00 / 100万 tokens、画像出力 $30.00 / 100万 tokens、テキスト入力 $5.00 / 100万 tokens。複数枚生成による割引は公式には示されていません。したがって、出力画像ぶんの出力トークンが増え、実質的に枚数に応じて増えます。参考表では `1024x1024` の `high` が約 $0.211 / image などと示されています。

**参照画像との併用**:  
可能です。`/v1/images/edits` にも `n` があります。GPT Image モデルでは複数の入力画像も扱えます。

参照URL:
- https://developers.openai.com/api/reference/resources/images/methods/generate
- https://developers.openai.com/api/reference/resources/images/methods/edit
- https://developers.openai.com/api/docs/guides/image-generation
- https://developers.openai.com/api/docs/pricing

## codex CLI: `codex exec` 方式

**結論: 生成枚数を直接指定する CLI オプションは確認できません。**

`codex exec` の公式 CLI リファレンスとローカル `codex exec --help` を確認しましたが、画像生成枚数に相当する `--n`、`--num-images`、`--count` のようなオプションはありません。

存在する画像関連オプションは次です。

- **`--image, -i`**: 初期プロンプトに画像ファイルを添付する入力用オプション
- これは参照画像を渡すためのもので、出力画像の枚数指定ではありません。

このリポジトリの `.claude/skills/image-gen/SKILL.md` でも、codex 方式は `codex exec --image <REF_IMAGE_1>,<REF_IMAGE_2> -- "<PROMPT>"` の形で参照画像を渡すだけで、生成枚数パラメータは定義されていません。

**料金**:  
`codex exec` はエージェント実行なので、OpenAI Images API の `n` のような公開された画像枚数課金パラメータはありません。プロンプトで「4枚作って」と依頼すればエージェントが複数回画像生成する可能性はありますが、CLI仕様上の1リクエスト複数枚生成ではありません。割引や枚数単位の課金仕様も CLI 公式仕様としては確認できません。

**レスポンス形式**:  
`codex exec` は通常、進捗を stderr、最終メッセージを stdout に出します。`--json` を使うと JSONL イベントになります。Images API のような `data: [{b64_json: ...}]` 形式ではありません。このリポジトリのスキルでは、生成画像を `~/.codex/generated_images/<SESSION_ID>/*.png` から拾う実装になっていますが、これはスキル側の運用であり、画像枚数指定 API ではありません。

**参照画像との併用**:  
参照画像は `--image` で渡せます。ただし出力枚数指定は CLI オプションとして存在しません。

参照URL:
- https://learn.chatgpt.com/docs/developer-commands
- https://learn.chatgpt.com/docs/non-interactive-mode

## Google Gemini API: `gemini-3.1-flash-image`, Interactions API

**結論: `/v1beta/interactions` には、最終画像の枚数を指定する専用パラメータは確認できません。**

確認した Interactions API のリクエストボディには、主に次のようなフィールドがあります。

- `model`
- `input`
- `response_format`
- `stream`
- `store`
- `background`
- `generation_config`

画像出力の制御は `response_format` で行いますが、これは出力形式・縦横比・サイズの指定であり、枚数指定ではありません。

```json
{
  "model": "gemini-3.1-flash-image",
  "input": "Create an image...",
  "response_format": {
    "type": "image",
    "mime_type": "image/jpeg",
    "aspect_ratio": "16:9",
    "image_size": "2K"
  }
}
```

**指定可能な画像設定**:

- `response_format.type`: `"image"`
- `mime_type`: 公式スキーマ上は `image/jpeg`
- `aspect_ratio`: `1:1`, `2:3`, `3:2`, `3:4`, `4:3`, `4:5`, `5:4`, `9:16`, `16:9`, `21:9`, `1:8`, `8:1`, `1:4`, `4:1`
- `image_size`: `512`, `1K`, `2K`, `4K`
- デフォルト: 入力画像がある場合は入力画像サイズに合わせ、そうでなければ `1:1`。Gemini 3 image models は 1K がデフォルトと説明されています。

Google の画像生成ガイドには「モデルはユーザーが明示的に求めた画像出力数に常に従うとは限らない」という制限が書かれています。つまりプロンプトで「4枚」と書いても、APIパラメータとして保証されるものではありません。

**レスポンス形式**:  
レスポンスは `steps` 配列に `model_output` が入り、その `content` 配列の中に画像ブロックが入ります。簡易プロパティ `output_image` は最後の画像ブロックだけを返します。複数画像やテキスト混在の場合は `steps` を手動走査します。

```json
{
  "id": "v1_...",
  "status": "completed",
  "steps": [
    {
      "type": "model_output",
      "content": [
        {
          "type": "image",
          "data": "BASE64_ENCODED_IMAGE",
          "mime_type": "image/png"
        }
      ]
    }
  ]
}
```

**料金**:  
枚数指定パラメータがないため、`n` による料金増加という仕様はありません。ただし、実際に複数の画像ブロックが返った場合は画像出力トークンが増えます。`gemini-3.1-flash-image` の標準料金は画像出力 $60 / 100万 tokens。公式換算では 0.5K が $0.045、1K が $0.067、2K が $0.101、4K が $0.151 / image です。複数画像割引は確認できません。

**参照画像との併用**:  
参照画像入力は可能です。`gemini-3.1-flash-image` は、単一ワークフローでキャラクター類似性は最大4キャラクター、オブジェクト高忠実度は最大10オブジェクトが目安とされています。ただし、参照画像ありでも出力枚数指定パラメータはありません。

補足: Google の OpenAI互換エンドポイントには `n` が記載されていますが、これは `/v1beta/openai/images/generations` 互換レイヤーの話であり、今回対象の Interactions API `/v1beta/interactions` とは別物です。

参照URL:
- https://ai.google.dev/api/interactions-api
- https://ai.google.dev/gemini-api/docs/image-generation
- https://ai.google.dev/gemini-api/docs/pricing
- https://ai.google.dev/gemini-api/docs/openai

## MiniMax 公式画像生成 API: `image-01`

**結論: あります。**  
`POST https://api.minimax.io/v1/image_generation` で `n` を使えます。

- **パラメータ名**: `n`
- **意味**: 1リクエストで生成する画像枚数
- **範囲**: `1` 以上 `9` 以下
- **デフォルト**: `1`
- **対象**:
  - Text-to-Image
  - Image-to-Image、つまり `subject_reference` を使う参照画像生成

公式例でも Text-to-Image で `n: 3`、Image-to-Image で `n: 2` が使われています。

**レスポンス形式**:  
`response_format: "url"` の場合は `data.image_urls` が配列になります。

```json
{
  "id": "03ff3cd0820949eb8a410056b5f21d38",
  "data": {
    "image_urls": ["XXX", "XXX", "XXX"]
  },
  "metadata": {
    "failed_count": "0",
    "success_count": "3"
  },
  "base_resp": {
    "status_code": 0,
    "status_msg": "success"
  }
}
```

`response_format: "base64"` の場合は公式ガイド例で `response.json()["data"]["image_base64"]` を配列として扱っています。URLは24時間で失効します。

**料金**:  
公式 Pay as You Go 価格は `image-01` が **$0.0035 / image**。したがって `n=3` なら基本的に $0.0035 × 3 = $0.0105 です。複数枚生成による割引や追加固定費は公式には示されていません。

**参照画像との併用**:  
可能です。Image-to-Image APIでも `n` が使えます。ただし MiniMax のガイドでは、参照画像は **1リクエストにつき1枚のみ** と説明されています。`subject_reference` に参照画像を入れ、同じリクエストで `n` を指定できます。

参照URL:
- https://platform.minimax.io/docs/api-reference/image-generation-t2i
- https://platform.minimax.io/docs/api-reference/image-generation-i2i
- https://platform.minimax.io/docs/guides/image-generation
- https://platform.minimax.io/docs/guides/pricing-paygo
