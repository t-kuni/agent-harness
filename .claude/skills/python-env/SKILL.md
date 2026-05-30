---
name: python-env
description: >
  what: Python仮想環境（.venv）の利用ルールとセットアップ手順
  when: Pythonスクリプトの実行やパッケージのインストールが必要な作業をする時
---

# Python実行環境

## 利用ルール

* Pythonを使う場合は `.venv` フォルダの仮想環境を使用する
    * 例：`.venv/bin/python script.py`、`.venv/bin/pip install ...`
* `.venv` が見つからない場合は `meta-scripts/setup.sh` を実行して環境を作成する
