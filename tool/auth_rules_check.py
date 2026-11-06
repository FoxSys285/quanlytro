"""Run auth/phone security checks against the local Firestore emulator only."""
import base64
import json
import time

import requests

from collect_nationwide_rentals import wire_value

BASE = 'http://127.0.0.1:8086/v1/projects/demo-auth/databases/(default)/documents'


def token(uid, **claims):
    def encode(value):
        return base64.urlsafe_b64encode(json.dumps(value).encode()).decode().rstrip('=')
    return encode({'alg': 'none', 'typ': 'JWT'}) + '.' + encode({
        'aud': 'demo-auth', 'iss': 'https://securetoken.google.com/demo-auth',
        'sub': uid, 'user_id': uid, 'iat': int(time.time()),
        'exp': int(time.time()) + 3600, 'firebase': {'sign_in_provider': 'custom'},
        **claims,
    }) + '.'


def create(uid, identity, role='tenant', phone='+84912345678', verified=False, **extra):
    fields = {'email': '' if 'email' not in identity else identity['email'],
              'displayName': 'Nguyen Van An', 'role': role, 'disabled': False,
              'phoneNumber': phone, 'phoneVerified': verified, 'phoneIsSynthetic': False,
              **extra}
    writes = []
    if role == 'tenant':
        code = 'A' + ''.join(char for char in uid.upper() if char.isalnum())[:7].ljust(7, '0')
        fields['tenantId'] = code
        writes.append({'update': {'name': BASE.split('/v1/')[1] + '/tenant_codes/' + code,
                                  'fields': {}},
                       'updateTransforms': [{'fieldPath': 'createdAt', 'setToServerValue': 'REQUEST_TIME'}]})
    writes.append({'update': {'name': BASE.split('/v1/')[1] + '/users/' + uid,
                              'fields': {k: wire_value(v) for k, v in fields.items()}},
                   'updateTransforms': [{'fieldPath': 'createdAt', 'setToServerValue': 'REQUEST_TIME'}]})
    return requests.post(BASE + ':commit', json={'writes': writes},
                         headers={'Authorization': 'Bearer ' + token(uid, **identity)}, timeout=15)


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
    requests.delete('http://127.0.0.1:8086/emulator/v1/projects/demo-auth/databases/(default)/documents', timeout=15).raise_for_status()
    email = {'email': 'new@example.com'}
    phone = {'phone_number': '+84912345678'}
    check(create('email-tenant', email), True, 'email tenant stores an unverified contact')
    check(create('email-owner', email, role='landlord'), True, 'email landlord stores a contact')
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
    print('AUTH_PHONE_RULES_CHECKS_PASSED')


if __name__ == '__main__':
    main()
