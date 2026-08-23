---
name: grok-imagine
description: xAI Grok Imagine APIで画像・動画を生成し、リポジトリ内の指定パスに保存する。「Grokで画像/動画を生成して」「grok-imagineで作って」などオーナーが明示的にxAI/Grokを指定した時に使う。API直接呼び出し（スクリプト方式）のみ対応。
---

## ルール

- 画像生成には `scripts/generate_image.sh`、動画生成には `scripts/generate_video.sh` を使う（いずれもAPI直接呼び出し）
- APIキー（`XAI_API_KEY`）はスクリプト内部でのみ環境変数として参照する。AIエージェント自身が `echo $XAI_API_KEY` 等でキーの値を参照・存在確認することは禁止
- スクリプトの標準出力・標準エラー出力・実行結果の報告に、APIキーの値を含めない（含まれる出力があった場合はマスクする）
- 参照画像（キャラクター設定画・既存の生成物など）がある場合、画像生成では必ずスクリプトの第3引数（カンマ区切りの画像パス、最大3枚）で渡す。テキストプロンプトだけで一貫性を保とうとしない
- 動画をImage-to-videoで生成する場合は `--image` で入力画像を渡す。Text-to-videoのみの場合は省略する
- 出力先パスがオーナーから指定されていない場合は確認する
- 生成された画像・動画のURLは一時URL（有効期限あり）のため、スクリプトが取得後すぐにダウンロード・保存する。レスポンスのURLをそのまま報告して終わらない

## 手順（画像生成）

1. `scripts/generate_image.sh` を実行する

参照画像なし（新規生成、`<PROMPT>`・`<DEST_PATH_IN_REPO>` を実際の値に置き換える。第4引数はアスペクト比、第5引数は解像度で省略可）：

```bash
bash /home/kuni/Documents/agent-harness/.claude/skills/grok-imagine/scripts/generate_image.sh \
  "<PROMPT>" \
  "<DEST_PATH_IN_REPO>" \
  "" \
  "<ASPECT_RATIO>" \
  "<RESOLUTION>"
```

- `ASPECT_RATIO`: `1:1`, `3:4`, `4:3`, `9:16`, `16:9`, `2:3`, `3:2`, `9:19.5`, `19.5:9`, `9:20`, `20:9`, `1:2`, `2:1`, `21:9`, `5:2`, `auto`（省略時 `auto`）
- `RESOLUTION`: `1k`, `2k`（省略時 `1k`）

参照画像あり（画像編集・合成、`<REF_IMAGE_1>,<REF_IMAGE_2>,...` はカンマ区切りで最大3枚まで）：

```bash
bash /home/kuni/Documents/agent-harness/.claude/skills/grok-imagine/scripts/generate_image.sh \
  "<PROMPT>" \
  "<DEST_PATH_IN_REPO>" \
  "<REF_IMAGE_1>,<REF_IMAGE_2>" \
  "<ASPECT_RATIO>" \
  "<RESOLUTION>"
```

- 単一画像編集時は出力比率が入力画像から自動検出されるため `ASPECT_RATIO` は無視される（引数としては渡してよいが実質未使用）
- プロンプト内で複数参照画像それぞれの役割を明示する（例：「1枚目の人物を2枚目の背景に合成して」）

2. スクリプトの終了コードと `Saved: <path>` の出力を確認し、生成が成功したことを確かめる

## 手順（動画生成）

1. `scripts/generate_video.sh` を実行する

Text-to-video（入力画像なし）：

```bash
bash /home/kuni/Documents/agent-harness/.claude/skills/grok-imagine/scripts/generate_video.sh \
  --prompt "<PROMPT>" \
  --out "<DEST_PATH_IN_REPO>.mp4" \
  --duration <SEC> \
  --aspect-ratio "<ASPECT_RATIO>" \
  --resolution "<RESOLUTION>"
```

Image-to-video（入力画像から動画生成）：

```bash
bash /home/kuni/Documents/agent-harness/.claude/skills/grok-imagine/scripts/generate_video.sh \
  --prompt "<PROMPT>" \
  --image "<FIRST_FRAME_IMAGE>" \
  --out "<DEST_PATH_IN_REPO>.mp4" \
  --duration <SEC> \
  --resolution "<RESOLUTION>"
```

- `--duration`: 1〜15秒（省略時8秒）
- `--aspect-ratio`: `1:1`, `16:9`, `9:16`, `4:3`, `3:4`, `3:2`, `2:3`（省略時16:9。Image-to-videoで省略すると入力画像の比率になる）
- `--resolution`: `480p` / `720p` / `1080p`（省略時480p）
- `--poll-interval` / `--poll-timeout`: 省略時それぞれ5秒 / 900秒

2. `完了: <path> (<サイズ>)` の出力を確認し、生成が成功したことを確かめる

## エラー時の対応

スクリプトが失敗した場合、代替手段で自己解決しない。
オーナーにエラー内容を報告し、指示を仰ぐ。エラー内容を報告する際もAPIキーの値は含めない。

## 出力

- 保存先のパス
- 何を生成したかの説明（1行）
- 画像・動画のどちらを生成したか
