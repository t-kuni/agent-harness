# Claude Code前提のハーネスエンジニアリング向け汎用リポジトリテンプレート

## 調査の前提

一次情報源は、主に entity["organization","Anthropic","ai company"] の Claude Code 公式ドキュメントである。公式の docs map は 2026-05-02 UTC 時点で、CLI、 memory、rules、skills、subagents、hooks、MCP、Agent SDK、各種統合までの全体像を整理している。本報告は、その英語ドキュメント群を前提に、提示されたハーネス方針へ落とし込んだ設計提案である。 citeturn3view0turn2search4

Claude Code は同じ基盤エンジンを CLI、IDE、Desktop、web など複数の表面から利用できるが、リポジトリテンプレートの観点で重要なのは、project scope で commit されるファイル群である。公式には `CLAUDE.md`、`.claude/settings.json`、`.claude/rules/`、`.claude/skills/`、`.mcp.json` などが project-scoped の主な置き場であり、ここに「毎回読む短い知識」「対象限定ルール」「オンデマンド手順」「外部連携」を分解して配置できる。 citeturn7search0turn14view3turn23search1

あなたの定義に従うなら、ハーネスは「タスク遂行に必要な固有知識」と「それを自己改善する枠組み」であり、メタハーネスは前者の配置・更新・検証設計を司る層、ドメインハーネスは具体タスクを速く正確に進める知識層になる。Claude Code の機能群はこの二層構造と整合しやすく、特に `CLAUDE.md`、rules、skills、hooks、MCP、subagents が対応先として明確である。 citeturn8search0turn9view3turn10view3turn15view0turn18view0turn5search2turn16view0

## Claude Codeの機能棚卸し

中核の agentic loop は、モデルが「調査・行動・検証」を反復しながら、Read / Edit / Write / Bash / Glob / Grep / WebSearch / WebFetch などの built-in tools を使う構造である。built-in tools には schedule 系、todo/task 系、subagent 起動、MCP resource 読み取りなども含まれ、plan mode や checkpointing も標準で備わるため、単なる会話ツールではなく「探索して、変更して、検証して、巻き戻せる」実行環境として見た方が正確である。 citeturn5search0turn14view0turn13search1

知識・記憶レイヤでは、`CLAUDE.md` が every session で読む永続指示、`.claude/rules/*.md` が path-scoped ルール、skills が必要時だけ本体を読み込む再利用手順、auto memory が machine-local な補助的記憶として位置付けられている。公式には `CLAUDE.md` は短く具体的に書くべきで、手順化された長い内容は skill へ、対象限定の制約は rules へ逃がすのが基本である。また Claude Code は `AGENTS.md` を直接は読まず、必要なら `CLAUDE.md` から import する。 citeturn9view3turn10view3turn15view0turn15view2turn15view4turn9view0turn25view2

統制・自動化レイヤでは、hooks が最重要である。公式に hooks は「LLM がたまたまそうする」のではなく、「そのイベントでは必ずこの処理を走らせる」という決定論的制御のための仕組みであり、`SessionStart`、`PreToolUse`、`PermissionRequest`、`PostToolUse`、`InstructionsLoaded`、`PreCompact`、`PostCompact` など多数のイベントを持つ。permissions も細かく設定でき、`plan`、`acceptEdits`、`dontAsk`、`auto`、`bypassPermissions` などの mode を用途別に選べる。 citeturn2search7turn18view0turn18view1turn14view2turn26view0turn26view1turn26view2turn26view3turn26view4

並列化・役割分担レイヤでは、built-in subagents の Explore、Plan、general-purpose がすでにあり、Explore は read-only の高速調査、Plan は plan mode 補助、general-purpose は行動込みの複雑タスク向けである。custom subagents も作れるが、agent teams は experimental かつ disabled by default で、token cost と coordination overhead が大きいので、常用よりも大規模な並列研究向けと見るべきである。 citeturn16view0turn16view1turn16view4turn7search3

