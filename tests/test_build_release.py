#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILDER = ROOT / "scripts" / "build_release.py"


def build(output: Path) -> Path:
    flags = 0x08000000 if sys.platform == "win32" else 0
    subprocess.run(
        [sys.executable, str(BUILDER), "--output-dir", str(output)],
        cwd=ROOT,
        check=True,
        creationflags=flags,
        stdout=subprocess.DEVNULL,
    )
    return output / "ShirsLazyTrix-v0.0.1.zip"


with tempfile.TemporaryDirectory() as temporary:
    base = Path(temporary)
    first = build(base / "first")
    second = build(base / "second")

    assert first.read_bytes() == second.read_bytes(), "same-host builds differ"

    with zipfile.ZipFile(first, "r") as archive:
        members = archive.infolist()
        assert members, "release archive is empty"
        assert all(item.create_system == 3 for item in members), (
            "ZIP creator-system metadata must be fixed to Unix for cross-host bytes"
        )
        assert all(item.external_attr == 0o100644 << 16 for item in members), (
            "ZIP file modes are not fixed"
        )
        assert archive.testzip() is None, "release archive failed CRC validation"

print("cross-host-zip-metadata: PASS")
print("deterministic-release-build: PASS")
