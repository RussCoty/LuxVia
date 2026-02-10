#!/usr/bin/swift

// Test script to verify the improved relationship extraction logic
import Foundation

// Simulate the extractRelationshipFromKeywords function
func extractRelationshipFromKeywords(from text: String) -> String? {
    let lower = text.lowercased()
    
    // Define relationship keywords with their normalized forms
    // Order matters: more specific terms first to avoid false matches
    let relationshipMap: [(keywords: [String], normalized: String)] = [
        // Multi-word relationships first (to prioritize "best friend" over "friend")
        (["best friend", "bestfriend"], "best friend"),
        
        // Family - Grandparents (check before parents to avoid "mother" in "grandmother")
        (["grandmother", "grandma", "granny", "nana", "gran"], "grandmother"),
        (["grandfather", "grandpa", "granddad", "gramps"], "grandfather"),
        
        // Family - Parents
        (["mother", "mom", "mum", "mama", "mommy"], "mother"),
        (["father", "dad", "papa", "daddy"], "father"),
        
        // Family - Siblings
        (["sister"], "sister"),
        (["brother"], "brother"),
        
        // Family - Extended
        (["aunt", "auntie"], "aunt"),
        (["uncle"], "uncle"),
        (["cousin"], "cousin"),
        (["niece"], "niece"),
        (["nephew"], "nephew"),
        (["daughter"], "daughter"),
        (["son"], "son"),
        
        // Marriage/Partnership
        (["wife"], "wife"),
        (["husband"], "husband"),
        (["spouse"], "spouse"),
        (["partner"], "partner"),
        
        // Other relationships (friend last since it's most general)
        (["colleague", "coworker", "co-worker"], "colleague"),
        (["mentor"], "mentor"),
        (["teacher"], "teacher"),
        (["neighbor", "neighbour"], "neighbor"),
        (["friend"], "friend")
    ]
    
    // Keep track of all matches with their positions
    var matches: [(normalized: String, position: Int)] = []
    
    // Search for relationship patterns
    for (keywords, normalized) in relationshipMap {
        for keyword in keywords {
            // Check for possessive patterns with exact positions
            let patterns = [
                "my \(keyword)",
                "our \(keyword)",
                "the \(keyword)",
                "my late \(keyword)",
                "it's for my \(keyword)",
                "it was my \(keyword)"
            ]
            
            for pattern in patterns {
                if let range = lower.range(of: pattern) {
                    matches.append((normalized, lower.distance(from: lower.startIndex, to: range.lowerBound)))
                }
            }
            
            // Also check for standalone mentions at word boundaries
            if let range = lower.range(of: "\\b\(keyword)\\b", options: .regularExpression) {
                // Only add if not already matched by a pattern
                let position = lower.distance(from: lower.startIndex, to: range.lowerBound)
                if !matches.contains(where: { abs($0.position - position) < 5 }) {
                    matches.append((normalized, position))
                }
            }
        }
    }
    
    // If we have matches, use the LAST one (closest to end of text)
    // This handles cases like "My mom's sister, my aunt" → should pick "aunt"
    if let lastMatch = matches.max(by: { $0.position < $1.position }) {
        return lastMatch.normalized
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
    // Direct relationship mentions (from problem statement)
    TestCase(input: "My grandmother passed away", expectedOutput: "grandmother", description: "Direct relationship mention"),
    TestCase(input: "It's for my grandma", expectedOutput: "grandmother", description: "Casual variation - grandma → grandmother"),
    TestCase(input: "She was my mother and best friend", expectedOutput: "mother", description: "In context - should extract mother"),
    TestCase(input: "My mom's sister, my aunt", expectedOutput: "aunt", description: "Multiple relationships - should extract aunt"),
    
    // Additional family relationships
    TestCase(input: "My father was a wonderful man", expectedOutput: "father", description: "Father mention"),
    TestCase(input: "It's for my dad", expectedOutput: "father", description: "Dad → father normalization"),
    TestCase(input: "My grandfather served in WWII", expectedOutput: "grandfather", description: "Grandfather mention"),
    TestCase(input: "Our grandpa loved fishing", expectedOutput: "grandfather", description: "Grandpa → grandfather normalization"),
    
    // Siblings
    TestCase(input: "My sister passed away last week", expectedOutput: "sister", description: "Sister mention"),
    TestCase(input: "My brother was my best friend", expectedOutput: "brother", description: "Brother mention"),
    
    // Extended family
    TestCase(input: "My uncle taught me so much", expectedOutput: "uncle", description: "Uncle mention"),
    TestCase(input: "Our cousin was like a sister", expectedOutput: "cousin", description: "Cousin mention"),
    TestCase(input: "My niece brought so much joy", expectedOutput: "niece", description: "Niece mention"),
    
    // Marriage/Partnership
    TestCase(input: "My wife was the love of my life", expectedOutput: "wife", description: "Wife mention"),
    TestCase(input: "My husband passed away", expectedOutput: "husband", description: "Husband mention"),
    TestCase(input: "My partner and I were together for 20 years", expectedOutput: "partner", description: "Partner mention"),
    
    // Other relationships
    TestCase(input: "My best friend since childhood", expectedOutput: "best friend", description: "Best friend mention"),
    TestCase(input: "She was my friend", expectedOutput: "friend", description: "Friend mention"),
    TestCase(input: "My colleague and mentor", expectedOutput: "colleague", description: "Colleague mention"),
    TestCase(input: "Our neighbor for 30 years", expectedOutput: "neighbor", description: "Neighbor mention"),
    
    // Edge cases
    TestCase(input: "My late grandmother", expectedOutput: "grandmother", description: "Late grandmother pattern"),
    TestCase(input: "It was my mom", expectedOutput: "mother", description: "It was my pattern"),
    TestCase(input: "The mother of my children", expectedOutput: "mother", description: "The [relationship] pattern"),
    
    // Non-relationship text (should return nil)
    TestCase(input: "Hello", expectedOutput: nil, description: "Greeting - no relationship"),
    TestCase(input: "Thank you", expectedOutput: nil, description: "Thanks - no relationship"),
    TestCase(input: "She was kind and generous", expectedOutput: nil, description: "Traits without relationship"),
]

// Run tests
print("🧪 Running Relationship Extraction Tests\n")
print(String(repeating: "=", count: 70))

var passed = 0
var failed = 0

for (index, testCase) in testCases.enumerated() {
    let result = extractRelationshipFromKeywords(from: testCase.input)
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

print(String(repeating: "=", count: 70))
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
