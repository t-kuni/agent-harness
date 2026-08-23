#!/usr/bin/env python3
"""OpenAI gpt-image-2 API を呼び出して画像を生成し、指定パスに保存する。

使い方:
  generate_image.py <PROMPT> <OUTPUT_PATH> [REF_IMAGES] [SIZE]

  REF_IMAGES: カンマ区切りの参照画像パス（省略可）
  SIZE: "WIDTHxHEIGHT" 形式（省略時 "auto"、モデルが自動選択、固定解像度ではない）
        幅・高さが16の倍数、長辺:短辺が3:1以内、総ピクセル数655,360〜8,294,400の制約あり

前提:
  - 環境変数 OPENAI_API_KEY にAPIキーが設定されていること
    （このスクリプト自体が環境変数を参照する。呼び出し元のAIエージェントが
      環境変数を参照・存在確認する必要は無い）
  - requests パッケージが利用可能なこと（.venv 経由で実行する）

エンドポイント:
  - 参照画像あり: POST /v1/images/edits (multipart/form-data)
  - 参照画像なし: POST /v1/images/generations (application/json)
"""
import base64
import os
import sys
from pathlib import Path

import requests


def main() -> int:
    if len(sys.argv) < 3:
        print("Usage: generate_image.py <PROMPT> <OUTPUT_PATH> [REF_IMAGES] [SIZE]", file=sys.stderr)
        return 1

    prompt = sys.argv[1]
    output_path = sys.argv[2]
    ref_images = sys.argv[3] if len(sys.argv) > 3 else ""
    size = sys.argv[4] if len(sys.argv) > 4 else "auto"

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("Error: OPENAI_API_KEY is not set", file=sys.stderr)
        return 1

    headers = {"Authorization": f"Bearer {api_key}"}

    if ref_images:
        # 参照画像あり: /v1/images/edits (multipart/form-data)
        img_paths = [p for p in ref_images.split(",") if p]
        files = []
        opened = []
        try:
            for img in img_paths:
                fh = open(img, "rb")
                opened.append(fh)
                files.append(("image[]", (Path(img).name, fh)))
            data = {"model": "gpt-image-2", "prompt": prompt, "size": size}
            resp = requests.post(
                "https://api.openai.com/v1/images/edits",
                headers=headers,
                data=data,
                files=files,
            )
        finally:
            for fh in opened:
                fh.close()
    else:
        # 参照画像なし: /v1/images/generations (application/json)
        payload = {
            "model": "gpt-image-2",
            "prompt": prompt,
            "size": size,
            "quality": "high",
            "n": 1,
        }
        resp = requests.post(
            "https://api.openai.com/v1/images/generations",
            headers={**headers, "Content-Type": "application/json"},
            json=payload,
        )

    try:
        body = resp.json()
    except ValueError:
        print("Error: OpenAI API returned a non-JSON response", file=sys.stderr)
        print(f"HTTP status: {resp.status_code}", file=sys.stderr)
        return 1

    if "error" in body:
        print("Error: OpenAI API returned an error", file=sys.stderr)
        print(body["error"], file=sys.stderr)
        return 1

    try:
        b64_data = body["data"][0]["b64_json"]
    except (KeyError, IndexError, TypeError):
        print("Error: unexpected response shape from OpenAI API", file=sys.stderr)
        return 1

    out_path = Path(output_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(base64.b64decode(b64_data))

    print(f"Saved: {output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
