#!/usr/bin/env python3
"""MiniMax公式画像生成API（モデルID image-01）を呼び出して画像を生成し、指定パスに保存する。

使い方:
  generate_image_minimax.py <PROMPT> <OUTPUT_PATH> [REF_IMAGE] [ASPECT_RATIO]

  REF_IMAGE: 参照画像のパス（省略可）。MiniMax API仕様上、参照画像は1枚のみ対応
             （OpenAI/Gemini方式と異なりカンマ区切り複数指定はできない）
  ASPECT_RATIO: "1:1", "16:9", "4:3", "3:2", "2:3", "3:4", "9:16", "21:9"
                （省略時 "1:1"）

前提:
  - 環境変数 MINIMAX_API_KEY にAPIキーが設定されていること
    （このスクリプト自体が環境変数を参照する。呼び出し元のAIエージェントが
      環境変数を参照・存在確認する必要は無い）
  - requests パッケージが利用可能なこと（.venv 経由で実行する）

エンドポイント:
  - 参照画像の有無によらず同一エンドポイント POST /v1/image_generation を使う
    （OpenAI方式のように generations/edits でエンドポイントが分かれていない）
  - 参照画像はローカルファイルをBase64化し data:image/<mime>;base64,... 形式にして
    subject_reference[0].image_file に埋め込む（公式APIはURL指定が主だが、
    MiniMax公式スクリプトでもBase64 data URIでの指定が確認されている）
  - response_format は base64 固定でリクエストする（url指定は24時間で失効するため、
    このスクリプト内で完結させるにはbase64の方が単純）
"""
import base64
import mimetypes
import os
import sys
from pathlib import Path

import requests


def guess_mime(path: str) -> str:
    ext = Path(path).suffix.lower()
    return {
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".webp": "image/webp",
    }.get(ext, "image/png")


def main() -> int:
    if len(sys.argv) < 3:
        print(
            "Usage: generate_image_minimax.py <PROMPT> <OUTPUT_PATH> [REF_IMAGE] [ASPECT_RATIO]",
            file=sys.stderr,
        )
        return 1

    prompt = sys.argv[1]
    output_path = sys.argv[2]
    ref_image = sys.argv[3] if len(sys.argv) > 3 else ""
    aspect_ratio = sys.argv[4] if len(sys.argv) > 4 else "1:1"

    api_key = os.environ.get("MINIMAX_API_KEY")
    if not api_key:
        print("Error: MINIMAX_API_KEY is not set", file=sys.stderr)
        return 1

    payload = {
        "model": "image-01",
        "prompt": prompt,
        "aspect_ratio": aspect_ratio,
        "response_format": "base64",
        "n": 1,
    }

    if ref_image:
        mime = guess_mime(ref_image)
        data = base64.b64encode(Path(ref_image).read_bytes()).decode("ascii")
        payload["subject_reference"] = [
            {"type": "character", "image_file": f"data:{mime};base64,{data}"}
        ]

    resp = requests.post(
        "https://api.minimax.io/v1/image_generation",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        json=payload,
    )

    try:
        body = resp.json()
    except ValueError:
        print("Error: MiniMax API returned a non-JSON response", file=sys.stderr)
        print(f"HTTP status: {resp.status_code}", file=sys.stderr)
        return 1

    base_resp = body.get("base_resp", {})
    if base_resp.get("status_code", 0) != 0:
        print("Error: MiniMax API returned an error", file=sys.stderr)
        print(base_resp, file=sys.stderr)
        return 1

    try:
        b64_data = body["data"]["image_base64"][0]
    except (KeyError, IndexError, TypeError):
        print("Error: unexpected response shape from MiniMax API", file=sys.stderr)
        return 1

    out_path = Path(output_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(base64.b64decode(b64_data))

    print(f"Saved: {output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
