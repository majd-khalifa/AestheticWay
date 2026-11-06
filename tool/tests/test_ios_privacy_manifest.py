"""Offline plist/configuration checks, run on Ubuntu and native Windows CI.

No Xcode archive, production retention or SDK delivery is implied by these checks.
"""
from pathlib import Path
import plistlib
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "ios/Runner/PrivacyInfo.xcprivacy"


class IosPrivacyManifestTest(unittest.TestCase):
    def setUp(self):
        self.manifest = plistlib.loads(MANIFEST.read_bytes())
        self.entries = self.manifest["NSPrivacyCollectedDataTypes"]

    def test_schema_boolean_types_no_duplicate_keys_or_data_types(self):
        for node in ET.fromstring(MANIFEST.read_bytes()).iter("dict"):
            keys = [child.text for child in node if child.tag == "key"]
            self.assertEqual(len(keys), len(set(keys)))
        types = [row["NSPrivacyCollectedDataType"] for row in self.entries]
        self.assertEqual(len(types), len(set(types)))
        purposes = {
            "NSPrivacyCollectedDataTypePurposeAppFunctionality",
            "NSPrivacyCollectedDataTypePurposeAnalytics",
        }
        for row in self.entries:
            self.assertEqual(set(row), {
                "NSPrivacyCollectedDataType", "NSPrivacyCollectedDataTypeLinked",
                "NSPrivacyCollectedDataTypeTracking", "NSPrivacyCollectedDataTypePurposes",
            })
            self.assertIs(type(row["NSPrivacyCollectedDataTypeLinked"]), bool)
            self.assertIs(type(row["NSPrivacyCollectedDataTypeTracking"]), bool)
            self.assertTrue(row["NSPrivacyCollectedDataTypePurposes"])
            self.assertTrue(set(row["NSPrivacyCollectedDataTypePurposes"]) <= purposes)

    def test_both_location_resolutions_disclosed_as_account_associated_functionality(self):
        for kind in ["PreciseLocation", "CoarseLocation"]:
            row = next(r for r in self.entries if r["NSPrivacyCollectedDataType"] == "NSPrivacyCollectedDataType" + kind)
            self.assertTrue(row["NSPrivacyCollectedDataTypeLinked"])
            self.assertFalse(row["NSPrivacyCollectedDataTypeTracking"])
            self.assertEqual(row["NSPrivacyCollectedDataTypePurposes"], ["NSPrivacyCollectedDataTypePurposeAppFunctionality"])
        self.assertFalse(self.manifest["NSPrivacyTracking"])
        self.assertEqual(self.manifest["NSPrivacyTrackingDomains"], [])

    def test_existing_disclosures_remain_present(self):
        prefix = "NSPrivacyCollectedDataType"
        prior = {"Name", "EmailAddress", "PhoneNumber", "UserID", "PhotosorVideos", "OtherUserContent", "Health", "ProductInteraction"}
        actual = {r[prefix].removeprefix(prefix) for r in self.entries}
        self.assertEqual(actual, prior | {"PreciseLocation", "CoarseLocation"})
        for row in self.entries:
            self.assertTrue(row[prefix + "Linked"])
            self.assertFalse(row[prefix + "Tracking"])
            expected = [prefix + "PurposeAppFunctionality"]
            if row[prefix].removeprefix(prefix) in {"UserID", "Health", "ProductInteraction"}:
                expected.append(prefix + "PurposeAnalytics")
            self.assertEqual(row[prefix + "Purposes"], expected)

    def test_foreground_only_permission_explains_transmission_and_manual_choice(self):
        info = plistlib.loads((ROOT / "ios/Runner/Info.plist").read_bytes())
        usage = info["NSLocationWhenInUseUsageDescription"].lower()
        for term in ["nearby clinics", "approximate or precise", "sent to aesthetic way", "city instead"]:
            self.assertIn(term, usage)
        self.assertNotIn("NSLocationAlwaysUsageDescription", info)
        self.assertNotIn("NSLocationAlwaysAndWhenInUseUsageDescription", info)
        self.assertNotIn("location", info.get("UIBackgroundModes", []))
        self.assertIn("BYPASS_PERMISSION_LOCATION_ALWAYS=1", (ROOT / "ios/Podfile").read_text())

    def test_permission_is_localized_without_losing_precision_or_manual_alternative(self):
        for language, terms in {
            "en": ["approximate or precise", "sent to Aesthetic Way", "city instead"],
            "ar": ["تقريبية أو دقيقة", "تُرسل إحداثيات", "والمدينة بدلاً"],
        }.items():
            text = (ROOT / f"ios/Runner/{language}.lproj/InfoPlist.strings").read_text(encoding="utf-8")
            self.assertIn('"NSLocationWhenInUseUsageDescription"', text)
            for term in terms:
                self.assertIn(term, text)

    def test_manifest_is_in_app_resources_and_bundle_identity_is_preserved(self):
        project = (ROOT / "ios/Runner.xcodeproj/project.pbxproj").read_text()
        self.assertIn("PrivacyInfo.xcprivacy in Resources", project)
        self.assertIn("PRODUCT_BUNDLE_IDENTIFIER = com.aestheticway.aestheticWay;", project)


if __name__ == "__main__":
    unittest.main()
