#!/usr/bin/swift

// Test script to verify the improved relationship extraction logic
import Foundation

// Simulate the extractRelationshipFromKeywords function
func extractRelationshipFromKeywords(from text: String) -> String? {
    let lower = text.lowercased()
    
    // Define relationship keywords with their normalized forms
    let relationshipMap: [(keywords: [String], normalized: String, priority: Int)] = [
        // Family relationships get higher priority (1)
        // Grandparents
        (["grandmother", "grandma", "granny", "nana", "gran"], "grandmother", 1),
        (["grandfather", "grandpa", "granddad", "gramps"], "grandfather", 1),
        
        // Parents
        (["mother", "mom", "mum", "mama", "mommy"], "mother", 1),
        (["father", "dad", "papa", "daddy"], "father", 1),
        
        // Siblings
        (["sister"], "sister", 1),
        (["brother"], "brother", 1),
        
        // Extended family
        (["aunt", "auntie"], "aunt", 1),
        (["uncle"], "uncle", 1),
        (["cousin"], "cousin", 1),
        (["niece"], "niece", 1),
        (["nephew"], "nephew", 1),
        (["daughter"], "daughter", 1),
        (["son"], "son", 1),
        
        // Marriage/Partnership (high priority)
        (["wife"], "wife", 1),
        (["husband"], "husband", 1),
        (["spouse"], "spouse", 1),
        (["partner"], "partner", 1),
        
        // Multi-word must come before single word (check "best friend" before "friend")
        (["best friend", "bestfriend"], "best friend", 2),
        
        // Other relationships (lower priority - 3)
        (["colleague", "coworker", "co-worker"], "colleague", 3),
        (["mentor"], "mentor", 3),
        (["teacher"], "teacher", 3),
        (["neighbor", "neighbour"], "neighbor", 3),
        (["friend"], "friend", 4)  // Lowest priority since it's most general
    ]
    
    // Keep track of all matches
    struct Match {
        let normalized: String
        let position: Int
        let priority: Int
        let hasStrongContext: Bool
    }
    var matches: [Match] = []
    
    // Search for relationship patterns
    for (keywords, normalized, priority) in relationshipMap {
        for keyword in keywords {
            // Use word boundary regex for exact matching
            let pattern = "\\b\(keyword)\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            
            let nsRange = NSRange(lower.startIndex..<lower.endIndex, in: lower)
            let regexMatches = regex.matches(in: lower, options: [], range: nsRange)
            
            for regexMatch in regexMatches {
                if let range = Range(regexMatch.range, in: lower) {
                    let position = lower.distance(from: lower.startIndex, to: range.lowerBound)
                    
                    // Check context before the keyword
                    let contextStart = lower.index(range.lowerBound, offsetBy: -30, limitedBy: lower.startIndex) ?? lower.startIndex
                    let context = String(lower[contextStart..<range.upperBound])
                    
                    // Strong context = possessive my/our/the before the keyword
                    let hasStrongContext = context.contains("my \(keyword)") ||
                                         context.contains("our \(keyword)") ||
                                         context.contains("the \(keyword)")
                    
                    matches.append(Match(
                        normalized: normalized,
                        position: position,
                        priority: priority,
                        hasStrongContext: hasStrongContext
                    ))
                }
            }
        }
    }
    
    // Select best match using this priority:
    // 1. Matches with strong context (my/our/the) over standalone mentions
    // 2. Among strong context matches, prefer higher priority (family > friend)
    // 3. If same context and priority, prefer earlier position (first mentioned relationship)
    if let bestMatch = matches.min(by: { m1, m2 in
        // Strong context beats no context
        if m1.hasStrongContext != m2.hasStrongContext {
            return !m1.hasStrongContext && m2.hasStrongContext
        }
        // Lower priority number = higher importance
        if m1.priority != m2.priority {
            return m1.priority > m2.priority
        }
        // Earlier position wins (first relationship mentioned)
        return m1.position > m2.position
    }) {
        return bestMatch.normalized
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
