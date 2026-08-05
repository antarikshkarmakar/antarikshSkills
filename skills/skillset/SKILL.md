---
name: ak-skillset
description: Skill triage, observation intake, deep analysis (11 thinking lenses), XML specs, multi-agent review synthesis, and context-based suggestions.
trigger: /ak-skillset
---

# /ak-skillset -- Skill Triage, Authoring & Advisory Manager

This command coordinates the authoring, modification, validation, and contextual suggestion of agent skills within the `antarikshSkills` framework.

---

## 1. Observation Intake
Before creating or editing any instructions, read `memory/skill-observations.md` if it exists. Read only the active file by default; do not load `memory/skill-observations.archive.md` unless the user asks for older history. Pull in relevant `OPEN` observations as requirements, especially entries matching the target skill, "All skills", portability, dependencies, context loading, public/internal safety, or over-engineering.

Do not blindly action every observation. Classify each as:
*   **Action now**: directly relevant and still valid.
*   **Defer**: valid but outside the requested scope.
*   **Decline**: obsolete, too specific, or conflicts with current framework philosophy.

Only mark an observation `ACTIONED` after the skill update is implemented and verified.

---

## 2. Skill Triage
Before creating or editing any instructions, classify the user request into one of the following classes:
*   **`USE_EXISTING`**: The request is fully covered by an existing modular skill in `skills/` (e.g. `align`, `tdd`, `diagnose`, `review`, `compact`, `handoff`). Stop and run the corresponding trigger.
*   **`IMPROVE_EXISTING`**: The request is an enhancement or edge case fix for a skill that already exists. Stage modifications directly in the target `skills/<name>/SKILL.md`.
*   **`CREATE_NEW`**: The request covers a new domain or workflow. Create a new directory and draft a new `SKILL.md` file.
*   **`COMPOSE`**: The request requires combining multiple workflows. Write a composer recipe calling other skills sequentially.

---

## 2.5 Baseline Gate — Prove the Skill Is Needed (RED)
**A skill is a behavioural claim, not a document.** It earns its place only if an agent does measurably better *with* it than *without* it. Before analysing or drafting anything, establish the baseline:

1. Pick 1-2 representative tasks the proposed skill is meant to improve.
2. Run them **without** the skill — a fresh subagent where the runner supports it (RULESET Subagent Delegation), otherwise a clean session.
3. Record **verbatim** what goes wrong: the wrong assumption, the skipped step, the unsafe default.

**A baseline can fail in two different ways, and both justify a skill:**

- **Capability failure** — the agent cannot do the task, or does it wrongly. The skill supplies missing knowledge or procedure.
- **Rigour failure** — the agent reaches a defensible answer, but without evidence, without consistent scoping, or without leaving a record the next run can build on. The skill supplies discipline.

**If the baseline neither fails nor lacks rigour — it is correct *and* well-evidenced *and* repeatable — stop. The skill is unnecessary** (Ponytail Rung 1: does it need to exist?). A skill that documents what the agent already does well costs context on every load and returns nothing. Say so and close the request.

Do not read "the baseline got the right answer" as "no skill needed". Ask the sharper question: **what did the baseline fail to do *well*?** A run that reasons its way to a correct conclusion, with no reproduction, no severity classification, and nothing written down for next time, has failed on rigour even though its answer was right.

Whichever kind of failure you found, name it now — it fixes what the GREEN check in 2.6 is allowed to claim. A skill justified on rigour must be measured on rigour; do not later defend it as a detection improvement it never demonstrated.

The recorded failures become the skill's requirements and its trigger keywords. You are no longer guessing what the skill should say — the baseline told you.

## 2.6 Verification Gate — Prove the Skill Works (GREEN)
After drafting (step 4) and before shipping, re-run the **same** baseline tasks **with** the skill:

- **Gate on behavioural delta**, not on how the text reads. The with-skill runs must not reproduce the baseline failures — **of the kind you named in 2.5**. A capability-justified skill must fix wrong answers; a rigour-justified skill must produce the evidence, scoping, or record the baseline lacked. A skill that reads well and changes nothing has failed.
- **If you built a known-positive case to test one specific rule, verify the case actually requires that rule** before trusting the result. State why the planted problem cannot be found without the rule, then check that claim — if a plain reading of the changed lines reveals it, the case is testing something else and the run cannot vouch for that rule. Re-scope what you claim, or rebuild the case.
- **Check triggering separately from content**: does the description fire on realistic phrasings, and stay quiet on near-misses that belong to a different skill? Over-triggering is a defect — it hijacks unrelated work.
- If the failures persist, fix the skill against **what you observed**, not what you assume the agent misread. Re-run.

