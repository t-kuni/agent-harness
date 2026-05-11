調査結果としては、現在の Claude Code では **Stop フックで実現するのが本命**です。  
ただし「stdout にリマインダーを出す」のではなく、`decision: "block"` または `exit 2` で停止をブロックし、`reason` / stderr を Claude へ返して「ハーネス改善処理を行ってから終了せよ」と続行させる必要があります。

参照した公式 docs: [Hooks reference](https://code.claude.com/docs/en/hooks), [Automate workflows with hooks](https://code.claude.com/docs/en/hooks-guide), [Skills](https://code.claude.com/docs/en/skills), [Memory / CLAUDE.md](https://code.claude.com/docs/en/memory)

**フックイベント一覧**
| イベント | 発火タイミング | Claude に出力が渡るか |
|---|---|---|
| `SessionStart` | セッション開始・resume・clear・compact 後 | はい。stdout / `additionalContext` が文脈へ入る |
| `Setup` | `--init-only`, `--init`, `--maintenance` | JSON `additionalContext` は渡せる。stdout は通常 debug |
| `InstructionsLoaded` | `CLAUDE.md` / rules 読み込み時 | 基本的に渡せない。監査向け |
| `UserPromptSubmit` | ユーザー prompt 処理前 | はい。stdout / `additionalContext` が prompt と一緒に入る |
| `UserPromptExpansion` | slash command 展開前 | はい。`additionalContext` を渡せる |
| `PreToolUse` | tool 実行前 | 拒否理由は Claude に渡る。通常 stdout は文脈化されない |
| `PermissionRequest` | 権限確認ダイアログ前 | deny の `message` は Claude に渡る |
| `PermissionDenied` | auto mode で tool が拒否された時 | `retry: true` で再試行可能メッセージを Claude に入れられる |
| `PostToolUse` | tool 成功後 | はい。`additionalContext` / `decision:block` の `reason` を渡せる |
| `PostToolUseFailure` | tool 失敗後 | はい。`additionalContext` を渡せる |
| `PostToolBatch` | 並列 tool 群の完了後、次の model call 前 | はい。`additionalContext` を渡せる |
| `Notification` | 通知発生時 | いいえ。主にユーザー通知・外部送信向け |
| `SubagentStart` | subagent 開始時 | subagent には `additionalContext` を渡せる |
| `SubagentStop` | subagent 終了時 | はい。Stop と同様に停止をブロック可能 |
| `TaskCreated` | task 作成時 | `exit 2` の stderr が model feedback になる |
| `TaskCompleted` | task 完了マーク時 | `exit 2` の stderr が model feedback になる |
| `Stop` | main Claude が応答を終えようとした時 | はい。`decision:block` / `exit 2` で Claude に続きを指示できる |
| `StopFailure` | API error 等で turn 終了 | いいえ。出力・exit code は無視 |
| `TeammateIdle` | agent team の teammate が idle 直前 | `exit 2` の stderr が teammate に渡る |
| `ConfigChange` | settings / skill 等の設定変更時 | block 理由は主にユーザー向け |
| `CwdChanged` | cwd 変更時 | 直接の Claude 文脈注入用途ではない |
| `FileChanged` | watch 対象ファイル変更時 | 直接の Claude 文脈注入用途ではない |
| `WorktreeCreate` | worktree 作成時 | stdout は worktree path として消費される |
| `WorktreeRemove` | worktree 削除時 | いいえ。cleanup 向け |
| `PreCompact` | compact 前 | block 可能だが、通常の作業後処理向けではない |
| `PostCompact` | compact 後 | いいえ。後処理・ログ向け |
| `SessionEnd` | セッション終了時 | いいえ。cleanup・ログ向け |
| `Elicitation` | MCP がユーザー入力要求時 | 応答をプログラム的に差し替え可能 |
| `ElicitationResult` | MCP 入力結果後 | 応答を差し替え可能 |

**実現方法、現実性が高い順**
1. **Stop hook で停止をブロックし、Claude に改善処理を続行させる**
   - メリット: 「作業後」のタイミングに最も近く、Claude に追加作業させられる。
   - デメリット: 無限ループ防止が必須。`stop_hook_active` や sentinel file で一度だけ発火させる必要がある。
   - 推奨。

2. **`CLAUDE.md` / `.claude/rules` に「最終応答前にハーネス改善を検討する」と書く**
   - メリット: 設定が簡単。常時効く。
   - デメリット: 自然言語指示なので遵守はベストエフォート。強制力は hook より弱い。

3. **`UserPromptSubmit` で前回セッション・前回 turn の反省材料を注入する**
   - メリット: stdout / `additionalContext` が確実に Claude に渡る。
   - デメリット: “タスク完了直後” ではなく次のユーザー prompt 時に効く。

4. **`PostToolUseFailure` / `PostToolBatch` で失敗直後に改善候補を注入する**
   - メリット: tool 失敗・遠回りをリアルタイムに扱える。
   - デメリット: 完了後の総括ではない。ノイズが増えやすい。

5. **`SessionEnd` で外部ログや改善候補ファイルを生成する**
   - メリット: セッション終了時の記録には向く。
   - デメリット: Claude には戻らないので、自律的な改善実行には不向き。

**推奨アプローチ**
最も推奨するのは、**Stop hook + CLAUDE.md の二段構え**です。  
Stop hook が終了を一度だけブロックして Claude に「改善処理を実行せよ」と返し、CLAUDE.md 側に改善判断基準と `/improve-harness` の使い方を書いておく構成が、強制力と保守性のバランスがよいです。

**settings.json 例**
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cat .claude/hooks/strictly-enforced-rules.md"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/auto-improve-harness-stop.sh"
          }
        ]
      }
    ]
  }
}
```

**Stop hook スクリプト例**
```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
ACTIVE="$(jq -r '.stop_hook_active // false' <<< "$INPUT")"
SESSION_ID="$(jq -r '.session_id' <<< "$INPUT")"
SENTINEL=".claude/tmp/auto-improve-harness-${SESSION_ID}.done"

mkdir -p .claude/tmp

if [[ "$ACTIVE" == "true" || -f "$SENTINEL" ]]; then
  exit 0
fi

touch "$SENTINEL"

jq -n --arg reason '
Before stopping, perform the harness improvement review.
Review this turn for tool failures, permission denials, repeated attempts, missing rules, or avoidable detours.
If a concrete improvement exists, invoke /improve-harness if available; otherwise follow .claude/skills/improve-harness/SKILL.md directly.
If no useful improvement exists, state that briefly and then finish.
' '{ decision: "block", reason: $reason }'
```

**CLAUDE.md 記述例**
```md
## Harness improvement before final stop

Before the final response of a task, review the session for:
- failed tool calls
- permission or hook errors
- repeated or avoidable commands
- missing repository rules
- knowledge that should be added to the harness

When a concrete improvement is useful, run `/improve-harness` if available.
If the slash command is not available, follow `.claude/skills/improve-harness/SKILL.md`.
Keep changes small and directly tied to the observed failure or detour.
If there is no actionable improvement, do not edit the harness.
```

注意点として、公式 docs では **command hook 自体は slash command や tool call を直接起動できない** とされています。したがって hook が `/improve-harness` を直接実行するのではなく、Stop をブロックして Claude 本体に「次にそれを実行せよ」と返す設計にするのが正攻法です。
