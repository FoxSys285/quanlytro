"""Fetch photo albums from Nha Tot's publicly accessible listing JSON.

python tool/import_rental_photos.py --limit 20 --per-listing 3
Pillow is used only to compress downloaded photos, not to generate room pictures.
"""
import argparse
import concurrent.futures
import hashlib
import io
import json
from pathlib import Path
import sys
import urllib.parse
import urllib.request
import unicodedata

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.dart_tool/image_tools'))
from PIL import Image, ImageOps

API = 'https://gateway.chotot.com/v1/public/ad-listing'
PAGE = 'https://www.nhatot.com/thue-phong-tro'
ASSETS = ROOT / 'assets/images/rental_api'


def fetch(url, *, image=False):
    parsed = urllib.parse.urlparse(url)
    allowed = {'cdn.chotot.com'} if image else {'gateway.chotot.com'}
    if parsed.scheme != 'https' or parsed.hostname not in allowed:
        raise ValueError('Unexpected API/image origin')
    request = urllib.request.Request(url, headers={'User-Agent': 'QuanLyTro-StudentDemo/1.0',
        'Accept': 'image/*' if image else 'application/json'})
    with urllib.request.urlopen(request, timeout=25) as response:
        final = urllib.parse.urlparse(response.url)
        if final.scheme != 'https' or final.hostname not in allowed:
            raise ValueError('Unexpected redirect origin')
        data = response.read(8_000_001)
        if len(data) > 8_000_000:
            raise ValueError('Response is too large')
        return data


def room_type(title):
    text = ''.join(c for c in unicodedata.normalize('NFD', title.lower()) if unicodedata.category(c) != 'Mn')
    # ponytail: title-based grouping only; review the contact sheet before use.
    if any(word in text for word in ['ktx', 'ky tuc', 'giuong tang']):
        return 'group'
    if 'ban cong' in text:
        return 'balcony'
    if 'gac' in text:
        return 'loft'
    return 'studio'


def download(task):
    listing_id, index, url = task
    filename = f'nhatot_{listing_id}_{index + 1}.webp'
    path = ASSETS / filename
    data = fetch(url, image=True)
    im = ImageOps.exif_transpose(Image.open(io.BytesIO(data))).convert('RGB')
    if im.width < 120 or im.height < 120:
        raise ValueError('Photo is too small')
    im.thumbnail((800, 600))
    im.save(path, 'WEBP', quality=58, method=6)
    return {'asset': f'assets/images/rental_api/{filename}', 'url': url,
        'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'bytes': path.stat().st_size}


def literal(text):
    return "'" + text.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--limit', type=int, default=20)
    parser.add_argument('--per-listing', type=int, default=3)
    parser.add_argument('--keyword', default='')
    parser.add_argument('--append', action='store_true')
    args = parser.parse_args()
    if not 1 <= args.limit <= 30 or not 1 <= args.per_listing <= 4:
        parser.error('Use 1-30 listings and 1-4 photos per listing')
    ASSETS.mkdir(parents=True, exist_ok=True)
    parameters = {'cg':1050, 'limit':args.limit, 'o':0, 'st':'u,h', 'w':1}
    if args.keyword:
        parameters['q'] = args.keyword
    endpoint = API + '?' + urllib.parse.urlencode(parameters)
    data = json.loads(fetch(endpoint))
    albums, tasks = [], []
    seen = set()
    for ad in data.get('ads', []):
        if ad.get('category') != 1050 or not isinstance(ad.get('list_id'), int):
            continue
        images = ad.get('images') or [ad.get('image')]
        urls = [url for url in images if isinstance(url, str) and urllib.parse.urlparse(url).hostname == 'cdn.chotot.com'][:args.per_listing]
        if len(urls) < 2:
            continue
        listing_id = ad['list_id']
        if listing_id in seen:
            continue
        seen.add(listing_id)
        albums.append({'listingId': listing_id, 'type': room_type(ad.get('subject','')), 'endpoint': endpoint, 'photos': []})
        tasks.extend((listing_id, index, url) for index, url in enumerate(urls))
    downloaded = {}
    if not albums:
        raise ValueError('No usable albums returned; existing photos were kept')
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        for task, photo in zip(tasks, pool.map(download, tasks)):
            downloaded.setdefault(task[0], []).append(photo)
    for album in albums:
        album['photos'] = downloaded[album['listingId']]
    if args.append and (ASSETS / 'manifest.json').exists():
        previous = json.loads((ASSETS / 'manifest.json').read_text(encoding='utf-8'))['albums']
        merged = {a['listingId']: a for a in previous}
        merged.update({a['listingId']: a for a in albums})
        albums = list(merged.values())
    reviewed = json.loads((ROOT / 'tool/rental_photo_review.json').read_text(encoding='utf-8'))
    for album in albums:
        album['type'] = reviewed.get(str(album['listingId']), album['type'])
        unique = {}
        for photo in album['photos']:
            unique.setdefault(photo['sha256'], photo)
        album['photos'] = list(unique.values())
    albums = [album for album in albums if len(album['photos']) >= 2]
    manifest = {'provider':'Nha Tot / Cho Tot', 'endpoint':endpoint,
        'endpoints': sorted({a.get('endpoint', endpoint) for a in albums}), 'sourcePage':PAGE,
        'note':'Illustrations only; no real listing addresses or contacts are imported into managed properties.', 'albums':albums}
    (ASSETS / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    lines = ["part of 'room_photo.dart';", '', '// Generated by tool/import_rental_photos.py; all photos are illustrative.',
        'const _rentalApiAlbums = <({String type, List<RoomPhoto> photos})>[']
    for album in albums:
        lines.append(f"  (type: {literal(album['type'])}, photos: [")
        for photo in album['photos']:
            lines.append('    RoomPhoto(name: \'Ảnh phòng trọ · minh họa\', isReference: true,')
            lines.append(f"      assetPath: {literal(photo['asset'])}, url: {literal(photo['url'])}),")
        lines.append('  ]),')
    lines.append('];\n')
    (ROOT / 'lib/pages/shared/media/rental_api_photos.dart').write_text('\n'.join(lines), encoding='utf-8')
    print(f'{len(albums)} albums, {sum(len(a["photos"]) for a in albums)} photos, {sum(p["bytes"] for a in albums for p in a["photos"])} bytes')
    print('Grouping:', {key:sum(a['type']==key for a in albums) for key in ['studio','balcony','loft','group','property']})


if __name__ == '__main__':
    main()
