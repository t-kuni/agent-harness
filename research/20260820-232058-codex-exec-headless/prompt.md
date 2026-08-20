# このリポジトリについて

このリポジトリは「ハーネス」と呼ばれる、AIエージェント（Claude Code）が参照する知識ファイル群を管理するリポジトリである。
`codex`（OpenAIが提供するCLIツール）を単発の非対話コマンドとして起動するための知識をハーネスに追加する目的でこのリサーチを行っている。

`codex` CLIの `--help` および `codex exec --help` の出力は以下の通り（ローカル環境で実行して取得したもの）。

```
Codex CLI

If no subcommand is specified, options will be forwarded to the interactive CLI.

Usage: codex [OPTIONS] [PROMPT]
       codex [OPTIONS] <COMMAND> [ARGS]

Commands:
  exec            Run Codex non-interactively [aliases: e]
  review          Run a code review non-interactively
  login           Manage login
  logout          Remove stored authentication credentials
  mcp             Manage external MCP servers for Codex
  plugin          Manage Codex plugins
  mcp-server      Start Codex as an MCP server (stdio)
  app-server      [experimental] Run the app server or related tooling
  remote-control  [experimental] Manage the app-server daemon with remote control enabled
  completion      Generate shell completion scripts
  update          Update Codex to the latest version
  doctor          Diagnose local Codex installation, config, auth, and runtime health
  sandbox         Run commands within a Codex-provided sandbox
  debug           Debugging tools
  apply           Apply the latest diff produced by Codex agent as a `git apply` to your local
                  working tree [aliases: a]
  resume          Resume a previous interactive session (picker by default; use --last to continue
                  the most recent)
  archive         Archive a saved session by id or session name
  delete          Permanently delete a saved session by id or session name
  unarchive       Unarchive a saved session by id or session name
  fork            Fork a previous interactive session (picker by default; use --last to fork the
                  most recent)
  cloud           [EXPERIMENTAL] Browse tasks from Codex Cloud and apply changes locally
  exec-server     [EXPERIMENTAL] Run the standalone exec-server service
  features        Inspect feature flags
  help            Print this message or the help of the given subcommand(s)

Arguments:
  [PROMPT]
          Optional user prompt to start the session

Options:
  -c, --config <key=value>
          Override a configuration value that would otherwise be loaded from `~/.codex/config.toml`.
          Use a dotted path (`foo.bar.baz`) to override nested values. The `value` portion is parsed
          as TOML. If it fails to parse as TOML, the raw string is used as a literal.

          Examples: - `-c model="o3"` - `-c 'sandbox_permissions=["disk-full-read-access"]'` - `-c
          shell_environment_policy.inherit=all`

      --enable <FEATURE>
          Enable a feature (repeatable). Equivalent to `-c features.<name>=true`

      --disable <FEATURE>
          Disable a feature (repeatable). Equivalent to `-c features.<name>=false`

      --remote <ADDR>
          Connect the TUI to a remote app server endpoint.

          Accepted forms: `ws://host:port`, `wss://host:port`, `unix://`, or `unix://PATH`.

      --remote-auth-token-env <ENV_VAR>
          Name of the environment variable containing the bearer token to send to a remote app
          server websocket

      --strict-config
          Error out when config.toml contains fields that are not recognized by this version of
          Codex

  -i, --image <FILE>...
          Optional image(s) to attach to the initial prompt

  -m, --model <MODEL>
          Model the agent should use

      --oss
          Use open-source provider

      --local-provider <OSS_PROVIDER>
          Specify which local provider to use (lmstudio or ollama). If not specified with --oss,
          will use config default or show selection

  -p, --profile <CONFIG_PROFILE_V2>
          Layer $CODEX_HOME/<name>.config.toml on top of the base user config

  -s, --sandbox <SANDBOX_MODE>
          Select the sandbox policy to use when executing model-generated shell commands

          [possible values: read-only, workspace-write, danger-full-access]

      --approve-for-me
          Route approval requests through automatic review using the workspace-write sandbox

      --dangerously-bypass-approvals-and-sandbox
          Skip all confirmation prompts and execute commands without sandboxing. EXTREMELY
          DANGEROUS. Intended solely for running in environments that are externally sandboxed

      --dangerously-bypass-hook-trust
          Run enabled hooks without requiring persisted hook trust for this invocation. DANGEROUS.
          Intended only for automation that already vets hook sources

  -C, --cd <DIR>
          Tell the agent to use the specified directory as its working root

      --add-dir <DIR>
          Additional directories that should be writable alongside the primary workspace

  -a, --ask-for-approval <APPROVAL_POLICY>
          Configure when the model requires human approval before executing a command

          Possible values:
          - untrusted:  Only run "trusted" commands (e.g. ls, cat, sed) without asking for user
            approval. Will escalate to the user if the model proposes a command that is not in the
            "trusted" set
          - on-request: The model decides when to ask the user for approval
          - never:      Never ask for user approval Execution failures are immediately returned to
            the model

      --search
          Enable live web search. When enabled, the native Responses `web_search` tool is available
          to the model (no per‑call approval)

      --no-alt-screen
          Disable alternate screen mode

  -h, --help
          Print help (see a summary with '-h')

  -V, --version
          Print version