Record the before/after in the daily log so the next revision has a baseline to beat.

---

## 3. Deep Analysis Phase (11 Thinking Lenses)
Before generating or improving a skill, evaluate its utility through the following 11 thinking lenses:
1.  **Core Goal**: What exact problem does this skill solve, and what is the target business value?
2.  **User Persona**: Who is using it (e.g., developers, DevOps engineers, QA)? Adjust technical depth accordingly.
3.  **Prerequisites**: What system tools, packages, or settings must be active (e.g. Git, Sentry CLI, Trivy)?
4.  **Context Bounds**: What files, configurations, or directories in the project filesystem does this skill modify?
5.  **Edge Cases**: What could fail during execution, and how does the skill instruct recovery?
6.  **Platform Portability**: Are commands structured to run on both Windows (PowerShell) and Linux/macOS (Bash)?
7.  **Token Cache Efficiency**: How does this skill optimize prompts to avoid cache misses or context swelling?
8.  **Error Handling**: Does it instruct the agent to capture, print, and handle errors gracefully?
9.  **Security & Secrets**: Does the skill explicitly forbid hardcoding credentials, tokens, or PII?
10. **Verification Plan**: How does the user verify that the skill successfully achieved its outcome?
11. **Evolution Path**: How will the skill grow or compose with other skills in the future?

---

## 4. Specification-to-Generation Flow (XML Spec)
Do not write markdown skill steps directly from analysis. Write a structured XML specification first:
```xml
<skill_spec>
  <name>[skill-slug]</name>
  <trigger>/ak-[command]</trigger>
  <prerequisites>[required binaries/configs]</prerequisites>
  <context_bounds>[targeted files]</context_bounds>
  <steps>
    <step num="1">
      <action>[imperative goal]</action>
      <verification>[verifiable check command/output]</verification>
    </step>
  </steps>
  <security>[scrubbing/secrets rules]</security>
</skill_spec>
```
Once the spec is complete and verified, generate/update `SKILL.md` from it.

**Never fill a section you cannot ground — omit it.** An empty `<security>` block written because the template has one, a `<prerequisites>` list invented to look thorough, or a step whose `<verification>` is "check it works" are all worse than absent: they read as decided when nothing was decided, and the next author trusts them. If the baseline (step 2.5) produced no evidence for a section, leave it out. Sections are earned by evidence, not by the template's shape (RULESET Phil II, plan proportionality).

---

## 5. Multi-Agent Synthesis (Review Duel)
Simulate a review duel among 4 roles to evaluate the compiled skill file before pushing:
*   **Design Reviewer**: Assures compliance with the Ponytail lazy developer ladder (Philosophy I) and Karpathy simplicity (Philosophy II).
*   **Usability Reviewer**: Verifies steps are highly practical, unambiguous, and easy to copy/run.
*   **Evolution Reviewer**: Ensures the skill doesn't duplicate existing logic and scales well.
*   **Script Reviewer**: Validates bash and powershell commands for syntax, platform compatibility, and ShellCheck compliance.

---

## 6. Public/Internal Safety Sweep
Before making a skill public or plugin-ready, scan the changed instructions, examples, templates, and README text for client names, project names, proprietary URLs, internal terms, credentials, personal data, traceable examples, and tool paths that only exist on one machine. If the content is reusable after redaction, make it public-safe. If not, keep it internal and say why.

---

## 7. Context Skill Advisor
Suggest relevant skills from session, project, and personal context. Adjust suggestions based on the user's preferred proactivity level:
*   **Silent**: Only suggest skills when explicitly asked (e.g., when the user runs `/ak-skillset`).
*   **Hint**: Print a tiny 1-line suggestion footer when starting a session or finishing a code change (e.g., *"Tip: Run /ak-ci-check to test line endings before committing"*).
*   **Active**: Proactively recommend skills during alignment, coding, or debugging if the open files suggest a mismatch (e.g., open docker configs will trigger a recommendation to use `/ak-devops`).
