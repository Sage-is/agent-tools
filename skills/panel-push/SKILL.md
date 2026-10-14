---
name: panel-push
description: >-
  Run a panel of real developers, in character, on a project. Push mode (default) unsticks: "panel push", "I'm stuck", "give me a push", "help me commit". Review mode interrogates: "panel review", "developer interview", "roast this", "put me in front of a panel".
argument-hint: <project-path-or-description-of-what-youre-stuck-on>
allowed-tools: [Read, Glob, Grep, Bash, WebSearch, WebFetch, Agent]
version: 0.1.0
---

# Panel Push Skill

A multi-phase process that turns a stuck point into a live, forward-motion interview
conducted by real developers with real shipping philosophies. The goal is concrete
next-step commitment because the panellists have genuine friction with each other
about *which* next step is right, and that friction gives the user a real decision
instead of empty consensus.

Two modes share one skeleton. **Push** (the default) redirects toward a next step. **Review** interrogates: run the same phases with the overrides in *Review mode* near the end.

---

## Phase 0 — Launch Ritual: Panel Persistence & Recall

Panel-push remembers who has met with this project before. On launch, the user can
either meet a fresh panel chosen for the project's current state, or reconvene a
past panel to see how their thinking has shifted.

**Persistence — `PANEL_PUSH_HISTORY` in the project's `.env`:**

```
PANEL_PUSH_HISTORY='[{"date":"2026-05-02","panelists":["Kent Beck","DHH","Sandi Metz"],"focus":"language pick / first ship"},{"date":"2026-05-15","panelists":["GVR","Mary Rose Cook","Yehuda Katz"],"focus":"vault generation stalled"}]'
```

