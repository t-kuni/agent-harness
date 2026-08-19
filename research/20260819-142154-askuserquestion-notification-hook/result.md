# 結論

**2026年8月19日時点の最新公開版 Claude Code 2.1.235 では、`AskUserQuestion` による回答待ちを通知するには、`PreToolUse` フックに `matcher: "AskUserQuestion"` を設定します。**

`AskUserQuestion` の処理順序は次のとおりです。

1. Claude が質問内容と選択肢を生成する
2. **`PreToolUse` が発火する**
3. `AskUserQuestion` の対話画面が表示され、ユーザー回答待ちになる
4. ユーザーが回答する
5. ツールが正常終了する
6. **`PostToolUse` が発火する**

したがって、「質問が表示され、ユーザー回答待ちになる瞬間」を最も正確かつ即時に捉えられるのは、`Notification` ではなく **`PreToolUse` + `matcher: "AskUserQuestion"`** です。`PostToolUse` は回答後なので、この用途には遅すぎます。([code.claude.com](https://code.claude.com/docs/en/hooks))

なお、2026年8月19日時点で npm の `latest` が示す Claude Code のバージョンは **2.1.235** です。([registry.npmjs.org](https://registry.npmjs.org/%40anthropic-ai/claude-code/latest))

---

# 発火するフックイベント

## 1. `PreToolUse`

**発火します。**

現在の公式 Hooks リファレンスでは、`PreToolUse` がマッチできる組み込みツール名として、明示的に次が列挙されています。

- `Bash`
- `PowerShell`
- `Edit`
- `Write`
- `Read`
- `Glob`
- `Grep`
- `Agent`
- `WebFetch`
- `WebSearch`
- **`AskUserQuestion`**
- `ExitPlanMode`
- MCPツール

また公式ドキュメントは、`AskUserQuestion` の処理について「Claude が `AskUserQuestion` を呼ぶと、`PreToolUse` フックが発火する」と明記しています。([code.claude.com](https://code.claude.com/docs/en/hooks))

設定するマッチャーは次のとおりです。

```json
"matcher": "AskUserQuestion"
```

これはツール名への完全一致です。`PreToolUse`、`PostToolUse` などのツール系イベントでは、`matcher` が `tool_name` に対して評価されます。([code.claude.com](https://code.claude.com/docs/en/hooks))

---

## 2. `PostToolUse`

**発火しますが、ユーザーが回答した後です。**

公式リファレンスでは、`PostToolUse` は「ツールが正常に完了した直後」に発火し、マッチャーには `PreToolUse` と同じツール名を使用できるとされています。したがって、次の指定も有効です。

```json
"matcher": "AskUserQuestion"
```

ただし、`AskUserQuestion` はユーザーの回答を受け取るまでツール処理が完了しません。そのため、`PostToolUse` が発火するのは回答待ちに入った時点ではなく、**ユーザーが質問に回答してツールが完了した後**です。([code.claude.com](https://code.claude.com/docs/en/hooks))

---

## 3. `Notification`

**`AskUserQuestion` 専用の `Notification` イベントは発火しません。**

現在利用できる `Notification` のマッチャーは以下です。

| matcher | 発火条件 |
|---|---|
| `permission_prompt` | ツール使用の承認画面が約6秒間待機している |
| `idle_prompt` | Claudeの応答完了から約60秒経過し、ユーザーが入力していない |
| `auth_success` | 認証完了 |
| `elicitation_dialog` | MCPの入力フォームが表示され、約6秒間入力がない |
| `elicitation_url_dialog` | MCPがブラウザURLを開くよう要求し、約6秒間入力がない |
| `elicitation_complete` | MCP入力フォームが送信または閉じられた |
| `elicitation_response` | MCPへの回答が送信された |
| `agent_needs_input` | バックグラウンドセッションが入力待ちになった |
| `agent_completed` | バックグラウンドセッションが完了または失敗した |

この一覧に `AskUserQuestion`、`user_question`、`ask_user_question` などの通知種別はありません。([code.claude.com](https://code.claude.com/docs/en/hooks))

また、以下の理由から既存の通知種別も直接の代用にはなりません。

- `permission_prompt` は、ツール使用の**許可承認**を待っている場合の通知である
- `AskUserQuestion` は公式のツール一覧上、「Permission Required: No」のツールである
- `idle_prompt` は、Claudeが応答を完了して通常の次プロンプト待ちに入ってから約60秒後の通知であり、ツールの途中で回答待ちになる状態を示す即時イベントではない

したがって、`Notification` は `AskUserQuestion` の待機開始を識別するための公式な即時イベントではありません。([code.claude.com](https://code.claude.com/docs/en/tools-reference?utm_source=openai))

---

## 4. `PermissionRequest`

通常の `AskUserQuestion` 呼び出しでは、**`AskUserQuestion` 自体にツール使用許可が不要なため、回答待ちを示すイベントとしては発火しません**。

`PermissionRequest` は、ツール呼び出しに対して権限判断が必要になり、許可ダイアログを表示する場合のイベントです。質問内容への回答を待つ `AskUserQuestion` の入力ダイアログとは別のものです。([docs.claude.com](https://docs.claude.com/en/docs/claude-code/hooks))

---

# 最も正確なイベント

| イベント | 発火タイミング | 質問・選択肢 | 通知用途への適否 |
|---|---|---:|---|
| **`PreToolUse` / `AskUserQuestion`** | 質問画面を処理・表示する直前 | 取得可能 | **最適** |
| `PostToolUse` / `AskUserQuestion` | ユーザー回答後 | 入力と結果を取得可能 | 遅い |
| `Notification` | 各通知種別の条件を満たしたとき | 質問構造は含まれない | 不適 |
| `PermissionRequest` | ツール使用許可が必要なとき | 通常の質問回答待ちとは別 | 不適 |
| `Stop` | Claudeのターン完了時 | 最終応答のみ | ツール途中の待機では発火しない |

したがって、採用すべき設定は次です。

```text
PreToolUse
  └─ matcher: AskUserQuestion
       └─ notify-sendを実行
```

`PreToolUse` は厳密には質問画面の表示直前に発火しますが、現行の hooks において `AskUserQuestion` の待機開始に最も近い、即時かつ構造化されたイベントです。

---

# `PreToolUse` の標準入力JSON

## 共通フィールド

コマンドフックには、JSONが標準入力で渡されます。主要な共通フィールドは以下です。

| フィールド | 内容 |
|---|---|
| `session_id` | Claude Code セッションID |
| `prompt_id` | 現在処理しているユーザープロンプトのUUID。最初の入力前は存在しないことがある |
| `transcript_path` | 会話トランスクリプトJSONLのパス |
| `cwd` | フック発火時の作業ディレクトリ |
| `permission_mode` | `default`、`plan`、`acceptEdits`、`auto` など |
| `effort` | 利用可能な場合、現在のeffortレベル |
| `hook_event_name` | この場合は `"PreToolUse"` |
| `agent_id` | サブエージェント内の場合のみ |
| `agent_type` | サブエージェントまたは `--agent` 使用時 |

`PreToolUse` 固有のフィールドは次の3つです。

| フィールド | 内容 |
|---|---|
| `tool_name` | `"AskUserQuestion"` |
| `tool_input` | 質問、ヘッダー、選択肢など |
| `tool_use_id` | このツール呼び出しのID |

([code.claude.com](https://code.claude.com/docs/en/hooks))

## `tool_input.questions` の構造

各質問には次のフィールドが含まれます。

| フィールド | 内容 |
|---|---|
| `question` | ユーザーへ表示する完全な質問文 |
| `header` | 質問の短い見出し |
| `options` | 2～4個の選択肢 |
| `options[].label` | 選択肢名 |
| `options[].description` | 選択肢の説明 |
| `multiSelect` | 複数選択可能なら `true` |

([code.claude.com](https://code.claude.com/docs/en/agent-sdk/user-input))

## サンプルJSON

```json
{
  "session_id": "abc123",
  "prompt_id": "550e8400-e29b-41d4-a716-446655440000",
  "transcript_path": "/home/user/.claude/projects/example/transcript.jsonl",
  "cwd": "/home/user/project",
  "permission_mode": "plan",
  "effort": {
    "level": "high"
  },
  "hook_event_name": "PreToolUse",
  "tool_name": "AskUserQuestion",
  "tool_input": {
    "questions": [
      {
        "question": "どの実装方式を採用しますか？",
        "header": "実装方式",
        "options": [
          {
            "label": "方式A",
            "description": "既存コードを最小限変更します"
          },
          {
            "label": "方式B",
            "description": "新しい構造へリファクタリングします"
          }
        ],
        "multiSelect": false
      },
      {
        "question": "どの検証を実行しますか？",
        "header": "検証",
        "options": [
          {
            "label": "Unit test",
            "description": "単体テストを実行します"
          },
          {
            "label": "Lint",
            "description": "静的解析を実行します"
          }
        ],
        "multiSelect": true
      }
    ]
  },
  "tool_use_id": "toolu_01ABC123"
}
```

このJSONには質問文だけでなく、見出し、選択肢名、選択肢の説明、複数選択の可否が含まれます。

---

# 推奨する `settings.json` 設定

以下を `~/.claude/settings.json` の `"hooks"` 配下に追加します。

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "AskUserQuestion",
        "hooks": [
          {
            "type": "command",
            "command": "payload=$(cat); message=$(printf '%s' \"$payload\" | jq -r '.tool_input.questions | map(\"• \" + .question + \"\\n  選択肢: \" + ([.options[].label] | join(\" / \"))) | join(\"\\n\\n\")'); notify-send 'Claude Code: 回答が必要です' \"$message\""
          }
        ]
      }
    ]
  }
}
```

表示される通知本文は、例えば次のようになります。

```text
• どの実装方式を採用しますか？
  選択肢: 方式A / 方式B

• どの検証を実行しますか？
  選択肢: Unit test / Lint
```

既存の `settings.json` にすでに `"hooks"` や `"PreToolUse"` がある場合は、同名キーをもう一つ作るのではなく、既存の `PreToolUse` 配列へ次のオブジェクトを追加します。

```json
{
  "matcher": "AskUserQuestion",
  "hooks": [
    {
      "type": "command",
      "command": "payload=$(cat); message=$(printf '%s' \"$payload\" | jq -r '.tool_input.questions | map(\"• \" + .question + \"\\n  選択肢: \" + ([.options[].label] | join(\" / \"))) | join(\"\\n\\n\")'); notify-send 'Claude Code: 回答が必要です' \"$message\""
    }
  ]
}
```

---

# 完了音も鳴らす設定

通知に加えて `.oga` ファイルを再生する場合は、コマンドを次のようにします。

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "AskUserQuestion",
        "hooks": [
          {
            "type": "command",
            "command": "payload=$(cat); message=$(printf '%s' \"$payload\" | jq -r '.tool_input.questions | map(\"• \" + .question + \"\\n  選択肢: \" + ([.options[].label] | join(\" / \"))) | join(\"\\n\\n\")'); notify-send 'Claude Code: 回答が必要です' \"$message\"; paplay /usr/share/sounds/freedesktop/stereo/complete.oga >/dev/null 2>&1 &"
          }
        ]
      }
    ]
  }
}
```

既存の `Stop` フックと同じ音源を使う場合は、`paplay` のパスを既存設定と同じものに置き換えます。

---

# フックスクリプトを別ファイルにする場合

複雑なシェル処理を `settings.json` に直接書かず、スクリプトへ分離することもできます。

## `~/.claude/hooks/ask-user-notify.sh`

```bash
#!/usr/bin/env bash

set -u

payload=$(cat)

title="Claude Code: 回答が必要です"

message=$(
  printf '%s' "$payload" |
    jq -r '
      .tool_input.questions
      | map(
          "• " + .question
          + "\n  選択肢: "
          + ([.options[].label] | join(" / "))
        )
      | join("\n\n")
    '
)

notify-send "$title" "$message"

paplay /usr/share/sounds/freedesktop/stereo/complete.oga \
  >/dev/null 2>&1 &
```

実行権限を付けます。

```bash
chmod +x ~/.claude/hooks/ask-user-notify.sh
```

## `settings.json`

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "AskUserQuestion",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/ask-user-notify.sh"
          }
        ]
      }
    ]
  }
}
```

---

# `Notification` フックのペイロード

`Notification` フックが発火した場合、標準入力JSONには、共通フィールドに加えて次が含まれます。

| フィールド | 内容 |
|---|---|
| `message` | 通知メッセージ |
| `title` | 任意の通知タイトル。存在しない場合がある |
| `notification_type` | `permission_prompt`、`idle_prompt` などの通知種別 |

公式サンプルは次の構造です。

```json
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../transcript.jsonl",
  "cwd": "/Users/...",
  "hook_event_name": "Notification",
  "message": "Claude needs your permission",
  "title": "Permission needed",
  "notification_type": "permission_prompt"
}
```

([code.claude.com](https://code.claude.com/docs/en/hooks))

このペイロードには、以下は含まれません。

- `tool_name`
- `tool_input`
- `tool_use_id`
- `questions`
- 質問ごとの `options`
- `AskUserQuestion` であることを示す専用フィールド

そのため、`Notification` の `message` や `notification_type` から、`AskUserQuestion` の質問内容を構造的に取得することはできません。

---

# `Notification` のマッチャー指定

## すべての通知を受ける

`matcher` を省略するか、空文字列または `"*"` を指定します。

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/notification.sh"
          }
        ]
      }
    ]
  }
}
```

## 特定の通知種別だけ受ける

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/notification.sh"
          }
        ]
      },
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/notification.sh"
          }
        ]
      }
    ]
  }
}
```

複数の通知種別を一つのエントリで受ける場合は、次の指定も可能です。

```json
"matcher": "permission_prompt|idle_prompt"
```

`matcher` が空、`"*"`、または省略の場合は、そのイベントのすべての発生に一致します。([code.claude.com](https://code.claude.com/docs/en/hooks))

---

# `jq` による `Notification` ペイロードの取得例

```bash
#!/usr/bin/env bash

