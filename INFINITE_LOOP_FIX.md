# Infinite Loop Fix - Optional Questions

## Problem

Users reported the system was "looping on let me ask you about something else" - an infinite loop when optional questions were asked but not answered.

## Root Cause

The issue occurred when:
1. An optional question was asked (e.g., "What challenges did [name] overcome?")
2. The question was marked as asked in `askedQuestions` set
3. User's response didn't populate the form field (it remained `nil`)
4. `determineNextState()` checked if field was `nil`, returned same state
5. `nextQuestion()` saw question was already asked, recursively called itself
6. **Result:** Infinite loop displaying "Thank you. Let me ask about something else."

## The Fix

### Part 1: Update `determineNextState()` Logic

Added checks to skip optional questions that have already been asked:

```swift
// Before (caused loop)
} else if form.challengesOvercome == nil {
    return .collectingChallenges
}

// After (prevents loop)
} else if form.challengesOvercome == nil && !askedQuestions.contains(.challenges) {
    return .collectingChallenges
}
```

Applied to all 4 optional questions:
- `challenges`
- `smallDetails`
- `beliefs`
- `finalThoughts`

### Part 2: Remove Recursive Calls

Replaced recursive `nextQuestion(form: form)` calls with simple responses:

```swift
case .collectingBeliefs:
    if !askedQuestions.contains(.beliefs) {
        // Ask the question...
        return (.beliefs, questionText)
    }
    // Before: return nextQuestion(form: form) ← Could recurse infinitely
    // After:  
    return (nil, "Thank you.") // Let state machine handle progression
```

## How It Works Now

### Scenario: User Skips Optional Question

1. **System asks:** "What challenges did [name] overcome? (optional)"
2. **User responds:** "skip" or provides unclear answer
3. **System:**
   - Marks question as asked: `askedQuestions.insert(.challenges)`
   - Field remains nil: `form.challengesOvercome = nil`
4. **Next iteration:**
   - `determineNextState()` checks: `form.challengesOvercome == nil && !askedQuestions.contains(.challenges)`
   - Second condition is FALSE (question was asked)
   - Skips to next state: `.collectingSmallDetails`
5. **Result:** ✅ Proper progression, no loop

### Scenario: User Answers Optional Question

1. **System asks:** "What challenges did [name] overcome? (optional)"
2. **User responds:** "She overcame illness with grace"
3. **System:**
   - Marks question as asked: `askedQuestions.insert(.challenges)`
   - Populates field: `form.challengesOvercome = "She overcame illness with grace"`
4. **Next iteration:**
   - `determineNextState()` checks: `form.challengesOvercome == nil`
   - Condition is FALSE (field is populated)
   - Skips to next state: `.collectingSmallDetails`
5. **Result:** ✅ Proper progression

## Testing

Created comprehensive test suite (`test_loop_fix.swift`) that validates:

✅ **Test 1:** Optional question asked but not answered
- Expected: Skip to next state
- Result: PASS - Moves to `.readyForDraft`

✅ **Test 2:** Sequential optional question handling
- Expected: Progress through all optional questions without looping
- Result: PASS - Completes in 1 iteration

✅ **Test 3:** Required questions not affected
- Expected: Required questions still asked normally
- Result: PASS - Works as before

## Impact

### Before Fix
```
User: "skip"
System: "Thank you. Let me ask about something else."
[State: collectingBeliefs, form.beliefsOrRituals = nil, askedQuestions = {beliefs}]

nextQuestion() called
→ determineNextState() returns .collectingBeliefs (field is nil)
→ Question already asked, returns "Let me ask about something else."
→ nextQuestion() called recursively
→ determineNextState() returns .collectingBeliefs (field STILL nil)
→ INFINITE LOOP ❌
```

### After Fix
```
User: "skip"  
System: "Thank you."
[State: collectingBeliefs, form.beliefsOrRituals = nil, askedQuestions = {beliefs}]

Next user message triggers nextQuestion()
→ determineNextState() checks: nil && !askedQuestions.contains(.beliefs)
→ Second check is FALSE
→ Returns .collectingSmallDetails
→ Asks next question ✅
```

## Files Modified

1. **ConversationStateMachine.swift** (+12/-12 lines)
   - Added `!askedQuestions.contains()` checks for optional questions
   - Removed recursive `nextQuestion()` calls
   - Simplified fallback responses

## Verification

- ✅ All test cases pass
- ✅ No infinite loops possible
- ✅ Optional questions can be skipped
- ✅ Optional questions can be answered
- ✅ Required questions unaffected
- ✅ State machine progresses correctly

## Conclusion

The fix ensures that optional questions are only asked once, and if the user skips them or provides an invalid answer, the conversation progresses naturally to the next question instead of looping indefinitely.
