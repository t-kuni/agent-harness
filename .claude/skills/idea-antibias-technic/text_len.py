#!/usr/bin/env python3

import argparse
import os
import random


def env_int(name: str, default: int) -> int:
    value = os.getenv(name)
    if value is None:
        return default
    return int(value)


def env_str(name: str, default: str) -> str:
    return os.getenv(name, default)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="文章の長さ I1:2(40) I2:4(60) ... の形式で文字列を生成します"
    )

    parser.add_argument(
        "-n",
        "--items",
        type=int,
        default=env_int("TEXT_LEN_ITEMS", 10),
        help="出力する項目数。環境変数: TEXT_LEN_ITEMS",
    )

    parser.add_argument(
        "--prefix",
        default=env_str("TEXT_LEN_PREFIX", "文章の長さ"),
        help="先頭に付ける文字列。環境変数: TEXT_LEN_PREFIX",
    )

    parser.add_argument(
        "--label-prefix",
        default=env_str("TEXT_LEN_LABEL_PREFIX", "I"),
        help="各項目のラベル接頭辞。環境変数: TEXT_LEN_LABEL_PREFIX",
    )

    parser.add_argument(
        "--sentence-min",
        type=int,
        default=env_int("TEXT_LEN_SENTENCE_MIN", 2),
        help="文数の最小値。環境変数: TEXT_LEN_SENTENCE_MIN",
    )

    parser.add_argument(
        "--sentence-max",
        type=int,
        default=env_int("TEXT_LEN_SENTENCE_MAX", 4),
        help="文数の最大値。環境変数: TEXT_LEN_SENTENCE_MAX",
    )

    parser.add_argument(
        "--chars-min",
        type=int,
        default=env_int("TEXT_LEN_CHARS_MIN", 15),
        help="1文あたり文字数の最小値。環境変数: TEXT_LEN_CHARS_MIN",
    )

    parser.add_argument(
        "--chars-max",
        type=int,
        default=env_int("TEXT_LEN_CHARS_MAX", 30),
        help="1文あたり文字数の最大値。環境変数: TEXT_LEN_CHARS_MAX",
    )

    parser.add_argument(
        "--start",
        type=int,
        default=env_int("TEXT_LEN_START", 1),
        help="ラベル番号の開始値。環境変数: TEXT_LEN_START",
    )

    parser.add_argument(
        "--separator",
        default=env_str("TEXT_LEN_SEPARATOR", " "),
        help="項目間の区切り文字。環境変数: TEXT_LEN_SEPARATOR",
    )

    parser.add_argument(
        "--seed",
        type=int,
        default=os.getenv("TEXT_LEN_SEED"),
        help="乱数シード。環境変数: TEXT_LEN_SEED",
    )

    return parser.parse_args()


def validate_args(args: argparse.Namespace) -> None:
    if args.items < 1:
        raise ValueError("--items は1以上にしてください")

    if args.sentence_min > args.sentence_max:
        raise ValueError("--sentence-min は --sentence-max 以下にしてください")

    if args.chars_min > args.chars_max:
        raise ValueError("--chars-min は --chars-max 以下にしてください")

    if args.sentence_min < 1:
        raise ValueError("--sentence-min は1以上にしてください")

    if args.chars_min < 1:
        raise ValueError("--chars-min は1以上にしてください")


def build_item(
    index: int,
    label_prefix: str,
    sentence_min: int,
    sentence_max: int,
    chars_min: int,
    chars_max: int,
) -> str:
    sentence_count = random.randint(sentence_min, sentence_max)
    total_chars = random.randint(chars_min, chars_max) * sentence_count
    return f"{label_prefix}{index}:{sentence_count}({total_chars})"


def main() -> None:
    args = parse_args()
    validate_args(args)

    if args.seed is not None:
        random.seed(int(args.seed))

    items = [
        build_item(
            index=i,
            label_prefix=args.label_prefix,
            sentence_min=args.sentence_min,
            sentence_max=args.sentence_max,
            chars_min=args.chars_min,
            chars_max=args.chars_max,
        )
        for i in range(args.start, args.start + args.items)
    ]

    print(args.prefix + args.separator + args.separator.join(items))


if __name__ == "__main__":
    main()
