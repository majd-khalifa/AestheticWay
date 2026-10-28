"""Process-local safety boundary for the read-only backend contract probes."""

from contextlib import contextmanager
import os
from pathlib import Path
import tempfile
from unittest.mock import patch


LOCAL_STORAGE = "django.core.files.storage.FileSystemStorage"


@contextmanager
def isolated_django_audit():
    """Enter before settings/setup; clean all media even when a probe raises.

    The caller still owns backend source hashing, fixture assertions and output.
    This context is intentionally single-use in a fresh Python process: it must
    never silently reuse settings or storage initialized by another application.
    """
    from django.apps import apps
    from django.conf import settings
    from django.core.files.storage import default_storage, storages
    from django.core.files.storage.handler import StorageHandler
    from django.utils.functional import empty

    if (
        settings.configured
        or apps.apps_ready
        or storages._storages
        or storages._backends is not None
        or default_storage._wrapped is not empty
    ):
        raise RuntimeError("Audit isolation must precede Django/storage initialization")

    def deny_network(*args, **kwargs):
        raise RuntimeError("Network access is forbidden in an isolated contract audit")

    # Do not read an operator's credentials, profiles or storage switches. The
    # settings module may read .env, so explicit environment overrides come first.
    environment = {
        "USE_R2_STORAGE": "false",
        "USE_S3": "false",
        "AWS_EC2_METADATA_DISABLED": "true",
        "AWS_ACCESS_KEY_ID": "",
        "AWS_SECRET_ACCESS_KEY": "",
        "AWS_SESSION_TOKEN": "",
        "AWS_PROFILE": "",
        "AWS_DEFAULT_PROFILE": "",
        "CLOUDFLARE_R2_ACCESS_KEY_ID": "",
        "CLOUDFLARE_R2_SECRET_ACCESS_KEY": "",
    }
    with tempfile.TemporaryDirectory(prefix="aw_contract_audit_") as temporary:
        root = Path(temporary).resolve()
        create_storage = StorageHandler.create_storage

        def local_only_storage(handler, configuration):
            options = configuration.get("OPTIONS", {})
            location = Path(options.get("location", settings.MEDIA_ROOT)).resolve()
            if (
                configuration.get("BACKEND") != LOCAL_STORAGE
                or not location.is_relative_to(root)
                or not str(options.get("base_url", settings.MEDIA_URL)).startswith("/")
                or str(options.get("base_url", settings.MEDIA_URL)).startswith("//")
            ):
                raise RuntimeError("External or non-disposable audit storage refused")
            return create_storage(handler, configuration)

        with (
            patch.dict(os.environ, environment),
            patch("socket.socket.connect", deny_network),
            patch("socket.socket.connect_ex", deny_network),
            patch("socket.create_connection", deny_network),
            patch.object(StorageHandler, "create_storage", local_only_storage),
        ):
            # testing.py itself calls mkdtemp while importing base settings. Keep
            # that initial directory inside our owned root, too, without editing
            # backend files or leaving its otherwise unmanaged directory behind.
            with patch.object(tempfile, "tempdir", str(root)):
                inherited_aliases = set(settings.STORAGES)
            if (
                settings.DATABASES["default"]["ENGINE"] != "django.db.backends.sqlite3"
                or settings.DATABASES["default"]["NAME"] != ":memory:"
            ):
                raise RuntimeError("Contract audits require disposable in-memory SQLite")
            if storages._storages or storages._backends is not None:
                raise RuntimeError("Settings initialized storage before audit isolation")

            settings.MEDIA_ROOT = str(root / "media")
            settings.MEDIA_URL = "/audit-media/"
            settings.STATIC_ROOT = str(root / "static")
            settings.STATIC_URL = "/audit-static/"
            settings.USE_R2_STORAGE = False
            settings.USE_S3 = False
            settings.DEFAULT_FILE_STORAGE = LOCAL_STORAGE
            settings.STATICFILES_STORAGE = LOCAL_STORAGE
            # Replace every inherited alias/options, not only 'default'. Alias
            # names never become paths, so arbitrary configuration cannot escape.
            settings.STORAGES = {
                alias: {
                    "BACKEND": LOCAL_STORAGE,
                    "OPTIONS": {
                        "location": str(root / f"alias-{index}"),
                        "base_url": "/audit-media/",
                    },
                }
                for index, alias in enumerate(
                    sorted(inherited_aliases | {"default", "staticfiles"})
                )
            }

            def assert_local_storage():
                from django.core.files.storage import FileSystemStorage

                for alias in settings.STORAGES:
                    storage = storages[alias]
                    if (
                        type(storage) is not FileSystemStorage
                        or not Path(storage.location).resolve().is_relative_to(root)
                    ):
                        raise RuntimeError("Non-local audit storage is active")
                if apps.models_ready:
                    from django.db.models import FileField

                    for model in apps.get_models():
                        for field in model._meta.fields:
                            if isinstance(field, FileField):
                                storage = field.storage
                                if (
                                    not isinstance(storage, FileSystemStorage)
                                    or not Path(storage.location).resolve().is_relative_to(root)
                                ):
                                    raise RuntimeError(
                                        "Model field bypasses disposable audit storage"
                                    )

            assert_local_storage()
            try:
                yield assert_local_storage
            finally:
                # Check after setup and after probes as well; cleanup is owned by
                # TemporaryDirectory and still runs if this validation raises.
                assert_local_storage()
