---
name: poka-yoke
description: Mistake-proofing audit. Scans code for places where small structural changes (branded types, exhaustive switches, parse-at-boundary, pre-commit gates) could make a class of bug impossible, and proposes the cheapest device that prevents recurrence. Use when the user says "poka-yoke", "mistake-proof this", "fool-proof this", "add guardrails", "prevent this class of bug", "make it impossible to misuse", or after a bug fix when they want to stop the next instance.
argument-hint: "optional path or scope, e.g. src/auth/ or 'the last commit'"
---

# Poka-Yoke — Mistake-Proofing Audit

ポカヨケ — "inadvertent error prevention". From the Toyota Production System. When a defect happens twice, the fix is not to be more careful — it is to change the system so the defect cannot happen. First ask whether the footgun can be removed entirely. The cleanest guardrail is often subtraction.

## Workflow

1. **Confirm scope.** Whole repo, directory, file, or "the last commit". Ask if unclear.
2. **Try subtraction first.** If a risky branch, option, abstraction, or API can be removed without meaningful loss, prefer that over adding machinery.
3. **Hunt for mistake classes.** Walk the scope using the taxonomy below.
4. **Triage by leverage.** Rank by *blast radius prevented ÷ cost added*.
5. **Propose with rationale.** Name the mistake class, point to the location, state the failure mode, and propose the **cheapest** prevention: remove it, constrain it, or guard it. Ask to apply per item.
6. **Cross-link.** If the answer is mostly deletion and cleanup, suggest `muda`. If a module is fundamentally broken, suggest a deeper review.

## The Mistake-Class Taxonomy

This is the ontology that matters. Every finding should map to one of these.

Preference order:

1. Remove the source of error.
2. Make invalid states unrepresentable.
3. Add the smallest possible check or hook.

### Confusable arguments
Bare strings, numbers, or booleans passed positionally to functions where mix-up is plausible. `transfer(userId, accountId)` — what if they swap?
- **Cheap device:** remove the ambiguity first by collapsing the API or call site if possible; otherwise use branded/newtype (`type UserId = string & { __brand: 'UserId' }` in TS, `NewType('UserId', str)` in Python, `type UserId string` in Go), named parameters, or an options object.

### Non-exhaustive handling
`switch`/`match` without a default or exhaustiveness check. New enum variant added → silent skip.
- **Cheap device:** exhaustive switch helper (`assertNever(x)` in TS, `match` with wildcard panic in Rust, type-checker-enforced match in Python via `typing.assert_never`).

### Boundary trust
Unvalidated input from network, disk, env, or user trusted downstream as if it were typed. `JSON.parse` results passed around as `any`.
- **Cheap device:** parse-at-the-edge with a schema (Zod, Pydantic, serde). Validate once at the boundary; trust the parsed type internally.

### Stringly-typed state
Domain state encoded as ad-hoc strings or booleans. `status: 'pending' | 'done' | 'failed' | ...` scattered everywhere with no central definition.
- **Cheap device:** remove unused or redundant states first; otherwise use union types / discriminated unions / enums in one place. Optionally a state machine if transitions matter.

### Optional everywhere
Fields marked `?` or `| undefined` because "maybe later" or "sometimes". Every consumer pays the cost of the maybe.
- **Cheap device:** remove the optionality if the field is not meaningfully optional; otherwise tighten the type at construction, or split into two states (`DraftUser` vs `SavedUser`) so the maybe is gone after construction.

### Silent failure
`try/catch` that swallows. Default values that hide missing data. `as any` / `# type: ignore` / `@ts-expect-error` escape hatches. Empty array returned on error indistinguishable from "no results".
- **Cheap device:** throw at boundary, log loudly, remove the cast. Distinguish `[]` from `null` from `error`.

### Race & order
Code that assumes ordering it doesn't enforce. Two `await`s where the second depends on a side effect of the first that isn't awaited. Cleanup in the wrong place.
- **Cheap device:** explicit sequencing, transaction, lock, or restructure so the dependency is in the type signature.

### Configuration drift
Env vars referenced via `process.env.FOO` scattered around. Flags read from config without defaults documented. Two services with subtly different env names for the same thing.
- **Cheap device:** remove duplicate config entry points if possible; otherwise use one typed config loader with a schema, read once at startup, and throw on missing or invalid values.

### Hook gap
A class of bug that would have been caught by a pre-commit hook, CI check, or lint rule that simply isn't installed. The team relies on memory.
- **Cheap device:** remove the manual step if possible; otherwise add the hook. Even a one-line `grep -r 'console.log' src/ && exit 1` is a real Poka-Yoke device if console.log in prod has bitten the team before.

### Time & timezone
Dates passed as strings without timezone, mixed `Date` and ISO string, naive vs aware datetimes in Python.
- **Cheap device:** ban naive datetimes at the type level. One canonical representation (UTC ISO8601 string or a tz-aware type) at all boundaries.

### Floating-point money
Currency in floats, percentages multiplied before rounded, summing many small amounts.
- **Cheap device:** integer minor units (cents) or a `Decimal` type. Make the wrong type unrepresentable for money fields.

## Output Format

Group by severity. Each finding is one block. File paths must be clickable:

```
## High leverage (high blast radius prevented / low cost)

### [filename.ts:42](src/filename.ts#L42) — Confusable arguments
**Footgun:** `transfer(fromId, toId)` takes two bare strings; a caller in [api.ts:118](src/api.ts#L118) already had a swap-bug fixed last month.
**Cheapest device:** Remove the ambiguous API if possible; otherwise brand the IDs. ~10 lines, no runtime cost.
**Apply?** (yes / no / show diff)

### [config.ts:8](src/config.ts#L8) — Boundary trust
**Footgun:** `process.env.DATABASE_URL` is read in 7 places, no validation; a typo in `.env` produces an undefined that surfaces as a confusing connection error 30s later.
**Cheapest device:** Remove duplicate reads by centralizing config once at startup; validate there. ~25 lines.
**Apply?**

## Medium leverage

...

## Low leverage (mention only)

...
```

End with a one-line summary: *"3 high-leverage devices found. In 1 case the best fix is deletion. Want me to apply any?"*

## Rules & Constraints

- **The fix must be smaller than the bug it prevents.** Large refactors are not poka-yoke.
- **Subtract before you add.** If removing the footgun is viable, prefer that to adding a guardrail.
- **Source inspection over runtime inspection.** Catch mistakes at compile/lint time, not runtime.
- **Respect the language.** Tailor devices to the project's existing tooling and philosophy.
- **Identify classes, not one-offs.** Look for structural footguns, not unique mistakes.
- **No auto-applying.** The user must opt-in per item.
- **Deletion is valid when it is the smallest prevention.** If the issue is mostly dead weight, route to `muda`.
- **No defect lists.** This is structural footgun hunting, not bug-finding. Use `/review` for that.

## Companion Skills

Poka-Yoke is one of a family of Toyota/Lean concepts:

- **muda** — waste audit (the inverse: things that should be deleted, not guarded)
- **jidoka** *(not yet built)* — stop-the-line automation: hooks and CI that halt on first defect
- **kaizen** *(not yet built)* — small continuous improvement passes
- **genchi-genbutsu** *(not yet built)* — go-and-see: reproduce the bug in its environment before proposing a fix
