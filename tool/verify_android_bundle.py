"""Inspect a real signed AAB. No key/password input and no store upload."""
import argparse
import base64
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import zipfile

ANDROID = '{http://schemas.android.com/apk/res/android}'


def run(*command):
    return subprocess.run(command, text=True, capture_output=True, check=True).stdout


def manifest_entries(raw):
    unfolded = raw.decode('utf-8').replace('\r\n', '\n').replace('\n ', '')
    entries = {}
    for block in unfolded.split('\n\n'):
        fields = dict(line.split(': ', 1) for line in block.splitlines() if ': ' in line)
        if 'Name' in fields:
            entries[fields['Name']] = fields
    return entries


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bundle', required=True, type=Path)
    parser.add_argument('--bundletool', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--expected-certificate-sha256')
    args = parser.parse_args()
    assert args.bundle.is_file() and args.bundletool.is_file()
    assert hashlib.sha256(args.bundletool.read_bytes()).hexdigest() == 'a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29', 'Unexpected bundletool binary'
    manifest = run('java', '-jar', str(args.bundletool), 'dump', 'manifest', '--bundle=' + str(args.bundle), '--module=base')
    root = ET.fromstring(manifest)
    sdk = root.find('uses-sdk')
    app = root.find('application')
    assert root.attrib['package'] == 'com.aestheticway.aesthetic_way'
    assert int(sdk.attrib[ANDROID + 'targetSdkVersion']) == 36, 'AAB target API is not 36'
    assert int(sdk.attrib[ANDROID + 'minSdkVersion']) == 24, 'Unexpected minimum API'
    assert app.attrib.get(ANDROID + 'debuggable', 'false') == 'false'
    assert app.attrib[ANDROID + 'usesCleartextTraffic'] == 'false'
    assert app.attrib[ANDROID + 'allowBackup'] == 'false'
    configuration = json.loads(run('java', '-jar', str(args.bundletool), 'dump', 'config', '--bundle=' + str(args.bundle)))
    assert 'PAGE_ALIGNMENT_16K' in json.dumps(configuration), 'Bundle packaging is not configured for 16KB pages'
    verified = run('jarsigner', '-J-Duser.language=en', '-verify', str(args.bundle))
    assert 'jar verified.' in verified, 'AAB signature did not verify'
    certificate = run('keytool', '-J-Duser.language=en', '-printcert', '-jarfile', str(args.bundle))
    assert 'android debug' not in certificate.lower(), 'Debug certificate is forbidden'
    fingerprint = re.search(r'SHA256:\s*([0-9A-F:]+)', certificate).group(1).replace(':', '')
    if args.expected_certificate_sha256:
        assert fingerprint == args.expected_certificate_sha256.replace(':', '').upper(), 'Unexpected upload certificate'
    libraries = []
    with zipfile.ZipFile(args.bundle) as archive, tempfile.TemporaryDirectory() as temp:
        entries = manifest_entries(archive.read('META-INF/MANIFEST.MF'))
        for name in archive.namelist():
            if name.endswith('/') or re.fullmatch(r'META-INF/(MANIFEST.MF|[^/]+\.(SF|RSA|DSA|EC)|SIG-[^/]+)', name, re.I):
                continue
            digest = entries.get(name, {}).get('SHA-256-Digest')
            assert digest and base64.b64encode(hashlib.sha256(archive.read(name)).digest()).decode() == digest, 'Unsigned or modified AAB entry: ' + name
            if re.fullmatch(r'base/lib/(arm64-v8a|x86_64)/[^/]+\.so', name):
                library = Path(temp) / Path(name).name
                library.write_bytes(archive.read(name))
                loads = [int(line.split()[-1], 16) for line in run('readelf', '-lW', str(library)).splitlines() if line.strip().startswith('LOAD ')]
                assert loads and all(alignment >= 0x4000 for alignment in loads), 'Non-16KB ELF LOAD alignment: ' + name
                libraries.append({'path': name, 'load_alignments': loads})
        assert libraries, 'No 64-bit native libraries inspected'
    report = {
        'application_id': root.attrib['package'],
        'target_sdk': 36, 'minimum_sdk': 24,
        'version_code': root.attrib.get(ANDROID + 'versionCode'),
        'debuggable': False, 'cleartext_allowed': False, 'backup_allowed': False,
        'bundle_sha256': hashlib.sha256(args.bundle.read_bytes()).hexdigest(),
        'upload_certificate_sha256': fingerprint,
        'signature_and_all_entry_digests_verified': True,
        'bundle_16kb_packaging': True, 'native_64bit_libraries': libraries,
        'permissions': [p.attrib[ANDROID + 'name'] for p in root.findall('uses-permission')],
        'qualification': 'Compilation and packaging evidence; not installed-device QA or Play upload acceptance. CI uses an ephemeral verification certificate, not the production upload key.',
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