外部システムや CI と結ぶ面では、Claude Code は MCP で外部データ・外部操作を取り込み、tool search で MCP の文脈コストを抑えられる。さらに `claude -p` と Agent SDK で非対話実行でき、entity["company","GitHub","developer platform"] Actions と entity["company","GitLab","devops platform"] CI/CD の公式統合も用意されている。`Code Review` もあるが、これは managed review service であり、リポジトリ内テンプレートの中核というより周辺自動化である。 citeturn5search2turn19view2turn7search2turn14view1turn23search0turn1view1turn28search0turn28search1

実行面は CLI が最も完全で、Desktop / VS Code / JetBrains / web / mobile / Remote Control は同じエンジンの表面違いである。beta の Chrome 連携はブラウザ検証、computer use は GUI-only 作業、entity["company","Slack","work chat platform"] 連携は coding intent を Claude Code on the web へ振り分ける用途に向く。一方、output styles は応答の口調や構造を変える機能であり、知識の保存先ではない。 citeturn22search2turn1view2turn22search0turn22search1turn12search3turn27search0turn27search1turn21search0turn13search0

## 本要件に対する採用方針

1. リポジトリの SSoT は commit されたファイルに置く。auto memory は便利だが machine-local で、同じ repo の worktree 間では共有されても、別マシンや cloud session では共有されないため、メタハーネスやドメインハーネスの本体に使うべきではない。auto memory は補助記憶、repo 内ドキュメントは共有知識、と役割を分離するのがよい。 citeturn10view1turn10view2

2. `CLAUDE.md` は「毎回必要な短い運用原則」だけに限定する。公式も project-wide な broad instructions を `CLAUDE.md` に置き、長くなりすぎるなら rules や skills に分解することを勧めている。したがって、ハーネス定義そのものの全文を `CLAUDE.md` に埋め込むのではなく、短い routing と invariant だけを置き、知識本体は通常ファイルへ逃がす設計が適切である。 citeturn25view1turn25view2

3. メタハーネスの中心は `.claude/rules/` と `.claude/skills/` に分けるべきである。rules は path-specific に効かせられるので、「ハーネス文書を編集している時だけ」読みたい制約に向く。skills は body を必要時だけ読み込むため、「ドメインハーネスを起こす」「完了条件を決定論化する」「タスク終了後に自己改善する」といった反復手順に向く。 citeturn10view3turn10view4turn15view0turn15view2turn15view3

4. hooks は必須採用である。理由は、あなたの方針が「決定論的に検証できるなら、その工程を作り込む」にあるからで、これは Claude Code の hook 設計思想と一致する。base template では、まず compaction 後に重要原則を再注入する hook を入れ、のちに domain-specific な verifier 起動や protected-file guard を足していくのが安全で拡張しやすい。permissions は project-shared template に広範な allowlist を最初から埋めるより、必要になった時点で狭く追加する方がよい。 citeturn2search7turn17view4turn18view0turn14view2

5. 並列化は built-in の Explore / Plan subagents を基本とし、custom subagents と agent teams は base template から外す。custom subagents は recurring role が固まってから追加する方が maintenance cost が低い。agent teams は experimental で coordination overhead が高いので、「あらゆるタスクに適応可能なテンプレート」の初期構成に埋め込むべきではない。auto mode も research preview で plan・account・model 条件があり、安全保証の代替ではないため、前提機能にしない。 citeturn16view0turn16view1turn7search3turn26view2

6. `.mcp.json`、`claude -p`、Agent SDK、CI 統合は「検証と連携の入口」として採用する。ただし、これは domain harness 側に「何をどのコマンドで検証するか」が定義されてから価値が出る。`--bare` は hooks / skills / memory / MCP / `CLAUDE.md` を読み込まない再現性重視のモードなので、完全に固定化された scripted verification には向くが、日常の interactive harness engineering の基盤にはしない。 citeturn5search2turn19view0turn19view2turn7search2turn23search0turn1view1turn28search0

7. `AGENTS.md` は optional compatibility file として扱う。Claude Code 専用 repo なら primary file は `CLAUDE.md` でよいが、将来 multi-agent 化する可能性があるなら `AGENTS.md` を cross-agent-neutral な SSoT にして、`CLAUDE.md` の先頭から import する設計が最も重複を避けやすい。 citeturn9view0

## リポジトリ構成案

