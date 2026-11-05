"""Enable the requested phone provider and VN SMS region without changing billing."""
from datetime import datetime, timezone
import json

from collect_nationwide_rentals import ROOT, cloud, dump, project_config

project, _ = project_config()
url = f'https://identitytoolkit.googleapis.com/admin/v2/projects/{project}/config'
before = cloud('GET', url)
backup = ROOT / '.local-backups/landlord-phone-backfill/auth-config-before.json'
if not backup.exists():
    dump(backup, before)
regions = before.get('smsRegionConfig', {})
if 'allowlistOnly' in regions:
    regions = {'allowlistOnly': {'allowedRegions': sorted(set(
        regions['allowlistOnly'].get('allowedRegions', [])) | {'VN'})}}
elif 'allowByDefault' in regions:
    regions = {'allowByDefault': {'disallowedRegions': [
        r for r in regions['allowByDefault'].get('disallowedRegions', []) if r != 'VN']}}
else:
    regions = {'allowlistOnly': {'allowedRegions': ['VN']}}
cloud('PATCH', url + '?updateMask=signIn.phoneNumber.enabled,smsRegionConfig', {
    'signIn': {'phoneNumber': {'enabled': True}}, 'smsRegionConfig': regions,
})
after = cloud('GET', url)
if not after.get('signIn', {}).get('phoneNumber', {}).get('enabled'):
    raise RuntimeError('Phone provider read-back verification failed')
print('PHONE_PROVIDER_ENABLED', json.dumps({'project': project,
    'phoneEnabled': True, 'smsRegions': after.get('smsRegionConfig'),
    'billingChanged': False, 'smsMessagesSent': 0}))
