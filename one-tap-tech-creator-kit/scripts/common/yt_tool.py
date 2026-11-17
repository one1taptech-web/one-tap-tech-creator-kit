"""Creator Kit YouTube tool (Python standard library only).
mode "update": fill title/description/tags/thumbnail/schedule on a video you uploaded yourself (YouTube app or Studio). Recommended.
mode "upload": upload a file through the API. NOTE: Google locks API uploads from unaudited projects to Private.
Usage: yt_tool.py <job.json> <kit_root> <config_dir>
"""
import json, os, sys, time, urllib.request, urllib.parse, urllib.error

def die(msg):
    print('ERROR:', msg); sys.exit(1)

job_path, root, conf = sys.argv[1], sys.argv[2], sys.argv[3]
job = json.load(open(job_path, encoding='utf-8'))
P = lambda p: p if os.path.isabs(p) else os.path.join(root, p)

def token():
    try:
        cs = json.load(open(os.path.join(conf, 'client_secret.json'))); cs = cs.get('installed') or cs.get('web')
        tk = json.load(open(os.path.join(conf, 'youtube.token.json')))
    except FileNotFoundError:
        die('Not connected yet - run "Connect YouTube" first.')
    d = urllib.parse.urlencode({'client_id': cs['client_id'], 'client_secret': cs['client_secret'],
                                'refresh_token': tk['refresh_token'], 'grant_type': 'refresh_token'}).encode()
    try:
        return json.load(urllib.request.urlopen(urllib.request.Request(cs.get('token_uri', 'https://oauth2.googleapis.com/token'), data=d)))['access_token']
    except urllib.error.HTTPError as e:
        die('Google sign-in expired (%s). Run "Connect YouTube" again.' % e.code)

A = {'Authorization': 'Bearer ' + token()}
API = 'https://www.googleapis.com/youtube/v3'

def call(url, method='GET', body=None, headers=None, raw=None):
    h = dict(A); h.update(headers or {})
    data = raw if raw is not None else (json.dumps(body).encode() if body is not None else None)
    if body is not None: h['Content-Type'] = 'application/json; charset=UTF-8'
    try:
        r = urllib.request.urlopen(urllib.request.Request(url, method=method, data=data, headers=h))
        return r
    except urllib.error.HTTPError as e:
        die('%s %s -> %s %s' % (method, url.split('?')[0], e.code, e.read().decode(errors='replace')))

def apply_fields(snip, st):
    if job.get('title'): snip['title'] = job['title']
    if job.get('description_file'): snip['description'] = open(P(job['description_file']), encoding='utf-8').read().strip()
    if 'tags' in job: snip['tags'] = job['tags']
    snip['categoryId'] = str(job.get('category_id', snip.get('categoryId', '22')))
    for k, j in (('defaultLanguage', 'language'), ('defaultAudioLanguage', 'audio_language')):
        if job.get(j): snip[k] = job[j]
    if job.get('privacy'): st['privacyStatus'] = job['privacy']
    if job.get('publish_at'): st['privacyStatus'] = 'private'; st['publishAt'] = job['publish_at']
    st['selfDeclaredMadeForKids'] = bool(job.get('made_for_kids', False))
    st['containsSyntheticMedia'] = bool(job.get('contains_synthetic_media', False))

mode = job.get('mode', 'update')
if mode == 'update':
    vid = job.get('video_id') or die('video_id is required for mode "update".')
    items = json.load(call('%s/videos?part=snippet,status&id=%s' % (API, vid)))['items']
    if not items: die('Video %s not found on your channel.' % vid)
    snip, st = items[0]['snippet'], items[0]['status']
    snip = {k: snip[k] for k in ('title', 'description', 'tags', 'categoryId', 'defaultLanguage', 'defaultAudioLanguage') if k in snip}
    st = {k: st[k] for k in ('privacyStatus', 'publishAt', 'embeddable', 'license', 'publicStatsViewable', 'selfDeclaredMadeForKids', 'containsSyntheticMedia') if k in st}
    apply_fields(snip, st)
    call('%s/videos?part=snippet,status' % API, 'PUT', {'id': vid, 'snippet': snip, 'status': st})
    print('UPDATED', vid)
elif mode == 'upload':
    path = P(job.get('file') or die('file is required for mode "upload".'))
    if not os.path.isfile(path): die('File not found: ' + path)
    snip, st = {}, {'privacyStatus': 'private', 'embeddable': True, 'license': 'youtube', 'publicStatsViewable': True}
    apply_fields(snip, st)
    if not snip.get('title'): die('title is required for mode "upload".')
    size = os.path.getsize(path)
    r = call('https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status&notifySubscribers=%s'
             % ('true' if job.get('notify_subscribers', True) else 'false'), 'POST', {'snippet': snip, 'status': st},
             {'X-Upload-Content-Type': 'video/*', 'X-Upload-Content-Length': str(size)})
    loc = r.headers['Location']; print('Uploading %.1f MB ...' % (size / 1e6), flush=True)
    with open(path, 'rb') as f:  # streamed, not loaded into memory
        v = json.load(call(loc, 'PUT', raw=f, headers={'Content-Type': 'video/*', 'Content-Length': str(size)}))
    vid = v['id']; print('UPLOADED', vid)
else:
    die('mode must be "update" or "upload".')

if job.get('thumbnail'):
    tp = P(job['thumbnail']); ct = 'image/png' if tp.lower().endswith('.png') else 'image/jpeg'
    with open(tp, 'rb') as f:
        call('https://www.googleapis.com/upload/youtube/v3/thumbnails/set?videoId=%s' % vid, 'POST', raw=f.read(), headers={'Content-Type': ct})
    print('THUMBNAIL set')
c = json.load(call('%s/videos?part=snippet,status&id=%s' % (API, vid)))['items'][0]
print('CHECK', 'https://youtu.be/' + vid, '|', c['status']['privacyStatus'], '| publishAt:', c['status'].get('publishAt'), '|', c['snippet']['title'])
if mode == 'upload' and job.get('privacy') == 'public' and c['status']['privacyStatus'] != 'public':
    print('NOTE: YouTube kept it Private. API uploads from unaudited Google projects stay Private - use mode "update" on a video you upload yourself.')