公式の project-scoped file roles に、あなたのメタハーネス / ドメインハーネスの二層構造を重ねると、最小で拡張しやすい構成は次になる。`/init` は starter を作るのに有用だが、継続運用では自前の curated template を repo に固定した方が SSoT として扱いやすい。 citeturn7search0turn25view0turn25view2

```text
.
├── README.md
├── CLAUDE.md
├── .gitignore
├── .mcp.json
├── .claude/
│   ├── settings.json
│   ├── hooks/
│   │   └── rehydrate-context.sh
│   ├── rules/
│   │   ├── harness-editing.md
│   │   └── verification-design.md
│   └── skills/
│       ├── bootstrap-domain-harness/
│       │   └── SKILL.md
│       ├── improve-harness/
│       │   └── SKILL.md
│       └── verify-done/
│           └── SKILL.md
└── harness/
    ├── meta/
    │   ├── definition.md
    │   ├── file-routing.md
    │   ├── update-policy.md
    │   ├── owner-contract.md
    │   └── compact-reminder.md
    └── domains/
        ├── README.md
        └── _template/
            ├── overview.md
            ├── verification.md
            └── sources.md
```

この構成の意図は明快である。`CLAUDE.md` は短い always-on ブリーフ、`.claude/rules/` は対象限定制約、`.claude/skills/` は反復手順、`.claude/settings.json` は deterministic control、`.mcp.json` は external system bridge、`harness/meta/` はメタハーネス本体、`harness/domains/` は task-adaptive な domain harness 本体という分担である。長文知識を special file に押し込まず、special file は routing と automation に徹させる。 citeturn8search0turn10view3turn15view0turn18view0turn19view0

## テンプレート本文

README.md は人間とオーナー向けの入口として使い、Claude Code が every session で読む運用ルールはここに置かない。これにより `CLAUDE.md` を短く保ちやすい。 citeturn25view1turn25view2

```md
# ハーネスリポジトリ

このリポジトリは、Claude Code を用いてタスク実行とハーネス自己改善を継続するための土台である。

## 運用原則

- オーナーは「やりたい事」と「完了条件」を与える。
- エージェントはタスク遂行に必要なドメインハーネスを構築・更新する。
- ハーネスは日本語で記述し、SSoT と最新情報維持を徹底する。
- 遠回りが発生した場合は、再発防止に効く情報だけを既存ファイルへ統合する。
- 過程が非決定的でも、完了条件を決定論的に検証できるなら、その検証手段を優先して整備する。

## 主要な置き場

- `CLAUDE.md`
  - 毎セッション読む短い原則
- `.claude/rules/`
  - 対象ファイルでだけ有効にしたいルール
- `.claude/skills/`
  - 反復可能な手順
- `.claude/settings.json`
  - フックと実行時制御
- `harness/meta/`
  - メタハーネス本体
- `harness/domains/`
  - ドメインハーネス本体

## 基本的な進め方

1. オーナー要求を `harness/meta/owner-contract.md` の形へ正規化する。
2. 既存のドメインハーネスで足りなければ `harness/domains/` を更新する。
3. 決定論的検証を作れるなら先に整備する。
4. タスクを実行し、完了条件を検証する。
5. 遠回りがあればハーネスへ統合する。
```

`CLAUDE.md` は broad で毎回必要な指示だけに絞る。公式は short, concrete, structured に書くこと、長くなるなら rules や skills へ逃がすこと、imports も startup 時に全文注入されるので大きい文書の無闇な import は避けることを勧めている。そこで、このテンプレートでは import をほぼ使わず、routing と invariant だけを書く。 citeturn25view2turn9view1

