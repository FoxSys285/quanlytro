"""Read-only probes for the bounded discovery queries; prints counts, never tokens."""
import json
import os
import time
import sys

import requests

from collect_nationwide_rentals import project_config

project, _ = project_config()
url = f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents:runQuery'
failures = []


def field_filter(field, value):
    return {'fieldFilter': {'field': {'fieldPath': field}, 'op': 'EQUAL', 'value': {'booleanValue': value}}}


def probe(name, collection, filters, order='__name__', direction='ASCENDING'):
    start = time.monotonic()
    response = requests.post(url, headers={'Authorization': 'Bearer ' + os.environ['FIREBASE_ACCESS_TOKEN']},
        json={'structuredQuery': {'from': [{'collectionId': collection}],
            'where': {'compositeFilter': {'op': 'AND', 'filters': filters}},
            'orderBy': [{'field': {'fieldPath': order}, 'direction': direction}], 'limit': 11}}, timeout=30)
    payload = response.json()
    error_payload = payload if isinstance(payload, dict) else next((row for row in payload if 'error' in row), {})
    print(json.dumps({'query': name, 'http': response.status_code,
        'documents': sum('document' in row for row in payload) if isinstance(payload, list) else 0,
        'milliseconds': round((time.monotonic() - start) * 1000),
        'error': error_payload.get('error', {}).get('message', '')}), flush=True)
    if not response.ok:
        failures.append(name)
    return [row['document'] for row in payload if 'document' in row] if isinstance(payload, list) else []


for order in ['__name__', 'price', 'area']:
    probe('rooms-' + order, 'public_rooms', [field_filter('published', True), field_filter('available', True)], order)
verified = probe('verified-properties', 'rental_properties', [field_filter('published', True), field_filter('verified', True)])
ids = [row['name'].split('/')[-1] for row in verified[:10]]
if ids:
    probe('trusted-preview', 'public_rooms', [field_filter('published', True), field_filter('available', True),
        {'fieldFilter': {'field': {'fieldPath': 'propertyId'}, 'op': 'IN',
          'value': {'arrayValue': {'values': [{'stringValue': uid} for uid in ids]}}}}])
    for order in ['price', 'area']:
        for direction in ['ASCENDING', 'DESCENDING']:
            probe('property-' + order + '-' + direction, 'public_rooms',
                [field_filter('published', True), field_filter('available', True),
                 {'fieldFilter': {'field': {'fieldPath': 'propertyId'}, 'op': 'EQUAL',
                                  'value': {'stringValue': ids[0]}}}], order, direction)
    city = verified[0]['fields']['data']['mapValue']['fields']['property']['mapValue']['fields']['city']['stringValue']
    ward = verified[0]['fields']['data']['mapValue']['fields']['property']['mapValue']['fields']['ward']['stringValue']
    location_filters = [field_filter('published', True), field_filter('available', True),
        {'fieldFilter': {'field': {'fieldPath': 'city'}, 'op': 'IN',
                         'value': {'arrayValue': {'values': [{'stringValue': city}, {'stringValue': 'Hà Nội'}]}}}},
        {'fieldFilter': {'field': {'fieldPath': 'ward'}, 'op': 'IN',
                         'value': {'arrayValue': {'values': [{'stringValue': ward}, {'stringValue': 'Phường 25'}]}}}}]
    for order in ['__name__', 'price', 'area']:
        probe('city-ward-' + order, 'public_rooms', location_filters, order)
if failures:
    sys.exit(1)
