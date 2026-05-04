# リサーチアーカイブ

外部AIエージェントへのリサーチ依頼と結果を蓄積する。

## 構造

```
research/<slug>/
  prompt.md   外部AIへ渡すプロンプト（リポジトリ固有知識を含む自己完結型）
  result.md   外部AIからの回答（加工せずそのまま保存）
```

## 運用

- slug はリサーチ課題を表す短い名詞句（kebab-case、例: `harness-nav-strategy`）
- `prompt.md` は外部AIに直接貼り付けられる状態にする
- `result.md` は受け取った回答をそのまま保存する（加工しない）
- 学びをハーネスへ反映したら、更新したファイルを `result.md` の末尾に記録する

## 作成方法

`/research-prompt` スキルを使う。
