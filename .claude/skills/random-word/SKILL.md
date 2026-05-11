---
name: random-word
description: 企画・アイデア出し・ユーモアが欲しい場面で LLM の出力の偏りを防ぐため、ランダムな英単語またはトレンドワードを取得してプロンプトに混ぜる
---

## 用途

企画・アイデア出し・ユーモアが欲しい場面など、LLM に単純に考えさせると出力が偏るシーンで使う。
取得したランダムワードをプロンプトに混ぜることで、発想に偶然性を与える。

## 手法1: 辞書ファイル（オフライン・高速）

```bash
shuf -n <個数> /usr/share/dict/words
```

- 出力: 1行1単語

## 手法2: トレンドワード（trends24.in）

```bash
# セットアップ（初回のみ）
python3 -m venv .venv && .venv/bin/pip install -r .claude/skills/random-word/requirements.txt -q

# 実行（地域省略時は米国）
.venv/bin/python .claude/skills/random-word/trends24_pick.py <個数> [--region=<地域>]
```

対応地域:

| キー | 国 |
|------|------|
| `us` | 米国（デフォルト） |
| `japan` | 日本 |
| `korea` | 韓国 |
| `uk` | イギリス |

- ネットワーク接続必須
- 取得数はサイト次第。多すぎると `ValueError`
- 中国は trends24.in が未対応のため使用不可
- HTML構造が変わったら `trends24_pick.py` の `extract_trends()` を修正

## 選択基準

| 欲しいもの | 使う手法 |
|------------|---------|
| 汎用の英単語 | 手法1 |
| 現在の時事ワード | 手法2 |
