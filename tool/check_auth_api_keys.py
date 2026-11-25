"""Probe Auth API access without real credentials, account creation, or key output.

Run: python tool/check_auth_api_keys.py
Invalid credentials should return HTTP 400; HTTP 403 indicates configuration failure.
"""
import json
from pathlib import Path
import re
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]


def probe(key, method, payload):
    url = ('https://identitytoolkit.googleapis.com/v1/accounts:' + method
           + '?' + urlencode({'key': key}))
    request = Request(url, data=json.dumps(payload).encode(),
                      headers={'Content-Type': 'application/json'})
    try:
        with urlopen(request, timeout=30) as response:
            return response.status, ''
    except HTTPError as error:
        data = json.loads(error.read())
        # Print only known error codes; provider diagnostics can contain tokens.
        message = data.get('error', {}).get('message', '').split(' : ')[0]
        return error.code, message
    except (URLError, TimeoutError):
        return 0, 'NETWORK_ERROR'


def main():
    source = (ROOT / 'lib/firebase_options.dart').read_text(encoding='utf-8')
    failed = False
    for platform in ('android', 'web', 'windows'):
        block = re.search(r'FirebaseOptions ' + platform
                          + r'\s*=\s*FirebaseOptions\((.*?)\);', source, re.S)
        key = re.search(r"apiKey:\s*'([^']+)'", block.group(1)).group(1)
        for method, payload, expected in (
            ('signInWithPassword', {
                'email': 'login-probe@example.invalid',
                'password': 'invalid-probe-password', 'returnSecureToken': True,
            }, {'INVALID_LOGIN_CREDENTIALS', 'EMAIL_NOT_FOUND', 'INVALID_PASSWORD'}),
            ('signInWithIdp', {
                'postBody': 'id_token=invalid-probe-token&providerId=google.com',
                'requestUri': 'http://localhost', 'returnSecureToken': True,
            }, {'INVALID_IDP_RESPONSE'}),
        ):
            status, code = probe(key, method, payload)
            ok = status == 400 and code in expected
            failed |= not ok
            print(json.dumps({'platform': platform, 'method': method,
                              'status': status, 'apiAccessible': ok}))
    for relative in ('android/app/google-services.json', 'google-services.json'):
        config = json.loads((ROOT / relative).read_text(encoding='utf-8'))
        block = re.search(r'FirebaseOptions android\s*=\s*FirebaseOptions\((.*?)\);',
                          source, re.S).group(1)
        key = re.search(r"apiKey:\s*'([^']+)'", block).group(1)
        clients = [c for c in config['client'] if c['client_info'].get(
            'android_client_info', {}).get('package_name') == 'com.example.quanlytro']
        matches = bool(clients) and all(
            any(k['current_key'] == key for k in c.get('api_key', []))
            for c in clients)
        failed |= not matches
        print(json.dumps({'file': relative, 'matchesDartAndroidKey': matches}))
    return int(failed)


if __name__ == '__main__':
    sys.exit(main())
