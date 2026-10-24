import Flutter
import UIKit
import XCTest

class RunnerTests: XCTestCase {

  func testNativeHostLoadsFlutterDelegate() {
    XCTAssertTrue(UIApplication.shared.delegate is FlutterAppDelegate)
  }

  func testBundleIdentityAndRequiredResources() throws {
    XCTAssertEqual(Bundle.main.bundleIdentifier, "com.aestheticway.aestheticWay")
    XCTAssertNotNil(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
    XCTAssertNotNil(Bundle.main.url(forResource: "LaunchScreen", withExtension: "storyboardc"))
    for key in ["NSCameraUsageDescription", "NSPhotoLibraryUsageDescription", "NSLocationWhenInUseUsageDescription"] {
      let description = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: key) as? String)
      XCTAssertFalse(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    XCTAssertNil(Bundle.main.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription"))
    XCTAssertNil(Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription"))
    XCTAssertNil(Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysAndWhenInUseUsageDescription"))
    let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
    XCTAssertFalse(backgroundModes.contains("location"))
  }

}