```md
# このリポジトリで最優先すること

- オーナー要求の達成だけでなく、次回以降の最短手を作るためにハーネスも改善する。
- 一般論やモデルが既に知っている常識は書かない。再実行時の近道になる固有知識だけ残す。
- すべてのハーネス文書は日本語で書く。

# 参照のしかた

- まずこのファイルを守る。
- 次に、対象パスに対応する `.claude/rules/` を守る。
- 次に、必要時だけ `harness/meta/` と `harness/domains/` の SSoT を読む。
- 手順が長い時は `.claude/skills/` を使う。

# 作業原則

- 変更前に、目的・制約・完了条件・検証方法を言語化する。
- 小変更を除き、まず調査し、次に計画し、その後に実装する。
- 完了条件を決定論的に検証できるなら、検証を先に整備するか、少なくとも同時に整備する。
- 既存ファイルへ統合できる情報は、新規ファイルや追記型の新規章として積み上げない。
- 重複記述は禁止。参照で済むなら参照する。
- 変更後は、遠回りや詰まりの原因を見直し、再発防止に効く知識だけをハーネスへ反映する。

# ファイルの使い分け

- 毎回必要な短い原則だけを `CLAUDE.md` に置く。
- 対象パス限定の規則は `.claude/rules/` に置く。
- 手順書・チェックリスト・反復ワークフローは `.claude/skills/` に置く。
- 外部ツール接続は `.mcp.json` に置く。
- 長文の知識本体は `harness/meta/` または `harness/domains/` に置く。

# このリポジトリで避けること

- 一時メモを SSoT 化すること
- 変更履歴を本文へ積み上げること
- 検証不能な完了宣言
- ハーネス更新と無関係な装飾的ドキュメント追加
```

`.gitignore` には local-only memory / settings だけを最低限入れる。`.mcp.json` は project-scoped MCP 定義の公式な置き場なので、base template では空でも置いておく方が later adoption が容易である。 citeturn14view3turn19view0

```gitignore
CLAUDE.local.md
.claude/settings.local.json
```

```json
{
  "mcpServers": {}
}
```

`.claude/settings.json` と hook script は deterministic control の入口である。公式には hooks は lifecycle event に対する確定処理であり、compaction 後の文脈再注入も `SessionStart` の `compact` matcher で実現できる。base template では、まずその一点だけを仕込んでおくのが最も汎用的である。 citeturn17view4turn18view0turn18view1

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/rehydrate-context.sh"
          }
        ]
      }
    ]
  }
}
```

```bash
#!/usr/bin/env bash
set -euo pipefail
cat harness/meta/compact-reminder.md
```

```md
# compaction 後の再注入

- 既存ファイルへ統合できる情報は、追記型の新規ファイルへ逃がさない。
- ハーネスは最新情報だけを残し、古い情報は削除または置換する。
- 完了条件を決定論的に検証できる形を優先する。
- 一般論は書かず、このリポジトリ固有の近道だけを残す。
- ハーネス本文は日本語で記述する。
```

rules は path-specific load ができるので、ハーネス文書編集の約束事と、verification 設計時の約束事を分けて置くのがよい。これにより、通常のコード実装中に不要な meta-instructions が常時入るのを防げる。 citeturn10view3turn10view4

```md
---
paths:
  - "CLAUDE.md"
  - ".claude/**/*.md"
  - ".claude/**/*.json"
  - "harness/**/*.md"
  - ".mcp.json"
---

# ハーネス編集ルール

- 追加より統合を優先する。
- 最新情報だけを残し、履歴は本文に残さない。
- 一般論は書かず、固有の近道だけを書く。
- 参照で済むなら複製しない。
- 毎回必要な短い原則だけを `CLAUDE.md` に置く。
- 長い手順は skill、対象限定の制約は rules、長文知識は `harness/` に置く。
- すべて日本語で記述する。
```

```md
---
paths:
  - "harness/domains/**/*.md"
  - "scripts/**"
  - "tools/**"
  - "Makefile"
  - ".github/workflows/**"
  - ".gitlab-ci.yml"
---

# 検証設計ルール

- 完了条件を検証可能な単位へ分解する。
- 先に壊れを見つける検証から並べる。
- 既存の verifier があるなら再利用する。
- 新しい verifier を作る時は、できるだけ一つの入口から実行できるようにする。
- `verification.md` と実際の実行入口を一致させる。
- 手動確認だけに頼る場合は、何を見れば合格かを明記する。
```

skills は long procedure を on-demand で読む置き場なので、base template には「domain harness を起こす」「task 完了後に harness を改善する」「done condition を検証する」の三つを入れるのが最小で強い。skills は slash command として直呼びもでき、relevant なら Claude が自動採用もできる。 citeturn5search1turn15view0turn15view2turn15view3

```md
---
name: bootstrap-domain-harness
description: 現在のタスクに必要なドメインハーネスを最小構成で作成または更新する
---

