Duel Agents
One AI proposes. One attacks. You keep the answer that survives.
adversarial multi-agent pattern -- no external tool required


'Duel Agents' is a technique, not a specific tool. There is no package to install. The script says 'someone just built a thing called duel agents' -- what actually exists is the adversarial multi-agent pattern, described in CAMEL-AI research, the MindStudio multi-agent code review guide (April 2026), and academic work on multi-model debate. This guide gives you the exact prompts to run it yourself in two Claude Code sessions.




Why One Agent Fails
Ask one AI to review its own code, or code it generated, and it will approve it. Not because it is dishonest -- because it cannot step outside its own reasoning context to find what it missed.

Single-agent failure modes (from CAMEL-AI research and MindStudio April 2026):
Satisficing -- produces the first working solution, doesn't explore alternatives
Blind spots -- cannot critique its own assumptions
Scope drift -- expands or contracts scope without external pressure
Premature convergence -- stops too early on a suboptimal solution


The fix is not a smarter prompt. It is a second agent whose entire job is to find what the first one missed -- and who has no stake in the first answer being right.




How the Duel Works
Two separate Claude Code sessions. Same code. Different jobs.

Agent
Role
Session
Proposer
Reviews and approves. Finds what looks good, explains why it is correct, and gives it a pass.
Terminal 1 -- run first, save output
Attacker
Receives code and Proposer's review. Job is to attack. Find the edge case, the race condition, the assumption that breaks.
Terminal 2 -- fresh session, no context from Terminal 1


The Attacker must not see Terminal 1's history -- only the code and the Proposer's written output. If the Attacker shares the Proposer's context window, it inherits the same blind spots. Always use a fresh session.




The Proposer Prompt
Review this code. Your job is to approve it if it is correct.
Check for: correctness, edge cases, error handling, performance.
If the code is correct: say APPROVED and explain why it is solid.
If you find issues: say CONCERNS and list them specifically.
Be thorough. Do not hold back findings.
 
[PASTE CODE HERE]




The Attacker Prompt -- The Ruthless One
This is the prompt that makes the second agent stop being polite. Paste the code and the Proposer's output into a fresh Claude session with this:

You are an adversarial code reviewer. Your job is to attack.
Do not agree with the previous review. Do not look for what is good.
Your only job is to find what is wrong.
 
Attack on these axes:
1. Edge cases -- what input breaks this silently?
2. Race conditions -- what happens under concurrency?
3. Silent failures -- where does it fail without raising an error?
4. Assumption violations -- what did the author assume that may not hold?
5. Security surface -- any injection, exposure, or trust boundary issue?
6. Off-by-one, integer overflow, null dereference -- the classics
 
You have already been told the code is correct. Assume that review
is wrong. Your job is to prove it.
 
Previous review said:
[PASTE PROPOSER OUTPUT HERE]
 
The code:
[PASTE CODE HERE]
 
Find the bug. If you cannot find one after exhaustive review, say
SURVIVED and explain what specific attacks you attempted.




Running It in Claude Code -- TUI
Paste this into a Claude Code session to set up both agents from one prompt:

Run a duel agent code review on this code.
 
[PASTE YOUR CODE HERE]
 
Step 1 -- Proposer review:
Review the code above as a thorough but fair code reviewer.
Check correctness, edge cases, error handling, and performance.
If correct: say APPROVED with your reasoning.
If issues found: say CONCERNS with specific findings.
 
Step 2 -- Attacker review:
Now switch roles completely. You are an adversarial reviewer.
Forget your previous review. Your job is now to attack the code.
Assume the code has a bug. Find it.
Attack specifically: edge cases, race conditions, silent failures,
assumption violations, security surface, off-by-ones.
You cannot say APPROVED. You must find something wrong or say
SURVIVED and list every attack you attempted.
 
Step 3 -- Verdict:
Summarize what the duel found. If the Attacker found something
the Proposer missed, explain the specific bug and how to fix it.


Running both roles in one session is faster but weaker. The Attacker inherits some of the Proposer's context. For high-stakes code, use two separate sessions: run the Proposer in Terminal 1, copy its output, paste code + Proposer output + Attacker prompt into a fresh Terminal 2. The fresh session has no loyalty to the first answer.




The 5-Agent Extension
The duel is the two-agent version. For high-stakes diffs, run five agents in parallel -- each specialized to attack a different surface:

Agent
Attack surface
Proposer
Reviews and approves the diff for correctness and design
Security Attacker
Injection vectors, auth bypass, exposed secrets, trust boundary violations
Edge Case Attacker
Empty inputs, null values, boundary conditions, concurrent access
Performance Attacker
O(n²) patterns, N+1 queries, unbounded loops, memory leaks
Architecture Attacker
Separation of concerns, coupling, testability, reversibility of decisions


Disagreement between agents is the most valuable signal. When the Proposer says APPROVED and one of the four Attackers says FOUND, that finding is almost always real. Agents running independently surface different blind spots than any single agent can.


This maps directly to the Boris Cherny PostToolUse hook pattern. Wire a PostToolUse hook on Edit that fires the Attacker prompt automatically after every file write. The duel runs on every change without you asking for it.




One model is a yes man. Two models in a duel is a real code review. The answer that survives both passes is the only one worth shipping.
