The 4-File Second Brain
Claude remembers everything. One afternoon to set up.

The magic isn&#39;t in any single file. It&#39;s that the four reference each other. Claude pulls the right one at the
right time without being told.

The Problem
Claude forgets everything between sessions because it has no persistent state. Every session starts from zero.
You re-explain context. It makes mistakes it already made. You correct it again.
This isn&#39;t a Claude problem. It&#39;s a missing infrastructure problem. Four files fix it.

The 4-File System

File 1 MEMORY.md
The Index -- Current state of everything
• Claude reads this at the start of every session before doing anything else
• Contains: active projects with status, active clients with next touchpoints, open loops, decisions that affect
how you work
• Keep it under 300 lines. This is the map, not the territory.
• When something changes, update MEMORY.md first. It&#39;s always the source of truth for current state.

File 2 AGENTS.md
The Rules -- How Claude should behave in every session
• Session start protocol -- what Claude reads and in what order, before touching anything
• Memory routing rules -- exactly where to write client updates, project notes, daily logs, and corrections
• Hard rules -- things Claude must never do (credentials, git safety, PII)
• Platform formatting -- different rules for Slack, email, client docs, code
• LEARNED section -- every correction you make becomes a permanent rule

File 3 memory/daily/YYYY-MM-DD.md
The History -- Append-only log of what happened
• Claude appends to this automatically throughout the session -- tasks done, decisions made, blockers hit
• Append-only. Never edits past entries. You can always reconstruct what happened.
• Format: [HH:MM] [DONE/DECIDED/BLOCKED/NOTE] Description
• At session end, Claude writes a one-paragraph summary: what got done, decisions, open loops,

tomorrow&#39;s first task
• Review weekly. Archive entries older than 30 days to keep files lean.

File 4 memory/projects/&lt;name&gt;.md
The Depth -- One file per client or project
• Claude reads this file when you mention the client or project by name
• Contains: contacts, current state, decisions log, architecture/structure, history, open loops
• Only confirmed facts. No speculation. When a decision reverses, note the reversal -- don&#39;t delete.
• Switch clients, Claude reads that one file, knows everything. Full context in 30 seconds.
• This is where you put what you&#39;d otherwise spend 10 minutes re-explaining.

How They Reference Each Other
This is the part that makes it feel like a second brain instead of four disconnected files.
File References When
MEMORY.md AGENTS.md, projects/ Session start. Claude reads index first, then

follows links to what matters.

AGENTS.md daily/, projects/ Rules tell Claude where to write. Routing rules

point to the other files.

daily/YYYY-MM-DD.md MEMORY.md (open loops) Blockers and open loops get flagged into
MEMORY.md so they&#39;re visible next session.

projects/&lt;name&gt;.md MEMORY.md (status),

daily/

Project decisions log to the daily. Status
changes update MEMORY.md.

Setup -- TUI Prompt
Paste this into Claude Code. It creates the full folder structure and all four files in your project directory.

Set up my Claude second-brain file system.
Create this folder structure in the current directory:
MEMORY.md -- current state index
AGENTS.md -- operating manual and routing rules
memory/
daily/ -- append-only daily logs (one file per day)
projects/ -- one file per client or project
inbox.md -- staging area for unrouted notes
For each file, scaffold it with the correct sections:
MEMORY.md: Current Focus, Active Projects (table), Active Clients (table),
Decisions Log, Open Loops, Context Claude Needs, Last Updated
AGENTS.md: Session Start Protocol, Memory Routing, Daily Log Protocol,

Project File Protocol, Hard Rules, Read Smallest Useful Context,
Platform Formatting, Learned
memory/daily/YYYY-MM-DD.md: Start of Day, Log Entries, End of Day Summary
memory/projects/PROJECT-NAME.md: Overview, Contacts, Current State,
Decisions Log, Architecture/Structure, History, Context, Open Loops, Files
Use placeholder text in [brackets] throughout so I know what to fill in.
Keep MEMORY.md and AGENTS.md under 300 lines each.
Tell me when done and show me the folder structure.

File Structure
your-project/
MEMORY.md -- session start, Claude reads this first
AGENTS.md -- rules, routing, behavior
memory/
inbox.md -- staging for unrouted notes
daily/
2026-05-11.md -- today&#39;s log
2026-05-10.md -- yesterday&#39;s log
projects/
client-one.md -- full context for client one
client-two.md -- full context for client two
project-x.md -- full context for project x

Put MEMORY.md and AGENTS.md in the root of the directory Claude Code opens in. Claude reads files
relative to its working directory. If they&#39;re buried in a subfolder, Claude won&#39;t find them automatically at session
start.

One Afternoon to Set Up
1. Create the folder structure (5 min -- use the TUI prompt above)
2. Fill in MEMORY.md with your current projects and clients (20 min)
3. Add your hard rules to AGENTS.md (10 min)
4. Create one project file for your most active client (15 min)
5. Run one session. At the end, ask Claude to write the end-of-day summary. (ongoing)
By day three the daily log has enough history that Claude can brief you on yesterday without you
saying a word. By day thirty it knows your business better than most employees.