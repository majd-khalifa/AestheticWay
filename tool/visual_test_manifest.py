"""Non-secret provenance for reviewed test renders; never approves baselines."""
import hashlib
import json
import platform
import subprocess
from pathlib import Path

files = [
    "test/fixtures/fonts/DejaVuSans.ttf",
    "test/fixtures/fonts/DejaVuSans-Bold.ttf",
    "test/fixtures/media/packaging_fixture.png",
    "test/fixtures/media/portrait_frame_fixture.png",
]
print(json.dumps({
    "native_os": platform.system(),
    "native_machine": platform.machine(),
    "commit": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
    "fixture_sha256": {name: hashlib.sha256(Path(name).read_bytes()).hexdigest() for name in files},
    "logical_viewport": [390, 844],
    "device_pixel_ratio": 3,
    "capture_pixel_ratio": 1,
    "comparison": "exact pixels; no tolerance or missing-baseline fallback",
    "presentation": "pinned Android theme, standard density, padded targets",
}, indent=2))
