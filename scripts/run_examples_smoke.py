#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def run_command(command: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=cwd, text=True, capture_output=True)


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    examples_dir = repo_root / "examples"

    example_paths = sorted(examples_dir.glob("*.js"))
    if not example_paths:
        print("No examples found under examples/*.js", file=sys.stderr)
        return 1

    binary_path = repo_root / "bin" / "giavascript-smoke"
    binary_path.parent.mkdir(parents=True, exist_ok=True)

    build_result = run_command(
        ["crystal", "build", "src/giavascript_cli.cr", "-o", str(binary_path)],
        cwd=repo_root,
    )
    if build_result.returncode != 0:
        if build_result.stdout:
            print(build_result.stdout, file=sys.stderr, end="")
        if build_result.stderr:
            print(build_result.stderr, file=sys.stderr, end="")
        return build_result.returncode

    failures = []
    for example_path in example_paths:
        relative_example = example_path.relative_to(repo_root)
        print(f"Running {relative_example}")
        result = run_command([str(binary_path), str(relative_example)], cwd=repo_root)

        if result.returncode != 0:
            failures.append(relative_example)
            if result.stdout:
                print(result.stdout, file=sys.stderr, end="")
            if result.stderr:
                print(result.stderr, file=sys.stderr, end="")

    if failures:
        print("\nExample smoke tests failed:", file=sys.stderr)
        for failed in failures:
            print(f"- {failed}", file=sys.stderr)
        return 1

    print(f"All {len(example_paths)} example smoke tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
