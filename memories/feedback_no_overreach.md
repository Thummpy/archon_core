---
name: no-overreach-on-implementation
description: Do NOT execute implementation steps the user didn't ask for — especially bulk changes to config/workflows. Ask first.
type: feedback
originSessionId: da27e23b-36e8-4760-954c-a67532905a25
---
When the user asks to "encode knowledge" or "set a rule," do the minimal thing asked. Do NOT extrapolate to bulk modifications of existing files.
**Why:** User explicitly corrected after all 11 default workflows were copied and patched without being asked. This created a mess and mirrors the overreach behavior they hate in Opus 4.7 and Sonnet 4.6.
**How to apply:** When the user says "set X as a global preference," save the preference. Do NOT apply it to every existing file unless explicitly told to. Always ask before making bulk changes. The cost of asking is low; the cost of an unwanted bulk edit is high.
