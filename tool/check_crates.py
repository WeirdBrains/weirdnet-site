#!/usr/bin/env python3
"""Fail if a weirdnet crate published on crates.io has no page on the site.

Reads lib/content/crates.dart (slug, crateName, version) and asks the crates.io API for
every crate named weirdnet* (weirdnet-* and weirdnetctl). A published crate with no entry
fails the check. A version on the site that differs from the newest on crates.io is a
warning, or a failure with --strict. Uses only the standard library.
"""
import json
import pathlib
import re
import sys
import urllib.request

API = 'https://crates.io/api/v1/crates?q=weirdnet&per_page=100&page={}'
UA = 'weirdnet-site check_crates (https://github.com/WeirdBrains/weirdnet-site)'


def site_crates(path):
    src = pathlib.Path(path).read_text()
    out = {}
    for block in re.split(r'\n  Crate\(', src)[1:]:
        slug = re.search(r"slug: '([^']+)'", block)
        if not slug:
            continue
        name = re.search(r"crateName: '([^']+)'", block)
        version = re.search(r"version: '([^']+)'", block)
        out[name.group(1) if name else 'weirdnet-' + slug.group(1)] = version.group(1) if version else ''
    return out


def published():
    found, page = {}, 1
    while True:
        req = urllib.request.Request(API.format(page), headers={'User-Agent': UA, 'Accept': 'application/json'})
        with urllib.request.urlopen(req, timeout=30) as r:
            data = json.load(r)
        for c in data['crates']:
            if c['name'].startswith('weirdnet'):
                found[c['name']] = c.get('max_stable_version') or c['max_version']
        if len(data['crates']) < 100:
            return found
        page += 1


def main():
    strict = '--strict' in sys.argv
    site = site_crates('lib/content/crates.dart')
    live = published()
    missing = sorted(n for n in live if n not in site)
    stale = sorted((n, site[n], v) for n, v in live.items() if n in site and site[n] and site[n] != v)
    for n in missing:
        print(f'::error::{n} {live[n]} is on crates.io but has no entry in lib/content/crates.dart')
    for n, have, want in stale:
        level = 'error' if strict else 'warning'
        print(f'::{level}::{n}: the site says {have}, crates.io has {want}')
    print(f'{len(live)} weirdnet crates on crates.io, {len(site)} on the site')
    sys.exit(1 if missing or (strict and stale) else 0)


if __name__ == '__main__':
    main()
