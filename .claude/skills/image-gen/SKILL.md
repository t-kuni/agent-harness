---
name: image-gen
description: codexを用いて画像を生成し、リポジトリ内の指定パスにコピーする。「画像を生成して」「画像を作って」などの指示で使う。
---

## ルール

- codexは画像生成のみを担当する（セキュリティのため最小権限）
- 生成画像のリポジトリへの移動は claude code の責務
- 出力先パスがオーナーから指定されていない場合は確認する

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
  "<PROMPT>" | tee "$CODEX_OUTPUT"
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
