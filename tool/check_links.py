#!/usr/bin/env python3
"""Check the built site's links (WeirdBrains public-content rules 6 and 7).

Run after `jaspr build`. For every HTML page under build/jaspr (or the directory given):

- every internal href/src resolves to a file in the build (a path, path/index.html or path.html),
  and every #fragment on another page names an id on it;
- the page links to https://weirdbrains.com (the shared footer);
- no URL appears as bare text outside a link, <code> or <pre>, so every URL is clickable.

With --external it also fetches each external URL once, with a browser-like User-Agent and
Accept header (crates.io answers 404 to clients that don't ask for HTML), and fails on a status
other than 2xx/3xx. Hosts that refuse scripts (403/429) are reported as warnings, not failures.
Uses only the standard library.
"""
import argparse
import concurrent.futures
import html.parser
import pathlib
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

MAIN_SITE = 'https://weirdbrains.com'
UA = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36'
BARE_URL = re.compile(r'https?://[^\s<>"\']+')
SKIP_SCHEMES = ('mailto:', 'tel:', 'data:', 'javascript:')


class Page(html.parser.HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.links, self.ids, self.bare = [], set(), []
        self.stack = []  # open a/code/pre/script/style tags

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if 'id' in a:
            self.ids.add(a['id'])
        if tag == 'a' and 'name' in a:
            self.ids.add(a['name'])
        for key in ('href', 'src'):
            if a.get(key) and not (tag == 'link' and a.get('rel') in ('preconnect', 'dns-prefetch')):
                self.links.append(a[key])
        if tag in ('a', 'code', 'pre', 'script', 'style', 'textarea'):
            self.stack.append(tag)

    def handle_endtag(self, tag):
        if tag in self.stack:
            while self.stack and self.stack.pop() != tag:
                pass

    def handle_data(self, data):
        if not self.stack:
            self.bare += BARE_URL.findall(data)


def resolve(root, page, href):
    path = urllib.parse.unquote(href.split('#')[0].split('?')[0])
    base = root if path.startswith('/') else page.parent
    target = (base / path.lstrip('/')).resolve() if path else page
    for cand in (target, target / 'index.html', target.with_name(target.name + '.html')):
        if cand.is_file():
            return cand
    return None


def fetch(url):
    req_headers = {'User-Agent': UA, 'Accept': 'text/html,application/xhtml+xml,*/*;q=0.8'}
    status = None
    for method in ('HEAD', 'GET'):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, method=method, headers=req_headers), timeout=20) as r:
                return url, r.status
        except urllib.error.HTTPError as e:
            status = e.code
        except Exception as e:  # network errors
            status = f'error: {e}'[:80]
    return url, status


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('build', nargs='?', default='build/jaspr')
    ap.add_argument('--external', action='store_true', help='also fetch external URLs')
    args = ap.parse_args()
    root = pathlib.Path(args.build).resolve()
    pages = sorted(root.rglob('*.html'))
    if not pages:
        sys.exit(f'no HTML pages under {root}; run `jaspr build` first')

    parsed = {}
    for p in pages:
        pp = Page()
        pp.feed(p.read_text(encoding='utf-8'))
        parsed[p] = pp

    errors, warnings, external = [], [], set()
    for p, pp in parsed.items():
        rel = p.relative_to(root)
        if not any(l.rstrip('/') == MAIN_SITE for l in pp.links):
            errors.append(f'{rel}: no link to {MAIN_SITE}')
        for url in pp.bare:
            errors.append(f'{rel}: bare URL not in a link: {url}')
        for href in pp.links:
            if href.startswith(SKIP_SCHEMES):
                continue
            if href.startswith(('http://', 'https://', '//')):
                external.add(href)
                continue
            target = resolve(root, p, href)
            if target is None:
                errors.append(f'{rel}: broken link {href}')
                continue
            frag = href.split('#', 1)[1] if '#' in href else ''
            if frag and target in parsed and frag not in parsed[target].ids:
                errors.append(f'{rel}: {href}: no id "{frag}" on {target.relative_to(root)}')

    if args.external:
        with concurrent.futures.ThreadPoolExecutor(16) as ex:
            for url, status in ex.map(fetch, sorted(external)):
                if isinstance(status, int) and status < 400:
                    continue
                (warnings if status in (403, 429) else errors).append(f'{url}: {status}')

    for w in warnings:
        print(f'::warning::{w}')
    for e in errors:
        print(f'::error::{e}')
    ext = f', {len(external)} external' + (' fetched' if args.external else ' (not fetched)')
    print(f'{len(pages)} pages{ext}; {len(errors)} errors, {len(warnings)} warnings')
    sys.exit(1 if errors else 0)


if __name__ == '__main__':
    main()
