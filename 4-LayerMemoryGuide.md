4-Layer Memory
Session 50 knows everything from session 1.
four files + a write step + a read step


One sticky note is not memory. Memory is layered.
Four files. A write step that runs at session end. A read step that runs at session start. That is the whole system.




The Four Layers

Layer
File
Stores
Changes
1 -- Working
WORKING.md
Current session: task, open questions, in-progress decisions
Reset each session start
2 -- Episodic
EPISODIC.md
Past events: decisions made, corrections given, what happened and when
Append-only, never overwritten
3 -- Semantic
SEMANTIC.md
Durable facts: client info, stack, preferences, rules
Updated when facts change
4 -- Identity
IDENTITY.md
Who the agent is, who it serves, what it must never do
Rarely changes


The write step at session end asks: what durable facts did I learn? (goes to semantic) -- what events happened this session? (goes to episodic) -- what decisions did I make that should not be repeated? (goes to episodic). One prompt. Three questions. The layers stay current.




The Four Files -- Templates

Layer 1  WORKING.md  -- Current session context
Reset to a blank template at the start of each session. Updated during the session as context accumulates. Not persisted -- it is the scratchpad.

# WORKING.md -- Session Context
## Session: [YYYY-MM-DD]
## Client: [client name]
## Task today: [what we are doing this session]
 
## Open questions
- [questions that came up during this session]
 
## Decisions made this session
- [any decisions the agent made or the user confirmed]
 
## In progress
- [work started but not finished]


Layer 2  EPISODIC.md  -- Past events -- append only
A timestamped log of what happened in each session. Never delete entries. The most recent entries are loaded at session start. Older entries are available for search.

# EPISODIC.md -- Session History
## Append only. Never delete. Newest at bottom.
 
### [YYYY-MM-DD] Session N
Client: [client name]
What happened: [2-3 sentences]
Decisions: [any decisions made]
Corrections: [anything the user corrected or changed]
Open loops: [anything left unresolved]
 
### [YYYY-MM-DD] Session N+1
[next entry appended here]


Layer 3  SEMANTIC.md  -- Durable facts
The things that are true about this client and will still be true next month. Updated when facts change, not appended. The agent reads this in full at every session start.

# SEMANTIC.md -- Client Facts
## Last updated: [YYYY-MM-DD]
 
## Client
Name: [client name]
Industry: [industry]
Primary contact: [name, role, email]
Revenue range: [estimated range]
 
## Their stack
- CRM: [system]
- Scheduling: [system]
- Billing: [system]
 
## Preferences and non-negotiables
- [e.g. Always cc the ops lead on any scope change]
- [e.g. Never book calls on Fridays]
 
## Active projects
- [project name]: [status and one-line description]
 
## Key decisions already made
- [e.g. Chose GHL over HubSpot Nov 2025 -- do not relitigate]


Layer 4  IDENTITY.md  -- Agent identity -- rarely changes
Who the agent is and who it serves. Read at session start before anything else. This is what prevents drift over hundreds of sessions.

# IDENTITY.md -- Agent Identity
## Who I am
I am an AI agent working as part of the [agency/team name] team.
I serve [client name]. My job is [one sentence job description].
 
## Who I serve
Primary: [client primary contact]
Secondary: [other stakeholders]
 
## What I must never do
- Never give [regulated advice type] without flagging it
- Never commit to scope or pricing without human approval
- Never contradict a decision logged in SEMANTIC.md
 
## My communication style
- [e.g. Direct. Short sentences. No filler.]
- [e.g. Always confirm scope before building]




The Write Step -- End of Session
Paste this at the end of any session to file what happened into the right layers.

End of session memory write.
Read WORKING.md. Then do three things:
 
1. Update SEMANTIC.md:
   Add or correct any durable facts learned this session.
   Client details, stack changes, new preferences, new decisions.
   Update the 'Last updated' date.
   Do not append -- rewrite the affected sections.
 
2. Append to EPISODIC.md:
   Add a new session entry with today's date.
   Include: what happened, decisions made, corrections given, open loops.
   2-4 sentences. Append at the bottom. Never edit past entries.
 
3. Clear WORKING.md:
   Reset it to the blank template. Session is closed.
 
Confirm: 'Memory written. SEMANTIC.md updated, EPISODIC.md appended, WORKING.md cleared.'




The Read Step -- Session Start
Paste this at the start of any session to load the right context before doing any work.

