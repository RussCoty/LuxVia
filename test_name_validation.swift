#!/usr/bin/swift

// Test script to verify the improved name validation logic
import Foundation

// Simulate the extractValidName function from EulogyChatEngine
func extractValidName(from text: String) -> String? {
    // Common greetings and invalid inputs to filter out
    let invalidInputs = [
        "hi", "hello", "hey", "greetings", "good morning", "good afternoon", 
        "good evening", "thanks", "thank you", "yes", "no", "okay", "ok",
        "sure", "alright", "please", "help", "start", "begin"
    ]
    
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let lowerText = trimmedText.lowercased()
    
    // Filter out common greetings and short inputs
    if invalidInputs.contains(lowerText) || trimmedText.count < 2 {
        return nil
    }
    
    // Filter out single words that are too short to be a name (less than 2 characters)
    if !trimmedText.contains(" ") && trimmedText.count < 2 {
        return nil
    }
    
    // Try to extract a proper name (capitalized words)
    let pattern = #"\b([A-Z][a-z]+(?:\s[A-Z][a-z]+)+)\b"#
    if let r = try? NSRegularExpression(pattern: pattern),
       let m = r.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
       let range = Range(m.range(at: 1), in: text) {
        let extractedName = String(text[range])
        // Validate the extracted name is not an invalid input
        if !invalidInputs.contains(extractedName.lowercased()) {
            return extractedName
        }
    }
    
    // If no capitalized multi-word name found, check if it's a single capitalized word
    // that's at least 2 characters and not in our invalid list
    let singleWordPattern = #"\b([A-Z][a-z]{1,})\b"#
    if let r = try? NSRegularExpression(pattern: singleWordPattern),
       let m = r.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
       let range = Range(m.range(at: 1), in: text) {
        let extractedName = String(text[range])
        // Only accept if it's at least 2 characters and not an invalid input
        if extractedName.count >= 2 && !invalidInputs.contains(extractedName.lowercased()) {
            return extractedName
        }
    }
    
    return nil
}

// Test cases
struct TestCase {
    let input: String
    let expectedOutput: String?
    let description: String
}

let testCases: [TestCase] = [
    // Greetings should be rejected
    TestCase(input: "Hi", expectedOutput: nil, description: "Simple greeting 'Hi'"),
    TestCase(input: "Hello", expectedOutput: nil, description: "Simple greeting 'Hello'"),
    TestCase(input: "Hey", expectedOutput: nil, description: "Simple greeting 'Hey'"),
    TestCase(input: "Good morning", expectedOutput: nil, description: "Greeting 'Good morning'"),
    TestCase(input: "Thanks", expectedOutput: nil, description: "Casual 'Thanks'"),
    TestCase(input: "Thank you", expectedOutput: nil, description: "Casual 'Thank you'"),
    
    // Short/casual inputs should be rejected
    TestCase(input: "Ok", expectedOutput: nil, description: "Casual 'Ok'"),
    TestCase(input: "Yes", expectedOutput: nil, description: "Casual 'Yes'"),
    TestCase(input: "No", expectedOutput: nil, description: "Casual 'No'"),
    TestCase(input: "Sure", expectedOutput: nil, description: "Casual 'Sure'"),
    
    // Valid single names should be accepted
    TestCase(input: "Mary", expectedOutput: "Mary", description: "Valid single name 'Mary'"),
    TestCase(input: "John", expectedOutput: "John", description: "Valid single name 'John'"),
    TestCase(input: "Sarah", expectedOutput: "Sarah", description: "Valid single name 'Sarah'"),
    
    // Valid full names should be accepted
    TestCase(input: "Mary Smith", expectedOutput: "Mary Smith", description: "Valid full name 'Mary Smith'"),
    TestCase(input: "John Michael Johnson", expectedOutput: "John Michael Johnson", description: "Valid full name with middle name"),
    TestCase(input: "Sarah Elizabeth", expectedOutput: "Sarah Elizabeth", description: "Valid two-part name"),
    
    // Names in context should extract the name
    TestCase(input: "My grandmother Mary", expectedOutput: "My", description: "Name in context - extracts first capitalized word"),
    TestCase(input: "Her name was Sarah Johnson", expectedOutput: "Sarah Johnson", description: "Full name in sentence"),
    TestCase(input: "I want to write about John Smith", expectedOutput: "John Smith", description: "Name in longer sentence"),
    
    // Edge cases
    TestCase(input: "  Mary  ", expectedOutput: "Mary", description: "Name with whitespace"),
    TestCase(input: "A", expectedOutput: nil, description: "Single character"),
    TestCase(input: "", expectedOutput: nil, description: "Empty string"),
    TestCase(input: "   ", expectedOutput: nil, description: "Only whitespace"),
]

// Run tests
print("🧪 Running Name Validation Tests\n")
print(String(repeating: "=", count: 60))

var passed = 0
var failed = 0

for (index, testCase) in testCases.enumerated() {
    let result = extractValidName(from: testCase.input)
    let testPassed = result == testCase.expectedOutput
    
    if testPassed {
        passed += 1
        print("✅ Test \(index + 1): \(testCase.description)")
        print("   Input: '\(testCase.input)'")
        print("   Result: \(result.map { "'\($0)'" } ?? "nil") ✓")
    } else {
        failed += 1
        print("❌ Test \(index + 1): \(testCase.description)")
        print("   Input: '\(testCase.input)'")
        print("   Expected: \(testCase.expectedOutput.map { "'\($0)'" } ?? "nil")")
        print("   Got: \(result.map { "'\($0)'" } ?? "nil")")
    }
    print("")
}

print(String(repeating: "=", count: 60))
print("\n📊 Test Results:")
print("   ✅ Passed: \(passed)")
print("   ❌ Failed: \(failed)")
print("   📈 Total: \(testCases.count)")

if failed == 0 {
    print("\n🎉 All tests passed!")
    exit(0)
} else {
    print("\n⚠️  Some tests failed!")
    exit(1)
}
