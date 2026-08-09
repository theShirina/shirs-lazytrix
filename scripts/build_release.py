#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import re
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = [
    "ShirsLazyTrix.toc",
    "ShirsLazyTrix_Engine.lua",
    "ShirsLazyTrix_Merchant.lua",
    "ShirsLazyTrix_Controller.lua",
    "ShirsLazyTrix_UI.lua",
    "ShirsLazyTrix.lua",
    "LazyTrixIcon.tga",
    "README.txt",
    "LICENSE",
]
STAMP = (2026, 1, 1, 0, 0, 0)


def version() -> str:
    toc = (ROOT / "ShirsLazyTrix.toc").read_text(encoding="utf-8")
    match = re.search(r"^## Version:\s*(\S+)\s*$", toc, re.MULTILINE)
    if not match:
        raise SystemExit("missing TOC version")
    return match.group(1)


def build(output_dir: Path) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    target = output_dir / f"ShirsLazyTrix-v{version()}.zip"
    with tempfile.NamedTemporaryFile(dir=output_dir, suffix=".zip", delete=False) as handle:
        temporary = Path(handle.name)
    try:
        with zipfile.ZipFile(temporary, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for name in RUNTIME:
                source = ROOT / name
                if not source.is_file():
                    raise SystemExit(f"missing runtime file: {name}")
                info = zipfile.ZipInfo(f"ShirsLazyTrix/{name}", STAMP)
                info.create_system = 3
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = 0o100644 << 16
                data = source.read_bytes()
                if source.suffix.lower() in {".lua", ".toc", ".txt", ".md"} or source.name == "LICENSE":
                    data = data.replace(b"\r\n", b"\n")
                archive.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
        temporary.replace(target)
    finally:
        temporary.unlink(missing_ok=True)

    digest = hashlib.sha256(target.read_bytes()).hexdigest()
    checksum = target.with_suffix(target.suffix + ".sha256")
    checksum.write_text(f"{digest}  {target.name}\n", encoding="ascii", newline="\n")
    return target


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=ROOT / "dist")
    args = parser.parse_args()
    artifact = build(args.output_dir)
    print(artifact)
