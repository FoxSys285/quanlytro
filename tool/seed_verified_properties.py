"""Mark 400 synthetic catalogue properties as demo-verified, with valid app proofs.

Preview creates an immutable plan and backups. Apply uses one conditional atomic
commit and changes verification fields only. No Security Rules are deployed.
"""
import argparse
from collections import Counter, defaultdict, deque
from copy import deepcopy
from datetime import datetime, timezone
import hashlib
import json
import re
import shutil
import subprocess

from collect_nationwide_rentals import ROOT, cloud, dump, project_config, verified_read
from publish_vietnam_catalogue import base_url, decode_document, list_collection
from backfill_landlord_phones import nested_fields

WORK = ROOT / '.local-backups/verified-properties-400'
BATCH = 'vn34-v1'
COUNT = 400


def eligible(document):
    return (document.get('importBatch') == BATCH and document.get('isDemo') is True
            and document.get('generation') == 'synthetic'
            and document.get('published') is True and not document.get('archived')
            and isinstance(document.get('data'), dict))


def select_properties(documents, proofs, count=COUNT):
    candidates = {p: d for p, d in documents.items() if eligible(d)}
    if len(candidates) < count:
        raise ValueError('Not enough published synthetic catalogue properties')
    # Preserve existing valid approvals; never revoke another approval to hit a count.
    chosen = sorted(p for p, d in candidates.items()
                    if d.get('verified') is True and d.get('verificationProof') == proofs.get(p))
    if len(chosen) > count:
        raise ValueError('Already more verified catalogue properties than the requested target')
    groups = defaultdict(list)
    selected = set(chosen)
    for path, document in candidates.items():
        if path not in selected:
            groups[str(document.get('provinceCode', 'unknown'))].append(path)
    queues = {key: deque(sorted(paths, key=lambda p: hashlib.sha256(p.encode()).hexdigest()))
              for key, paths in sorted(groups.items())}
    province_counts = Counter(str(candidates[p].get('provinceCode', 'unknown')) for p in chosen)
    while len(chosen) < count:
        available = [key for key, queue in queues.items() if queue]
        province = min(available, key=lambda key: (province_counts[key], key))
        chosen.append(queues[province].popleft())
        province_counts[province] += 1
    return chosen


def app_proofs(documents, label):
    input_path, output_path = WORK / f'{label}-decoded.json', WORK / f'{label}-proofs.json'
    dump(input_path, documents)
    dart = shutil.which('dart')
    if not dart:
        raise RuntimeError('Dart SDK is required to compute the same proof as the app')
    subprocess.run([dart, str(ROOT / 'tool/property_verification_manifest.dart'),
                    str(input_path), str(output_path)], cwd=ROOT, check=True)
    return json.loads(output_path.read_text(encoding='utf-8'))


def read_current():
    current = list_collection('rental_properties')
    management = cloud('GET', base_url() + '/management/system', allow_missing=True)
    if management is not None:
        current['management/system'] = management
    return current


def preview():
    if (WORK / 'plan.json').exists():
        raise ValueError('Plan already exists; resume it without replacing backups')
    current = read_current()
    decoded = {path: decode_document(doc) for path, doc in current.items()}
    proofs = app_proofs(decoded, 'before')
    selected = select_properties(decoded, proofs)
    reviewed_at = datetime.now(timezone.utc).isoformat()
    metadata = {'status': 'verified', 'scope': 'demo', 'schemaVersion': 1,
                'reviewedAt': reviewed_at, 'reviewedBy': 'demo-catalogue-seed',
                'note': 'Xác minh mô phỏng cho dữ liệu mẫu; chưa kiểm chứng nhà trọ ngoài thực tế.'}
    changes = [{'path': path, 'updateTime': current[path]['updateTime'],
                'fields': {'verified': True, 'verificationProof': proofs[path],
                           'verification': metadata}} for path in selected]
    admin = decoded.get('management/system', {}).get('admin', {})
    flags = {**admin.get('verified', {})}
    saved_proofs = {**admin.get('verificationProofs', {})}
    notes = {**admin.get('reviewNotes', {})}
    for path in selected:
        property_id = path.split('/')[1]
        flags[property_id] = True
        saved_proofs[property_id] = proofs[path]
        notes.pop(property_id, None)
    changes.append({'path': 'management/system',
                    'updateTime': current.get('management/system', {}).get('updateTime'),
                    'fields': {'admin.verified': flags, 'admin.verificationProofs': saved_proofs,
                               'admin.reviewNotes': notes}})
    plan = {'project': project_config()[0], 'createdAt': reviewed_at,
            'target': COUNT, 'selected': selected, 'changes': changes,
            'provinceCounts': dict(sorted(Counter(str(decoded[p].get('provinceCode'))
                                                   for p in selected).items()))}
    dump(WORK / 'before.json', current)
    dump(WORK / 'plan.json', plan)
    print('VERIFIED_PROPERTIES_PREVIEW', json.dumps({
        'project': plan['project'], 'publishedDemoProperties': sum(eligible(d) for d in decoded.values()),
        'selected': len(selected), 'provinces': len(plan['provinceCounts']),
        'perProvinceRange': [min(plan['provinceCounts'].values()), max(plan['provinceCounts'].values())],
        'writes': len(changes), 'demoVerificationOnly': True, 'securityRulesChanged': False}))


