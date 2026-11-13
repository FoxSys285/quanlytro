"""Run with: firebase emulators:exec --only firestore --project demo-quanlytro
    "python tool/property_verification_rules_test.py"

All requests target the local demo emulator, including the administrative seed.
"""
import base64
import json
import time
import requests

PROJECT = 'demo-quanlytro'
BASE = f'http://127.0.0.1:8080/v1/projects/{PROJECT}/databases/(default)/documents/'

def wire(value):
    if isinstance(value, bool):
        return {'booleanValue': value}
    if isinstance(value, str):
        return {'stringValue': value}
    return {'mapValue': {'fields': {key: wire(item) for key, item in value.items()}}}

def token(uid):
    def part(value):
        return base64.urlsafe_b64encode(json.dumps(value).encode()).decode().rstrip('=')
    now = int(time.time())
    return part({'alg': 'none', 'typ': 'JWT'}) + '.' + part({
        'sub': uid, 'user_id': uid, 'aud': PROJECT,
        'iss': 'https://securetoken.google.com/' + PROJECT,
        'iat': now, 'exp': now + 3600,
        'firebase': {'sign_in_provider': 'custom'},
    }) + '.'

def write(path, data, auth, expected, update=False):
    params = [('updateMask.fieldPaths', key) for key in data] if update else []
    response = requests.patch(BASE + path, params=params,
        json={'fields': {key: wire(value) for key, value in data.items()}},
        headers={'Authorization': 'Bearer ' + auth}, timeout=15)
    assert response.status_code == expected, (path, response.status_code, response.text)

for uid, role in [('owner-a', 'landlord'), ('admin-a', 'admin')]:
    write('users/' + uid, {'role': role, 'disabled': False}, 'owner', 200)
owner, admin = token('owner-a'), token('admin-a')
path = 'rental_properties/owner-a'
write(path, {'ownerUid': 'owner-a', 'published': True, 'verified': True, 'verificationProof': 'forged'}, owner, 403)
write(path, {'ownerUid': 'owner-a', 'published': True, 'verified': False, 'verificationProof': '', 'data': {'property': {'id': 'owner-a', 'name': 'Test'}}}, owner, 200)
write(path, {'verified': True}, owner, 403, update=True)
write(path, {'verified': True, 'verificationProof': 'approved-proof'}, admin, 200, update=True)
write(path, {'verificationProof': 'forged'}, owner, 403, update=True)
write(path, {'data': {'property': {'id': 'owner-a', 'name': 'Edited property'}}}, owner, 200, update=True)
response = requests.get(BASE + path, timeout=15)
assert response.status_code == 200
assert response.json()['fields']['verified']['booleanValue'] is True
write(path, {'verified': False, 'verificationProof': ''}, admin, 200, update=True)
print('PROPERTY_VERIFICATION_RULES_PASSED: owner cannot self-verify, admin can verify/revoke, public reads and owner edits work.')
