**結論**

確認できた範囲では、条件4つを同一の生成リクエストで同時指定できる可能性が公式ドキュメント上もっとも明確なのは **Together AI の `Wan-AI/wan2.7-i2v` を使う `POST /v2/videos` / `client.videos.create()`** です。

ただし、Together の公式ドキュメントには「開始フレーム + 終了フレーム + 外部音声」を1つのサンプルで同時に載せた例はなく、根拠は `media` オブジェクトの統一スキーマと、I2Vモデル互換表で `frame_images` と `audio_inputs` の両方が対応とされている点です。導入前には実APIで1回テストする前提が安全です。

---

## 調査結果一覧

| サービス | 4要素同時入力 | 根拠の要点 |
|---|---:|---|
| Together AI / Wan 2.7 I2V | **可能と判断** | I2Vで `frame_images` が first/last 対応、同じ `media` 内で `audio_inputs` もI2V対応 |
| Google Cloud / Veo 3.1 | **不可** | first/last frame とテキストは対応。外部音声入力はなく、`generateAudio` は生成音声のON/OFF |
| Runway API | **不可または未確認** | first/last frame は対応。音声・リップシンク系は別系統。Hailuo 3.0では reference audio が keyframe と併用不可と明記 |
| fal.ai / Pika Pikaframes | **不可** | keyframe補間と prompt は対応。音声入力パラメータなし |
| Kling AI | **不可と判断** | start/end frame と lip-sync は公式更新上は別機能として扱われる。lip-syncは生成済み動画への後段処理系 |

---

## 1. Together AI / Wan 2.7

- **サービス名・提供元**: Together AI / Wan 2.7 model family
- **機能・エンドポイント**: `POST https://api.together.ai/v2/videos`、SDKでは `client.videos.create()`
- **公式ドキュメント**: https://docs.together.ai/docs/wan2.7-quickstart

### 入力仕様

