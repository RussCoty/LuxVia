#!/usr/bin/swift

// Test script to verify color coding for LLM responses
import Foundation

// Simulate the ChatMessage and related types
enum ChatRole { case user, assistant, draft }
enum MessageSource { case user, aiGenerated, preWritten, draft }

struct TestChatMessage {
    let role: ChatRole
    let text: String
    let source: MessageSource
    
    init(role: ChatRole, text: String, source: MessageSource? = nil) {
        self.role = role
        self.text = text
        // Auto-determine source based on role if not explicitly provided
        if let source = source {
            self.source = source
        } else {
            switch role {
            case .user:
                self.source = .user
            case .draft:
                self.source = .draft
            case .assistant:
                self.source = .preWritten // default for assistant
            }
        }
    }
}

// Test cases
struct TestCase {
    let message: TestChatMessage
    let expectedSource: MessageSource
    let description: String
}

let testCases: [TestCase] = [
    // User messages should always be user source
    TestCase(
        message: TestChatMessage(role: .user, text: "Hello"),
        expectedSource: .user,
        description: "User message defaults to user source"
    ),
    
    // Draft messages should always be draft source
    TestCase(
        message: TestChatMessage(role: .draft, text: "Draft eulogy text..."),
        expectedSource: .draft,
        description: "Draft message defaults to draft source"
    ),
    
    // Assistant messages default to preWritten
    TestCase(
        message: TestChatMessage(role: .assistant, text: "What was their name?"),
        expectedSource: .preWritten,
        description: "Assistant message defaults to preWritten source"
    ),
    
    // Explicitly set AI-generated source
    TestCase(
        message: TestChatMessage(role: .assistant, text: "I'm sorry for your loss. Could you tell me more about them?", source: .aiGenerated),
        expectedSource: .aiGenerated,
        description: "Assistant message explicitly marked as aiGenerated"
    ),
    
    // Explicitly set pre-written source
    TestCase(
        message: TestChatMessage(role: .assistant, text: "What was their **full name**?", source: .preWritten),
        expectedSource: .preWritten,
        description: "Assistant message explicitly marked as preWritten"
    ),
    
    // Override default with explicit source
    TestCase(
        message: TestChatMessage(role: .assistant, text: "Response", source: .aiGenerated),
        expectedSource: .aiGenerated,
        description: "Explicit source overrides default assistant source"
    ),
]

// Run tests
print("🧪 Running Color Coding Tests\n")
print(String(repeating: "=", count: 70))

var passed = 0
var failed = 0

for (index, testCase) in testCases.enumerated() {
    let result = testCase.message.source
    let testPassed = result == testCase.expectedSource
    
    if testPassed {
        passed += 1
        print("✅ Test \(index + 1): \(testCase.description)")
        print("   Role: \(testCase.message.role)")
        print("   Source: \(result) ✓")
    } else {
        failed += 1
        print("❌ Test \(index + 1): \(testCase.description)")
        print("   Role: \(testCase.message.role)")
        print("   Expected: \(testCase.expectedSource)")
        print("   Got: \(result)")
    }
    print("")
}

print(String(repeating: "=", count: 70))
print("\n📊 Test Results:")
print("   ✅ Passed: \(passed)")
print("   ❌ Failed: \(failed)")
print("   📈 Total: \(testCases.count)")

// Test color determination logic
print("\n🎨 Color Coding Logic Tests\n")
print(String(repeating: "=", count: 70))

enum BubbleColor: String {
    case accentColor = "Accent Color (User)"
    case aiGenerated = "Light Blue (AI Generated)"
    case preWritten = "Light Purple (Pre-Written)"
    case systemBackground = "System Background"
}

func determineBubbleColor(role: ChatRole, source: MessageSource) -> BubbleColor {
    if role == .user {
        return .accentColor
    } else if source == .aiGenerated {
        return .aiGenerated
    } else if source == .preWritten {
        return .preWritten
    } else {
        return .systemBackground
    }
}

struct ColorTest {
    let role: ChatRole
    let source: MessageSource
    let expectedColor: BubbleColor
    let description: String
}

let colorTests: [ColorTest] = [
    ColorTest(role: .user, source: .user, expectedColor: .accentColor, 
              description: "User messages use accent color"),
    ColorTest(role: .assistant, source: .aiGenerated, expectedColor: .aiGenerated,
              description: "AI-generated messages use light blue"),
    ColorTest(role: .assistant, source: .preWritten, expectedColor: .preWritten,
              description: "Pre-written messages use light purple"),
    ColorTest(role: .draft, source: .draft, expectedColor: .systemBackground,
              description: "Draft messages use system background"),
]

var colorPassed = 0
var colorFailed = 0

for (index, colorTest) in colorTests.enumerated() {
    let result = determineBubbleColor(role: colorTest.role, source: colorTest.source)
    let testPassed = result == colorTest.expectedColor
    
    if testPassed {
        colorPassed += 1
        print("✅ Color Test \(index + 1): \(colorTest.description)")
        print("   Color: \(result.rawValue) ✓")
    } else {
        colorFailed += 1
        print("❌ Color Test \(index + 1): \(colorTest.description)")
        print("   Expected: \(colorTest.expectedColor.rawValue)")
        print("   Got: \(result.rawValue)")
    }
    print("")
}

print(String(repeating: "=", count: 70))
print("\n📊 Color Test Results:")
print("   ✅ Passed: \(colorPassed)")
print("   ❌ Failed: \(colorFailed)")
print("   📈 Total: \(colorTests.count)")

let totalPassed = passed + colorPassed
let totalFailed = failed + colorFailed
let totalTests = testCases.count + colorTests.count

print("\n" + String(repeating: "=", count: 70))
print("📊 Overall Results:")
print("   ✅ Total Passed: \(totalPassed)")
print("   ❌ Total Failed: \(totalFailed)")
print("   📈 Total Tests: \(totalTests)")

if totalFailed == 0 {
    print("\n🎉 All color coding tests passed!")
    exit(0)
} else {
    print("\n⚠️  Some tests failed!")
    exit(1)
}
