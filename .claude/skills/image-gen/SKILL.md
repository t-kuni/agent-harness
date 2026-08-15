---
name: image-gen
description: codexを用いて画像を生成し、リポジトリ内の指定パスにコピーする。「画像を生成して」「画像を作って」などの指示で使う。
---

## ルール

- `codex exec` は `Bash` ツールで直接実行する（同期実行）。`TaskCreate` による非同期実行は禁止
- Bashツールの `timeout` パラメータに最低 **600000ms（10分）** を指定する（デフォルト2分ではタイムアウトする）
- codexは画像生成のみを担当する（セキュリティのため最小権限）
- 生成画像のリポジトリへの移動は claude code の責務
- 出力先パスがオーナーから指定されていない場合は確認する
- リファレンス画像（キャラクター設定画・既存の生成物など）がある場合、必ず `codex exec` の `--image` オプションで渡す。テキストプロンプトだけで一貫性を保とうとしない
  - `-i, --image <FILE>...` は複数値を取れるオプションのため、`--image path1 --image path2 "<prompt>"` のように書くと、プロンプト文字列まで `--image` の値として貪欲に読み込まれ、プロンプトが渡らずに失敗する
  - 必ず画像パスをカンマ区切りでまとめ、`--` でプロンプトと明示的に区切ること：`--image path1,path2 -- "<PROMPT>"`
  - プロンプト内で各画像の役割を明示する（例：「Image 1は○○のキャラクター設定画、Image 2は…」）

## 手順

1. codex で画像生成を実行し、出力をファイルに保存する（`<PROMPT>` を実際の生成指示に置き換える）

```bash
CODEX_OUTPUT=$(mktemp /tmp/image-gen-out.XXXXXX)
codex exec \
  --model gpt-5.5 \
  --sandbox read-only \
  --ephemeral \
  --skip-git-repo-check \
  --config 'approval_policy="never"' \
  "<PROMPT>" 2>&1 | tee "$CODEX_OUTPUT"
```

リファレンス画像を渡す場合は、上記コマンドの `"<PROMPT>"` の前に `--image <REF_IMAGE_1>,<REF_IMAGE_2>,... --` を挿入する（`<REF_IMAGE_n>` はリファレンス画像のパス）。

```bash
codex exec \
  --model gpt-5.5 \
  --sandbox read-only \
  --ephemeral \
  --skip-git-repo-check \
  --config 'approval_policy="never"' \
  --image <REF_IMAGE_1>,<REF_IMAGE_2> \
  -- \
  "<PROMPT>" 2>&1 | tee "$CODEX_OUTPUT"
```

2. 出力からセッションIDを取得し、生成画像のパスを特定する

```bash
SESSION_ID=$(grep "^session id:" "$CODEX_OUTPUT" | awk '{print $3}')
rm -f "$CODEX_OUTPUT"
GENERATED_IMAGE=$(ls ~/.codex/generated_images/$SESSION_ID/*.png 2>/dev/null | head -1)
```

3. 生成画像をリポジトリ内の指定パスにコピーする

```bash
cp "$GENERATED_IMAGE" <DEST_PATH_IN_REPO>
```

## エラー時の対応

codex コマンドが失敗した場合（認証エラー・コマンド不在・その他）、代替手段で自己解決しない。
オーナーにエラー内容を報告し、指示を仰ぐ。

## 出力

- コピー先のパス
- 何を生成したかの説明（1行）
