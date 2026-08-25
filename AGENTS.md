# Repository working rules

This repository is the persistent source of truth for reusable short-drama Codex skills only.

- At the start of every relevant task, re-read the invoked skill and the local project's memory, conclusions, and deliverables. Do this even when the same material appeared earlier in the conversation; local project files, not conversational recall, are the source of truth for project data.
- Treat every project as an isolated scope. Read only the active project's source files and local project directory; never inspect, search, inherit, compare, or reuse data from another project unless the user explicitly names that project as a reference.
- Do not carry characters, assets, prompts, preferences, conclusions, naming, or visual decisions across project boundaries. Reusable skill instructions are the only default cross-project input.
- Deliver content as plain text in the conversation by default. When a saved artifact is useful, prefer a `.txt` file. Do not create Markdown, Word, PDF, spreadsheet, or other formatted documents unless the user explicitly requests that format.
- If context is compacted, the task resumes after a long interruption, or the active project changes, repeat that read before continuing.
- Preserve user intent and never invent preferences or project facts.
- When a request, correction, or observed result appears to change reusable skill behavior, explain the proposed reusable change and ask whether the user wants it written into the skill. Do not edit the skill until the user confirms. A direct request to update the skill counts as confirmation.
- Store every project's scripts, facts, preferences, characters, assets, prompts, conclusions, and media only inside that local project directory. Never copy project data into this repository or any cloud sync target.
- After any skill change, validate skills, then run `scripts/sync.ps1 push` before final delivery when a configured remote is available.
- A failed push must never discard local work. Report the failure and keep the commit locally.
- Never commit project data, credentials, cookies, tokens, private source documents, generated media, or machine-specific absolute paths.
- Pull uses fast-forward only. Do not force-push, rewrite remote history, or auto-resolve conflicting concurrent edits.
- Do not create commits when no tracked content changed.
