## 正式名称・提供元

- 正式 MCP 名: `io.github.elevenlabs/elevenlabs-mcp`
- 提供元: ElevenLabs 公式
- GitHub: https://github.com/elevenlabs/elevenlabs-mcp
- 配布形態: Python / PyPI パッケージ `elevenlabs-mcp`
- 実行コマンド: `elevenlabs-mcp`
- 最新 PyPI 版: `0.12.2`、Python 要件は `>=3.11`（PyPI 上では 2026-08-04 リリース）  
  公式 README と PyPI は、Claude Desktop / Cursor / Windsurf / OpenAI Agents などの MCP クライアント対応を明記している。GitHub README では MCP 名も `io.github.elevenlabs/elevenlabs-mcp` と示されている。参照: [GitHub README](https://github.com/elevenlabs/elevenlabs-mcp), [PyPI](https://pypi.org/project/elevenlabs-mcp/)。

## 導入の前提条件

1. ElevenLabs アカウントを作成する。
   - 公式 README は無料枠として月 10k credits があると説明している。
   - 音声生成・文字起こし・音楽生成など API を呼ぶ機能は ElevenLabs credits を消費する。

2. API キーを取得する。
   - 取得先: https://elevenlabs.io/app/settings/api-keys
   - ElevenLabs API は API キー認証を使い、キーは使用量・クォータの追跡にも使われる。
   - 個人 API キーの作成には Full Seat が必要。サービスアカウント API キーは multi-seat 顧客向けで、管理者が管理する。

3. Python 3.11 以上を用意する。
   - `uvx` 経由なら個別の仮想環境作成なしで実行できる。
   - `pip install elevenlabs-mcp` で通常インストールも可能。

4. プラン制約を確認する。
   - MP3 192kbps は Creator 以上、PCM 44.1kHz は Pro 以上が必要。
   - Data residency は Enterprise 機能。
   - Instant Voice Cloning は多くのプランで利用可能、Professional Voice Cloning は Creator 以上。
   - Zero Retention Mode / HIPAA 要件のユーザーは、公式 docs 上で MCP support が現時点では利用不可とされている。

## インストール手順

1. `uv` を入れる。

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

2. API キーを環境変数に入れる。

```bash
export ELEVENLABS_API_KEY="sk_..."
```

3. 動作確認として `uvx` で起動できるか確認する。

```bash
uvx elevenlabs-mcp
```

4. `pip` で導入する場合は次の通り。

```bash
python -m pip install elevenlabs-mcp
python -m elevenlabs_mcp --api-key "$ELEVENLABS_API_KEY" --print
```

`--print` は Cursor / Windsurf など、JSON 設定を貼り付けるタイプの MCP クライアントで使う設定生成に向いている。

## Claude Code での設定方法

### 方法 1: `claude mcp add` を使う

ローカル stdio MCP サーバーとして登録する。

```bash
claude mcp add \
  --env ELEVENLABS_API_KEY="$ELEVENLABS_API_KEY" \
  --transport stdio \
  elevenlabs \
  -- uvx elevenlabs-mcp
```

プロジェクト共有の `.mcp.json` に入れたい場合:

```bash
claude mcp add \
  --scope project \
  --env ELEVENLABS_API_KEY="$ELEVENLABS_API_KEY" \
  --transport stdio \
  elevenlabs \
  -- uvx elevenlabs-mcp
```

確認:

```bash
claude mcp list
claude mcp get elevenlabs
```

Claude Code の中では `/mcp` で接続状態を確認できる。Claude Code 公式 docs では stdio サーバー追加時に `--` 以降がサーバー実行コマンドとして渡されると説明されている。

### 方法 2: `.mcp.json` を直接書く

プロジェクトルートに `.mcp.json` を置く。

```json
{
  "mcpServers": {
    "elevenlabs": {
      "type": "stdio",
      "command": "uvx",
      "args": ["elevenlabs-mcp"],
      "env": {
        "ELEVENLABS_API_KEY": "${ELEVENLABS_API_KEY}"
      }
    }
  }
}
```

生成ファイルの入出力先を明示する場合:

```json
{
  "mcpServers": {
    "elevenlabs": {
      "type": "stdio",
      "command": "uvx",
      "args": ["elevenlabs-mcp"],
      "env": {
        "ELEVENLABS_API_KEY": "${ELEVENLABS_API_KEY}",
        "ELEVENLABS_MCP_BASE_PATH": "/absolute/path/to/audio-work",
        "ELEVENLABS_MCP_OUTPUT_MODE": "files"
      }
    }
  }
}
```

`ELEVENLABS_MCP_OUTPUT_MODE` は `files`、`resources`、`both` を指定できる。

### 方法 3: `claude mcp add-json` を使う

```bash
claude mcp add-json elevenlabs \
'{"type":"stdio","command":"uvx","args":["elevenlabs-mcp"],"env":{"ELEVENLABS_API_KEY":"${ELEVENLABS_API_KEY}"}}'
```

## Claude Desktop / Cursor / Windsurf での設定

### Claude Desktop

`claude_desktop_config.json` に追加する。

```json
{
  "mcpServers": {
    "ElevenLabs": {
      "command": "uvx",
      "args": ["elevenlabs-mcp"],
      "env": {
        "ELEVENLABS_API_KEY": "<insert-your-api-key-here>"
      }
    }
  }
}
```

Claude Desktop では `Claude > Settings > Developer > Edit Config` から編集する。Windows では Developer Mode の有効化が必要と README に記載されている。

### Cursor / Windsurf など

```bash
python -m pip install elevenlabs-mcp
python -m elevenlabs_mcp --api-key "$ELEVENLABS_API_KEY" --print
```

出力された MCP 設定 JSON を、各クライアントの MCP 設定画面または設定ファイルに貼り付ける。

## 利用可能な主なツール・機能

- 音声合成: `text_to_speech`
- 音声認識 / 文字起こし: `speech_to_text`
- 効果音生成: `text_to_sound_effects`
- Voice Library 検索: `search_voices`, `search_voice_library`, `get_voice`
- モデル一覧: `list_models`
- 音声クローン: `voice_clone`
- 音声変換 / Voice Changer: `speech_to_speech`
- 音声分離: `isolate_audio`
- Voice Design: `text_to_voice`, `create_voice_from_preview`
- Conversational AI Agent: `create_agent`, `list_agents`, `get_agent`
- ナレッジベース追加: `add_knowledge_base_to_agent`
- 会話履歴: `list_conversations`, `get_conversation`
- エージェント会話シミュレーション: `simulate_conversation`
- 電話番号 / アウトバウンド通話: `list_phone_numbers`, `make_outbound_call`
- ローカル音声再生: `play_audio`
- 音楽生成: `compose_music`, `create_composition_plan`
- 動画から BGM 生成: `video_to_music`
- 音楽 inpainting 用アップロード: `upload_music_for_inpainting`
- MCP resource 出力: `elevenlabs://{filename}`

## 既知の制約・注意点

- `ELEVENLABS_API_KEY` が未設定だとサーバー起動時にエラーになる。
- 多くのツールは ElevenLabs API を呼ぶため credits を消費する。
- 入力ファイルを扱うツールは `ELEVENLABS_MCP_BASE_PATH` 配下のファイルだけを読む。未指定時の既定は `~/Desktop`。
- `uvx` が見つからない場合は `which uvx` で絶対パスを確認し、`command` に `/usr/local/bin/uvx` のような絶対パスを指定する。
- MCP Inspector では voice design や audio isolation など長時間処理で timeout が出る場合があるが、README は Claude では通常発生しないとしている。
- `ELEVENLABS_API_RESIDENCY` は data residency 用。Data residency 自体は Enterprise 機能で、リージョンごとに別 API URL・別 API key が必要。
- Zero Retention Mode または HIPAA compliance が必要なユーザーには、公式 docs 上で MCP support は現時点で利用不可とされている。
- 音声クローンは権利・同意・利用規約の確認が必須。

## 参照した公式ドキュメント URL 一覧

- https://github.com/elevenlabs/elevenlabs-mcp
- https://pypi.org/project/elevenlabs-mcp/
- https://elevenlabs.io/blog/introducing-elevenlabs-mcp
- https://elevenlabs.io/docs/overview/administration/workspaces/api-keys
- https://elevenlabs.io/docs/api-reference/authentication
- https://elevenlabs.io/docs/overview/capabilities/text-to-speech
- https://elevenlabs.io/docs/overview/capabilities/voices
- https://elevenlabs.io/docs/overview/administration/data-residency
- https://elevenlabs.io/docs/eleven-api/resources/zero-retention-mode
- https://code.claude.com/docs/en/mcp