目的:
現在のタスクに必要な domain harness を最小構成で作る。

手順:
1. オーナー要求からドメイン名、完了条件、制約、入力、出力を抽出する。
2. `harness/domains/` の既存候補を調べ、流用できるものがあれば再利用する。
3. 足りなければ `harness/domains/<domain-slug>/` を新設し、`_template` を基に `overview.md`、`verification.md`、`sources.md` を作る。
4. `overview.md` には固有語彙、対象範囲、制約、主要成果物、参照すべき仕様をまとめる。
5. `verification.md` には完了条件ごとの確認方法、実行入口、期待結果、手動確認点を書く。
6. 決定論的検証を作れるなら、その入口を既存プロジェクト方式で追加し、`verification.md` に反映する。
7. メタハーネスへ統合すべき学びがあれば更新する。

出力要件:
- 追加・更新したファイルを列挙する。
- どの完了条件をどの検証へ対応付けたか示す。
- まだ決定論化できていない点を明示する。
```

```md
---
name: improve-harness
description: 直近タスクを振り返り、遠回りを減らすためにハーネスを更新する
---

目的:
直近タスクで発生した遠回りを、次回以降は起こさないためにハーネスへ統合する。

手順:
1. 直近タスクで詰まった箇所、探し直した箇所、曖昧だった完了条件を洗い出す。
2. その原因が知識不足、配置ミス、検証不足、権限や外部連携不足のどれかを判定する。
3. `harness/meta/file-routing.md` に従い、更新先を `CLAUDE.md`、rules、skills、meta docs、domain docs の中から選ぶ。
4. 新規追加より既存ファイルへの統合を優先する。
5. 古くなった記述、重複記述、役割が重なった記述は削除または統合する。
6. 完了条件の検証が弱かったなら `verification.md` と実際の verifier を更新する。

出力要件:
- 何が回り道だったか
- 何をどのファイルへ入れたか
- その更新で次回何が短縮されるか
```

```md
---
name: verify-done
description: 完了条件を検証に対応付け、実行して、完了可否を判定する
---

目的:
完了条件を曖昧な達成感ではなく、検証結果で判定する。

手順:
1. オーナー要求と `harness/domains/**/verification.md` を読み、完了条件一覧を確定する。
2. 各完了条件を、決定論的検証・半決定論的検証・手動確認のいずれかに分類する。
3. 既存の検証入口があるなら実行する。
4. 検証入口が無いが短時間で決定論化できるなら、先に最小の verifier を作る。
5. 各完了条件を `pass`、`fail`、`unknown` のいずれかで判定する。
6. `unknown` を残すなら、なぜ不明なのか、何を追加すれば決定論化できるのかを書く。

出力要件:
- 完了条件ごとの判定表
- 実行した検証入口
- 追加した verifier
- 残った不確実性
```

`harness/meta/` は special file ではなく ordinary docs layer にする。理由は、ここに置くのが「毎回読むべき短い指示」ではなく、長めの設計原則と判断基準だからである。CLAUDE 本体へ押し込まず、必要時に file tools や skills 経由で読む方が公式の役割分担に沿う。 citeturn25view1turn25view2turn15view0

```md
# 定義

## ハーネス

AIエージェントがタスクを処理するのに必要な固有知識と、自己改善可能な運用知識の総体。

## メタハーネス

ハーネス自体をどう設計・更新・配置するかを定める知識。
対象:
- どの種別の知識をどのファイルへ置くか
- どの条件でハーネスを更新するか
- どの条件で決定論的検証を作るか
- エージェント機能をどう組み合わせるか

## ドメインハーネス

特定タスク群を速く正確に進めるための知識。
対象:
- 用語
- 制約
- 主要成果物
- 入出力
- 参照すべき仕様
- 完了条件の検証方法

## 記述原則

- 日本語で書く。
- SSoT を守る。
- 一般論は書かない。
- 現行運用に必要な最新情報のみを残す。
- 決定論的検証を優先する。
```

```md
# ファイル配置の判断基準