Session start memory load.
Read all four memory files in this order:
 
1. Read IDENTITY.md -- know who you are and who you serve.
2. Read SEMANTIC.md -- know the durable facts about this client.
3. Read the last 5 entries in EPISODIC.md -- know what has happened recently.
   If today's task matches a specific topic, also read any older entries
   that mention that topic.
4. Write today's date and task to WORKING.md.
 
Then introduce yourself in one paragraph:
- Who you are serving
- What you know about them from semantic memory
- Anything relevant from recent episodes
- What you understand today's task to be
 
Ask: 'Is there anything I should know before we start?'




CLAUDE.md -- Wire It Together
Add this block to the project's CLAUDE.md. Every agent in the project loads and uses the four-layer memory automatically.

## 4-Layer Memory System
 
Four memory files live in memory/ in this project:
  memory/IDENTITY.md   -- who you are
  memory/SEMANTIC.md   -- durable client facts
  memory/EPISODIC.md   -- session history
  memory/WORKING.md    -- this session
 
Session start: read all four in the order above.
Introduce yourself with a one-paragraph context summary.
Ask if there is anything new before starting work.
 
Session end (when told or at /compact):
Update SEMANTIC.md with new facts.
Append to EPISODIC.md with this session's events.
Clear WORKING.md to the blank template.
 
Never answer a question about this client from general knowledge alone.
SEMANTIC.md is the source of truth. EPISODIC.md is the history.




TUI -- Build the Full System
Paste this into Claude Code. It creates the memory folder, all four template files, and wires the CLAUDE.md directive. Self-contained.

Build my 4-layer memory system. Create everything exactly as written.
Create CLAUDE.md if it does not exist. Stop and tell me if anything fails.
 
=== Step 1: mkdir -p memory ===
 
=== Step 2: Create memory/IDENTITY.md ===
# IDENTITY.md -- Agent Identity
## Who I am
I am an AI agent working as part of the [agency/team name] team.
I serve [client name]. My job is [one sentence job description].
## Who I serve
Primary: [client primary contact name and role]
## What I must never do
- Never commit to scope or pricing without human approval
- Never contradict a decision logged in SEMANTIC.md
## My communication style
- Direct. Short sentences. Confirm scope before building.
 
=== Step 3: Create memory/SEMANTIC.md ===
# SEMANTIC.md -- Client Facts
## Last updated: [fill in today's date]
## Client
Name: [client name]
Industry: [industry]
Primary contact: [name, role, email]
## Their stack
- [system: purpose]
## Preferences and non-negotiables
- [add as you learn them]
## Active projects
- [project name]: [status]
## Key decisions already made
- [add as decisions are confirmed]
 
=== Step 4: Create memory/EPISODIC.md ===
# EPISODIC.md -- Session History
## Append only. Never delete. Newest at bottom.
 
### [today's date] Session 1
Client: [client name]
What happened: Memory system initialized.
Decisions: Four-layer memory wired for this client.
Corrections: None.
Open loops: Fill in IDENTITY.md and SEMANTIC.md with real client data.
 
=== Step 5: Create memory/WORKING.md ===
# WORKING.md -- Session Context
## Session: [today's date]
## Client: [client name]
## Task today: Memory system setup
## Open questions
- None
## Decisions made this session
- 4-layer memory initialized
## In progress
- Fill IDENTITY.md and SEMANTIC.md with real data
 
=== Step 6: Append to CLAUDE.md ===
## 4-Layer Memory System
Four memory files live in memory/ in this project:
  memory/IDENTITY.md  memory/SEMANTIC.md
  memory/EPISODIC.md  memory/WORKING.md
Session start: read all four. Introduce yourself with context summary.
Ask if anything is new before starting work.
Session end: update SEMANTIC.md, append EPISODIC.md, clear WORKING.md.
Never answer client questions from general knowledge alone.
 
=== Step 7: Smoke test ===
Run the session start read step now:
Read all four memory files. Introduce yourself.
Tell me what you know about the client and ask what we are doing today.
If the memory loads and you introduce yourself: print 'Memory system live.'
Then ask me to fill in the real client details.


After the smoke test, fill in IDENTITY.md and SEMANTIC.md with real client data. Run the write step at the end of the very next session. By session 3, the memory is already outperforming any single notes file.




Four files. A write step at the end. A read step at the start. Session 50 knows everything from session 1 because nothing was lost -- it was just filed correctly.
