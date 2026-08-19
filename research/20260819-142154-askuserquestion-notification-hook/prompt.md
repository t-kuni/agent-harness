# このリポジトリについて

このリポジトリは Claude Code（Anthropic製CLIエージェント）のユーザー設定・プロジェクト設定を管理するリポジトリである。

Claude Code はユーザーのホームディレクトリの `~/.claude/settings.json`、およびプロジェクトルートの `.claude/settings.json` / `.claude/settings.local.json` に設定を持つ。設定ファイルには `hooks` フィールドがあり、Claude Codeのライフサイクル上の特定イベント（例：`Stop`、`Notification`、`PreToolUse`、`PostToolUse`、`UserPromptSubmit` など）が発生したタイミングでシェルコマンドを実行できる。各フックエントリは `matcher`（対象を絞り込む正規表現、ツール名にマッチさせるケースが多い）と `hooks`（実行するコマンドのリスト、各要素は `type: "command"` と `command` を持つ）から構成される。フックコマンドの標準入力には、そのイベントに関する情報がJSON形式で渡される（例：`Stop` イベントでは `last_assistant_message` などのフィールドを含むJSON）。

現在、このリポジトリのユーザー設定 `~/.claude/settings.json` には以下のフックが設定されている。

- `Stop` フック：Claude Codeの処理が完了した際（アシスタントの応答が完結し、ユーザーの入力待ちになったタイミング）に、`notify-send`（Linuxのデスクトップ通知コマンド）でOS通知を出し、さらに完了音（`paplay`で `.oga` ファイルを再生）を鳴らす
- `Notification` フック：既に登録されているが、現状は完了音を鳴らす処理のみで、デスクトップ通知（`notify-send`）は行っていない

Claude Codeにはユーザーとの対話中に選択肢を提示して回答を待つ `AskUserQuestion` というツールがあり、これが呼ばれるとClaude Codeの処理はユーザーの選択待ちで一時停止する。現状、この一時停止時には `Stop` フックの通知（`notify-send` によるデスクトップ通知）が発火せず、オーナーは処理が停止していることに気づきにくい。

# 問い

Claude Code（2026年8月時点の最新バージョン）において、`AskUserQuestion` ツールが呼ばれてユーザーの回答待ちで処理が一時停止した際にも、通常の作業完了時（`Stop` フック相当）と同様にオーナーへデスクトップ通知が届くようにするには、hooksの仕組み上どのような設定を行えばよいか。

具体的には以下を明らかにしたい。

- `AskUserQuestion` ツールの呼び出しによってユーザー入力待ちで一時停止した際に、どのフックイベント（`Notification`、`PreToolUse`、`PostToolUse`、その他）が実際に発火するのか。公式ドキュメントの記述と、可能であれば実際の挙動の根拠（イベントのペイロード内容、発火条件の詳細）
- `Notification` フックが `AskUserQuestion` の待機時にも発火する場合、そのフックコマンドの標準入力に渡されるJSONペイロードにはどのようなフィールドが含まれるか（例：待機理由を判別できるフィールドの有無、質問文や選択肢の内容が含まれるか）
- `PreToolUse` / `PostToolUse` フックで `matcher: "AskUserQuestion"` のように特定ツール名を指定して発火させることは可能か。可能な場合、`PreToolUse` と `PostToolUse` のどちらのタイミングでユーザーの回答待ち状態を検知できるか（`PostToolUse` はツール実行完了後に発火するため、ユーザーが回答した後になる可能性がある点に注意して調査すること）
- 上記のいずれの方法が、「`AskUserQuestion` によってユーザーの回答待ちで一時停止した瞬間」を最も正確に捉えられるフックイベントか
- Claude Code の hooks 設定ファイル（`settings.json`）における `Notification` イベントのマッチャー（`matcher`）の指定方法、およびフックコマンドがJSON標準入力から通知理由やメッセージ内容を取得する具体的な方法（`jq` などでの抽出例を含む）

# 出力要件

- 日本語で出力すること
- Claude Code の hooks の公式ドキュメント（`docs.claude.com` または `docs.anthropic.com` 配下の Hooks 関連ページ）を最優先の情報源とし、参照したURLを明記すること
- `AskUserQuestion` 呼び出し時に発火する具体的なフックイベント名を明示すること
- そのフックイベントの標準入力JSONペイロードの構造（フィールド一覧とサンプルJSON）を示すこと
- `settings.json` にそのまま追記できる、hooks設定のJSON例を示すこと（`notify-send` などのデスクトップ通知コマンドを使う想定でよい）
- 前提知識のない読者でも理解できる粒度で説明すること
- 選択肢や仮説は提示せず、現状の事実（公式ドキュメントおよび検証可能な挙動）のみを記述すること
