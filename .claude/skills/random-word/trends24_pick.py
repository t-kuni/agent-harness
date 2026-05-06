import random
import sys
from collections import OrderedDict

import requests
from bs4 import BeautifulSoup


URL = "https://trends24.in/united-states/"


def fetch_html(url: str) -> str:
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Accept-Language": "en-US,en;q=0.9",
    }
    r = requests.get(url, headers=headers, timeout=20)
    r.raise_for_status()
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
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 10

    html = fetch_html(URL)
    trends = extract_trends(html)

    picked = pick_random(trends, n)
    for i, word in enumerate(picked, 1):
        print(f"{i}. {word}")


if __name__ == "__main__":
    main()
