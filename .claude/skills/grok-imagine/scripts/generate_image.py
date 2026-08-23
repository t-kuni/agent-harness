#!/usr/bin/env python3
"""xAI Grok Imagine API（画像）を呼び出して画像を生成し、指定パスに保存する。

使い方:
  generate_image.py <PROMPT> <OUTPUT_PATH> [REF_IMAGE_1,REF_IMAGE_2,...] [ASPECT_RATIO] [RESOLUTION]

前提:
  - 環境変数 XAI_API_KEY にAPIキーが設定されていること
    （このスクリプト自体がシェルの環境変数を参照する。呼び出し元のAIエージェントが
      環境変数を参照・存在確認する必要は無い）

参照画像なし: POST /v1/images/generations
参照画像あり: POST /v1/images/edits（xAIはmultipartではなくJSON。画像は最大3枚まで）

ASPECT_RATIO: 1:1, 3:4, 4:3, 9:16, 16:9, 2:3, 3:2, 9:19.5, 19.5:9, 9:20, 20:9,
              1:2, 2:1, 21:9, 5:2, auto（省略時 auto）
RESOLUTION: 1k, 2k（省略時 1k）

base64データはHTTPリクエストのJSONボディとして直接送信する（シェル引数を経由しないため
ARG_MAX制限を受けない）。
"""
import base64
import mimetypes
import os
import sys

import requests

MODEL = "grok-imagine-image-2.0"


def die(msg: str) -> None:
    print(f"Error: {msg}", file=sys.stderr)
    sys.exit(1)


def to_data_uri(path: str) -> str:
    mime, _ = mimetypes.guess_type(path)
    if mime is None:
        mime = "image/png"
    with open(path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode("ascii")
    return f"data:{mime};base64,{b64}"


def main() -> None:
    if len(sys.argv) < 3:
        die("PROMPT and OUTPUT_PATH are required")

    prompt = sys.argv[1]
    output_path = sys.argv[2]
    ref_images_arg = sys.argv[3] if len(sys.argv) > 3 else ""
    aspect_ratio = sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] else "auto"
    resolution = sys.argv[5] if len(sys.argv) > 5 and sys.argv[5] else "1k"

    api_key = os.environ.get("XAI_API_KEY")
    if not api_key:
        die("XAI_API_KEY is not set")

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }

    ref_images = [p for p in ref_images_arg.split(",") if p] if ref_images_arg else []

    if ref_images:
        if len(ref_images) > 3:
            die(f"参照画像は最大3枚まで（渡された枚数: {len(ref_images)}）")

        images = []
        for img in ref_images:
            if not os.path.isfile(img):
                die(f"参照画像が見つかりません: {img}")
            images.append({"url": to_data_uri(img)})

        body = {
            "model": MODEL,
            "prompt": prompt,
            "images": images,
            "resolution": resolution,
            "response_format": "b64_json",
        }
        url = "https://api.x.ai/v1/images/edits"
    else:
        body = {
            "model": MODEL,
            "prompt": prompt,
            "aspect_ratio": aspect_ratio,
            "resolution": resolution,
            "response_format": "b64_json",
        }
        url = "https://api.x.ai/v1/images/generations"

    resp = requests.post(url, headers=headers, json=body)

    try:
        data = resp.json()
    except ValueError:
        die(f"xAI API returned a non-JSON response (status {resp.status_code})")

    if not resp.ok or "error" in data or "code" in data:
        print("Error: xAI API returned an error", file=sys.stderr)
        print(data, file=sys.stderr)
        sys.exit(1)

    b64 = (data.get("data") or [{}])[0].get("b64_json")
    if not b64:
        print("Error: レスポンスに画像データが含まれていません", file=sys.stderr)
        print(data, file=sys.stderr)
        sys.exit(1)

    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
    with open(output_path, "wb") as f:
        f.write(base64.b64decode(b64))

    print(f"Saved: {output_path}")


if __name__ == "__main__":
    main()
