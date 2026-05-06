#!/usr/bin/env python3

import argparse
import math
import statistics
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
    parser.add_argument(
        "--warmup",
        type=int,
        default=3,
        help="Number of untimed warmup runs (default: 3)",
    )
    parser.add_argument(
        "--stat",
        choices=("mean", "median", "p95"),
        default="median",
        help="Statistic to print from timed runs (default: median)",
    )
    parser.add_argument(
        "--stats",
        default=None,
        help="Comma-separated stats to print from one run set (mean,median,p95)",
    )
    args = parser.parse_args()

    for _ in range(args.warmup):
        subprocess.run(
            args.command,
            shell=True,
            executable="/bin/bash",
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    durations = []
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
        durations.append(time.perf_counter() - start)

    if args.stats:
        stats = [part.strip() for part in args.stats.split(",") if part.strip()]
    else:
        stats = [args.stat]

    allowed_stats = {"mean", "median", "p95"}
    if not stats or any(stat not in allowed_stats for stat in stats):
        raise ValueError("--stats must contain only: mean, median, p95")

    values = [f"{compute_stat(durations, stat):.3f}" for stat in stats]
    print(" ".join(values))


def compute_stat(durations: list[float], stat: str) -> float:
    if stat == "mean":
        return statistics.fmean(durations)

    if stat == "median":
        return statistics.median(durations)

    sorted_durations = sorted(durations)
    rank = int(math.ceil(0.95 * len(sorted_durations))) - 1
    rank = max(0, min(rank, len(sorted_durations) - 1))
    return sorted_durations[rank]


if __name__ == "__main__":
    main()
