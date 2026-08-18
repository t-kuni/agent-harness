---
name: image-gen
description: codexを用いて画像を生成し、リポジトリ内の指定パスにコピーする。「画像を生成して」「画像を作って」などの指示で使う。codexがエラーになった場合はOpenAI gpt-image-2 APIにフォールバックする。
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
- `codex exec` がエラーになった場合（クォータ到達・認証エラー等）、オーナーへの確認なしに下記「フォールバック: OpenAI API直接呼び出し」に自動的に切り替えてよい

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

3. `GENERATED_IMAGE` が取得できなかった場合、または手順1でcodexがエラー終了した場合は、下記「フォールバック: OpenAI API直接呼び出し」を実行する

4. 生成画像をリポジトリ内の指定パスにコピーする

```bash
cp "$GENERATED_IMAGE" <DEST_PATH_IN_REPO>
```

## フォールバック: OpenAI API直接呼び出し

- `codex exec` がエラーになった場合（クォータ到達・認証エラー・コマンド不在等）に、`scripts/generate_image.sh` を使ってOpenAIの `gpt-image-2` APIを直接呼び出す
- APIキー（`OPENAI_API_KEY`）はスクリプト内部でのみ環境変数として参照する。AIエージェント自身が `echo $OPENAI_API_KEY` 等でキーの値を参照・存在確認することは禁止
- スクリプトの標準出力・標準エラー出力・実行結果の報告に、APIキーの値を含めない（含まれる出力があった場合はマスクする）
- リファレンス画像がある場合は、スクリプトの第3引数（カンマ区切りの画像パス）で渡す

参照画像なし（新規生成、`<PROMPT>` と `<DEST_PATH_IN_REPO>` を実際の値に置き換える）：

```bash
bash /home/kuni/Documents/agent-harness/.claude/skills/image-gen/scripts/generate_image.sh \
  "<PROMPT>" \
  "<DEST_PATH_IN_REPO>"
```

参照画像あり（画像編集・合成、`<REF_IMAGE_1>,<REF_IMAGE_2>,...` はカンマ区切りでまとめる）：

```bash
bash /home/kuni/Documents/agent-harness/.claude/skills/image-gen/scripts/generate_image.sh \
  "<PROMPT>" \
  "<DEST_PATH_IN_REPO>" \
  "<REF_IMAGE_1>,<REF_IMAGE_2>"
```

スクリプトの終了コードと `Saved: <path>` の出力を確認し、生成が成功したことを確かめる。

## エラー時の対応

codexコマンド・フォールバックのAPI直接呼び出しの両方が失敗した場合、代替手段で自己解決しない。
オーナーにエラー内容を報告し、指示を仰ぐ。エラー内容を報告する際もAPIキーの値は含めない。

## 出力

- コピー先のパス
- 何を生成したかの説明（1行）
- codex方式・フォールバック（API方式）のどちらで生成したか
