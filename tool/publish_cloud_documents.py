"""Publish exported documents with backups and optimistic concurrency.
Run export_cloud_data_test.dart first. Without --apply this is a preview.
"""
import argparse
import datetime as dt
import json
from pathlib import Path
import urllib.error
from update_demo_firestore import ROOT, BASE, WORK, request


def value(item):
    if item is None:
        return {'nullValue': None}
    if isinstance(item, bool):
        return {'booleanValue': item}
    if isinstance(item, int):
        return {'integerValue': str(item)}
    if isinstance(item, float):
        return {'doubleValue': item}
    if isinstance(item, str):
        return {'stringValue': item}
    if isinstance(item, list):
        return {'arrayValue': {'values': [value(v) for v in item]}}
    return {'mapValue': {'fields': {k: value(v) for k, v in item.items()}}}


def decode(item):
    if 'mapValue' in item:
        return {k: decode(v) for k, v in item['mapValue'].get('fields', {}).items()}
    if 'arrayValue' in item:
        return [decode(v) for v in item['arrayValue'].get('values', [])]
    if 'integerValue' in item:
        return int(item['integerValue'])
    return next(iter(item.values()))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    source = json.loads((WORK / 'cloud_documents.json').read_text(encoding='utf-8'))
    allowed = {'public_rooms', 'rental_properties', 'rental_records', 'users', 'management', 'support_tickets', 'public_settings'}
    assert all(path.split('/')[0] in allowed and len(path.split('/')) == 2 for path in source)
    previous = {}
    for collection in {path.split('/')[0] for path in source}:
        page = ''
        while True:
            response = request(BASE + '/' + collection + '?pageSize=1000' + page)
            previous.update({d['name'].split('/documents/')[1]: d for d in response.get('documents', [])})
            token = response.get('nextPageToken')
            if not token:
                break
            from urllib.parse import quote
            page = '&pageToken=' + quote(token, safe='')
    stamp = dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    (WORK / f'cloud-backup-{stamp}.json').write_text(json.dumps(previous, ensure_ascii=False), encoding='utf-8')
    writes = []
    prefix = BASE.split('/v1/')[1]
    for path, data in source.items():
        fields = {key: value(v) for key, v in data.items()}
        old = previous.get(path)
        if old and {k: decode(v) for k, v in old['fields'].items()} == data:
            continue
        assert len(json.dumps(fields, ensure_ascii=False).encode()) < 950_000, path
        writes.append({'update': {'name': prefix + '/' + path, 'fields': fields},
            'currentDocument': {'updateTime': old['updateTime']} if old else {'exists': False}})
    print(f'{len(source)} exported documents, {len(writes)} changed. Backup is inside .dart_tool/demo_data.', flush=True)
    if not args.apply:
        print('PREVIEW_ONLY')
        return
    for offset in range(0, len(writes), 100):
        request(BASE + ':commit', {'writes': writes[offset:offset + 100]})
    # Verify the complete collection after publishing, not just the final write.
    for collection in {path.split('/')[0] for path in source}:
        count = 0
        page = ''
        while True:
            response = request(BASE + '/' + collection + '?pageSize=1000' + page)
            for doc in response.get('documents', []):
                path = doc['name'].split('/documents/')[1]
                if path in source:
                    assert {k: decode(v) for k, v in doc['fields'].items()} == source[path], path
                    count += 1
            token = response.get('nextPageToken')
            if not token:
                break
            from urllib.parse import quote
            page = '&pageToken=' + quote(token, safe='')
        assert count == sum(path.startswith(collection + '/') for path in source)
        print(f'{collection}: verified {count} documents', flush=True)
    print('PUBLISHED_AND_VERIFIED')


if __name__ == '__main__':
    main()
