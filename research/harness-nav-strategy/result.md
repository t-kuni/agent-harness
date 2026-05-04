## Q1. 各ファイルの推奨導線戦略

### `harness/meta/owner-contract.md`

* 使用タイミング

  * 新規タスク開始時。
  * ただし、単純な一問一答・小修正では読ませない。
  * 読ませる条件は「目的・完了条件・制約・非目標・検証方法が曖昧なタスク」「複数ファイル変更を伴うタスク」「ハーネス更新タスク」。

* 推奨導線

  * CLAUDE.md に短い導線だけ置く。
  * rules ではなく CLAUDE.md が適切。理由は、タスク開始時はまだ編集対象パスが決まっていないため。
  * hook で強制注入するほどではない。毎ターン出るとノイズ化する。

* 具体変更

  * `CLAUDE.md` に以下を追加。

```md
## タスク開始時の要求整理

新規タスクで目的・完了条件・制約・非目標・検証方法が曖昧な場合は、実装前に `harness/meta/owner-contract.md` を読み、要求を構造化してから進める。単純な質問・小修正では読まない。
```

* 理由

  * CLAUDE.md は毎セッション読まれるため、存在発見の導線に向く一方、本文を入れると常時コンテキストを消費する。公式ドキュメントでも、CLAUDE.md は常時読むべき事実・規約に留め、手順や限定的な知識は skill や rules に逃がす設計が推奨されている。([Claude][1])

### `harness/meta/definition.md`

* 使用タイミング

  * `CLAUDE.md`、`.claude/**`、`harness/**`、`.mcp.json` を編集するとき。
  * 特に「これはメタハーネスか、ドメインハーネスか」「どの層に置くべきか」を判断するとき。

* 推奨導線

  * `.claude/rules/harness-editing.md` から必ず参照させる。
  * `improve-harness` skill からも参照させる。
  * CLAUDE.md には本文も詳細導線も置かない。

* 具体変更

  * `.claude/rules/harness-editing.md` に以下を追加。

```md
## ハーネス概念の参照

ハーネス関連ファイルを編集する前に、語彙・層・記述原則の判断が必要な場合は `harness/meta/definition.md` を読む。

特に以下の場合は必ず読む:
- 新しい harness/meta ファイルを追加・改名・削除する
- harness/domains の構造を変更する
- CLAUDE.md、skills、rules、hooks の責務境界を変更する
- 「メタハーネス」「ドメインハーネス」「ハーネス」のいずれに属するかを判断する
```

* `.claude/skills/improve-harness/SKILL.md` に以下を追加。

```md
## 事前参照

ハーネス改善を行う前に以下を読む:
- `harness/meta/definition.md`
- `harness/meta/update-policy.md`
- `harness/meta/file-routing.md`
```

* 理由

  * rules はパス限定の条件付き知識に向く。Claude Code 公式ドキュメントでも、`.claude/rules/` は特定ファイル種別・ディレクトリ向けの指示を CLAUDE.md から分離する用途として説明されている。([Claude][2])

### `harness/meta/update-policy.md`

* 使用タイミング

  * ハーネスを更新するかどうか判断するとき。
  * `improve-harness` 実行時。
  * ハーネス編集後のレビュー時。

* 推奨導線

  * 第一導線は `improve-harness` skill。
  * 第二導線として `.claude/rules/harness-editing.md` に「更新判断が発生した場合だけ読む」と書く。
  * CLAUDE.md には「ハーネス改善は `/improve-harness` を使う」程度に留める。

* 具体変更

  * `.claude/skills/improve-harness/SKILL.md` に、`file-routing.md` だけでなく `update-policy.md` も必須参照として追加。

```md
## 必須参照

ハーネス更新の要否判断では `harness/meta/update-policy.md` を読む。
配置先判断では `harness/meta/file-routing.md` を読む。
語彙・層の判断では `harness/meta/definition.md` を読む。
```

* `.claude/rules/harness-editing.md` に以下を追加。

```md
## 更新判断

ハーネスファイルを変更する場合、変更理由が「再発防止」「導線改善」「運用ルール追加」「知識の配置変更」に該当するなら、編集前に `harness/meta/update-policy.md` を読む。
```

