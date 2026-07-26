#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    examples_dir = repo_root / "examples"

    example_paths = sorted(examples_dir.glob("*.js"))
    if not example_paths:
        print("No examples found under examples/*.js", file=sys.stderr)
        return 1

    binary_path = repo_root / "bin" / "giavascript-smoke"
    binary_path.parent.mkdir(parents=True, exist_ok=True)

    build_result = subprocess.run(
        ["crystal", "build", "src/giavascript_cli.cr", "-o", str(binary_path)],
        cwd=repo_root,
        text=True,
        capture_output=True,
    )
    if build_result.returncode != 0:
        sys.stderr.write(build_result.stdout + build_result.stderr)
        return build_result.returncode

    failures = []
    for example_path in example_paths:
        relative_example = example_path.relative_to(repo_root)
        print(f"Running {relative_example}")
        result = subprocess.run(
            [str(binary_path), str(relative_example)],
            cwd=repo_root,
            text=True,
            capture_output=True,
        )

        if result.returncode != 0:
            failures.append(relative_example)
            sys.stderr.write(result.stdout + result.stderr)

    if failures:
        print("\nExample smoke tests failed:", file=sys.stderr)
        for failed in failures:
            print(f"- {failed}", file=sys.stderr)
        return 1

    print(f"All {len(example_paths)} example smoke tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