## `CLAUDE.md` に置くもの

- 毎回必要な短い原則
- プロジェクト全体に共通する不変条件
- 参照先の導線

## `.claude/rules/` に置くもの

- 特定パスでのみ必要な規則
- 編集中のファイル種別にだけ効く制約

## `.claude/skills/` に置くもの

- 再利用可能な手順
- チェックリスト
- 長いが毎回は不要なワークフロー

## `.claude/settings.json` に置くもの

- 権限
- フック
- 実行時の機械的制御

## `.mcp.json` に置くもの

- 外部システム接続
- 外部データ参照
- 外部アクション実行

## `harness/meta/` に置くもの

- ハーネス定義
- 更新基準
- オーナー要求の正規化方法
- 配置ルールそのもの

## `harness/domains/` に置くもの

- ドメイン固有の知識
- ドメイン固有の検証
- ドメイン固有の参照元

## 新規ファイル追加の基準

- 既存ファイルへ自然に統合できない
- 参照頻度または利用タイミングが明確に異なる
- 役割が単一で説明可能
```

```md
# 更新ポリシー

## 更新する時

- 同じ誤りが二度起きた
- コードレビューや検証で、事前に知っていれば防げた
- 回り道の原因が特定できた
- 完了条件をより短い手で検証できると分かった

## 更新しない時

- 一度しか使わない一般論
- モデルが既に知っている常識
- 単なる履歴や感想
- 根拠のない好み

## 更新方法

1. 追加前に既存の記述先を確認する。
2. 重複するなら既存記述へマージする。
3. 古い情報は削除または置換する。
4. 参照で済む箇所は参照にする。
5. 検証手段が変わったら `verification.md` を先に更新する。

## 完了後レビュー

- 何が詰まりだったか
- 何が不足知識だったか
- 次回短縮に効く最小差分は何か
- それはどのファイルへ入れるべきか
```

```md
# オーナー要求の正規化テンプレート

## 目的

- 何を実現したいか

## 完了条件

- 判定可能な条件を箇条書きで書く
- 可能なら期待結果、数値、観測点を含める

## 非目標

- 今回やらないこと

## 制約

- 期限
- 使ってよい技術
- 使ってはいけない技術
- セキュリティ、法務、運用上の条件

## 入力

- 参照資料
- 既存成果物
- 外部システム
- サンプルデータ

## 出力

- 期待する成果物
- 期待する配置先
- 期待するレビュー方法

## 検証

- 既存の決定論的検証
- 新規に追加すべき検証
- 手動確認が必要な点

## 未確定事項

- 推定で進めてよい点
- オーナー確認が必要な点
```

```md
# compaction 後に忘れてはいけないこと

- 追加より統合を優先する。
- 変更履歴を本文へ積み上げない。
- 一般論ではなく、この repo 固有の近道だけを書く。
- 完了条件を検証可能な形で扱う。
- 日本語で書く。
```

`harness/domains/` は domain harness の本体であり、ここに task-adaptive knowledge を集める。special file にせず ordinary docs と machine-readable artifact の混在を許すことで、OpenAPI、schema、sample、spec なども同じ domain 配下に収めやすくなる。公式の file routing 上も、「長文知識や reference material は skills / CLAUDE ではなく通常ファイルへ置き、必要時に読む」方が適合する。 citeturn15view0turn25view1turn7search0

```md
# ドメインハーネスの作り方

各ドメインは `harness/domains/<domain-slug>/` に置く。

最低限のファイル:
- `overview.md`
- `verification.md`
- `sources.md`

運用:
- 既存ドメインへ統合できるなら新設しない。
- slug は短く、検索しやすく、単数名詞を基本にする。
- 仕様書、OpenAPI、SQL、JSON Schema、サンプル出力など、機械可読な SSoT はドメイン配下へ置き、`sources.md` から参照する。
- `verification.md` の記述と実際の検証手段を一致させる。
```

```md
# <domain-slug>

## 目的

- このドメインで達成したいこと

## スコープ

- 含むもの
- 含まないもの

## 用語

- 用語: 意味

## 主要成果物

- 成果物: 配置先
- 成果物: 形式

