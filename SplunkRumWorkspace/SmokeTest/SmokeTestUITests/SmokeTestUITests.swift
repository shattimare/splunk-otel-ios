//
/*
Copyright 2021 Splunk Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import XCTest
import Swifter

// "annotations":[{"value":"process.start","timestamp":1631578180579894}
struct TestZipkinSpan: Decodable {
    var name: String
    var tags: [String: String]
    var annotations: [TestZipkinAnnotation]
}
struct TestZipkinAnnotation: Decodable {
    var value: String
    var timestamp: Int64
}
var receivedSpans: [TestZipkinSpan] = []

class SmokeTestUITests: XCTestCase {

    // swiftlint:disable overridden_super_call
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    func testStartup() throws {
        // UI tests must launch the application that they test.
        let server = HttpServer()
        server["/"] = { request in
            print("... server got spans")
            let spans = try! JSONDecoder().decode([TestZipkinSpan].self, from: Data(request.body))
            receivedSpans.append(contentsOf: spans)
            return HttpResponse.ok(.text("ok"))
        }
        try server.start(8989)

        let app = XCUIApplication()
        app.launch()
        sleep(10)

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        print(receivedSpans)
        XCTAssert(receivedSpans.count > 2)
        let srInit = receivedSpans.first(where: { (span) -> Bool in
            return span.name == "SplunkRum.initialize"
        })
        XCTAssertNotNil(srInit)
        let appStart = receivedSpans.first(where: { (span) -> Bool in
            return span.name == "AppStart"
        })
        XCTAssertNotNil(appStart)
        XCTAssertNotNil(appStart?.annotations.first(where: { (annot) -> Bool in
            return annot.value == "process.start"
        }))
        XCTAssertNotNil(appStart?.annotations.first(where: { (annot) -> Bool in
            return annot.value == "UIApplicationDidFinishLaunchingNotification"
        }))
        XCTAssertNotNil(appStart?.annotations.first(where: { (annot) -> Bool in
            return annot.value == "UIApplicationWillEnterForegroundNotification"
        }))
        XCTAssertNotNil(appStart?.annotations.first(where: { (annot) -> Bool in
            return annot.value == "UIApplicationDidBecomeActiveNotification"
        }))
        let presTrans = receivedSpans.first(where: { (span) -> Bool in
            return span.name == "PresentationTransition"
        })
        XCTAssertNotNil(presTrans)
        XCTAssertEqual("ViewController", presTrans?.tags["screen.name"]?.description)

        // FIXME interaction and screen name change
    }

}