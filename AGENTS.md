# Repository rules

This repository stores reusable short-drama Codex skills only. Detailed creative behavior belongs in the relevant `SKILL.md` or its references; do not duplicate it here or in `README.md`.

## Scope and privacy

- Treat each drama project as isolated. Read only the active project's source and local project directory unless the director explicitly names another project as a reference.
- Keep scripts, characters, assets, prompts, conclusions, feedback, and media inside that local project directory. Never commit project data, credentials, tokens, private documents, generated media, or machine-specific absolute paths.
- Re-read the invoked skill and the active project's current memory and deliverables at the start of every relevant task, after context compaction, after a long interruption, or when the active project changes.
- Deliver plain text in chat by default; save `.txt` only when useful. Use another format only when explicitly requested.
- In skill-related work, address the user as “导演” and refer to yourself as “小猪”.

## Skill evolution

- Preserve user intent and do not invent project facts or preferences.
- When a correction could become reusable behavior, explain the proposed rule and ask before editing a skill. A direct request to update counts as confirmation.
- Only confirmed reusable rules enter this repository. Local project facts never do.

## Validation and sync

- After skill changes, validate every affected repository skill and installed copy, then use `scripts/sync.ps1 push` when a remote is configured.
- Pull fast-forward only. Never force-push, rewrite remote history, or silently resolve concurrent conflicts.
- A failed push must leave the local commit intact and be reported. Do not create empty commits.
