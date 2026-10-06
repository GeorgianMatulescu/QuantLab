"""Restore compressed data and check snapshot hashes without overwriting files."""
import gzip
import hashlib
import json
import shutil
from pathlib import Path

def main():
    root = Path(__file__).resolve().parents[2]
    manifest = json.loads((root / 'data/downloaded_snapshot_manifest.json').read_text())
    for item in manifest:
        target = root / item['path']
        compressed = Path(str(target) + '.gz')
        if not target.exists() and compressed.exists():
            temporary = target.with_name(target.name + '.restoring')
            try:
                with gzip.open(compressed, 'rb') as source, temporary.open('xb') as output:
                    shutil.copyfileobj(source, output)
                with temporary.open('rb') as stream:
                    restored_digest = hashlib.file_digest(stream, 'sha256').hexdigest()
                if restored_digest != item['sha256']:
                    raise RuntimeError(f'Invalid snapshot: {target}')
                temporary.rename(target)
            finally:
                temporary.unlink(missing_ok=True)
        if not target.exists():
            raise FileNotFoundError(target)
        with target.open('rb') as stream:
            digest = hashlib.file_digest(stream, 'sha256').hexdigest()
        if digest != item['sha256']:
            print(f'Existing data differs from snapshot; preserved: {item["path"]}')
        else:
            print(f'OK: {item["path"]}')

if __name__ == '__main__':
    main()
