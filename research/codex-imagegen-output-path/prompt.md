# codex image_gen ツールの出力先パス指定方法のリサーチ

## 背景

`codex exec` コマンドで画像生成を行っている。生成された画像は `~/.codex/generated_images/<session-id>/ig_*.png` に保存される。現在は生成後に `find` でファイルを特定しているが、生成前にパスを確定させたい。

## ローカルのドキュメントから判明していること

`~/.codex/skills/.system/imagegen/SKILL.md` には以下の記述がある：

- built-in `image_gen` ツールの出力先は `$CODEX_HOME/generated_images/` 配下（デフォルト）
- "Do not describe or rely on a destination-path argument (if any) on the built-in `image_gen` tool."
- "If the user names a destination, move or copy the selected output there." → ユーザーがパスを指定すれば、codex がそこへコピーする

CLI フォールバック（`scripts/image_gen.py`）には `--out <path>` オプションがあり、出力先を直接指定できる。

現在の `codex exec` 呼び出しは `--sandbox read-only` を使用している。

## 問い

以下の方法で、claude code 側が事前に確定したパス（例：`/tmp/my-image.png`）に画像を保存させることは可能か？

1. **built-in image_gen + プロンプト指示**: `codex exec --sandbox read-only` で「/tmp/my-image.png に保存してください」と指示した場合、codex は生成後にそのパスへコピーできるか（`--sandbox read-only` では `/tmp` への書き込みが制限されるか）

2. **built-in image_gen + sandbox 変更**: `--sandbox workspace-write` に変えてワークスペース内のパス（例：`./tmp/generated.png`）を指定すれば、事前に確定したパスに保存できるか

3. **CLI フォールバック**: `scripts/image_gen.py --out /tmp/my-image.png` を `codex exec` 経由で実行すれば、指定パスに確実に保存できるか。その場合の `sandbox` 設定は何が適切か

## 期待する出力形式

- 各方法の実現可否（可能・不可能・条件付き可能）
- 可能な場合の具体的なコマンド例
- `--sandbox` 設定と `/tmp` や ワークスペース外パスへの書き込み可否の関係
- 推奨アプローチとその理由

出力は日本語で記述してください。
