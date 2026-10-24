"""Run real hosted XCTest with bounded CoreSimulator startup diagnostics.

macOS CI only. No test skips, signing changes, timeout increases or credentials.
"""

import json
import os
import pwd
import subprocess
import sys
import time


def run(command, timeout):
    print("Native QA stage:", " ".join(command), flush=True)
    return subprocess.run(
        command, check=True, timeout=timeout, text=True, capture_output=True
    )


if sys.platform != "darwin":
    raise SystemExit("This runner requires macOS and the pinned Xcode installation.")

# Failed prior runs stalled inside simctl before xcodebuild executed. Retry only
# discovery, after restarting the current runner user's simulator service.
for attempt in range(2):
    try:
        listing = json.loads(
            run(
                ["xcrun", "simctl", "list", "devices", "available", "--json"], 45
            ).stdout
        )
        break
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError):
        if attempt:
            raise SystemExit(
                "CoreSimulator discovery failed twice; no XCTest result is claimed."
            )
        print(
            "Restarting the runner user CoreSimulator service after failed discovery.",
            flush=True,
        )
        subprocess.run(
            [
                "killall",
                "-u",
                pwd.getpwuid(os.getuid()).pw_name,
                "com.apple.CoreSimulator.CoreSimulatorService",
            ],
            check=False,
        )
        time.sleep(2)

simulator = next(
    (
        v["udid"]
        for key, devices in listing["devices"].items()
        if "iOS-26" in key
        for v in devices
        if v["name"].startswith("iPhone")
    ),
    None,
)
if not simulator:
    raise SystemExit(
        "No available iOS 26 iPhone simulator; no XCTest result is claimed."
    )
booted = json.loads(
    run(["xcrun", "simctl", "list", "devices", "booted", "--json"], 45).stdout
)
if not any(d["udid"] == simulator for ds in booted["devices"].values() for d in ds):
    result = run(["xcrun", "simctl", "boot", simulator], 60)
    print(result.stdout, flush=True)
print(run(["xcrun", "simctl", "bootstatus", simulator, "-b"], 180).stdout, flush=True)
print("Executing real hosted XCTest now.", flush=True)
# Stream native build/test output. The existing workflow retains its 12 minute
# step bound and the existing per-test/destination limits stay at 120 seconds.
subprocess.run(
    [
        "xcodebuild",
        "test",
        "-workspace",
        "ios/Runner.xcworkspace",
        "-scheme",
        "Runner",
        "-configuration",
        "Debug",
        "-destination",
        f"platform=iOS Simulator,id={simulator}",
        "-destination-timeout",
        "120",
        "-parallel-testing-enabled",
        "NO",
        "-test-timeouts-enabled",
        "YES",
        "-maximum-test-execution-time-allowance",
        "120",
        "-resultBundlePath",
        "release-evidence/RunnerTests.xcresult",
        "CODE_SIGNING_ALLOWED=NO",
    ],
    check=True,
)
