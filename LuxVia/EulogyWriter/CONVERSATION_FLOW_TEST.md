# AI Eulogy Chat - Natural Conversation Flow Testing Guide

## Overview
The AI chat now uses LLM-driven conversation instead of rigid questions. This provides a more natural, human-like experience that references previously shared information and guides users toward creating a complete eulogy draft.

## Key Changes
1. **Conversational Opening**: Instead of asking for specific fields, the AI invites natural sharing
2. **Context-Aware Responses**: The LLM references previously provided information (name, relationship, pronouns) in all responses
3. **Goal-Driven Flow**: The AI actively guides the conversation toward draft creation once sufficient information is collected
4. **Smart Information Extraction**: The ML classifier still extracts structured data from natural conversation
5. **Draft Readiness Detection**: Explicit signaling when enough information is gathered to create a meaningful eulogy
6. **Graceful Fallback**: If LLM fails, falls back to directed questions

## Configuration
- **With OpenAI API Key**: Set `openai_api_key` in UserDefaults to use GPT-4o-mini
- **Without API Key**: Uses MockLLMService with context-aware responses

## Example Conversation Flow

### Natural Flow (Desired Behavior - UPDATED with Context-Awareness)
```
Assistant: I'm here to help you create a meaningful and personal eulogy. This is a space 
where we can talk naturally about your loved one.

Please share whatever feels right to you - their name, who they were to you, what made 
them special, or any memories that come to mind. I'll listen and ask gentle questions 
along the way.

User: My grandmother Mary passed away last week. She was an amazing woman.

Assistant (LLM): I'm so sorry for your loss. Mary sounds like she held a very special place 
in your life. What are some of the qualities that made her so amazing to you?

[Note: AI acknowledges the name "Mary" and will reference it in future responses]

User: She was so kind and patient. She loved gardening and would spend hours in her garden.

Assistant (LLM): Those are wonderful qualities that really capture Mary. What were some of 
the things she loved to do? Any hobbies or passions that brought her joy?

[Note: AI references "Mary" by name and her qualities - shows context-awareness]

User: She loved gardening, as I mentioned, and also baking cookies for the family.

Assistant (LLM): That really brings Mary to life. Is there a particular story or moment that 
captures her essence - something that makes you smile when you remember it?

[Note: AI remembers Mary's gardening hobby and doesn't ask about hobbies again]

User: Yes, she taught me how to plant tomatoes when I was 8. We would pick them together 
every summer.

Assistant (LLM): What a touching memory of Mary. Before I help craft the eulogy, would you 
like to include any spiritual, religious, or humanist elements that would honor her beliefs?

[Note: AI references "Mary" again, showing continued context-awareness]

User: She was Catholic and her faith was very important to her.

Assistant (LLM): Thank you for sharing that about Mary. I believe I have everything I need 
to create a meaningful draft. Shall I put that together for you?

[Note: AI has detected form.isReadyForDraft = true and proposes creating the draft]

User: Yes, please.

[Draft generated - System automatically creates draft when ready]
```

## Testing Checklist

- [ ] Initial greeting is warm and conversational (not asking for specific fields)
- [ ] **NEW**: Responses reference previously shared information (name, relationship, pronouns)
- [ ] **NEW**: AI uses correct pronouns (he/she/they) when referring to the deceased
- [ ] Questions feel natural, not like a form to fill out
- [ ] **NEW**: No repetitive questions about information already provided
- [ ] AI shows empathy and understanding
- [ ] Information is extracted correctly (name, relationship, traits, hobbies, stories)
- [ ] **NEW**: Conversation progresses toward draft creation (not open-ended gathering)
- [ ] **NEW**: AI explicitly proposes creating draft when sufficient information is collected
- [ ] **NEW**: Draft is generated automatically after user confirms readiness
- [ ] Draft incorporates all shared information appropriately
- [ ] User can request edits naturally after seeing draft

## What to Test

### Context-Awareness Tests
1. **Name Reference**: After sharing a name, verify the AI uses it in subsequent responses
2. **Relationship Reference**: After sharing relationship, verify AI references it (e.g., "your grandmother")
3. **Pronoun Usage**: Verify AI uses correct pronouns based on relationship (grandmother → she/her)
4. **No Repetition**: Share a hobby, then verify AI doesn't ask about hobbies again
5. **Story Acknowledgment**: Share a story, verify AI references it in follow-up questions

### Draft Progression Tests
1. **Early Stage**: With only name, verify AI asks for more information
2. **Mid Stage**: With name + relationship + traits, verify AI asks for stories
3. **Ready Stage**: With name + relationship + traits + stories, verify AI proposes creating draft
4. **Confirmation**: Say "yes" to draft proposal, verify draft is generated automatically
5. **Extended Conversation**: After 10+ exchanges with sufficient info, verify AI strongly suggests creating draft

### Edge Cases
1. **Greeting Only**: Send "Hi" → verify AI responds warmly and guides to share about loved one
2. **Short Responses**: Send "no" when asked about beliefs → verify AI moves to draft creation
3. **Additional Info After Ready**: Share extra story when ready → verify AI acknowledges and still moves toward draft

## Mock Service Testing
The MockLLMService now uses the system prompt context to provide intelligent responses:
- **Context-Aware**: Reads the system prompt to understand what information has already been collected
- **Avoids Repetition**: Won't ask for information that's already in the form (name, relationship, traits, hobbies, stories, beliefs)
- **Natural Progression**: Guides conversation based on what's still needed
- **Intelligent Fallback**: Uses "Still need:" list from system prompt to ask for missing information
- **Actual Story Content**: The LLM receives the full text of stories shared, not just the count
- **Pronoun Awareness**: Extracts and uses correct pronouns (he/she/they) when referencing the deceased
- **Draft Readiness**: Detects when enough information is collected and actively proposes creating the draft

Key improvements:
1. Parses system context to detect: hasName, hasRelationship, hasPronouns, hasTraits, hasHobbies, hasStories, hasBeliefs
2. Only asks for information that hasn't been provided yet
3. Provides different responses depending on what combination of information is available
4. Uses the "Still need:" section to intelligently guide the next question
5. **NEW**: Extracts actual values (name, relationship, pronouns) and uses them in responses
6. **NEW**: Detects "⚠️ DRAFT READY" signal and moves toward draft creation
7. **NEW**: All responses reference previously provided information by name

This creates a natural, context-aware conversation that feels empathetic and purposeful, even without a real LLM API key.
