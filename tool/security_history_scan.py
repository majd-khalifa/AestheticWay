#!/usr/bin/env python3
"""Local, read-only reachable Git blob scan. NEVER prints matching secret values.

Heuristic shape detection only: findings require private owner review; absence
is not proof that a repository or its unreachable history contains no secrets.
"""
import json
import re
import subprocess

PATTERNS = {
    'private_key': re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'),
    'github_token': re.compile(r'\b(?:gh[pousr]_[A-Za-z0-9]{32,}|github_pat_[A-Za-z0-9_]{50,})\b'),
    'aws_access_id': re.compile(r'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b'),
    'google_api_key_shape': re.compile(r'\bAIza[A-Za-z0-9_-]{35}\b'),
    'slack_token_shape': re.compile(r'\bxox[baprs]-[A-Za-z0-9-]{20,}\b'),
    'jwt_shape': re.compile(r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b'),
}

def main():
    objects = subprocess.check_output(['git', 'rev-list', '--objects', '--all'], text=True).splitlines()
    scanned, findings = 0, []
    for line in objects:
        parts = line.split(' ', 1)
        if len(parts) != 2:
            continue
        oid, name = parts
        kind = subprocess.check_output(['git', 'cat-file', '-t', oid], text=True).strip()
        if kind != 'blob':
            continue
        raw = subprocess.check_output(['git', 'cat-file', 'blob', oid])
        if b'\x00' in raw or len(raw) > 4 * 1024 * 1024:
            continue
        try:
            text = raw.decode('utf-8')
        except UnicodeDecodeError:
            continue
        scanned += 1
        for rule, pattern in PATTERNS.items():
            for match in pattern.finditer(text):
                findings.append({'rule': rule, 'path': name, 'blob': oid,
                                 'line': text.count('\n', 0, match.start()) + 1})
    print(json.dumps({'scope': 'all reachable refs, textual blobs <=4MiB',
                      'text_blobs_scanned': scanned, 'findings': findings}, indent=2))

if __name__ == '__main__':
    main()
