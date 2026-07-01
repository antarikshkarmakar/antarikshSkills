---
name: ak-doc
description: Technical Documentation — generates structural summaries, interface boundaries, and diagrams using tables and Mermaid diagrams
trigger: /ak-doc
---

# /ak-doc — Direct Technical Documentation

Use this skill when asked to write developer documentation, interface specifications, or module design documents.

## Step 1 — Read Public Contracts
- Scan public directories, header files, config files, and `INTERFACES.md` to identify public function signatures, REST endpoints, message schemas, or database tables.

## Step 2 — Format and Styling
When presenting documentation, enforce these aesthetic and readability guidelines:
- **Clean Tables**: Document all schemas, endpoint lists, query parameters, or file configurations in Markdown tables. Define columns clearly.
- **Alert Callouts**: Emphasize important caveats, constraints, or security notes using GitHub-style alerts (e.g. `> [!IMPORTANT]`, `> [!WARNING]`).
- **Mermaid Diagrams**: Create structural representations (e.g., flowcharts, sequence diagrams, class models) using Mermaid code blocks. Ensure syntax correctness:
  - Put quotes around labels containing brackets or parentheses.
  - Avoid HTML tags in node labels.

## Step 3 — Document Insertion
- Inject or update the target document (e.g. `docs/`, `GLOSSARY.md`, inline docstrings, or target `.md` files) with the structured content. Verify all file references utilize clickable markdown links.