## 制約

- 技術上の制約
- 運用上の制約
- 品質上の制約

## 主要手順

- 調査
- 設計
- 実装
- 検証

## 参照先

- `sources.md`
- 関連する仕様、スクリプト、環境
```

```md
# 検証

## 完了条件対応表

| 完了条件 | 検証手段 | 実行入口 | 期待結果 |
|---|---|---|---|
| <condition-1> | <test/check/review> | <command/path> | <expected> |

## 実行順序

1. 最短で壊れを検出する検証
2. 主要な決定論的検証
3. 必要なら手動確認

## 決定論的検証

- コマンド:
- 前提:
- 期待結果:

## 手動確認

- 観測点:
- 成功条件:
- 失敗時の切り分け先:

## 未決定項目

- まだ決定論化できていない条件
- 決定論化の障害
```

```md
# 情報源

## SSoT

- `path or url`: 何の真実源か
- `path or url`: 何の真実源か

## 派生物

- `path or url`: SSoT から派生する成果物
- `path or url`: 同期ルール

## 更新時の注意

- SSoT を更新したら、どの派生物を同期するか
- 同じ事実を別ファイルへ複製しない
- 外部仕様を引用する時は最新版への参照を優先する
```

## 任意採用の拡張機能

cross-agent compatibility が必要なら、`AGENTS.md` を optional file として追加する価値がある。公式には Claude Code は `AGENTS.md` を直接読まないが、`CLAUDE.md` から import すれば重複なしで両立できる。その場合は `CLAUDE.md` の先頭に `@AGENTS.md` を置き、その下に Claude Code 特有の補足だけを書くのがよい。 citeturn9view0

```md
# 共有エージェント指示

- このリポジトリでは、オーナー要求の達成とハーネス自己改善を同時に行う。
- ハーネスは日本語で記述する。
- SSoT と最新情報維持を徹底する。
- 一般論ではなく、再利用価値のある固有知識だけを残す。
- 決定論的に検証できる完了条件は、必ず検証手段と対で扱う。
- 追加より統合を優先し、履歴の積み上げで逃げない。
```

custom subagent は、harness 設計や verifier 作成が recurring role として独立してきた段階で追加すればよい。公式には custom subagents は独自 prompt、tool restriction、permission mode、hooks、skills preload を持てるが、built-in の Explore / Plan / general-purpose でも多くのケースは足りる。agent teams は experimental で重いので、まずはここまでで十分である。 citeturn16view0turn16view1turn16view4turn7search3

```md
---
name: harness-architect
description: ハーネス設計と更新が主目的の時に使う。メタハーネス整理、ドメインハーネス統合、決定論的検証の設計を担当する。
tools: Read, Edit, Write, Glob, Grep, Bash
---

あなたはハーネス設計専任エージェントである。

目的:
- タスク実行を速く正確にするために、ハーネスの構造と内容を改善する。
- 一般論ではなく、このリポジトリ固有の近道だけを残す。
- SSoT、最新情報維持、重複排除、決定論的検証を最優先する。

作業手順:
1. 既存の `harness/meta/` と `harness/domains/` を読み、重複と不足を確認する。
2. 追加先ではなく統合先を先に探す。
3. 完了条件を検証可能な単位に分解する。
4. verifier を既存のプロジェクト方式で追加できるか検討する。
5. 更新後に、何が短縮されるのかを必ず説明する。

禁止事項:
- 履歴を本文に追記し続けること
- 一時メモを SSoT 化すること
- 一般論で文書を膨らませること
```

provider-specific CI file、Chrome / computer use、Remote Control、managed Code Review、web / Desktop / IDE surfaces は、base template ではなく運用面の拡張として追加すべきである。CI 連携は deterministic verifier が固まってから、Chrome は browser verification が必要になってから、computer use は GUI-only 作業が出てから、Remote Control や web / Desktop / IDE は作業面の都合で選べばよい。output styles は knowledge layer ではなく response style layer なので、このハーネステンプレートの中核には入れない。auto mode も preview 機能であり、ベース前提にはしない。 citeturn1view1turn28search0turn27search0turn27search1turn12search3turn22search1turn22search2turn13search0turn26view2