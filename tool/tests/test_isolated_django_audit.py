"""Offline regression for audit tools; no backend source or credentials needed."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import textwrap
import unittest


TOOL_ROOT = Path(__file__).resolve().parents[1]


class IsolatedDjangoAuditTest(unittest.TestCase):
    def run_probe(self, mode, storage_flag="USE_R2_STORAGE"):
        with tempfile.TemporaryDirectory(prefix="aw_isolation_test_") as fixture:
            root = Path(fixture)
            # This settings module deliberately offers several remote aliases,
            # regardless of the flags. Its backend must never be instantiated.
            (root / "offline_settings.py").write_text(textwrap.dedent('''
                import tempfile
                SECRET_KEY = 'synthetic-offline-unit-fixture'
                INSTALLED_APPS = []
                DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3', 'NAME': ':memory:'}}
                MEDIA_ROOT = tempfile.mkdtemp(prefix='initial_settings_media_')
                MEDIA_URL = 'https://storage.invalid/'
                STORAGES = {
                    name: {'BACKEND': 'remote_trap.RemoteStorage'}
                    for name in ['default', 'staticfiles', 'private', '../hostile-alias']
                }
            '''))
            (root / "remote_trap.py").write_text(textwrap.dedent('''
                raise AssertionError('REMOTE STORAGE MODULE WAS IMPORTED')
            '''))
            environment = os.environ.copy()
            environment.update({
                "PYTHONDONTWRITEBYTECODE": "1",
                "PYTHONPATH": os.pathsep.join([str(TOOL_ROOT), str(root)]),
                "DJANGO_SETTINGS_MODULE": "offline_settings",
                # Own temp files created even by the deliberately preinitialized
                # settings case, which the isolation boundary must refuse.
                "TMPDIR": str(root),
                "TEMP": str(root),
                "TMP": str(root),
                storage_flag: "true",
                # Explicit synthetic values; never copy or use real credentials.
                "AWS_ACCESS_KEY_ID": "synthetic-not-a-key",
                "AWS_SECRET_ACCESS_KEY": "synthetic-not-a-secret",
                "CLOUDFLARE_R2_ACCESS_KEY_ID": "synthetic-not-a-key",
                "CLOUDFLARE_R2_SECRET_ACCESS_KEY": "synthetic-not-a-secret",
                "AW_ISOLATION_CASE": mode,
            })
            result = subprocess.run(
                [sys.executable, "-c", textwrap.dedent('''
                    import json, os, socket
                    from pathlib import Path
                    import django
                    from django.conf import settings
                    from django.core.files.base import ContentFile
                    from django.core.files.storage import storages
                    from isolated_django_audit import isolated_django_audit, LOCAL_STORAGE

                    mode = os.environ['AW_ISOLATION_CASE']
                    if mode in {'already_initialized', 'already_active_storage'}:
                        if mode == 'already_initialized':
                            assert settings.SECRET_KEY
                        else:
                            storages._storages['default'] = object()
                        try:
                            with isolated_django_audit():
                                raise AssertionError('Already initialized settings were accepted')
                        except RuntimeError as error:
                            assert 'precede' in str(error)
                    else:
                        try:
                            with isolated_django_audit() as assert_local:
                                owned_root = Path(settings.MEDIA_ROOT).parent
                                assert not django.apps.apps.ready
                                assert os.environ['USE_R2_STORAGE'] == 'false'
                                assert os.environ['USE_S3'] == 'false'
                                assert os.environ['AWS_ACCESS_KEY_ID'] == ''
                                django.setup()
                                assert_local()
                                assert len(settings.STORAGES) == 4
                                for alias in settings.STORAGES:
                                    storage = storages[alias]
                                    name = storage.save('proof.bin', ContentFile(b'genuine local bytes'))
                                    assert Path(storage.path(name)).is_file()
                                    with storage.open(name, 'rb') as uploaded:
                                        assert uploaded.read() == b'genuine local bytes'
                                    storage.delete(name)
                                    assert not storage.exists(name)
                                from django.db import models
                                class Portrait(models.Model):
                                    image = models.FileField(upload_to='portraits/')
                                    class Meta:
                                        app_label = 'offline_audit'
                                portrait = Portrait()
                                portrait.image.save('portrait.bin', ContentFile(b'local model media'), save=False)
                                assert Path(portrait.image.path).is_relative_to(owned_root)
                                assert portrait.image.read() == b'local model media'
                                portrait.image.close()
                                if mode == 'exception_cleanup':
                                    raise LookupError('intentional probe failure')
                                if mode == 'reject_remote_alias':
                                    storages.backends['injected'] = {'BACKEND': 'remote_trap.RemoteStorage'}
                                    try:
                                        storages['injected']
                                        raise AssertionError('Injected remote alias was accepted')
                                    except RuntimeError as error:
                                        assert 'refused' in str(error)
                                if mode == 'reject_path_escape':
                                    try:
                                        storages.create_storage({'BACKEND': LOCAL_STORAGE, 'OPTIONS': {'location': str(owned_root.parent)}})
                                        raise AssertionError('External filesystem path was accepted')
                                    except RuntimeError as error:
                                        assert 'refused' in str(error)
                                try:
                                    socket.create_connection(('production.invalid', 443))
                                    raise AssertionError('Network guard failed')
                                except RuntimeError as error:
                                    assert 'forbidden' in str(error)
                        except LookupError:
                            assert mode == 'exception_cleanup'
                        assert not owned_root.exists(), 'Temporary media survived probe completion'
                    assert 'remote_trap' not in __import__('sys').modules
                    print(json.dumps({'case': mode, 'passed': True}))
                ''')],
                env=environment,
                capture_output=True,
                text=True,
                timeout=30,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(json.loads(result.stdout)["passed"])

    def test_r2_environment_cannot_reach_remote_storage(self):
        self.run_probe("normal", "USE_R2_STORAGE")

    def test_s3_environment_cannot_reach_remote_storage(self):
        self.run_probe("normal", "USE_S3")

    def test_exception_also_cleans_media(self):
        self.run_probe("exception_cleanup")

    def test_new_remote_alias_is_rejected_before_import(self):
        self.run_probe("reject_remote_alias")

    def test_local_backend_cannot_escape_disposable_root(self):
        self.run_probe("reject_path_escape")

    def test_initialized_django_fails_closed(self):
        self.run_probe("already_initialized")

    def test_preexisting_storage_instance_fails_closed(self):
        self.run_probe("already_active_storage")


if __name__ == "__main__":
    unittest.main()
