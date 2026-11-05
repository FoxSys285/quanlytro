"""Create only missing discovery indexes. Never delete indexes or change Rules."""
import json

from collect_nationwide_rentals import ROOT, cloud, project_config

project, _ = project_config()
url = f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/collectionGroups/public_rooms/indexes'


def key(index):
    return (index.get('queryScope'), tuple((f['fieldPath'], f.get('order'))
        for f in index['fields'] if f['fieldPath'] != '__name__'))


def main():
    desired = json.loads((ROOT / 'firestore.indexes.json').read_text())['indexes']
    existing = cloud('GET', url).get('indexes', [])
    known = {key(index) for index in existing}
    created = 0
    for index in desired:
        if key(index) not in known:
            cloud('POST', url, {'queryScope': index['queryScope'], 'fields': index['fields']})
            created += 1
    after = cloud('GET', url).get('indexes', [])
    wanted = {key(index) for index in desired}
    print('DISCOVERY_INDEXES', json.dumps({'project': project, 'created': created,
        'states': {state: sum(i.get('state') == state and key(i) in wanted for i in after)
                   for state in ['READY', 'CREATING', 'NEEDS_REPAIR']},
        'indexesDeleted': 0, 'securityRulesChanged': False}))


if __name__ == '__main__':
    main()
