"""Back up/reset tropremium media through a temporary, authenticated Edge helper.

Cloudinary credentials stay inside Supabase. The helper expires in 30 minutes,
only accepts a random reset token, and can delete only tropremium/ public IDs.
"""
import argparse
import hashlib
import json
from pathlib import Path
import secrets
import shutil
import subprocess
import time
from urllib.request import Request, urlopen
from urllib.error import HTTPError

ROOT = Path(__file__).resolve().parents[1]
REF = 'hihsjrdzbtfldlscigzi'
NAME = 'app-reset-media'
URL = f'https://{REF}.supabase.co/functions/v1/{NAME}'

HELPER = r'''
const expectedHash = "TOKEN_HASH";
const expiresAt = EXPIRES_AT;
const hex = (b: ArrayBuffer) => [...new Uint8Array(b)].map(x=>x.toString(16).padStart(2,'0')).join('');
const digest = async (s: string, algorithm = 'SHA-256') => hex(await crypto.subtle.digest(algorithm, new TextEncoder().encode(s)));
Deno.serve(async (req: Request) => {
  const token = req.headers.get('Authorization')?.replace(/^Bearer /, '') ?? '';
  if (Date.now() > expiresAt || await digest(token) !== expectedHash) return new Response('Unauthorized', {status:401});
  if (Deno.env.get('FIREBASE_PROJECT_ID') !== 'tropremium-d14ac') return new Response('Wrong project', {status:409});
  const cloud = Deno.env.get('CLOUDINARY_CLOUD_NAME')!;
  const key = Deno.env.get('CLOUDINARY_API_KEY')!;
  const secret = Deno.env.get('CLOUDINARY_API_SECRET')!;
  if (!cloud || !key || !secret) return new Response('Missing configuration', {status:503});
  const base = `https://api.cloudinary.com/v1_1/${encodeURIComponent(cloud)}`;
  const authorization = 'Basic ' + btoa(`${key}:${secret}`);
  try {
    const body = await req.json();
    if (body.action === 'list') {
      const resources: Record<string, unknown>[] = [];
      for (const kind of ['image','video','raw']) for (const type of ['upload','authenticated','private']) {
        let cursor = '';
        do {
          const url = new URL(`${base}/resources/${kind}/${type}`);
          url.searchParams.set('prefix', 'tropremium/');
          url.searchParams.set('max_results', '500');
          if (cursor) url.searchParams.set('next_cursor', cursor);
          const response = await fetch(url, {headers:{Authorization:authorization}});
          if (!response.ok) throw new Error(`Cloudinary list HTTP ${response.status}`);
          const page = await response.json();
          for (const asset of page.resources ?? []) {
            if (!asset.public_id.startsWith('tropremium/')) throw new Error('Unexpected media prefix');
            let downloadUrl = asset.secure_url;
            if (type !== 'upload') {
              const timestamp = String(Math.floor(Date.now()/1000));
              const format = asset.format || asset.public_id.split('.').at(-1);
              const params: Record<string,string> = {expires_at:String(Number(timestamp)+1800), format, public_id:asset.public_id, timestamp, type};
              const signature = await digest(Object.keys(params).sort().map(k=>`${k}=${params[k]}`).join('&') + secret, 'SHA-1');
              const signed = new URL(`${base}/${kind}/download`);
              for (const [k,v] of Object.entries(params)) signed.searchParams.set(k,v);
              signed.searchParams.set('api_key', key);
              signed.searchParams.set('signature', signature);
              downloadUrl = signed.toString();
            }
            resources.push({...asset, downloadUrl});
          }
          cursor = page.next_cursor ?? '';
        } while(cursor);
      }
      return Response.json({resources});
    }
    if (body.action === 'delete') {
      const asset = body.asset;
      if (!asset || !asset.public_id?.startsWith('tropremium/') || !['image','video','raw'].includes(asset.resource_type) || !['upload','authenticated','private'].includes(asset.type)) return new Response('Invalid asset', {status:400});
      const url = new URL(`${base}/resources/${asset.resource_type}/${asset.type}`);
      url.searchParams.append('public_ids[]', asset.public_id);
      url.searchParams.set('invalidate', 'true');
      const response = await fetch(url, {method:'DELETE', headers:{Authorization:authorization}});
      if (!response.ok) throw new Error(`Cloudinary delete HTTP ${response.status}`);
      const result = await response.json();
      return Response.json({deleted:result.deleted});
    }
    return new Response('Invalid action', {status:400});
  } catch (error) {
    return Response.json({error:String(error)}, {status:502});
  }
});
'''


