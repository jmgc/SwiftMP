import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(IntMPTests.allTests),
        testCase(UIntMPTests.allTests),
        testCase(QuotMPTests.allTests),
        testCase(FloatMPTests.allTests),
    ]
}
#endif