* `CLAUDE.md` に以下を追加。

```md
## ハーネス改善

直近タスクの遠回り・再発防止・導線切れをハーネスへ反映する場合は `/improve-harness` を使う。
```

* 理由

  * `update-policy.md` は「読むかどうか」自体が判断対象なので、常時読むよりも skill と path-scoped rule の二重導線が適切。skills は本文がオンデマンドで読み込まれるため、長めの判断手順を置く場所として適している。([Claude][3])

### `harness/domains/README.md`

* 使用タイミング

  * 新しいドメインハーネスを作るとき。
  * 既存ドメインハーネスの構成・命名・運用ルールを変えるとき。

* 推奨導線

  * `domains/README.md` をドメインハーネス構造の正本にする。
  * `bootstrap-domain-harness` skill は README の内容を重複保持せず、README を読む手順に変える。
  * `.claude/rules/harness-editing.md` からも、`harness/domains/**` の構造変更時だけ README を参照させる。

* 具体変更

  * `.claude/skills/bootstrap-domain-harness/SKILL.md` の重複説明を削り、以下に置き換える。

```md
## 必須参照

新しいドメインハーネスを作る前に `harness/domains/README.md` を読む。
slug 命名、標準ファイル構成、運用ルールは README を正本とする。
```

* `harness/domains/README.md` 冒頭に以下を追加。

```md
# ドメインハーネス設計 README

このファイルはドメインハーネスの構造・slug 命名・標準ファイル構成・運用ルールの正本である。

参照導線:
- 新規作成時: `.claude/skills/bootstrap-domain-harness/SKILL.md`
- 構造変更時: `.claude/rules/harness-editing.md`
```

* `.claude/rules/harness-editing.md` に以下を追加。

