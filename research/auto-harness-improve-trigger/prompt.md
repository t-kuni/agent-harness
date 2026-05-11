# リサーチ課題

## このリポジトリについて

このリポジトリは「ハーネス」と呼ばれる Claude Code（Anthropic製AIエージェントCLI）向けの知識ファイル群を管理するリポジトリである。

Claude Code は `.claude/` ディレクトリ以下に以下のような設定を持つ：
- `settings.json` : 権限・フックの設定
- `hooks/` : 各種イベント時に実行されるシェルスクリプト
- `skills/` : スラッシュコマンドで呼び出せるスキル定義

### 現在の hooks 設定（settings.json）

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
            "command": "bash .claude/hooks/suggest-improve-harness.sh"
          }
        ]
      }
    ]
  }
}
```

### Stop フックの現状の課題

`Stop` フックは Claude が応答を完全に終えた後に実行される。
そのため、Stop フックのシェルスクリプト出力を Claude が受け取ってさらに処理することはできない。
現在の `suggest-improve-harness.sh` はオーナー（ユーザー）に対して「/improve-harness を実行してください」と促すだけのリマインダーであり、自動化されていない。

### 目的

タスク完了後、Claudeがこれまでの作業（ツール呼び出しの失敗・エラー・遠回り）を自律的に振り返り、ハーネス改善スキルを自動実行する仕組みを作りたい。

## 問い

Claude Code の hooks システムにおいて、「Claude がタスクを完了した後に自律的にハーネス改善処理を実行する」ことを実現するための方法は何か？

具体的には以下を明らかにしたい：

1. Claude Code の hooks イベント種別の一覧と、各イベントのフック出力が Claude に渡されるかどうか
2. Stop フック以外に「タスク完了後」のタイミングで Claude に追加処理させる方法
3. CLAUDE.md や rules などの仕組みを使って「作業後に自律的にハーネス改善を実行するよう Claude に指示する」ことが可能かどうか
4. 現実的な代替アプローチ（例：UserPromptSubmit フックの活用、CLAUDE.md への記述、etc.）

## 期待する出力形式

- 日本語で回答すること
- 各フックイベントの挙動を表形式で整理する
- 「自動ハーネス改善」を実現する方法を、実現可能性の高い順に箇条書きで列挙する
- 各方法のメリット・デメリットを簡潔に記載する
- 最も推奨するアプローチを1つ選び、その理由を述べる
- 具体的な設定例（settings.json の記述や CLAUDE.md の記述例）があれば示す
