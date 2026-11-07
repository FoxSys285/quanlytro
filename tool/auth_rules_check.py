"""Run auth/phone security checks against the local Firestore emulator only."""
import base64
import argparse
import json
import time

import requests

from collect_nationwide_rentals import wire_value

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--port', type=int, default=8080)
args = parser.parse_args()
HOST = f'http://127.0.0.1:{args.port}'
BASE = HOST + '/v1/projects/demo-auth/databases/(default)/documents'


def token(uid, **claims):
    def encode(value):
        return base64.urlsafe_b64encode(json.dumps(value).encode()).decode().rstrip('=')
    return encode({'alg': 'none', 'typ': 'JWT'}) + '.' + encode({
        'aud': 'demo-auth', 'iss': 'https://securetoken.google.com/demo-auth',
        'sub': uid, 'user_id': uid, 'iat': int(time.time()),
        'exp': int(time.time()) + 3600, 'firebase': {'sign_in_provider': 'custom'},
        **claims,
    }) + '.'


def create(uid, identity, role='tenant', phone='+84912345678', verified=False,
           transaction=False, reserve_code=True, code=None, **extra):
    fields = {'email': '' if 'email' not in identity else identity['email'],
              'displayName': 'Nguyen Van An', 'role': role, 'disabled': False,
              'phoneNumber': phone, 'phoneVerified': verified, 'phoneIsSynthetic': False,
              **extra}
    writes = []
    if role == 'tenant':
        code = code or 'A' + ''.join(char for char in uid.upper() if char.isalnum())[:7].ljust(7, '0')
        fields['tenantId'] = code
        if reserve_code:
            writes.append({'update': {'name': BASE.split('/v1/')[1] + '/tenant_codes/' + code,
                                      'fields': {}},
                           'updateTransforms': [{'fieldPath': 'createdAt', 'setToServerValue': 'REQUEST_TIME'}]})
    writes.append({'update': {'name': BASE.split('/v1/')[1] + '/users/' + uid,
                              'fields': {k: wire_value(v) for k, v in fields.items()}},
                   'updateTransforms': [{'fieldPath': 'createdAt', 'setToServerValue': 'REQUEST_TIME'}]})
    headers = {'Authorization': 'Bearer ' + token(uid, **identity)}
    body = {'writes': writes}
    if transaction:
        response = requests.post(BASE + ':beginTransaction', json={}, headers=headers, timeout=15)
        response.raise_for_status()
        body['transaction'] = response.json()['transaction']
        # Match the app: read the missing profile and code before writing both.
        documents = [BASE.split('/v1/')[1] + '/users/' + uid]
        if role == 'tenant':
            documents.append(BASE.split('/v1/')[1] + '/tenant_codes/' + code)
        response = requests.post(BASE + ':batchGet',
                                 json={'documents': documents, 'transaction': body['transaction']},
                                 headers=headers, timeout=15)
        if not response.ok:
            return response
    return requests.post(BASE + ':commit', json=body, headers=headers, timeout=15)


def update(uid, identity, patch, as_uid=None):
    params = [('updateMask.fieldPaths', field) for field in patch]
    return requests.patch(BASE + '/users/' + uid, params=params,
                          json={'fields': {k: wire_value(v) for k, v in patch.items()}},
                          headers={'Authorization': 'Bearer ' + token(as_uid or uid, **identity)}, timeout=15)


def check(response, allowed, description):
    if response.ok != allowed:
        raise AssertionError(f'{description}: HTTP {response.status_code} {response.text[:800]}')
    print('PASS', description)


def main():
    requests.delete(HOST + '/emulator/v1/projects/demo-auth/databases/(default)/documents', timeout=15).raise_for_status()
    email = {'email': 'new@example.com'}
    phone = {'phone_number': '+84912345678'}
    check(create('email-tenant', email), True, 'email tenant stores an unverified contact')
    check(create('email-owner', email, role='landlord'), True, 'email landlord stores a contact')
    check(create('retry-tenant', email, transaction=True), True, 'tenant transaction can read and create its missing profile and code')
    check(create('retry-owner', email, role='landlord', transaction=True), True, 'landlord transaction can read and create its missing profile')
    check(create('no-reservation', email, reserve_code=False), False, 'tenant profile cannot omit its code reservation')
    check(create('code-collision', email, code='AEMAILTE'), False, 'another tenant cannot reuse an existing code')
    check(create('bad-code', email, code='tenant-old-uid'), False, 'legacy UID-shaped codes cannot be created')
    check(create('phone-tenant', phone, verified=True), True, 'phone-only tenant uses verified claim and empty email')
    check(create('phone-owner', phone, role='landlord', verified=True), True, 'phone-only landlord cannot need an email claim')
    check(create('forged-phone', email, verified=True), False, 'email identity cannot claim verified phone')
    check(create('bad-phone', email, phone='0000000000'), False, 'placeholder phone is rejected')
    check(create('fake-admin', email, role='admin'), False, 'provider signup cannot self-assign admin')
    check(create('sample-number', email, phoneIsSynthetic=True), False, 'clients cannot label a signup as synthetic')
    patch = {'phoneNumber': '+84912345678', 'phoneVerified': True, 'phoneIsSynthetic': False}
    check(update('email-tenant', email, patch), False, 'unverified token cannot link a phone')
    check(update('email-tenant', {**email, **phone}, patch), True, 'same UID links verified phone')
    check(update('email-tenant', {**email, **phone}, {**patch, 'role': 'admin'}), False, 'phone linking cannot change role')
    check(update('email-tenant', {**email, **phone}, patch, as_uid='email-owner'), False, 'another user cannot link your phone')
    response = requests.get(BASE + '/users/email-tenant', timeout=15)
    check(response, False, 'contact profiles are not public')
    headers = {'Authorization': 'Bearer ' + token('email-tenant', **email)}
    response = requests.get(BASE + '/users/email-owner', headers=headers, timeout=15)
    check(response, False, 'tenants cannot read other users profiles')
    response = requests.get(BASE + '/tenant_codes', headers=headers, timeout=15)
    check(response, False, 'tenants cannot list code reservations')
    print('AUTH_PHONE_RULES_CHECKS_PASSED')


if __name__ == '__main__':
    main()
