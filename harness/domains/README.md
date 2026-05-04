# ドメインハーネスの作り方

このファイルはドメインハーネスの構造・slug 命名・標準ファイル構成・運用ルールの正本である。
skills や rules はここを参照し、同じ内容を重複して持たない。

参照導線:
- 新規作成時: `.claude/skills/bootstrap-domain-harness/SKILL.md`
- 構造変更時: `.claude/rules/harness-editing.md`

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
