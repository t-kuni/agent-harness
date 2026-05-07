# スキル一覧

## プロジェクトスキル（`.claude/skills/`）

| スキル名 | description | 種別 |
|---|---|---|
| `bootstrap-domain-harness` | 現在のタスクに必要なドメインハーネスを最小構成で作成または更新する | メタハーネス |
| `harness-guide` | ハーネスの概念定義・配置先判断・更新ポリシーを参照する（ハーネス編集時に使用） | メタハーネス |
| `improve-harness` | 直近タスクを振り返り、遠回りを減らすためにハーネスを更新する | メタハーネス |
| `owner-contract` | 新規タスクの目的・完了条件・制約・検証を構造化するテンプレートを参照する | メタハーネス |
| `random-word` | 企画・アイデア出し・ユーモアが欲しい場面で LLM の出力の偏りを防ぐため、ランダムな英単語またはトレンドワードを取得してプロンプトに混ぜる | メタハーネス |
| `research-prompt` | 外部AIエージェントへのリサーチ依頼プロンプトを生成し、research/ に保存する | メタハーネス |
| `verify-done` | 完了条件を検証に対応付け、実行して、完了可否を判定する | ドメインハーネス |

## システムスキル（Claude Code 組み込み）

| スキル名 | description | 種別 |
|---|---|---|
| `claude-api` | Build, debug, and optimize Claude API / Anthropic SDK apps | ドメインハーネス |
| `fewer-permission-prompts` | Scan your transcripts for common read-only Bash and MCP tool calls, then add a prioritized allowlist to reduce permission prompts | メタハーネス |
| `init` | Initialize a new CLAUDE.md file with codebase documentation | メタハーネス |
| `keybindings-help` | Use when the user wants to customize keyboard shortcuts, rebind keys, add chord bindings, or modify ~/.claude/keybindings.json | メタハーネス |
| `loop` | Run a prompt or slash command on a recurring interval | メタハーネス |
| `review` | Review a pull request | メタハーネス |
| `schedule` | Create, update, list, or run scheduled remote agents (routines) that execute on a cron schedule | メタハーネス |
| `security-review` | Complete a security review of the pending changes on the current branch | ドメインハーネス |
| `simplify` | Review changed code for reuse, quality, and efficiency, then fix any issues found | メタハーネス |
| `update-config` | Configure the Claude Code harness via settings.json (permissions, hooks, env vars, automated behaviors) | メタハーネス |
