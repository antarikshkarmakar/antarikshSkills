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
