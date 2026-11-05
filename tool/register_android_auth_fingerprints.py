"""Register this machine's Android debug certificate for Firebase Google/Phone auth."""
import json
import os
from pathlib import Path
import re
import subprocess

from collect_nationwide_rentals import ROOT, cloud, project_config

project, _ = project_config()
config = json.loads((ROOT / 'android/app/google-services.json').read_text(encoding='utf-8'))
app_id = config['client'][0]['client_info']['mobilesdk_app_id']
keystore = Path(os.environ['USERPROFILE']) / '.android/debug.keystore'
if not keystore.is_file():
    raise RuntimeError('Android debug keystore not found')
certificate = subprocess.run(['keytool', '-list', '-v', '-keystore', str(keystore),
                              '-alias', 'androiddebugkey', '-storepass', 'android'],
                             capture_output=True, text=True, check=True).stdout
base = f'https://firebase.googleapis.com/v1beta1/projects/{project}/androidApps/{app_id}/sha'
existing = cloud('GET', base).get('certificates', [])
known = {c['shaHash'].replace(':', '').lower() for c in existing}
added = 0
fingerprints = {}
for kind, cert_type in [('SHA1', 'SHA_1'), ('SHA256', 'SHA_256')]:
    match = re.search(kind + r':\s*([A-Fa-f0-9:]+)', certificate)
    if match is None:
        raise RuntimeError('Cannot parse the Android certificate fingerprint')
    fingerprint = match.group(1).replace(':', '').lower()
    fingerprints[cert_type] = fingerprint
    if fingerprint not in known:
        cloud('POST', base, {'shaHash': fingerprint, 'certType': cert_type})
        added += 1
after = {c['shaHash'].replace(':', '').lower() for c in cloud('GET', base).get('certificates', [])}
if not set(fingerprints.values()).issubset(after):
    raise RuntimeError('Firebase certificate read-back mismatch')
print('ANDROID_AUTH_FINGERPRINTS_VERIFIED', json.dumps({
    'project': project, 'appId': app_id, 'added': added, 'fingerprints': fingerprints,
}))
