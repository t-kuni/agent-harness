#!/usr/bin/env python3
"""Google Gemini API（Gemini 3.1 Flash Image、通称 nano banana2）を呼び出して画像を生成し、指定パスに保存する。

使い方:
  generate_image_gemini.py <PROMPT> <OUTPUT_PATH> [REF_IMAGES] [ASPECT_RATIO] [IMAGE_SIZE]

  REF_IMAGES: カンマ区切りの参照画像パス（省略可）
  ASPECT_RATIO: "1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9",
                "21:9", "1:8", "8:1", "1:4", "4:1"（省略時 "16:9"）
  IMAGE_SIZE: "512", "1K", "2K", "4K"（省略時 "1K"。"512" は gemini-3.1-flash-image のみ対応）

前提:
  - 環境変数 GEMINI_API_KEY にAPIキーが設定されていること
    （このスクリプト自体が環境変数を参照する。呼び出し元のAIエージェントが
      環境変数を参照・存在確認する必要は無い）
  - requests パッケージが利用可能なこと（.venv 経由で実行する）

エンドポイント:
  - 参照画像の有無によらず同一エンドポイント POST /v1beta/interactions を使う
    （OpenAI方式のように generations/edits でエンドポイントが分かれていない）
  - 参照画像はBase64化してJSONボディに直接埋め込む（シェル版はjqの引数長上限を
    超えて失敗していたため、Pythonでは同じ制約を受けない実装にしている）
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


def avoid_overwrite(path: Path) -> Path:
    """pathがすでに存在する場合、拡張子の前に連番を付けて空いているパスを返す。"""
    if not path.exists():
        return path
    i = 2
    while True:
        candidate = path.with_name(f"{path.stem}_{i}{path.suffix}")
        if not candidate.exists():
            return candidate
        i += 1


def main() -> int:
    if len(sys.argv) < 3:
        print(
            "Usage: generate_image_gemini.py <PROMPT> <OUTPUT_PATH> [REF_IMAGES] [ASPECT_RATIO] [IMAGE_SIZE]",
            file=sys.stderr,
        )
        return 1

    prompt = sys.argv[1]
    output_path = sys.argv[2]
    ref_images = sys.argv[3] if len(sys.argv) > 3 else ""
    aspect_ratio = sys.argv[4] if len(sys.argv) > 4 else "16:9"
    image_size = sys.argv[5] if len(sys.argv) > 5 else "1K"

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("Error: GEMINI_API_KEY is not set", file=sys.stderr)
        return 1

    input_items = [{"type": "text", "text": prompt}]
    if ref_images:
        for img in ref_images.split(","):
            if not img:
                continue
            mime = guess_mime(img)
            data = base64.b64encode(Path(img).read_bytes()).decode("ascii")
            input_items.append({"type": "image", "mime_type": mime, "data": data})

    payload = {
        "model": "gemini-3.1-flash-image",
        "input": input_items,
        "response_format": {
            "type": "image",
            "mime_type": "image/jpeg",
            "aspect_ratio": aspect_ratio,
            "image_size": image_size,
        },
    }

    resp = requests.post(
        "https://generativelanguage.googleapis.com/v1beta/interactions",
        headers={"x-goog-api-key": api_key, "Content-Type": "application/json"},
        json=payload,
    )

    try:
        body = resp.json()
    except ValueError:
        print("Error: Gemini API returned a non-JSON response", file=sys.stderr)
        print(f"HTTP status: {resp.status_code}", file=sys.stderr)
        return 1

    if "error" in body:
        print("Error: Gemini API returned an error", file=sys.stderr)
        print(body["error"], file=sys.stderr)
        return 1

    image_data = None
    for step in body.get("steps", []):
        if step.get("type") != "model_output":
            continue
        for content in step.get("content", []):
            if content.get("type") == "image":
                image_data = content.get("data")
                break
        if image_data:
            break

    if not image_data:
        print("Error: unexpected response shape from Gemini API (no image found)", file=sys.stderr)
        return 1

    out_path = avoid_overwrite(Path(output_path))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(base64.b64decode(image_data))

    print(f"Saved: {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