```

```
Run Codex non-interactively

Usage: codex exec [OPTIONS] [PROMPT]
       codex exec [OPTIONS] <COMMAND> [ARGS]

Commands:
  resume  Resume a previous session by id or pick the most recent with --last
  review  Run a code review against the current repository
  help    Print this message or the help of the given subcommand(s)

Arguments:
  [PROMPT]
          Initial instructions for the agent. If not provided as an argument (or if `-` is used),
          instructions are read from stdin. If stdin is piped and a prompt is also provided, stdin
          is appended as a `<stdin>` block

Options:
  -c, --config <key=value>
          Override a configuration value that would otherwise be loaded from `~/.codex/config.toml`.
          ...

  -m, --model <MODEL>
          Model the agent should use

  -s, --sandbox <SANDBOX_MODE>
          Select the sandbox policy to use when executing model-generated shell commands

          [possible values: read-only, workspace-write, danger-full-access]

  -a, --ask-for-approval <APPROVAL_POLICY>
          (see above)

  -C, --cd <DIR>
          Tell the agent to use the specified directory as its working root

      --add-dir <DIR>
          Additional directories that should be writable alongside the primary workspace

      --skip-git-repo-check
          Allow running Codex outside a Git repository

      --ephemeral
          Run without persisting session files to disk

      --output-schema <FILE>
          Path to a JSON Schema file describing the model's final response shape

      --json
          Print events to stdout as JSONL

  -o, --output-last-message <FILE>
          Specifies file where the last message from the agent should be written

  -h, --help
          Print help (see a summary with '-h')
```

# 問い

`codex` CLI（OpenAIのコーディングエージェントCLI、契約プランはChatGPT Proサブスクリプション）を、単発の非対話コマンド（`codex exec`）として起動する場合の、以下5点について、公式ドキュメント（OpenAIの公式サイト・公式GitHubリポジトリ `openai/codex` のドキュメント）を根拠に明らかにせよ。

1. **サンドボックス**: `codex exec` を実行した際、指定したディレクトリ以外のファイルシステムを一切見せない（読み書き不可にする）独立したサンドボックス環境で動作させるには、どのオプション・設定をどう組み合わせればよいか。`--sandbox`、`-C/--cd`、`--add-dir` 等の各オプションが具体的にファイルシステムアクセスにどう作用するか、`read-only` と `workspace-write` の違いを含めて説明せよ。
2. **推論力（reasoning effort）**: `codex exec` で推論力（reasoning effort）を指定できるか。できる場合、指定方法（CLIオプション名・`-c` 経由の設定キー名）と、選択可能な値の一覧を、対応モデルごとの違いも含めて明らかにせよ。
3. **モデル選択**: `codex exec` でモデルを選択できるか。できる場合、指定方法（`-m/--model` の値）と、2026年8月時点でChatGPT Pro契約で選択可能なモデルの一覧を明らかにせよ。
4. **Web検索の許可**: `codex exec` でWeb検索ツールを有効化する方法（`--search` オプション、または `-c` 経由の設定キー）を明らかにせよ。有効化した場合の挙動（承認なしで使えるか等）も含めて説明せよ。
5. **ChatGPT Proプランでの利用範囲**: ChatGPT Pro（API従量課金ではなくChatGPTサブスクリプション経由でのcodexログイン）で `codex exec` を利用する場合、上記1〜4の機能（サンドボックス・推論力指定・モデル選択・Web検索）についてプラン起因の制限（利用可能なモデルの制限、レートリミット、機能制限など）があるかどうかを明らかにせよ。

# 出力要件

- 日本語で出力すること
- 前提知識のない読者でも理解できるように、専門用語には簡単な補足を添えること
- 上記1〜5の項目ごとに見出しを立てて回答すること
- 各項目について、実際に動作する具体的なコマンド例（フルオプション）を1つ以上示すこと
- 情報源のURLを明記すること
- 情報が古い可能性がある場合や、公式ドキュメントで明言されていない場合はその旨を明記すること
