---
name: random-number
description: 選択肢をランダムに選ぶ場面などで、LLM の出力の偏りを防ぐためにランダムな数値を取得する。最小値・最大値指定、0〜1 の実数、整数に対応。
---

## 用途

選択肢のランダム選択・サンプリング・テストデータ生成など、LLM に単純に選ばせると偏るシーンで使う。
取得した乱数を判断の起点にすることで、出力に偶然性を与える。

## パターン別コマンド

### 整数（範囲指定）

```bash
shuf -i <最小値>-<最大値> -n 1
```

例: 1〜10 の整数を1つ
```bash
shuf -i 1-10 -n 1
```

複数個取得する場合は `-n` の値を増やす（重複なし）。

### 整数（範囲指定・複数・重複あり）

```bash
python3 -c "import random; print(random.randint(<最小値>, <最大値>))"
```

### 0〜1 の実数（float）

```bash
python3 -c "import random; print(random.random())"
```

### 任意範囲の実数

```bash
python3 -c "import random; print(random.uniform(<最小値>, <最大値>))"
```

## 選択基準

| 欲しいもの | 使うコマンド |
|------------|-------------|
| 整数・範囲指定（重複なし） | `shuf -i` |
| 整数・範囲指定（重複あり or 繰り返し） | `python3 random.randint` |
| 0〜1 の実数 | `python3 random.random()` |
| 任意範囲の実数 | `python3 random.uniform` |

## 使い方

1. 上記コマンドを Bash ツールで実行して数値を取得する
2. 取得した数値を選択・判断の根拠として使う（数値自体をオーナーに見せるとより透明性が高い）
