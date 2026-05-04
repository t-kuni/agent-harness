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
