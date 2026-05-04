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