```md
## ドメインハーネス編集

`harness/domains/**` の構造・slug・標準ファイル構成を変更する場合は、編集前に `harness/domains/README.md` を読む。
```

* 理由

  * README と skill が同じ内容を持つと、必ず片方が古くなる。skill は実行手順、README は構造定義の正本、という分担にするのが安定する。skills は補助ファイルを参照して必要時だけ読ませる構成が公式にも想定されている。([Claude][3])

## 変更が必要なファイルと変更内容

* `CLAUDE.md`

  * `owner-contract.md` への短い導線を追加。
  * ハーネス改善時は `/improve-harness` を使う導線を追加。
  * 本文は増やさず、参照条件だけを書く。

* `.claude/rules/harness-editing.md`

  * `definition.md` への参照条件を追加。
  * `update-policy.md` への参照条件を追加。
  * `harness/domains/README.md` への参照条件を追加。

* `.claude/skills/improve-harness/SKILL.md`

  * 必須参照を `file-routing.md` だけでなく、`definition.md`、`update-policy.md` に拡張。

* `.claude/skills/bootstrap-domain-harness/SKILL.md`

  * ドメイン構造の重複説明を削る。
  * `harness/domains/README.md` を正本として読む手順に変更。

* `harness/domains/README.md`

  * このファイルがドメインハーネス構造の正本であることを明記。
  * 参照元として `bootstrap-domain-harness` と `harness-editing.md` を明記。

* 追加推奨: `harness/meta/route-manifest.md` または `harness/meta/route-manifest.yml`

  * 各知識ファイルについて、用途・読む条件・主導線・副導線・正本性を列挙する。
  * これは人間用というより、将来の導線チェック用。

## 採用した場合のトレードオフ・副作用

* CLAUDE.md に導線を少し追加するため、常時コンテキストはわずかに増える。

  * ただし本文ではなくルーティングだけなので、増加は小さい。
  * CLAUDE.md は 200 行未満を目安に保つのが望ましい。([Claude][1])

* `harness-editing.md` の責務が少し重くなる。

  * ただし、対象パスがハーネス関連に限定されているため妥当。
  * ハーネス編集時以外には読まれないため、常時ノイズにはなりにくい。

* `improve-harness` 実行時に読むファイルが増える。

  * 初動コストは増える。
  * 代わりに「更新すべきか」「どこへ置くか」「どの層の知識か」の判断精度が上がる。

* `domains/README.md` を正本にすると、`bootstrap-domain-harness` 単体の自己完結性は下がる。

  * ただし重複管理が消えるため、長期的には保守性が上がる。

## Q2. 「必要な時に確実に、不要な時には読まれない」設計原則

「常に読む」に置くべきものは、全セッションで必要な不変条件だけです。具体的には、プロジェクトの目的、絶対に守る禁止事項、主要コマンド、知識の入口です。CLAUDE.md はセッション開始時に全文が入るため、長い手順・テンプレート・ドメイン知識を置くと、毎回コストを払ううえに重要度も薄まります。([Claude][1])

「特定条件で読む」は、パス・イベント・作業種別に紐づく知識に使います。対象ファイルが決まっているなら `.claude/rules/`、必ず機械的に走らせたい処理なら hooks、繰り返し使う手順や判断プロセスなら skills が向きます。hooks はライフサイクルイベントで確実に発火する一方、skill は Claude またはユーザーが必要時に読む知識なので、強制性と推論性を分けて設計するべきです。([Claude][4])

「手動で読む」は、頻度が低い、本文が長い、または人間が意図的に起動したい手順に使います。たとえば `bootstrap-domain-harness` は明確な作業開始コマンドなので skill が適切です。一方、`owner-contract.md` はタスク開始時の判断補助なので、本文は手動参照でも、存在発見だけは CLAUDE.md に置く必要があります。

## Q3. CLAUDE.md 肥大化を防ぎながら導線を整備するバランス

CLAUDE.md は「知識本体」ではなく「ルーティングテーブル」にします。各行は「いつ」「何を読むか」だけにし、本文・テンプレート・判断基準は `harness/meta/`、`harness/domains/`、skills、rules に置きます。これにより、存在発見は常時保証しつつ、詳細知識は必要時まで遅延ロードできます。

具体的には、CLAUDE.md には 4〜6 個の入口だけを置きます。「タスク開始の要求整理」「ハーネス改善」「検証」「ドメインハーネス作成」「ハーネス編集時の rules 参照」程度です。詳細なファイル一覧を CLAUDE.md に展開し始めると、更新漏れが CLAUDE.md 側にも発生するため、一覧性は `route-manifest` に逃がすべきです。

skill や rules の中だけに導線を置くと、初回発見性が落ちます。したがって、CLAUDE.md は「入口」、rules/skills は「実行時の詳細導線」、各 README/meta ファイルは「正本」という三層に分けます。この分担なら、CLAUDE.md は肥大化せず、かつ導線切れも見つけやすくなります。

## Q4. 将来の導線切れを防ぐ設計原則

新しい `harness/` ファイルを追加するときは、「内容」より先に「参照される条件」を決めるべきです。各ファイルの冒頭に、用途、読むタイミング、読まない条件、主導線、正本か派生かを frontmatter または冒頭ブロックで書きます。主導線が `CLAUDE.md`、`.claude/rules/*`、`.claude/skills/*`、hooks、他の README のいずれにも存在しないファイルは追加不可にします。

新しい skill や rules を追加するときは、逆方向のチェックも必要です。その skill/rule が読むべき正本ファイルを複製していないか、既存の meta/domain ファイルと責務が重複していないか、参照先が古くなったときに検出できるかを確認します。特に skill は便利なので本文を抱え込みがちですが、長期運用では「skill は手順、README/meta は正本」に寄せた方が破綻しにくいです。

構造的には、`harness/meta/route-manifest.yml` と検査スクリプトを追加するのが有効です。PostToolUse または Stop hook で、`harness/**`、`.claude/skills/**`、`.claude/rules/**`、`CLAUDE.md` が変更されたときだけ、全 harness ファイルに主導線があるかを検査します。hooks はイベント駆動で確実に走るため、導線切れの検出には skill より適しています。([Claude][4])

[1]: https://code.claude.com/docs/en/memory "How Claude remembers your project - Claude Code Docs"
[2]: https://code.claude.com/docs/en/features-overview "Extend Claude Code - Claude Code Docs"
[3]: https://code.claude.com/docs/en/skills "Extend Claude with skills - Claude Code Docs"
[4]: https://code.claude.com/docs/en/hooks "Hooks reference - Claude Code Docs"
