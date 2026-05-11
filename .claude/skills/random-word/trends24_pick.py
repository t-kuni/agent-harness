import random
import sys
from collections import OrderedDict

import requests
from bs4 import BeautifulSoup


REGIONS = {
    "us": "united-states",
    "japan": "japan",
    "korea": "korea",
    "uk": "united-kingdom",
}

BASE_URL = "https://trends24.in/{region}/"


def fetch_html(url: str) -> str:
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Accept-Language": "en-US,en;q=0.9",
    }
    r = requests.get(url, headers=headers, timeout=20)
    r.raise_for_status()
    r.encoding = r.apparent_encoding
    return r.text


def extract_trends(html: str) -> list[str]:
    soup = BeautifulSoup(html, "html.parser")

    trends = []

    # twitter.com へのリンク文字列をトレンド語として拾う
    for a in soup.select('a[href*="twitter.com"]'):
        word = a.get_text(strip=True)
        if not word:
            continue
        trends.append(word)

    # 順序を保って重複除去
    unique_trends = list(OrderedDict.fromkeys(trends))
    return unique_trends


def pick_random(trends: list[str], n: int) -> list[str]:
    if n < 0:
        raise ValueError("n must be >= 0")
    if not trends:
        raise ValueError("no trends found")
    if n > len(trends):
        raise ValueError(f"n is too large. available={len(trends)}")
    return random.sample(trends, n)


def main():
    args = sys.argv[1:]

    region_key = "us"
    n = 10

    for arg in args:
        if arg.startswith("--region="):
            region_key = arg.split("=", 1)[1].lower()
        else:
            n = int(arg)

    if region_key not in REGIONS:
        valid = ", ".join(REGIONS.keys())
        print(f"Error: unknown region '{region_key}'. valid: {valid}", file=sys.stderr)
        sys.exit(1)

    url = BASE_URL.format(region=REGIONS[region_key])
    html = fetch_html(url)
    trends = extract_trends(html)

    picked = pick_random(trends, n)
    for i, word in enumerate(picked, 1):
        print(f"{i}. {word}")


if __name__ == "__main__":
    main()
