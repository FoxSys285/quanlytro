"""Back up/reset the app's linked Supabase rows and Android sandbox."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
REF = 'hihsjrdzbtfldlscigzi'
TABLES = ['sepay_unmatched_transactions', 'sepay_transactions',
          'subscription_orders', 'subscription_payment_settings',
          'subscription_legacy_migrations']
ADB = Path.home() / 'AppData/Local/Android/Sdk/platform-tools/adb.exe'


def query(sql, readonly=True):
    command = [shutil.which('npx.cmd'), '--yes', 'supabase', 'db', 'query',
               '--remote=' + REF, '--output', 'json']
    command += ['--read-only'] if readonly else ['--yes']
    # Keep SQL out of shell interpolation and CLI positional parsing.
    sql_file = BACKUP / 'supabase-query.sql'
    sql_file.write_text(sql, encoding='utf-8')
    result = subprocess.run(command + ['--file', str(sql_file)], capture_output=True)
    if result.returncode:
        raise RuntimeError('Supabase query failed: ' + result.stderr.decode('utf-8', errors='replace')[:600])
    text = result.stdout.decode('utf-8')
    return json.loads(text[text.index('{'):]).get('rows', [])


def prepare():
    actual = query("select tablename from pg_tables where schemaname='public' order by tablename")
    if {item['tablename'] for item in actual} != set(TABLES):
        raise RuntimeError('Unexpected public tables; review reset scope first')
    rows = query('select ' + ', '.join(
        f"(select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) from public.{table} t) as {table}"
        for table in TABLES))
    (BACKUP / 'supabase.json').write_text(json.dumps(rows[0], ensure_ascii=False, indent=2), encoding='utf-8')
    devices = subprocess.run([str(ADB), 'devices'], capture_output=True, check=True).stdout.decode()
    serials = [line.split()[0] for line in devices.splitlines()[1:] if line.endswith('\tdevice')]
    if serials != ['R5CY90587HA']:
        raise RuntimeError('Connected Android device changed; inspect before clearing app')
    with (BACKUP / 'android-app-data.tar').open('wb') as output:
        subprocess.run([str(ADB), '-s', serials[0], 'exec-out', 'run-as',
                        'com.example.quanlytro', 'tar', '-cf', '-', '.'], stdout=output, check=True)
    import tarfile
    with tarfile.open(BACKUP / 'android-app-data.tar') as archive:
        members = len(archive.getmembers())
    print(json.dumps({'supabase': {table: len(rows[0][table]) for table in TABLES},
                      'androidBackupEntries': members}))


def apply():
    before = json.loads((BACKUP / 'supabase.json').read_text(encoding='utf-8'))
    # Backup and delete the linked app tables only. Keep their schema, functions,
    # provider credentials, Security Rules and the migration history intact.
    statements = ['begin;', 'lock table ' + ', '.join('public.' + t for t in TABLES) + ' in access exclusive mode;']
    for table in TABLES:
        expected = json.dumps(before[table], ensure_ascii=False).replace("'", "''")
        statements.append(f"do $$ begin if (select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) from public.{table} t) != '{expected}'::jsonb then raise exception 'Data changed after backup'; end if; end $$;")
    statements += ['truncate table ' + ', '.join('public.' + t for t in TABLES) + ';', 'commit;']
    query('\n'.join(statements), readonly=False)
    counts = query(' union all '.join(f"select '{table}' as name, count(*) from public.{table}" for table in TABLES))
    if any(row['count'] for row in counts):
        raise RuntimeError('Supabase still contains app rows')
    if not (BACKUP / 'android-app-data.tar').is_file():
        raise RuntimeError('Android backup missing')
    result = subprocess.run([str(ADB), '-s', 'R5CY90587HA', 'shell', 'pm', 'clear',
                             'com.example.quanlytro'], capture_output=True, check=True)
    if result.stdout.strip() != b'Success':
        raise RuntimeError('Android app data was not cleared')
    report = {'supabaseProject': REF, 'remaining': counts, 'androidAppData': 'cleared'}
    (BACKUP / 'integrations-reset.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps(report))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['prepare', 'apply'])
    parser.add_argument('--backup', required=True)
    args = parser.parse_args()
    BACKUP = Path(args.backup).resolve()
    if BACKUP.parent != (ROOT / '.local-backups').resolve():
        raise RuntimeError('Expected an existing workspace backup directory')
    manifest = json.loads((BACKUP / 'manifest.json').read_text(encoding='utf-8'))
    if manifest['project'] != 'tropremium-d14ac':
        raise RuntimeError('Unexpected Firebase project')
    prepare() if args.action == 'prepare' else apply()
