# AI Eulogy Chat - Natural Conversation Flow Testing Guide

## Overview
The AI chat now uses LLM-driven conversation instead of rigid questions. This provides a more natural, human-like experience.

## Key Changes
1. **Conversational Opening**: Instead of asking for specific fields, the AI invites natural sharing
2. **Dynamic Responses**: The LLM generates contextual responses based on the entire conversation
3. **Smart Information Extraction**: The ML classifier still extracts structured data from natural conversation
4. **Graceful Fallback**: If LLM fails, falls back to directed questions

## Configuration
- **With OpenAI API Key**: Set `openai_api_key` in UserDefaults to use GPT-4o-mini
- **Without API Key**: Uses MockLLMService with context-aware responses

## Example Conversation Flow

### Natural Flow (Desired Behavior)
```
Assistant: I'm here to help you create a meaningful and personal eulogy. This is a space 
where we can talk naturally about your loved one.

Please share whatever feels right to you - their name, who they were to you, what made 
them special, or any memories that come to mind. I'll listen and ask gentle questions 
along the way.

User: My grandmother Mary passed away last week. She was an amazing woman.
Assistant (LLM): I'm so sorry for your loss. Mary sounds like she held a very special place 
in your life. What are some of the qualities that made her so amazing to you?

User: She was so kind and patient. She loved gardening and would spend hours in her garden.

Assistant (LLM): That's beautiful - I can picture her finding peace among the flowers. 
Was there a particular memory with her in the garden that stands out to you?

User: Yes, she taught me how to plant tomatoes when I was 8. We would pick them together 
every summer.

Assistant (LLM): What a precious memory - those summer moments together. Is there anything 
about her faith or beliefs that you'd like reflected in the eulogy?

User: She was Catholic and her faith was very important to her.

Assistant (LLM): Thank you for sharing that. I have a good sense of Mary now. Would you 
like me to create a draft eulogy? I can make it warm and respectful of her Catholic faith.

[Draft generated after user confirms]
```

## Testing Checklist

- [ ] Initial greeting is warm and conversational (not asking for specific fields)
- [ ] Responses are contextual and build on previous conversation
- [ ] Questions feel natural, not like a form to fill out
- [ ] AI shows empathy and understanding
- [ ] Information is extracted correctly (name, relationship, traits, hobbies, stories)
- [ ] Conversation flows smoothly toward draft generation
- [ ] Draft incorporates all shared information appropriately
- [ ] User can request edits naturally after seeing draft

## Mock Service Testing
The MockLLMService provides intelligent responses based on conversation state:
- Early messages: Focus on getting to know the person
- After name mentioned: Ask about relationship
- After relationship: Ask about qualities/traits
- After traits: Ask about hobbies/passions
- After hobbies: Ask for stories
- After stories: Ask about beliefs

This creates a natural progression even without a real LLM API key.
