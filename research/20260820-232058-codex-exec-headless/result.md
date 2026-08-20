以下は 2026-08-20 時点で確認した範囲です。Codex は更新が速いので、モデル一覧と制限値は `codex --version`、`codex debug models`、公式 Docs の最新表示で再確認してください。

**1. サンドボックス**

結論: `--sandbox` だけで「指定ディレクトリ以外を一切読ませない」用途には弱いです。現行ドキュメント上の最も近い方法は、`-C` で作業ディレクトリを指定し、Permission Profile で `:root = "deny"` を置き、必要最小限のランタイム領域だけ `:minimal = "read"` として許可する構成です。OpenAI Docs は、Permission Profile がファイルシステム規則とネットワーク規則を組み合わせる最小権限ポリシーだと説明しています。また「workspace folders writable while denying reads to the rest of the filesystem」の例を載せています。ただしその例も `:minimal` 例外を含むため、実用上は「指定ディレクトリ以外は原則不可、ただしツール実行に必要な最小 OS/ランタイム領域は読める」と理解すべきです。([learn.chatgpt.com](https://learn.chatgpt.com/codex/permissions)) ([learn.chatgpt.com](https://learn.chatgpt.com/codex/permissions))

用語補足: workspace は Codex が作業対象とみなすディレクトリ集合、Permission Profile は「どこを読める/書ける/拒否するか」を明示する設定です。

具体例:

```bash
codex exec \
  -C /abs/path/to/project \
  -a never \
  -c 'default_permissions="workspace-only"' \
  -c 'permissions."workspace-only".extends=":workspace"' \
  -c 'permissions."workspace-only".filesystem.":root"="deny"' \
  -c 'permissions."workspace-only".filesystem.":minimal"="read"' \
  -c 'permissions."workspace-only".filesystem.":tmpdir"="deny"' \
  -c 'permissions."workspace-only".filesystem.":slash_tmp"="deny"' \
  -c 'web_search="disabled"' \
  'このディレクトリ内だけを調査して要約してください'
```

各オプションの作用:

- `-C/--cd <DIR>`: Codex の作業ルートを指定します。`chroot` ではないため、単独では他ディレクトリを不可視化しません。
- `--add-dir <DIR>`: 追加の作業ディレクトリを与えます。厳密に 1 ディレクトリだけにしたい場合は使いません。
- `--sandbox read-only`: 読み取り中心。非対話で `-a never` と組み合わせると、編集・外部実行・ネットワーク越境を承認で逃がさず失敗させます。
- `--sandbox workspace-write`: workspace 内の読み書きと通常のローカルコマンドを許可します。workspace 外編集やネットワークは承認対象です。([learn.chatgpt.com](https://learn.chatgpt.com/codex/agent-approvals-security))
- `sandbox_workspace_write.writable_roots`: `workspace-write` の追加書き込みルートです。厳密運用では増やさない方がよいです。([developers.openai.com](https://developers.openai.com/codex/config-reference))
- `sandbox_workspace_write.network_access`: `workspace-write` 内のコマンドにネットワークを許可する設定です。既定ではオフです。([learn.chatgpt.com](https://learn.chatgpt.com/codex/agent-approvals-security))

**2. 推論力 reasoning effort**

`codex exec` では専用の `--reasoning-effort` フラグは、提示された help にはありません。公式 Config Reference では `model_reasoning_effort` が設定キーとして定義されており、`-c` 経由で指定できます。値は Codex 設定上、`minimal | low | medium | high | xhigh` です。`xhigh` はモデル依存です。([developers.openai.com](https://developers.openai.com/codex/config-reference))

具体例:

```bash
codex exec \
  -C /abs/path/to/project \
  -m gpt-5.6-sol \
  -c 'model_reasoning_effort="high"' \
  --sandbox read-only \
  -a never \
  '設計上のリスクを洗い出してください'
```

モデル差分については注意が必要です。OpenAI API の GPT-5.6 モデルページでは `gpt-5.6-sol`、`gpt-5.6-terra`、`gpt-5.6-luna` が `none low medium high xhigh max` をサポートすると表示されています。([learn.chatgpt.com](https://learn.chatgpt.com/api/docs/models)) 一方、Codex CLI の Config Reference は `max` を `model_reasoning_effort` の値として明記していません。Codex のモデル UI には Low/Medium/High/Extra High/Max/Ultra が表示されますが、Ultra はサブエージェントを使うモードで、単なる reasoning effort ではありません。([learn.chatgpt.com](https://learn.chatgpt.com/docs/models))

したがってハーネスに書くなら、`codex exec` の安定指定値は `minimal/low/medium/high/xhigh` とし、`max` や `ultra` はバージョン依存または UI/高度機能扱いとして注記するのが安全です。

**3. モデル選択**

`codex exec` では `-m/--model` でモデルを指定できます。公式 Models ページは、同じ `-m` が非対話実行でも使える例として `codex exec -m gpt-5.6 "Review the current changes"` を示しています。([learn.chatgpt.com](https://learn.chatgpt.com/docs/models))

具体例:

```bash
codex exec \
  -C /abs/path/to/project \
  -m gpt-5.6-terra \
  --sandbox workspace-write \
  -a never \
  'テストを追加して必要な修正を行ってください'
```

2026-08-20 時点で ChatGPT Pro の Codex で公式に確認できる主な選択肢:

- `gpt-5.6` / `gpt-5.6-sol`: Sol。`gpt-5.6` は Sol への alias と API docs に記載。
- `gpt-5.6-terra`
- `gpt-5.6-luna`
- `gpt-5.3-codex-spark`: Pro ユーザー向け research preview。([learn.chatgpt.com](https://learn.chatgpt.com/docs/models))
- `gpt-5.5`
- `gpt-5.4`
- `gpt-5.4-mini`

ただし `gpt-5.4` と `gpt-5.4-mini` は ChatGPT サインインの Codex では 2026-08-31 に退役予定と公式 Models ページにあります。保存設定では `gpt-5.4 -> gpt-5.6-terra`、`gpt-5.4-mini -> gpt-5.6-luna` へ置換するよう案内されています。([learn.chatgpt.com](https://learn.chatgpt.com/docs/models))

**4. Web検索の許可**

`codex` のトップレベル help では `--search` が live web search を有効化するオプションです。確実な形はトップレベルオプションとして `exec` の前に置くことです。

```bash
codex --search exec \
  -C /abs/path/to/project \
  -m gpt-5.6-sol \
  --sandbox read-only \
  -a never \
  '最新の公式情報を検索して、この依存関係の移行方針を要約してください'
```

`-c` 経由なら次のように書けます。

```bash
codex exec \
  -C /abs/path/to/project \
  -m gpt-5.6-sol \
  -c 'web_search="live"' \
  --sandbox read-only \
  -a never \
  '最新情報を検索して要約してください'
```

公式 Config Reference の `web_search` は `disabled | cached | indexed | live` です。既定は `cached`、`live` は `--search` と同等と説明されています。([developers.openai.com](https://developers.openai.com/codex/config-reference)) Web検索ツールは、ローカルコマンドのネットワークアクセスとは別系統です。つまり `sandbox_workspace_write.network_access=false` でも、`web_search="live"` を許可すれば hosted search tool は使えます。([learn.chatgpt.com](https://learn.chatgpt.com/codex/permissions))

「承認なしで使えるか」は、提示された `codex --help` には “no per-call approval” とあります。ただし、今回確認できたオンライン公式 Docs の該当箇所では、その文言自体は強く明記されていません。ハーネスには「CLI help では per-call approval なし。ただし Web検索自体は `web_search` 設定・管理ポリシー・プラン可用性に従う」と書くのが安全です。

**5. ChatGPT Proプランでの利用範囲**

ChatGPT Pro では Codex CLI と `codex exec` は利用対象です。Pricing ページは Pro が Plus の内容に加えて、GPT-5.3-Codex-Spark、Plus 比 5x または 20x の Codex usage を提供すると説明しています。([learn.chatgpt.com](https://learn.chatgpt.com/docs/pricing))

具体例:

```bash
codex exec \
  -C /abs/path/to/project \
  -m gpt-5.6-luna \
  -c 'model_reasoning_effort="low"' \
  --sandbox read-only \
  -a never \
  -c 'web_search="disabled"' \
  --ephemeral \
  'この変更差分を短くレビューしてください'
```

プラン起因の制限:

- サンドボックス: Pro だから緩くなる/厳しくなるという記載はありません。ローカル OS サンドボックスと Permission Profile の設定で決まります。
- 推論力: 高い reasoning effort はより多くの使用量を消費します。公式 Pricing は、モデル choice、context、reasoning、tool use、retrieval、caching が allowance に影響すると説明しています。([learn.chatgpt.com](https://learn.chatgpt.com/docs/pricing))
- モデル選択: Pro では GPT-5.6 系に加えて Pro-only の Spark が使えます。ただし古いモデルは退役予定があります。
- Web検索: Pro の機能表には Web search が含まれますが、使用量には影響し得ます。ローカルコマンドのネットワーク許可とは別設定です。
- レート制限: Pro 5x の目安は 5時間あたり Sol 50-500、Terra 125-1,000、Luna 1,250-10,000 local messages。Pro 20x は Sol 200-2,000、Terra 500-4,000、Luna 5,000-40,000 local messages。追加の weekly limit があり得ます。([learn.chatgpt.com](https://learn.chatgpt.com/docs/pricing))

主要情報源 URL:

- https://learn.chatgpt.com/docs/codex/cli
- https://learn.chatgpt.com/docs/models
- https://learn.chatgpt.com/docs/config-file/config-reference
- https://learn.chatgpt.com/docs/permissions
- https://learn.chatgpt.com/docs/sandboxing
- https://learn.chatgpt.com/docs/pricing
- https://developers.openai.com/api/docs/models
- https://github.com/openai/codex/blob/main/docs/exec.md
- https://github.com/openai/codex/blob/main/codex-rs/core/config.schema.json
