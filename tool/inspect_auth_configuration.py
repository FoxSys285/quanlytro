"""Print configuration status only; never print OAuth secrets or access tokens."""
import json
from collect_nationwide_rentals import cloud, project_config

project, _ = project_config()
base = 'https://identitytoolkit.googleapis.com/admin/v2/projects/' + project
config = cloud('GET', base + '/config')
providers = cloud('GET', base + '/defaultSupportedIdpConfigs')
try:
    billing = cloud('GET', f'https://cloudbilling.googleapis.com/v1/projects/{project}/billingInfo').get('billingEnabled')
except RuntimeError:
    billing = None
print('FIREBASE_AUTH_CONFIGURATION', json.dumps({
    'project': project,
    'phoneEnabled': config.get('signIn', {}).get('phoneNumber', {}).get('enabled', False),
    'emailEnabled': config.get('signIn', {}).get('email', {}).get('enabled', False),
    'providers': [{'provider': p.get('name', '').split('/')[-1],
                   'enabled': p.get('enabled', False),
                   'hasClientId': bool(p.get('clientId'))}
                  for p in providers.get('defaultSupportedIdpConfigs', [])],
    'smsRegions': config.get('smsRegionConfig', {}),
    'billingEnabled': billing,
}))
