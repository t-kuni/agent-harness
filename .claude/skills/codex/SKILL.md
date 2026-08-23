---
name: codex
description: >
  what: codex CLI（OpenAIのコーディングエージェントCLI）を非対話（`codex exec`）で起動する方法の知識
  when: オーナーが codex／codex exec をコマンドとして実行するよう指示した時に参照する
---

# codex CLI（非対話実行）

OpenAI のコーディングエージェント CLI。コマンド名は `codex`。非対話（単発コマンド）実行は `codex exec` サブコマンド。

## 起動方法

* `codex exec` はBashツール経由で起動し、`run_in_background: true` を指定する
* 理由：実行に10分以上かかることがあるため

* 契約プランは ChatGPT Plus（個人向け有料プラン）を前提とする
* 調査時点: 2026-08-22

## 基本形

```bash
codex exec \
  -C /abs/path/to/project \
  --sandbox read-only \
  'プロンプト'
```

* `[PROMPT]` を渡さない、または `-` を渡すと標準入力からプロンプトを読む。標準入力をパイプしつつ引数も渡した場合、標準入力は `<stdin>` ブロックとして追記される
* `-a/--ask-for-approval` オプションは削除済み（`codex exec --help` に存在しない）。`codex exec` は承認方針が常に `never` 相当で固定されており、明示指定なしで承認待ちなしに実行される（実行結果ヘッダーの `approval: never` で確認済み）。承認プロンプトを人間に出したい場合の手段は現状ない
* 承認・サンドボックスまわりで現存するオプションは `-s/--sandbox`、`--approve-for-me`（自動レビュー経由でworkspace-write相当の承認を通す）、`--dangerously-bypass-approvals-and-sandbox`（全確認・サンドボックスを無効化。極めて危険なので使用しない）
* `--skip-git-repo-check` を付けるとGitリポジトリ外でも実行できる
* `--ephemeral` を付けるとセッションファイルをディスクに永続化しない
* `-o/--output-last-message <FILE>` でエージェントの最終メッセージだけをファイルに書き出せる
* `--json` で標準出力にイベントをJSONL形式で出力する

## サンドボックス・ファイルシステムアクセス制限

* `-C/--cd <DIR>` はエージェントの作業ルートを指定するオプション。`chroot` ではないため、これ単独では指定ディレクトリ以外を不可視化しない
* `--add-dir <DIR>` は追加で書き込み可能にするディレクトリ。1ディレクトリのみに絞りたい場合は使わない
* `--sandbox` は `read-only | workspace-write | danger-full-access` の3択
  * `read-only`: 読み取り中心。編集・外部コマンド実行・ネットワーク越境は承認対象になるが、`codex exec` は承認方針が常に無効なため、そのまま失敗としてモデルに返る
  * `workspace-write`: workspace内の読み書きと通常のローカルコマンドを許可。workspace外の編集やネットワークアクセスは承認対象
  * `danger-full-access`: サンドボックスなし。使用しない
* `sandbox_workspace_write.writable_roots`（`-c` 経由）は `workspace-write` での追加書き込みルート。厳密運用では増やさない
* `sandbox_workspace_write.network_access`（`-c` 経由、既定オフ）は `workspace-write` 内コマンドへのネットワーク許可
* 「指定ディレクトリ以外を一切見せない」に最も近い構成は、`-C` で作業ルートを固定した上で Permission Profile を `-c` 経由で上書きし、`:root` を `deny`、必要最小限のランタイム領域のみ `:minimal` を `read` にする方法。ただしOSレベルの完全な隔離（コンテナ相当）ではなく、Codexが定義するファイルシステム規則による制限である点に注意

```bash
codex exec \
  -C /abs/path/to/project \
  --sandbox read-only \
  -c 'default_permissions="workspace-only"' \
  -c 'permissions."workspace-only".extends=":workspace"' \
  -c 'permissions."workspace-only".filesystem.":root"="deny"' \
  -c 'permissions."workspace-only".filesystem.":minimal"="read"' \
  -c 'permissions."workspace-only".filesystem.":tmpdir"="deny"' \
  -c 'permissions."workspace-only".filesystem.":slash_tmp"="deny"' \
  -c 'web_search="disabled"' \
  'このディレクトリ内だけを調査して要約してください'
```

