## Step Ownership Labels — [MANUALLY] vs [WE]

Label every step in plans, todo lists and runbooks that mix human and CLI work:

- **[MANUALLY]** — the user does it by hand: dashboards, browser flows, git writes (commit/tag/push), DNS, third-party UIs, commands that must run under the user's identity.
- **[WE]** — run from the CLI in this session: read-only checks, file edits, idempotent commands. The user stays in the loop and can intervene.

Never use **[USER]** or **[ME]** — they imply hand-off, not collaboration.