payload=$(cat)

notification_type=$(
  printf '%s' "$payload" |
    jq -r '.notification_type // ""'
)

title=$(
  printf '%s' "$payload" |
    jq -r '.title // "Claude Code"'
)

message=$(
  printf '%s' "$payload" |
    jq -r '.message // "Claude Code needs your attention"'
)

notify-send "$title" "$message"

printf 'notification_type=%s\n' "$notification_type" \
  >> "$HOME/.claude/notification.log"
```

一度 `payload=$(cat)` で標準入力全体を保存しているのは、標準入力を複数回直接読み込むことができないためです。

一つの `jq` 呼び出しで確認する場合は、次のようにできます。

```bash
jq '{
  event: .hook_event_name,
  type: .notification_type,
  title: .title,
  message: .message,
  session: .session_id,
  cwd: .cwd
}'
```

ただし、これは一般的な `Notification` の処理例であり、`AskUserQuestion` の質問文や選択肢を取得するものではありません。それらを取得するには `PreToolUse` の `.tool_input.questions` を使用します。

---

# 参照した公式ドキュメント

旧 `docs.claude.com` URLは、現在の `code.claude.com` にリダイレクトされます。

- Hooks reference  
  `https://docs.claude.com/en/docs/claude-code/hooks`  
  リダイレクト先：`https://code.claude.com/docs/en/hooks`

- Hooks guide  
  `https://docs.claude.com/en/docs/claude-code/hooks-guide`  
  リダイレクト先：`https://code.claude.com/docs/en/hooks-guide`

- Tools reference  
  `https://code.claude.com/docs/en/tools-reference`

- AskUserQuestion／ユーザー入力の構造  
  `https://code.claude.com/docs/en/agent-sdk/user-input`

公式 Hooks リファレンスは、`AskUserQuestion` を `PreToolUse` の対象ツールとして明記し、`tool_input.questions` の構造と、`PostToolUse` がツール完了後に発火することを規定しています。([docs.claude.com](https://docs.claude.com/en/docs/claude-code/hooks))