## 推論力（reasoning effort）

* 専用のCLIフラグはない。`-c 'model_reasoning_effort="..."'` で指定する
* 値は `minimal | low | medium | high | xhigh` を確認済み。`max` はモデル依存で、Config Referenceには明記されていない（UI上は Low/Medium/High/Extra High/Max/Ultra の表示があるが、Ultra はサブエージェントを使う別モードでありreasoning effortそのものではない）
* ハーネスとして安定して使える値は `minimal/low/medium/high/xhigh` とし、`max`／`ultra` はモデル・UIバージョン依存として扱う

```bash
codex exec \
  -C /abs/path/to/project \
  -m gpt-5.6-sol \
  -c 'model_reasoning_effort="high"' \
  --sandbox read-only \
  '設計上のリスクを洗い出してください'
```

## モデル選択

* `-m/--model` で指定する
* 2026-08-20時点で確認できた主な選択肢: `gpt-5.6`（`gpt-5.6-sol` のalias）、`gpt-5.6-terra`、`gpt-5.6-luna`、`gpt-5.5`
* `gpt-5.3-codex-spark` は Pro ユーザー向け research preview（Plus では使えない可能性が高いが未検証）
* `gpt-5.4` / `gpt-5.4-mini` は ChatGPTサインインのCodexでは2026-08-31に退役予定。保存済み設定は `gpt-5.4 -> gpt-5.6-terra`、`gpt-5.4-mini -> gpt-5.6-luna` へ自動置換される案内あり
* モデル一覧は変動が速いため、都度公式Docsまたは `codex --version` 等で最新を確認する

```bash
codex exec \
  -C /abs/path/to/project \
  -m gpt-5.6-terra \
  --sandbox workspace-write \
  'テストを追加して必要な修正を行ってください'
```

## Web検索の許可

* トップレベルの `--search`（`exec` サブコマンドより前に置く）、または `-c 'web_search="live"'` で有効化する
* `web_search` の値は `disabled | cached | indexed | live` の4段階。既定は `cached`。`live` が `--search` 相当
* Web検索ツール（hosted search）は、ローカルコマンドのネットワークアクセス（`sandbox_workspace_write.network_access`）とは別系統。サンドボックスでローカルコマンドのネットワークを遮断していても、`web_search="live"` を有効にすればWeb検索自体は使える
* CLIヘルプ上は「有効化すれば都度承認なしで使える（no per-call approval）」とあるが、契約プランの利用可否・使用量への影響についてはオンライン公式Docsで強く明記された記述は確認できていない

```bash
codex --search exec \
  -C /abs/path/to/project \
  -m gpt-5.6-sol \
  --sandbox read-only \
  '最新の公式情報を検索して、この依存関係の移行方針を要約してください'
```

## ChatGPT Plusプランでの利用範囲

* サンドボックス・reasoning effort指定・モデル選択・Web検索の有効化は、いずれもプランではなくローカル設定（`--sandbox`、`-c`オプション、Permission Profile）で決まる機能であり、Plusだから使えない・挙動が変わるという記載はない
* 高いreasoning effortやモデル選択は使用量（allowance）を消費する。Plusでの5時間あたり・週あたりの具体的なメッセージ数上限は未確認（Proでは 5x/20xプランごとにSol/Terra/Lunaで目安値が公式Pricingページに記載されているが、Plus向けの数値は別途確認が必要）
* `gpt-5.3-codex-spark` はPro向けresearch previewと明記されており、Plusで使えるかは未検証

## 未確認事項

* ChatGPT Plusでの正確なレート制限（5時間あたり・週あたりのメッセージ数上限）
* `gpt-5.3-codex-spark` がPlusプランで選択可能かどうか
* Permission Profileによるファイルシステム制限が、コンテナ相当の完全な隔離と同等かどうか
