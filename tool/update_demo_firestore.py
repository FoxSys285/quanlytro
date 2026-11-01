"""Back up, prepare, and optionally apply additive demo data to this project.

python tool/update_demo_firestore.py          # local preview only
python tool/update_demo_firestore.py --apply  # guarded atomic Firestore write
"""
import argparse
import datetime as dt
import json
from pathlib import Path
import shutil
import subprocess
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
BASE = 'https://firestore.googleapis.com/v1/projects/doantro-caf4b/databases/(default)/documents'
WORK = ROOT / '.dart_tool/demo_data'


def request(url, data=None):
    body = None if data is None else json.dumps(data, ensure_ascii=False).encode('utf-8')
    req = urllib.request.Request(url, data=body, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=40) as response:
        return json.load(response)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    WORK.mkdir(parents=True, exist_ok=True)
    documents = request(BASE + '/app_documents?pageSize=100')['documents']
    stamp = dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    backup = WORK / f'backup-{stamp}.json'
    backup.write_text(json.dumps(documents, ensure_ascii=False), encoding='utf-8')
    original = {d['name'].split('/')[-1]: d for d in documents}
    data = {key: json.loads(d['fields']['payload']['stringValue']) for key, d in original.items()}
    (WORK / 'input.json').write_text(json.dumps(data, ensure_ascii=False), encoding='utf-8')
    subprocess.run([shutil.which('flutter'), 'test', '--no-pub',
                    'tool/prepare_demo_data_test.dart', '--reporter', 'expanded'],
                   cwd=ROOT, check=True)
    prepared = json.loads((WORK / 'prepared.json').read_text(encoding='utf-8'))
    # Only these three application documents are in scope.
    targets = ['portfolio', 'conversations', 'admin']
    assert all(prepared[key] == value for key, value in data.items() if key not in targets)
    writes = []
    for key in targets:
        payload = json.dumps(prepared[key], ensure_ascii=False, separators=(',', ':'))
        size = len(payload.encode('utf-8'))
        assert size < 950_000, f'{key} exceeds conservative Firestore size budget'
        print(f'{key}: {size} bytes', flush=True)
        if prepared[key] == data[key]:
            continue
        writes.append({
            'update': {'name': original[key]['name'], 'fields': {
                'payload': {'stringValue': payload},
                'updated_at': {'stringValue': dt.datetime.now(dt.timezone.utc).isoformat()},
            }},
            'updateMask': {'fieldPaths': ['payload', 'updated_at']},
            'currentDocument': {'updateTime': original[key]['updateTime']},
        })
    print(f'Backup: {backup.relative_to(ROOT)}', flush=True)
    print(f'Prepared {len(writes)} changed documents; auth and other documents preserved.', flush=True)
    if args.apply and writes:
        request(BASE + ':commit', {'writes': writes})
        for key in targets:
            live = request(BASE + '/app_documents/' + key)
            assert json.loads(live['fields']['payload']['stringValue']) == prepared[key]
        print('APPLIED_AND_VERIFIED', flush=True)
    elif not args.apply:
        print('PREVIEW_ONLY', flush=True)


if __name__ == '__main__':
    main()