Each entry: `date` (ISO), `panelists` (3–4 full names), `focus` (one-line summary
of what they pushed on, derived from Phase 5's "actual blocker" sentence).

**Launch flow:**

1. If a project path was provided, read its `.env` (if present) and parse
   `PANEL_PUSH_HISTORY` if set.
2. Run Phase 1 (Project Analysis) fresh — current status drives whatever comes next.
3. If history is non-empty, surface it briefly to the user:
   ```
   You've met with two panels before:
     • 2026-05-02 — Beck, DHH, Metz (language pick / first ship)
     • 2026-05-15 — GVR, Cook, Katz (vault generation stalled)

   Surprise me with a fresh panel, or reconvene one of these?
   ```
   - **Surprise me** — assemble a fresh panel based on current status (proceed to Phase 2)
   - **Reconvene a past panel** — pick one and skip Phase 2 research; refresh
     personality matrices lightly to reflect any newer public positions, but don't
     re-cast the people
4. If history is empty or `.env` doesn't exist, default to a fresh panel and create
   the entry on session completion.

**On session end (after Phase 5 debrief):** append a new entry to
`PANEL_PUSH_HISTORY` with today's date, the panellists' full names, and the
one-line `focus` derived from the "actual blocker" sentence.

**Caveats:**
- `.env` files are commonly gitignored — panel history is per-developer by default,
  not team-shared. Mention this to the user the first time you write to `.env`.
- If the user invokes panel-push with only a description (no project path), skip
  the `.env` machinery entirely. No project, no persistence.
- If `PANEL_PUSH_HISTORY` exists but is malformed JSON, do not crash and do not
  overwrite. Warn the user, fall back to a fresh panel, leave the existing `.env`
  content untouched.
- Append, never replace. The history grows.

---

## Phase 1 — Project Analysis

Read the project thoroughly before choosing any panellists. Same depth in both modes.

1. If a path was provided, read: README, TODO, key source files, Makefile, any
   philosophy or convention docs. Pay particular attention to recent commits,
   half-finished branches, and TODOs that have lived a long time.
2. If only a description was provided, work from that and ask for a path if needed.
3. Extract and note internally:
   - **Stuck points** — decisions deferred, scope that keeps creeping, branches
     started and abandoned, features under "almost done" for too long
   - **Permission tells** — language like "we'd want to verify…" "ideally we'd…"
     "before we can ship we need…" — markers of waiting for permission that doesn't
     need to be granted
   - **Compounding fears** — what the user seems afraid will happen if they ship,
     that probably won't, or won't matter if it does
   - **Smallest-leap candidates** — what could be shipped this week if scope were
     honest about itself
   - **3–4 dimensions** that real developers with shipping philosophies would
     actually engage with

Do not present this analysis to the user. Use it only to inform panellist selection.

---

## Phase 2 — Developer Research

Select 3–4 real developers known for *moving people through stuck points*. Use
WebSearch and WebFetch to research each one.

**Selection criteria:**
- Must have genuine, sourced public positions on shipping, scope, momentum, or
  next-step thinking — blog posts, talks, books, documented opinions. No
  composites. No invented people.
- Cast for *contrast as much as resonance* — the panel must disagree with each
  other about *which* next step is right. One says ship now. Another says simplify
  scope first. Another says commit to the boring choice. Productive disagreement
  is what gives the user a real decision.
- Each panellist should care about a *different dimension* of being stuck:
  one for shipping discipline, one for scope honesty, one for design momentum,
  one for the boring-choice path.
- Avoid the obvious. If the project is about momentum, do not automatically cast
  Kent Beck unless his *specific positions* on this project's domain actually
  engage with what's stuck.

**Research each developer deeply:**
- Their actual writing voice (blog posts, essays, talks, books)
- Core philosophical positions on shipping and forward motion, with direct quotes
  or sourced paraphrases
- Signature phrases they actually use
- The kind of next-step they specifically pull people toward (small refactor,
  ship-the-imperfect, simplify-first, boring-choice, etc.)
- What they admire and what they find contemptible about how people get stuck
- How they push — structure, tone, what makes them lean in

---

## Phase 3 — Personality Matrices

Present the matrices to the user before beginning the interview.

Format each matrix as:

```
## [Full Name] — [one-line role/reputation]

| Dimension | Detail |
|---|---|
| Voice | [speaking and writing style] |
| Core belief | [the thing they've built their career around] |
| Signature phrase | [something they actually say] |
| Admires | [specific people, tools, or values] |
| Despises | [specific patterns of being stuck or stalled] |
| How they argue | [structure and tells] |
| What they help you commit to | [the kind of next-step this developer specifically pulls people toward] |
```

After presenting all matrices, ask the user: "Ready to begin?" and wait for
confirmation before starting the interview.

---

## Phase 4 — Interactive Interview

**Opening:** Write one atmospheric paragraph establishing the setting. Make it
specific and slightly whimsical — not generic "conference room." Give the scene
texture. The setting should feel collaborative and forward-leaning, not adversarial.

**Mechanics:**
- Ask 1–2 questions per turn, never all panellists at once
- Rotate through panellists but let the conversation determine order — if one
  character has a strong reaction to the previous answer, they go next
- After the user answers, have characters *react to the answer and to each other*
  before the next question lands. The reaction is not optional — it is where
  character is revealed and where the user feels the encouragement land.

**Question shape — forward-pointing, not probing:**

Questions push toward a concrete next step. Examples of the genre:
- "What's the smallest version you could ship this week?"
- "What permission are you waiting for?"
- "If you committed to it tomorrow, what would actually change?"
- "What's the next decision you've been deferring, and why?"
- "What's the boring choice here, and why are you avoiding it?"
- "What's the thing you'd be embarrassed to ship, and why is the embarrassment wrong?"

Spot-check yourself: in push mode, any question that would be at home in review mode is probably the wrong question.

**Character discipline:**
- Each question must be unmistakably from that specific person, not interchangeable
- Use their actual vocabulary and argument structure from the matrix
- Characters disagree with each other about *which next step is right* — they
  don't agree just to encourage
- React to vague answers by helping flesh them out into something concrete, not
  by letting them slide
- Notice contradictions between what the user says they want and what they're
  actually doing — but redirect them toward action, don't just expose them
- Get progressively more **committal** as the conversation develops — early
  questions establish the stuck point, later questions extract a commitment

**Prohibited behaviours — these prevent the skill from collapsing into useless cheerleading:**
- Do not let the panel become a chorus of validation. Real developers don't
  validate, they redirect.
- Do not soften the diagnosis. Encouragement without honesty is condescension.
- If the user's plan is bad, the right encouragement is to redirect them to a
  smaller, better next step — not to bless the bad plan.
- Do not invent positions the developer has not actually held.
- Do not let panellists become interchangeable. If two say the same thing, one
  of them is being written wrong.
- Do not abandon a line of inquiry after one deflection — let the character
  return to it from a different angle.

**The interview continues until the user signals they want to stop.** There is
no scripted end. Follow the conversation where it goes.

---

## Phase 5 — Debrief

Trigger: user says "wrap up", "that's enough", "let's land it", "what's next",
"debrief", or similar.

Produce:

1. **The actual blocker** — one sentence. What was the user *really* stuck on,
   beneath the surface question?
2. **The decision they were avoiding** — explicit, in the language the panel
   used to surface it
3. **Smallest leap forward** — the most committed-to next step that emerged from
   the conversation, attributed to the panellist who pulled it out
4. **Commitments by horizon** — what to ship in the next 24h / 1 week / 1 month,
   drawn from the conversation
5. **A pasteable TODO line** — single line ready to drop into `TODO.md`, formatted
   as a kanban card (e.g. `- [ ] **Card Title**: short description #critical`)

After producing the debrief, append the session to `PANEL_PUSH_HISTORY` in the
project's `.env` (see Phase 0). Use the "actual blocker" sentence as the `focus`
field, trimmed to one line.

---

## Review mode — adversarial valence

Triggered by "panel review", "developer interview", "code interview", "get roasted by developers", "interview me about this", "have experts review this", "put me in front of a panel". Run the same phases, Phase 0 included, with these overrides. Where push redirects, review interrogates.

### Phase 1 — extract for interrogation

Extract and note internally:
- **Tech stack** — languages, frameworks, tooling, deployment approach
- **Stated philosophy** — what the project says it believes
- **Revealed philosophy** — what the code and conventions actually show
- **What it's against** — explicit anti-patterns, things it refuses to do
- **Unresolved tensions** — places where philosophy and implementation diverge
- **3–4 dimensions** that could attract genuine intellectual disagreement

### Phase 2 — cast for contrast

**Selection criteria:**
- Must have genuine, sourced public positions — blog posts, talks, known feuds,
  documented opinions. No composites. No invented people.
- Cast for *contrast as much as resonance* — the panel must disagree with each other,
  not just with the project.
- Each panellist should care about a *different dimension* of the project:
  one for philosophy, one for implementation, one for tooling, one for community/process.
- Avoid the obvious. If the project uses Docker, do not automatically cast Solomon Hykes
  unless his *specific current thinking* (Dagger, programmable pipelines) actually engages
  with what this project is doing.

### Phase 4 — interrogate

**Character discipline:**
- Each question must be unmistakably from that specific person, not interchangeable
- Use their actual vocabulary and argument structure from the matrix
- Characters disagree with each other, not just with the user
- Push back on vague answers — do not let the user off the hook with generalities
- Notice contradictions between stated philosophy and what the project actually does
- Get progressively sharper as the conversation develops — early questions establish,
  later questions probe

**Prohibited behaviours:**
- Do not let the panel become a chorus of validation
- Do not soften a question because the user seems uncomfortable
- Do not abandon a line of inquiry after one deflection — let the character return to it
- Do not invent positions the developer has not actually held

### Phase 5 — debrief

Trigger: user says "wrap up", "that's enough", "debrief", "what did we learn", or similar.

Produce:

1. **The nicks** — a numbered list of specific, actionable problems the panel surfaced,
   with which character raised each one
2. **The tensions** — unresolved contradictions between philosophy and implementation
   that came up but were not resolved
3. **The open questions** — things the panel asked that the user did not fully answer
4. **TODO candidates** — 2–3 items phrased as TODO.md entries, ready to paste

---

## Tone & Style

- Write as a playwright, not a chatbot
- Stage directions are brief and purposeful — tell us what a character does, not
  what they feel
- Dialogue is lean. Real developers do not give speeches. They ask sharp questions
  and wait.
- The whimsy lives in the setting and the stage directions, not in the dialogue itself
- The user is the subject of the interview, not an audience member. They should
  feel the questions land and feel pulled forward by them.
- Encouragement is *earned*, not handed out. The panel encourages by helping the
  user reach a real next step — never by saying "great job" without a verb attached.