def cli(*args):
    result = subprocess.run([shutil.which('npx.cmd'), '--yes', 'supabase', *args], capture_output=True)
    if result.returncode:
        raise RuntimeError('Supabase helper command failed: ' + result.stderr.decode('utf-8', errors='replace')[:500])


def call(body):
    nonce = (BACKUP / 'media-reset-token').read_text(encoding='utf-8')
    request = Request(URL, data=json.dumps(body).encode(), method='POST', headers={
        'Authorization': 'Bearer ' + nonce, 'Content-Type': 'application/json'})
    try:
        with urlopen(request, timeout=120) as response:
            return json.load(response)
    except HTTPError as error:
        raise RuntimeError(f'Media reset helper HTTP {error.code}') from None


def prepare():
    nonce = secrets.token_urlsafe(48)
    (BACKUP / 'media-reset-token').write_text(nonce, encoding='utf-8')
    work = BACKUP / 'edge-helper'
    function = work / 'supabase/functions' / NAME
    function.mkdir(parents=True, exist_ok=True)
    (work / 'supabase/config.toml').write_text('project_id = "tropremium-reset"\n', encoding='utf-8')
    source = HELPER.replace('TOKEN_HASH', hashlib.sha256(nonce.encode()).hexdigest()).replace('EXPIRES_AT', str(int((time.time()+1800)*1000)))
    (function / 'index.ts').write_text(source, encoding='utf-8')
    cli('functions', 'deploy', NAME, '--remote=' + REF, '--use-api', '--no-verify-jwt', '--workdir', str(work), '--yes')
    assets = call({'action':'list'})['resources']
    directory = BACKUP / 'cloudinary-files'
    directory.mkdir(exist_ok=True)
    for index, asset in enumerate(assets):
        with urlopen(asset['downloadUrl'], timeout=60) as response:
            content = response.read()
        if len(content) != asset['bytes']:
            raise RuntimeError('Cloudinary backup size mismatch')
        (directory / f'{index:08d}.bin').write_bytes(content)
        asset.pop('downloadUrl')
    (BACKUP / 'cloudinary.json').write_text(json.dumps(assets, indent=2), encoding='utf-8')
    print(json.dumps({'cloudinaryAssetsBackedUp': len(assets), 'prefix':'tropremium/'}), flush=True)


def apply():
    assets = json.loads((BACKUP / 'cloudinary.json').read_text(encoding='utf-8'))
    live = call({'action':'list'})['resources']
    identity = lambda items: {(a['asset_id'], a['version']) for a in items}
    if identity(live) != identity(assets):
        raise RuntimeError('Cloudinary changed after backup')
    for asset in assets:
        result = call({'action':'delete', 'asset':asset})
        if result.get('deleted', {}).get(asset['public_id']) not in ('deleted','not_found'):
            raise RuntimeError('Cloudinary deletion incomplete')
    remaining = len(call({'action':'list'})['resources'])
    if remaining:
        raise RuntimeError('Cloudinary assets remain')
    cli('functions', 'delete', NAME, '--remote=' + REF, '--yes')
    report = {'cloudinaryAssetsDeleted':len(assets), 'remaining':remaining, 'temporaryHelper':'removed'}
    (BACKUP / 'cloudinary-reset.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps(report), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['prepare','apply','cleanup'])
    parser.add_argument('--backup', required=True)
    args = parser.parse_args()
    BACKUP = Path(args.backup).resolve()
    if BACKUP.parent != (ROOT / '.local-backups').resolve():
        raise RuntimeError('Unexpected backup directory')
    if args.action == 'prepare': prepare()
    elif args.action == 'apply': apply()
    else: cli('functions', 'delete', NAME, '--remote=' + REF, '--yes')
