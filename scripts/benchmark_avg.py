#!/usr/bin/env python3

import argparse
import subprocess
import time


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run a shell command multiple times and print average seconds."
    )
    parser.add_argument("command", help="Command to execute")
    parser.add_argument(
        "--runs",
        type=int,
        default=10,
        help="Number of benchmark runs (default: 10)",
    )
    args = parser.parse_args()

    total = 0.0
    for _ in range(args.runs):
        start = time.perf_counter()
        subprocess.run(
            args.command,
            shell=True,
            executable="/bin/bash",
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        total += time.perf_counter() - start

    print(f"{total / args.runs:.3f}")


if __name__ == "__main__":
    main()
