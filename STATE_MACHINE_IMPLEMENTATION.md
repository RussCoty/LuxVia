# State Machine-Based Conversation Flow - Implementation

## Overview
This refactoring replaces the buggy LLM-based conversation logic with a deterministic state machine that prevents repetitive questions and provides a reliable, offline conversation experience.

## Changes Made

### 1. New Files Created

#### `ConversationState.swift`
- Defines `ConversationState` enum with 9 states:
  - `greeting`: Initial state
  - `collectingName`: Asking for the deceased's name
  - `collectingRelationship`: Asking for relationship
  - `collectingTraits`: Asking for personality traits
  - `collectingHobbies`: Asking for hobbies/passions
  - `collectingStories`: Asking for memories/stories
  - `collectingBeliefs`: Asking for spiritual/religious elements (optional)
  - `readyForDraft`: All required info collected, awaiting user confirmation
  - `reviewingDraft`: Draft generated, user can request changes

- Defines `QuestionType` enum to track what questions have been asked:
  - `name`, `relationship`, `traits`, `hobbies`, `stories`, `beliefs`

#### `ConversationStateMachine.swift`
- Core state machine logic with 200+ lines
- **Key Features:**
  - Tracks current state
  - Maintains `Set<QuestionType>` of asked questions to prevent repetition
  - `determineNextState(form:)`: Calculates next state based on collected info
  - `nextQuestion(form:)`: Returns appropriate question for current state
  - `userWantsDraft(_:)`: Detects user confirmation patterns
  - `userWantsToSkip(_:)`: Detects when user wants to skip optional questions
  - `markDraftGenerated()`: Transitions to review state after draft creation

- **State Transitions:**
  - Only advances when required information is actually collected
  - Skips optional fields if user doesn't provide them
  - Never asks the same question twice (enforced by `askedQuestions` set)

#### `ResponseTemplates.swift`
- Provides context-aware response variations
- **Key Features:**
  - 2-4 variations per question type to feel natural
  - References previously collected information (name, relationship)
  - Uses correct pronouns (he/she/they)
  - `draftConfirmation()`: Returns confirmation message
  - `acknowledgmentWithTransition()`: Combines acknowledgment with next question

### 2. Modified Files

#### `EulogyChatEngine.swift`
**Major Changes:**
- Removed `llmService` property
- Removed Keychain API key handling
- Added `stateMachine` property
- Simplified `init()` to not require LLM service

**Refactored Methods:**
- `start()`: Now calls `askNextQuestion()` instead of generating full initial message
- `handle(_:)`: Simplified to:
  1. Extract information using classifier and heuristics
  2. Check if user wants draft (if in ready state)
  3. Check if user wants to skip (if asking optional question)
  4. Call `askNextQuestion()`

**New Methods:**
- `generateDraft()`: Generates and displays draft eulogy
- `askNextQuestion()`: Gets next question from state machine and adds progress checklist

**Removed Methods:**
- `generateLLMResponse()`: No longer needed (250+ lines removed)
- `nextQuestion()`: Replaced by state machine logic

**Kept Unchanged:**
- `extractRelationshipFromKeywords(_:)`: ML-enhanced keyword extraction
- `inferPronounsFromRelationship(_:)`: Automatic pronoun inference
- `applyLabel(_:with:)`: Classifier label application
- `applyHeuristics(from:)`: Heuristic extraction
- `extractValidName(from:)`: Name validation
- `inferPronouns(from:)`: Pronoun detection

#### `LLMService.swift`
**Removed:**
- `LLMService` protocol (no longer needed)
- `OpenAIService` class (~60 lines)
- `MockLLMService` class (~250 lines)
- `LLMError` enum

**Kept:**
- `LLMMessage` struct (for potential future use)

### 3. Xcode Project Updates
- Added new Swift files to `LuxVia.xcodeproj/project.pbxproj`
- All files properly linked in build phases

## Behavior Changes