- **テキストプロンプト**
  - パラメータ: `prompt`
  - 仕様: 動画生成用テキスト。最大5,000文字と記載あり。([docs.together.ai](https://docs.together.ai/docs/wan2.7-quickstart))

- **開始フレーム画像**
  - パラメータ: `media.frame_images[]`
  - 形式: `{"input_image": "https://example.com/start.png", "frame": "first"}`
  - I2Vで `frame` に `"first"` または `"last"` を指定する仕様。([docs.together.ai](https://docs.together.ai/docs/wan2.7-quickstart))

- **終了フレーム画像**
  - パラメータ: `media.frame_images[]`
  - 形式: `{"input_image": "https://example.com/end.png", "frame": "last"}`
  - 公式例では first/last を2つ渡し、2つのキーフレーム間を生成すると説明。([docs.together.ai](https://docs.together.ai/docs/wan2.7-quickstart))

- **外部音声データによるリップシンク**
  - パラメータ: `media.audio_inputs`
  - 形式: 音声ファイルURLの配列
  - 仕様: WAVまたはMP3、3-30秒、最大15MB。音声が動画より長い場合は切り詰め、短い場合は残りが無音。([docs.together.ai](https://docs.together.ai/docs/wan2.7-quickstart))
  - 挙動: `audio_inputs` は生成を駆動し、「lip sync, beat-matched motion」などに使われると記載。([docs.together.ai](https://docs.together.ai/docs/wan2.7-quickstart))

### 同一リクエスト可否

**可能と判断。**

根拠は、Together が `media` を「画像・動画・音声を動画生成リクエストに渡す統一オブジェクト」として定義し、I2Vモデルの互換表で次の両方を同時にI2V対応としているためです。

- `frame_images`: I2Vで first/last frame 対応
- `audio_inputs`: I2Vで single audio 対応([docs.together.ai](https://docs.together.ai/docs/wan2.7-quickstart))

想定リクエスト例:

```json
{
  "model": "Wan-AI/wan2.7-i2v",
  "prompt": "A character speaks naturally while moving from the first composition to the final pose.",
  "resolution": "720P",
  "ratio": "16:9",
  "seconds": "10",
  "media": {
    "frame_images": [
      { "input_image": "https://example.com/start.png", "frame": "first" },
      { "input_image": "https://example.com/end.png", "frame": "last" }
    ],
    "audio_inputs": [
      "https://example.com/dialogue.mp3"
    ]
  }
}
```

### API・MCP

- **API**: あり。`/v2/videos` と Python / TypeScript SDK。
- **MCP**: Together AI docs MCP server は公式に提供あり。ただしこれはドキュメント参照用で、動画生成実行用MCPとは限らない。([docs.together.ai](https://docs.together.ai/docs/agent-skills?utm_source=openai))

---

## 2. Google Cloud / Veo 3.1

- **サービス名・提供元**: Google Cloud / Veo 3.1
- **機能・エンドポイント**: `predictLongRunning` / `client.models.generate_videos`
- **公式ドキュメント**: https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/video/generate-videos-from-first-and-last-frames

### 入力仕様

- **テキストプロンプト**
  - パラメータ: `prompt`

- **開始フレーム画像**
  - Python SDK: `image=Image(...)`
  - REST: `instances[].image`
  - MIME: `image/jpeg`, `image/png`。([docs.cloud.google.com](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/video/generate-videos-from-first-and-last-frames))

- **終了フレーム画像**
  - Python SDK: `config.last_frame=Image(...)`
  - REST: `instances[].lastFrame`
  - `lastFrame` は `image` と併用時のみ使用可能。([docs.cloud.google.com](https://docs.cloud.google.com/gemini-enterprise-agent-platform/reference/rest/Shared.Types/VideoGenerationModelInstance))

- **音声**
  - パラメータ: `generateAudio`
  - これは「動画と一緒に音声トラックを生成するか」の boolean。([docs.cloud.google.com](https://docs.cloud.google.com/gemini-enterprise-agent-platform/reference/rest/Shared.Types/VideoGenerationModelParams))
  - 外部音声ファイルURLや音声バイナリを渡す入力欄は、Veoの `VideoGenerationModelInstance` に存在しない。スキーマ上の入力は `prompt`, `image`, `video`, `lastFrame`, `cameraControl`, `mask`, `referenceImages`。([docs.cloud.google.com](https://docs.cloud.google.com/gemini-enterprise-agent-platform/reference/rest/Shared.Types/VideoGenerationModelInstance))

### 同一リクエスト可否

**不可。**

Veo 3.1は first/last frame とテキストプロンプト、生成音声には対応しますが、ユーザーが渡した外部音声データに合わせてリップシンクする入力パラメータは確認できません。

### API・MCP

- **API**: あり。Google Gen AI SDK / REST API。
- **MCP**: この動画生成機能専用の公式MCPサーバーは確認できず。

---

## 3. Runway API

- **サービス名・提供元**: Runway
- **機能・エンドポイント**:
  - Image to Video: `/v1/image_to_video`
  - Avatar video: `/v1/avatar_videos`
- **公式ドキュメント**: https://docs.dev.runwayml.com/api/

### 入力仕様

- **テキストプロンプト**
  - パラメータ: `promptText`
  - Getting Startedでは `image_to_video.create(... prompt_text=...)` の例あり。([docs.dev.runwayml.com](https://docs.dev.runwayml.com/guides/using-the-api/?utm_source=openai))

- **開始フレーム画像**
  - パラメータ: `promptImage`
  - 2024-11-06 API以降、`promptImage` は文字列または `{uri, position}` 配列。`position: "first"` が開始フレーム。([docs.dev.runwayml.com](https://docs.dev.runwayml.com/api-details/versions/2024-11-06/?utm_source=openai))

- **終了フレーム画像**
  - 同じく `promptImage[]`
  - `position: "last"` を指定可能。2画像を渡すと、1枚目で開始し2枚目で終了すると説明。([docs.dev.runwayml.com](https://docs.dev.runwayml.com/api-details/versions/2024-11-06/?utm_source=openai))

- **音声データ / リップシンク**
  - Runway APIには音声入力一般の仕様があり、MP3/WAV/FLAC/M4A/AACなどを受けるフィールドが存在するタスクでは利用可能。([docs.dev.runwayml.com](https://docs.dev.runwayml.com/assets/inputs/))
  - Avatar Videosには「Generate avatar video from audio or text」エンドポイントがあるが、これはアバター動画系であり、first/last frame補間の `image_to_video` とは別系統。([docs.dev.runwayml.com](https://docs.dev.runwayml.com/api/))

### 同一リクエスト可否

**不可または未確認。少なくとも公式ドキュメント上、4要素の同時指定は確認できません。**

さらに、Runway API内の Hailuo 3.0 については重要な制約があります。公式の入力パラメータ説明で、keyframe指定、すなわち `position: first/last` と、unpositioned reference image は混在不可、かつ reference audio は keyframe ではなく unpositioned reference image でのみ有効とされています。([docs.dev.runwayml.com](https://docs.dev.runwayml.com/assets/inputs/))

つまり Runway経由で Hailuo 3.0 を使う場合も、**first/last keyframe + reference audio** の組み合わせは不可です。

### API・MCP

- **API**: あり。REST API / Python / TypeScript SDK。
- **MCP**: 公式MCPサーバーは確認できず。Runwayはエージェント向け skills リポジトリを公開しているが、MCPサーバーとは別扱い。([github.com](https://github.com/runwayml/skills/blob/main/README.md?utm_source=openai))

---

## 4. fal.ai / Pika 2.2 Pikaframes

- **サービス名・提供元**: fal.ai / Pika model endpoint
- **機能・エンドポイント**: `fal-ai/pika/v2.2/pikaframes`
- **ドキュメント**: https://fal.ai/models/fal-ai/pika/v2.2/pikaframes/api

### 入力仕様

- **テキストプロンプト**
  - パラメータ: `prompt`
  - 遷移全体のデフォルトプロンプト。transitionごとの上書きも可能。([fal.ai](https://fal.ai/models/fal-ai/pika/v2.2/pikaframes/api))

- **開始・終了フレーム画像**
  - パラメータ: `image_urls`
  - 2-5枚のキーフレーム画像URLを渡し、画像間の遷移を生成。([fal.ai](https://fal.ai/models/fal-ai/pika/v2.2/pikaframes/api))

- **音声データ / リップシンク**
  - 入力スキーマに音声パラメータなし。
  - 公式スキーマ上は `image_urls`, `transitions`, `prompt`, `negative_prompt`, `seed`, `resolution` などで構成。([fal.ai](https://fal.ai/models/fal-ai/pika/v2.2/pikaframes/api))

### 同一リクエスト可否

**不可。**  
開始・終了フレームとテキストプロンプトは対応しますが、外部音声データによるリップシンク入力がありません。

### API・MCP

- **API**: fal.ai APIとしてあり。
- **MCP**: 公式MCPサーバーは確認できず。

---

## 5. Kling AI

- **サービス名・提供元**: Kling AI / Kuaishou
- **関連機能**:
  - 動画生成の start/end frame
  - 生成済み動画に対する lip-sync

### 確認できた範囲

Klingの更新情報では、start/end frame、end frame、motion brush、camera control などの動画生成機能と、lip-sync機能が別項目として掲載されています。また lip-sync は「生成された動画」や条件を満たす動画に対する機能として説明されています。([docs.qingque.cn](https://docs.qingque.cn/d/home/eZQCQxBrX8eeImjK6Ddz5iOi5?identityId=1oEG9JKKMFv&utm_source=openai))

### 同一リクエスト可否

**不可と判断。**  
公式更新情報上、start/end frame制御と lip-sync は別機能として扱われており、1つの動画生成リクエスト内で「開始画像 + 終了画像 + 外部音声リップシンク + prompt」を同時に渡すエンドポイントは確認できませんでした。

### API・MCP

- **API**: 公式 Open Platform API あり。ただし今回の4要素同時入力は未確認。
- **MCP**: 非公式・コミュニティ実装は確認できるが、公式MCPサーバーは確認できず。

---

## 不足パターン整理

| サービス | 開始フレーム | 終了フレーム | 外部音声リップシンク | テキストプロンプト | 不足点 |
|---|---:|---:|---:|---:|---|
| Together AI Wan 2.7 I2V | 対応 | 対応 | 対応 | 対応 | 公式サンプルに4要素同時例がないため実機検証推奨 |
| Google Veo 3.1 | 対応 | 対応 | 非対応 | 対応 | 外部音声入力がない。音声は生成音声のみ |
| Runway Image to Video | 対応 | 対応 | 非対応 | 対応 | リップシンク/Avatar系が別エンドポイント |
| Runway Hailuo 3.0 | 対応 | 対応 | 制約あり | 対応 | reference audio は keyframe と併用不可 |
| Pika Pikaframes | 対応 | 対応 | 非対応 | 対応 | 音声入力なし |
| Kling AI | 対応 | 対応 | 別機能 | 対応 | lip-syncは後段処理系で、同一生成リクエスト未確認 |

**実務上の最有力候補は Together AI Wan 2.7 I2V です。**  
比較検討では、まず Together の上記リクエスト形でPoCし、出力のリップシンク品質と first/last frame の拘束力を確認するのが現実的です。
