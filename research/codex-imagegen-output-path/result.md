調査結果です。前提として、手元の `codex-cli` は `0.130.0` でした。公式 docs でも `--sandbox` は `read-only | workspace-write | danger-full-access`、追加書き込み先は `--add-dir` で付与する形です。

**結論**

| 方法 | 可否 | 理由 |
|---|---:|---|
| 1. built-in `image_gen` + プロンプト指示 + `--sandbox read-only` | 不可能または非推奨 | built-in 画像生成自体は `$CODEX_HOME/generated_images/...` に保存されるが、指定先への copy/move は Codex のファイル書き込みになる。`read-only` では `/tmp/my-image.png` への書き込みを前提にできない。 |
| 2. built-in `image_gen` + `--sandbox workspace-write` + workspace 内パス | 条件付き可能 | built-in に直接出力先を渡すのではなく、生成後に Codex が workspace 内へ copy/move する。最終パスは事前に決められる。 |
| 3. `scripts/image_gen.py --out` を `codex exec` 経由で実行 | 可能 | CLI fallback は `--out <path>` を持つので、API 呼び出し成功時に指定パスへ直接保存できる。`OPENAI_API_KEY`、ネットワーク許可、出力先への書き込み権限が必要。 |

**1. built-in + `read-only`**

これは避けた方がいいです。

```bash
codex exec --sandbox read-only \
  '画像を生成して /tmp/my-image.png に保存してください'
```

この場合、built-in `image_gen` の成果物は通常どおり `~/.codex/generated_images/<session-id>/ig_*.png` に保存されます。ただし、`/tmp/my-image.png` へコピーする段階は sandbox のファイル書き込み制限に引っかかります。`read-only` は「ファイルを検査できるが編集できない」モードなので、無人実行で指定パス保存を保証する用途には向きません。

**2. built-in + `workspace-write`**

workspace 内なら実用上は可能です。ただし「生成前に built-in の保存先を変える」のではなく、「最終成果物の配置先を事前に決め、生成後にそこへコピーする」です。

```bash
mkdir -p ./tmp

codex exec \
  --sandbox workspace-write \
  -C "$PWD" \
  'imagegen を使って画像を1枚生成してください。生成後、選択した最終画像を ./tmp/generated.png にコピーしてください。最終回答では ./tmp/generated.png を保存先として報告してください。'
```

より機械処理しやすくするなら:

```bash
codex exec \
  --sandbox workspace-write \
  -C "$PWD" \
  --output-last-message ./tmp/codex-result.txt \
  'imagegen を使って画像を1枚生成し、最終画像を ./tmp/generated.png にコピーしてください。成功したら saved_path: ./tmp/generated.png だけを返してください。'
```

workspace 外に置きたい場合は、`danger-full-access` より `--add-dir` がよいです。

```bash
codex exec \
  --sandbox workspace-write \
  --add-dir /tmp \
  -C "$PWD" \
  'imagegen を使って画像を1枚生成し、最終画像を /tmp/my-image.png にコピーしてください。'
```

ただし built-in 方式では、途中生成物の初期保存先は引き続き `$CODEX_HOME/generated_images/...` です。

**3. CLI fallback + `--out`**

指定パスに確実に出したいなら、これが一番明確です。

```bash
export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
export IMAGE_GEN="$CODEX_HOME/skills/.system/imagegen/scripts/image_gen.py"

codex exec \
  --sandbox workspace-write \
  --add-dir /tmp \
  -c sandbox_workspace_write.network_access=true \
  -C "$PWD" \
  'OPENAI_API_KEY が利用可能である前提で、次を実行してください:
   python3 "$CODEX_HOME/skills/.system/imagegen/scripts/image_gen.py" generate \
     --prompt "A cozy alpine cabin at dawn" \
     --size 1024x1024 \
     --out /tmp/my-image.png
   成功したら /tmp/my-image.png だけを返してください。'
```

workspace 内に出すなら `--add-dir /tmp` は不要です。

```bash
mkdir -p ./output/imagegen

codex exec \
  --sandbox workspace-write \
  -c sandbox_workspace_write.network_access=true \
  -C "$PWD" \
  'python3 "$CODEX_HOME/skills/.system/imagegen/scripts/image_gen.py" generate \
     --prompt "A cozy alpine cabin at dawn" \
     --size 1024x1024 \
     --out ./output/imagegen/my-image.png'
```

注意点:

- `scripts/image_gen.py` は OpenAI Image API を直接使うので `OPENAI_API_KEY` が必要です。
- shell network は `--ask-for-approval never` では有効になりません。`sandbox_workspace_write.network_access=true` などの設定が必要です。
- `/tmp` は環境によって workspace-write で書けることがありますが、保証したいなら `--add-dir /tmp` を付けるのが堅いです。
- 既存ファイルがあると CLI は失敗します。上書きするなら `--force` を付けます。

**推奨**

事前確定パスが必須なら **3. CLI fallback + `--out`** を推奨します。保存先が API 実行コマンドの引数なので、`find` や生成後の探索に依存しません。

Codex built-in の利用枠や手軽さを優先するなら **2. `workspace-write` + 生成後 copy** が次点です。ただしこれは「最終配置先を固定できる」だけで、「built-in image_gen の初期出力先を固定する」方法ではありません。
