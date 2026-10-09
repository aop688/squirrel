#!/usr/bin/env python3
# Trim data/rime_ice/cn_dicts/base.dict.yaml in place: drop rare entries
# (weight <= MIN_WEIGHT) and long phrases (> MAX_LENGTH characters).
# Re-run after syncing cn_dicts from upstream rime-ice; it is idempotent.

import sys
from pathlib import Path

MIN_WEIGHT = 10
MAX_LENGTH = 8

path = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).parent.parent / "data/rime_ice/cn_dicts/base.dict.yaml")

kept, dropped = [], 0
in_body = False
for line in path.read_text(encoding="utf-8").splitlines(keepends=True):
    if not in_body:
        in_body = line.startswith("...")
        kept.append(line)
        continue
    fields = line.rstrip("\n").split("\t")
    if line.startswith("#") or len(fields) < 3:
        kept.append(line)
        continue
    if int(fields[2]) <= MIN_WEIGHT or len(fields[0]) > MAX_LENGTH:
        dropped += 1
        continue
    kept.append(line)

path.write_text("".join(kept), encoding="utf-8")
print(f"{path.name}: dropped {dropped}, kept {sum(1 for _ in kept)} lines")
