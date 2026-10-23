#!/usr/bin/env python3
"""Verify a real SDK release ZIP, then extract into a new empty directory.
Invoke with python -I; keep this script outside the downloaded archive.
"""
import argparse
import hashlib
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import zipfile

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('archive', type=Path)
p.add_argument('sha256')
p.add_argument('destination', type=Path)
a = p.parse_args()
if not re.fullmatch('[0-9a-fA-F]{64}', a.sha256):
    raise SystemExit('Expected an explicit SHA256 of the real SDK asset')
with a.archive.open('rb') as stream:
    actual = hashlib.file_digest(stream, 'sha256').hexdigest()
if actual.lower() != a.sha256.lower():
    raise SystemExit('SDK checksum mismatch; nothing extracted')
destination = a.destination.resolve(strict=True)
if not destination.is_dir() or any(destination.iterdir()):
    raise SystemExit('Extraction directory must exist and be empty')
with zipfile.ZipFile(a.archive) as archive:
    total = 0
    for entry in archive.infolist():
        path = PurePosixPath(entry.filename)
        if path.is_absolute() or '..' in path.parts or ':' in entry.filename or chr(92) in entry.filename:
            raise SystemExit('Unsafe archive path')
        if stat.S_ISLNK(entry.external_attr >> 16):
            raise SystemExit('Outer package archive may not contain symbolic links')
        total += entry.file_size
        if total > 8 * 1024**3:
            raise SystemExit('SDK archive exceeds extraction size budget')
    for entry in archive.infolist():
        target = destination.joinpath(*PurePosixPath(entry.filename).parts)
        if entry.is_dir():
            target.mkdir(parents=True, exist_ok=True)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            with archive.open(entry) as source, target.open('xb') as output:
                shutil.copyfileobj(source, output)
print('Verified and extracted SDK package; binary build validation is still required.')