def read_plan():
    plan = json.loads((WORK / 'plan.json').read_text(encoding='utf-8'))
    if plan['project'] != project_config()[0] or len(plan['selected']) != COUNT:
        raise ValueError('Plan project/count does not match the authorized task')
    return plan


def at_path(data, dotted):
    for key in dotted.split('.'):
        if not isinstance(data, dict) or key not in data:
            return None
        data = data[key]
    return data


def apply():
    plan = read_plan()
    current = read_current()
    writes = []
    for change in plan['changes']:
        path = change['path']
        live = current.get(path)
        fields = decode_document(live) if live else {}
        if all(at_path(fields, key) == value for key, value in change['fields'].items()):
            continue
        if (live or {}).get('updateTime') != change['updateTime']:
            raise ValueError('Document changed after preview; no writes made: ' + path)
        if path in plan['selected'] and not eligible(fields):
            raise ValueError('A selected property is no longer eligible')
        writes.append({'update': {'name': base_url().split('/v1/')[1] + '/' + path,
                                   'fields': nested_fields(change['fields'])},
                       'updateMask': {'fieldPaths': list(change['fields'])},
                       'currentDocument': {'updateTime': change['updateTime']}
                       if live else {'exists': False}})
    if writes:
        cloud('POST', base_url() + ':commit', {'writes': writes})
    dump(WORK / 'commit.json', {'writes': len(writes), 'completedAt': datetime.now(timezone.utc).isoformat()})
    print('VERIFIED_PROPERTIES_COMMITTED', json.dumps({'writes': len(writes), 'atomic': True}))


def verify():
    plan = read_plan()
    before = json.loads((WORK / 'before.json').read_text(encoding='utf-8'))
    current = read_current()
    decoded = {p: decode_document(d) for p, d in current.items()}
    expected = {p: decode_document(d) for p, d in before.items()}
    for change in plan['changes']:
        target = expected.setdefault(change['path'], {})
        for dotted, value in change['fields'].items():
            parts = dotted.split('.')
            cursor = target
            for part in parts[:-1]:
                cursor = cursor.setdefault(part, {})
            cursor[parts[-1]] = deepcopy(value)
    if decoded != expected:
        mismatches = [p for p in expected if expected[p] != decoded.get(p)]
        raise ValueError('Read-back mismatch or unrelated data changed: ' + ', '.join(mismatches[:3]))
    proofs = app_proofs(decoded, 'after')
    verified = [p for p, d in decoded.items() if eligible(d)
                and d.get('verified') is True and d.get('verificationProof') == proofs.get(p)]
    if set(verified) != set(plan['selected']):
        raise ValueError('The app verification algorithm does not match the selected 400 properties')
    # Check public, unauthenticated reads used by the tenant catalogue.
    for path in (plan['selected'][0], plan['selected'][-1]):
        response = verified_read('GET', base_url() + '/' + path)
        if not response.ok or decode_document(response.json()) != decoded[path]:
            raise ValueError('Public catalogue read-back failed')
    report = {'project': plan['project'], 'verifiedDemoProperties': len(verified),
              'remainingUnverifiedDemoProperties': sum(eligible(d) for d in decoded.values()) - len(verified),
              'provinceCounts': plan['provinceCounts'], 'provinces': len(plan['provinceCounts']),
              'validAppProofs': True, 'adminVerificationSynced': True,
              'unrelatedFieldsPreserved': True, 'publicReadVerified': True,
              'verificationScope': 'demo', 'securityRulesChanged': False,
              'verifiedAt': datetime.now(timezone.utc).isoformat()}
    dump(ROOT / 'artifacts/BAO_CAO_400_NHA_TRO_XAC_MINH.json', report)
    print('VERIFIED_PROPERTIES_READ_BACK', json.dumps({
        **report, 'provinceCounts': 'saved in report'}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['preview', 'apply', 'verify'])
    globals()[parser.parse_args().action]()
