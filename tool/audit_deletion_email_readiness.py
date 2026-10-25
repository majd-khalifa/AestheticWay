"""Isolated source API probe. No real email/SMS, credentials or user data."""

import argparse
import hashlib
import json
import logging
import os
import secrets
import sys
from pathlib import Path
from unittest.mock import Mock, patch

p = argparse.ArgumentParser()
p.add_argument("--backend-root", type=Path, required=True)
p.add_argument("--output", type=Path, required=True)
a = p.parse_args()
root = a.backend_root.resolve()


def inventory():
    return {
        str(f.relative_to(root)): hashlib.sha256(f.read_bytes()).hexdigest()
        for f in root.rglob("*")
        if f.is_file()
    }


before = inventory()
sys.dont_write_bytecode = True
sys.path.insert(0, str(root))
os.environ["DJANGO_SETTINGS_MODULE"] = "config.settings.testing"
os.environ["SECRET_KEY"] = secrets.token_urlsafe(48)
logging.disable(logging.CRITICAL)
import django

django.setup()
from apps.accounts.models import User
from django.conf import settings
from django.core.cache import cache
from django.core.management import call_command
from rest_framework.test import APIClient

assert settings.DATABASES["default"]["NAME"] == ":memory:"
settings.ALLOWED_HOSTS = ["testserver"]
call_command("migrate", verbosity=0, interactive=False)
user = User.objects.create_user(phone="+971500000094", role="patient", is_verified=True)
client = APIClient()
client.force_authenticate(user=user)
records = []


def post(path, data):
    r = client.post("/api/v1/" + path, data, format="json")
    records.append({"route": path, "status": r.status_code})
    return r


with (
    patch("mailer.services.send_email", return_value=True),
    patch(
        "apps.accounts.services.profile_change.generate_otp_code", return_value="654321"
    ),
):
    assert (
        post(
            "auth/me/email/change/request/", {"new_email": "disposable@example.invalid"}
        ).status_code
        == 200
    )
    assert (
        post(
            "auth/me/email/change/confirm/",
            {"new_email": "disposable@example.invalid", "code": "654321"},
        ).status_code
        == 200
    )
user.refresh_from_db()
assert user.email == "disposable@example.invalid" and user.is_verified
assert "is_email_verified" not in [f.name for f in User._meta.fields]
assert not getattr(user, "is_email_verified", False)
sms = Mock()
sms.send_otp.return_value = True
mail = Mock()
mail.send_otp.return_value = True
with (
    patch("apps.accounts.services.account_deletion.get_sms_provider", return_value=sms),
    patch(
        "apps.accounts.services.account_deletion.get_email_otp_provider",
        return_value=mail,
    ) as email_provider,
):
    r = post("auth/me/deletion/request/", {})
    assert r.status_code == 200 and [d["channel"] for d in r.data["deliveries"]] == [
        "sms"
    ]
    assert not email_provider.called
    cache.clear()
    User.objects.filter(pk=user.pk).update(phone="")
    user.refresh_from_db()
    r = post("auth/me/deletion/request/", {})
    assert r.status_code == 400 and list(
        map(str, r.data["error"]["fields"]["code"])
    ) == ["NO_VERIFIED_DELIVERY_CHANNEL"]
assert inventory() == before
result = {
    "source_commit": "401560bdb06bd739f74eb42a88c68fc748e43dbb",
    "scope": "Isolated SQLite/APIClient; all mail/SMS mocked; no physical/provider delivery verification",
    "responses": records,
    "email_change_OTP_confirmed": True,
    "persisted_email_verified_flag_exists": False,
    "deletion_uses_confirmed_email": False,
    "deletion_dispatches_only_SMS_when_phone_present": True,
    "no_verified_channel_when_phone_absent_even_after_email_confirmation": True,
    "source_files_unchanged": len(before),
}
a.output.parent.mkdir(parents=True, exist_ok=True)
a.output.write_text(json.dumps(result, indent=2) + "\n")
print(f"{len(records)} source responses verified; {len(before)} source files unchanged")