### Before (Buggy LLM-Based)
❌ Asked same questions repeatedly (Scenario A)
❌ No explicit state tracking
❌ Weak condition detection (hasName, hasRelationship unreliable)
❌ String mismatch bug ("⚠️ READY:" vs "⚠️ DRAFT READY:")
❌ Auto-generated draft without confirmation
❌ Required OpenAI API key or used unreliable mock
❌ Limited context (only last 6 messages)

### After (State Machine)
✅ Never asks same question twice (enforced by Set)
✅ Explicit state tracking with transitions
✅ Reliable state determination based on collected data
✅ No string matching bugs
✅ Asks for confirmation before generating draft
✅ 100% offline, no API dependencies
✅ Full context always available

## Progress Checklist Feature

Every assistant response now includes a progress checklist:

```
**Progress:**
✓ Name: Rose
✓ Relationship: grandmother
✓ Traits: kind, patient
○ Hobbies/passions
○ Story/memory
○ Beliefs/rituals

What did Rose love to do?
```

This provides:
- Visual feedback on conversation progress
- Debug tool to verify information extraction
- User confidence that system understands them

## Draft Confirmation Flow

**Before:** Auto-generated as soon as `form.isReadyForDraft == true`

**After:** Two-step process:
1. System detects ready state, asks: "I have everything I need. Would you like me to create the draft?"
2. Waits for user confirmation ("yes", "please", "go ahead", etc.)
3. Only then generates draft

## Testing

### Unit Tests
- `/tmp/test_state_machine.swift`: Basic state machine logic
- `/tmp/test_conversation_scenarios.swift`: Full conversation scenarios

### Compilation
All files compile successfully with `swiftc -parse`

### Scenarios Verified
✅ Scenario 1: No Repetition - State machine prevents duplicate questions
✅ Scenario 2: Multiple Info at Once - Extracts all provided info, advances appropriately
✅ Scenario 3: Draft Readiness - Asks permission, doesn't auto-generate

## Code Quality Improvements

### Lines of Code
- **Removed:** ~500 lines (OpenAI + Mock LLM services)
- **Added:** ~350 lines (State machine + templates)
- **Net reduction:** 150 lines
- **Complexity reduction:** Conditional logic → State machine

### Maintainability
- State machine is testable in isolation
- Clear separation of concerns
- Template responses are easily customizable
- No external API dependencies

### Reliability
- Deterministic behavior (no LLM unpredictability)
- No network failures
- Fast response times (no API delays)
- Predictable state transitions

## Backward Compatibility

### Unchanged Components
✓ `EulogyModels.swift` - EulogyForm, EulogyTone, etc.
✓ `EulogyGenerator.swift` - TemplateGenerator
✓ `LuxSlotClassifier.mlmodel` - CoreML classifier
✓ `EulogyWriterView.swift` - UI (works without changes)

### API Compatibility
- `EulogyChatEngine.init()` signature changed but has default parameters
- `send(_:)` method unchanged
- Published properties unchanged
- UI binding unchanged

## Security Notes

### Removed Attack Surfaces
- No API key storage in Keychain
- No network requests to OpenAI
- No external dependencies
- Pure local operation

### Remaining Security
- Input validation (name extraction, keyword filtering)
- ML model runs locally (no data leaves device)
- No credential handling

## Future Enhancements

### Easy to Add
1. More question variations in ResponseTemplates
2. Additional optional fields (achievements, beliefs details)
3. Multi-language support (state machine logic unchanged)
4. A/B testing different question phrasings

### Migration Path to LLM
If needed in future:
1. Keep state machine for state tracking
2. Add LLM for natural language generation only
3. State machine prevents repetition, LLM makes it sound better

## Summary

This refactoring successfully addresses all issues from the problem statement:
- ✅ Eliminates repetitive questions through state tracking
- ✅ Provides reliable offline operation
- ✅ Implements progress checklist debug feature
- ✅ Requires confirmation before draft generation
- ✅ Reduces code complexity and maintenance burden
- ✅ Maintains backward compatibility with existing components
- ✅ Improves user experience with predictable, fast responses
