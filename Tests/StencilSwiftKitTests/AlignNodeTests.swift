//
// StencilSwiftKit UnitTests
// Copyright © 2019 Rosberry
// MIT Licence
//

@testable import Stencil
@testable import StencilSwiftKit
import XCTest

class AlignNodeTests: XCTestCase {
    func testPositiveCase() {
        let env = stencilSwiftEnvironment()
        let inputString = """
        {%align%}Hello {{ name | upperFirstLetter }} please align me {%anchor%}here
            and here
                and here{%endalign}
        """
        let expectedString = """
        Hello World! please align me here
                                     and here
                                     and here
        """
        guard let result = try? env.renderTemplate(string: inputString, context: ["name": "world!"]) else {
            XCTAssert(false)
            return
        }
        XCTAssertEqual(result, expectedString)
    }
}
