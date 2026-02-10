# Input Validation Tests for Eulogy Writer

## Overview
This document provides test cases to validate the improved input validation in the Eulogy Writer. The main improvements include:
1. Preventing greetings and short casual messages from being treated as names
2. Better validation of user inputs before extracting structured data
3. More thoughtful LLM responses that guide users properly

## Test Cases

### Test 1: Greeting Detection
**Input:** "Hi"
**Expected Behavior:**
- The system should NOT set "Hi" as the subject's name
- The LLM should respond with a warm greeting and ask for actual information
- MockLLM response should be: "Hello. I'm here to help you create a meaningful eulogy for your loved one. When you're ready, please share their name or tell me about them in your own words."

### Test 2: Multiple Greetings
**Inputs to test:** "Hello", "Hey", "Good morning", "Good afternoon", "Good evening", "Thanks", "Thank you"
**Expected Behavior:**
- None of these should be stored as a name
- Each should receive a warm acknowledgment and request for actual information

### Test 3: Short Invalid Inputs
**Inputs to test:** "Ok", "Yes", "No", "Sure", "Okay"
**Expected Behavior:**
- These should not be treated as names
- System should continue asking for meaningful information

### Test 4: Valid Single Name
**Input:** "Mary"
**Expected Behavior:**
- Should be recognized as a valid name (capitalized, at least 2 characters)
- Should be stored as form.subjectName
- System should acknowledge the name and ask about relationship

### Test 5: Valid Full Name
**Input:** "Mary Elizabeth Johnson"
**Expected Behavior:**
- Should be recognized as a valid full name
- Should be stored as form.subjectName
- System should acknowledge and move to next question

### Test 6: Name in Context
**Input:** "My grandmother's name was Mary"
**Expected Behavior:**
- Should extract "Mary" as the name
- Should potentially also extract "grandmother" as relationship
- System should confirm and continue gathering information

### Test 7: Mixed Greeting and Information
**Input:** "Hi, I want to write about my mother Sarah"
**Expected Behavior:**
- Should extract "Sarah" as the name (ignoring the "Hi" greeting)
- Should potentially extract "mother" as relationship
- System should acknowledge both pieces of information

### Test 8: Case Sensitivity
**Input:** "hi" (lowercase)
**Expected Behavior:**
- Should still be detected as a greeting
- Should not be treated as a name
- Should receive the same greeting response

### Test 9: Multiple Invalid Inputs in Sequence
**Sequence:**
1. User: "Hi"
2. User: "Hello"
3. User: "Yes"
4. User: "Mary Smith"

**Expected Behavior:**
- First three inputs should not populate any form fields
- Each should receive appropriate guidance
- Fourth input should correctly extract "Mary Smith" as the name

### Test 10: Natural Conversation Flow
**Sequence:**
1. User: "Hi"
2. Assistant: (greeting response)
3. User: "I want to write a eulogy for my grandmother Mary"
4. Assistant: (acknowledges name and relationship, asks for traits)
5. User: "She was kind and patient"
6. Assistant: (acknowledges traits, asks for hobbies)

**Expected Behavior:**
- "Hi" should not be stored as any information
- "Mary" should be extracted as name
- "grandmother" should be extracted as relationship
- "kind and patient" should be stored as traits
- Form should progressively fill with only valid information

## Validation Criteria

### Name Validation
✓ Must be at least 2 characters long
✓ Should not be in the list of common greetings/casual words
✓ Preferably contains capitalized words
✓ Can be a single capitalized word (e.g., "Mary") or full name (e.g., "Mary Smith")

### Invalid Inputs List
The following should NEVER be treated as names:
- hi, hello, hey, greetings
- good morning, good afternoon, good evening
- thanks, thank you
- yes, no, okay, ok, sure, alright
- please, help, start, begin

## Testing Instructions

### Manual Testing
1. Open the Eulogy Writer in the LuxVia app
2. For each test case above, input the specified text
3. Verify that:
   - The AI responds appropriately
   - No invalid data is stored in the form
   - Valid data is correctly extracted and stored
   - The conversation flows naturally

### Debugging
To verify what data is being stored:
- Check the console logs for "Classifier label:" messages
- Review the form state after each input
- Ensure `form.subjectName` only contains valid names
- Verify other fields (relationship, traits, etc.) are populated correctly

## Success Criteria
- [ ] All greeting inputs (Test 1-2) are handled gracefully without storing invalid data
- [ ] Short casual messages (Test 3) don't populate form fields
- [ ] Valid names (Tests 4-5) are correctly recognized and stored
- [ ] Contextual information (Tests 6-7) is properly extracted
- [ ] Case insensitivity works (Test 8)
- [ ] Sequential invalid inputs (Test 9) don't break the system
- [ ] Natural conversation flow (Test 10) works smoothly
- [ ] The system "thinks before it answers" by validating inputs properly

## Code Changes Summary

### EulogyChatEngine.swift
1. **Replaced `extractLikelyName` with `extractValidName`**
   - Added list of invalid inputs (greetings, casual words)
   - Added minimum length validation (at least 2 characters)
   - Added proper capitalization checks
   - Returns `nil` for invalid inputs instead of accepting any text

2. **Updated `applyLabel` function**
   - Now uses `extractValidName` instead of falling back to raw text
   - Only sets name if validation passes

3. **Updated `applyHeuristics` function**
   - Uses the improved `extractValidName` function
   - Ensures no invalid data slips through heuristic extraction

4. **Improved LLM system prompt**
   - Added guidance to validate inputs
   - Instructed to handle greetings appropriately
   - Emphasized not treating casual messages as meaningful data

### LLMService.swift (MockLLMService)
1. **Added greeting detection**
   - Checks for common greetings at the start of `generateContextualResponse`
   - Returns appropriate guidance message for greetings
   - Prevents greetings from being processed as meaningful input

## Notes
- The same LLM is used; we're just making it "think" better through improved prompting and validation
- These changes maintain backward compatibility with existing functionality
- The improvements apply to both MockLLMService (for testing) and OpenAIService (for production)
