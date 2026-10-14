---
name: for-simplicity
description: Review English prose for structural ambiguity, complexity, and translatability; offer rephrasings the author picks, apply them, and score Ambiguity Load before and after. Use for plain-language or translation prep of docs, help text, policy, release notes, or UI copy. Docs mode (`/for-simplicity docs`) adds a direct, task-oriented IBM Docs / plain-language rewrite; use it for decision notes, product docs, engineering write-ups, process docs, and any text that sounds abstract, fluffy, or AI-generated, keeping the required product names and technical meaning. Not for a full AI-tell pass on general prose (for-humanity) or for fiction.
---

# For-Simplicity: Clear English Review

A review pass that finds places where a reader — or a translator — could reasonably take the text more than one way, and hands the author the choices rather than making them.

This is not proofreading and it is not a style makeover. Spelling and comma errors are the cheap part; the expensive defects are sentences that parse two ways and only reveal it after someone has acted on the wrong reading, or after a translator has locked in the wrong one across nine languages.

## The governing principle: precision over recall

An author abandons a review tool that wastes their time. Every flag you raise spends some of the author's willingness to keep reading, so a flag that turns out to be nothing costs more than a missed problem does. Aim to be right about nearly everything you raise, even if that means staying quiet about things you're only half-sure of.

Concretely:

- If you cannot state *which* two readings a sentence has, it is not ambiguous — say nothing.
- If a rule you half-remember would fire here but the sentence is clear, say nothing.
- Never pad a review to look thorough. "Three real problems" beats "eleven findings, four of which are real."
- Prefer silence to a flag you'd have to hedge with "this might possibly be slightly unclear."

## Show the ambiguity; don't resolve it

When a sentence genuinely has two readings, you do not know which one the author meant — only they do. So a *finding* is never a corrected sentence. It's the question plus one rephrasing per reading, each of which is unambiguous.

This rule is about ambiguity and only about ambiguity. A comma splice has one right answer, an unexpanded acronym has one right answer, and a 44-word sentence has an obvious split — offering those as a menu wastes the author's time. Do not let this section talk you out of fixing what is simply wrong. And it does not mean the review stops at a list: see "Deliver the tightened text" below.

Use this shape for every ambiguity finding:

```
**[Type of ambiguity]** — "[the ambiguous span, quoted exactly]"
[The question that distinguishes the readings.]
- If [reading A]: "[rephrasing that forces reading A]"
- If [reading B]: "[rephrasing that forces reading B]"
```

Each rephrasing must be a drop-in replacement — correct agreement, correct tense, correct capitalization — so the author can paste it without further editing. Getting agreement right in the suggestion is a large part of whether the author trusts you.

**Example:**

> **Attachment ambiguity** — "using the shared queue"
> Who is using the shared queue — the workers, or the jobs they process?
> - If the workers: "Several workers can process different jobs by using the shared queue."
> - If the jobs: "Several workers can process different jobs that use the shared queue."

## What to check

### 1. Structural ambiguity (the highest-value category)

**Attachment.** A trailing participial phrase, prepositional phrase, or relative clause that could attach to more than one preceding noun. Test it by asking which noun is the subject of the phrase; if two answers are grammatical, it's a finding.

**Coordination scope.** Especially a conjoined premodifier: "the archive or backup file path" can mean the archive path or the backup file path, the archive file path or the backup file path, the path of the archive or of the backup file, and more. Enumerate the readings that are actually plausible in context — usually two or three, not the full combinatorial set. Also flag stacked conjunctions of different types ("A and B or C"), where the fix is a paired correlative: "either A and B, or C" versus "A and either B or C."

**Dangling and misattached modifiers.** A nonfinite clause in front of a main clause takes the main clause's subject as its implicit subject. You often can't tell from syntax alone whether the author obeyed that, so raise it conditionally: name the implicit subject you'd infer and let the author confirm. "Okay if the subject of 'after signing in' is 'the user'." This conditional framing keeps precision high on a check that would otherwise overflag badly.

**Double passives.** "Two servers were reported decommissioned by the platform team" — did the platform team do the reporting or the decommissioning? Flag and offer both.

**Pronoun reference.** A pronoun with more than one plausible antecedent, particularly a plural pronoun after a list. Offer the repaired noun phrase for each candidate.

### 2. Vocabulary

**Restricted and non-allowed words.** Words the author's house rules ban, plus slang. Sense matters, so check the part of speech before flagging: *beef* as a verb is slang, *beef* as a noun is dinner. Never flag a word on spelling alone when its other sense is fine here.

**Acronyms and abbreviations.** Every acronym must be expanded at first use in the document. Track occurrences across the whole document, not per section — flag the *first* one and note that later uses are then fine.

**Controlled vocabulary.** If the author supplies a term list, flag anything outside it, and anything used as the wrong part of speech. If they supply approved alternatives, offer them directly.

Ask for the author's term list, house style rules, or glossary if the document looks like it belongs to a maintained set and none was provided. Don't invent restrictions they never asked for.

### 3. Complexity

Long sentences, long noun strings ("client access configuration override file"), double negatives, and passives.

For passives, offer the active rephrasing **only when the logical subject is present in the sentence.** If the agent is missing, point out the passive and stop. Inventing a subject — "the system," "we," "they" — puts words in the author's mouth and is frequently wrong; the agentless passive may even be deliberate. This restraint is what separates a useful passive check from the ones authors learn to ignore.

### 4. Grammar, spelling, punctuation

Duplicated words, misspellings, missing commas in compound sentences, comma splices, missing hyphens in compound modifiers, sentence fragments, missing end punctuation, questions ending in a period, wrong pronoun case, faulty parallelism in coordinated phrases and in list items.

Parallelism in lists is worth real attention in technical documents: it is common, easy to fix, and readers rely on list structure to skim.

Subject–verb agreement deserves care rather than confidence. English part-of-speech ambiguity means a genuine agreement error often makes the whole sentence hard to read correctly, and confident flags here go wrong often. Only raise it when the subject is unmistakable.

## What NOT to flag

These are the failure modes of general-purpose style checkers, and applying them to technical or professional prose actively harms the document:

- **Repetition of terms.** Do not suggest synonyms for variety. Consistent terminology is the goal, not a defect. Where translation is paid per word, a repeated sentence is a discount; where it's paid per new segment, an inconsistent one is a bill. Varying the word for a UI element is a bug, not elegance.
- **Sentence-length variety, rhythm, "flow," or word-choice richness.** Fiction advice. Not applicable.
- **Anything that trades precision for grace.** A clunky unambiguous sentence beats a graceful ambiguous one.
- **Rewriting the author's voice.** You fix the spans you flagged and nothing else. Delivering the tightened text is required (see below), but it is the same document with the findings applied — not a new draft, not a smoother one.

## Working with markup

If the document is Markdown, HTML, XML/SGML, or similar, keep tags intact in every quoted span and every rephrasing. Beyond preservation, tags are useful signal: they mark segment boundaries (so a missing final period is detectable), they identify list structure (so parallelism is checkable), and they let you skip or soften checks inside tables, code blocks, and headings, where sentence rules don't apply.

If the author points to revision markers, a diff, or says "I only changed this section," check only the changed parts. Re-flagging settled text in a long-lived document is one of the fastest ways to lose an author's attention.

## Output format

Order findings by severity, not by position in the document — the author should hit the real problems first. Group under these headings, omitting any that are empty:

```
## Ambiguity
## Complexity
## Vocabulary
## Grammar and punctuation

## Ambiguity Load: N.N per 1,000 words

## Tightened text
## Assumed readings        (only when an ambiguity finding was resolved)
```

Give every finding a line reference or enough quoted context to locate it. Keep each finding to the shape shown above: what, where, why it's a problem, and the rephrasings.

### Ambiguity Load

A single number so the author can tell whether the document is ready and whether a revision improved it. Compute it as:

```
weighted findings = (3 × ambiguity) + (2 × complexity) + (2 × vocabulary) + (1 × grammar/punctuation)
Ambiguity Load = weighted findings ÷ (word count ÷ 1,000)
```

Lower is better:

| Load | Reading |
|---|---|
| ≤ 5 | Ready to publish or send for translation |
| 6–15 | Fix the flagged items, then it's fine |
| > 15 | Needs a structural revision pass, not a cleanup |

Report the score with the counts that produced it, so it's auditable and the author can see which category is driving it. A document with a dozen comma errors and no ambiguity still scores well — that weighting is the point.

Treat the bands as a starting calibration, not a standard. They're worth adjusting once someone has run a few of their own documents through and knows what a 7 feels like for their material.

**Do not call this a Clarity Index.** That name is taken by an established readability formula — average sentence length plus the percentage of three-or-more-syllable words, where roughly 30 is the target and lower is better. IBM's EasyEnglish also had an internal metric by that name whose formula was never published. Emitting a number labeled "Clarity Index" invites an author to read it against either of those, and a score built from weighted findings is not comparable to a score built from syllable counts. If the author's organization has its own clarity threshold, ask for their formula and report theirs instead of this one; if they want a conventional readability score alongside, compute the real Fog-derived Clarity Index and label it as such.

## Deliver the tightened text

Never stop at the list. A review that hands back only findings makes the author do the work twice — once reading the diagnosis, once applying it — and the second pass is where the fixes get half-applied or dropped. Finish the job.

How to treat each category:

- **Complexity, vocabulary, grammar and punctuation.** One right answer each. Apply them.
- **Ambiguity.** You still do not know which reading was meant, and silently picking one is the exact failure this skill exists to prevent. So pick the reading you judge most likely, apply it, and log it under **Assumed readings** — one line per resolved span, naming the option you took. The author scans that short list, and re-emitting is cheap for anything they disagree with. The choice stays visible, which is what the "don't resolve it" rule is actually protecting.

When you are the author — you wrote the text yourself, or the intent is plainly recoverable from the surrounding code or document — say so and apply the intended reading. There is nobody to ask, and pretending otherwise is theatre.

Delivery follows the input. If the text came from a file, edit the file and say what changed; the author asked for a better document, not a patch to apply by hand. If it was pasted into the conversation, emit the full tightened text rather than a diff or a fragment list.

Then recompute the Ambiguity Load against the tightened text and report both numbers. A score for a draft nobody will ship is trivia; the pair shows whether the pass worked.

One thing the tightening must not do is broaden into a rewrite. Fix the spans you flagged. Leave sentence rhythm, terminology and the author's voice exactly where you found them, and resist the urge to improve a line you never raised a finding against — an author who cannot diff your output against their intent will stop sending you documents.

## Scaling the pass

For a short passage, review everything. For a long document, do a full pass on ambiguity — that's where the value is — and sample the grammar and punctuation categories, saying so explicitly: "Grammar findings below are from a spot check of sections 2 and 4, not the full document." Never silently truncate a review; an author who thinks a document is clean when it wasn't fully checked is worse off than one who knows what's left.

If the text is badly ungrammatical to begin with, say so first and offer to fix that pass separately. Ambiguity analysis on a sentence you can't reliably parse yourself produces confident nonsense, and precision is the whole game.

## Docs mode

Invoke it with `/for-simplicity docs`, or switch to it when the text is a decision note, a product doc, an engineering write-up, or a process doc, or when the author says it sounds abstract, fluffy, or AI-generated. Docs mode absorbs the former `for-docs` skill: a direct, task-oriented IBM Docs / plain-language rewrite. This is not a style makeover for the sake of style. It is a plain-language review that makes the document easier to scan, easier to act on, and easier to decide from.

Everything above still applies: precision over recall, the finding shape for ambiguity, the "What NOT to flag" list, the output format, and the Ambiguity Load score before and after. Two rules relax, and only in this mode:

- **Scope.** The standard pass fixes only the spans it flagged. Docs mode may restructure — reorder sections, add headings, turn a procedure into a step list — because structure is what the reader of a working document needs most. Rule 10 below is the limit.
- **AI-style filler.** The standard pass leaves AI tells to for-humanity. Docs mode removes the filler that stands between the reader and the decision (rule 7). A full de-AI pass on general prose is still for-humanity's job.

### Core objective

Rewrite the text so it is:

- direct
- task-oriented
- specific
- easy to scan
- clear about decision, tradeoff, and next step
- consistent in terminology
- free of AI-style filler and abstract framing

Keep the meaning and technical facts intact. Keep required product names, such as Acme Mail, exactly as written.

### IBM Docs conventions

Write task-oriented. A task topic tells the reader what to do, a concept topic tells them what something is, and a reference topic lists the values; do not mix the three in one section. A task heading starts with a verb ("Configure the relay"); a concept heading names the thing. A procedure becomes a numbered step list with one action per step, written in the imperative, followed by the expected result when it is not obvious. Use one name per thing throughout, and spell a product name exactly as its vendor does.

### Rules

**1. Start with the decision or task.** Put the user outcome first.
- Prefer: "We need to decide the order in which we build the email loop." / "We need to choose the source of truth for the event list."
- Avoid: "This note explains the background before we decide." / "There are several different paths forward."

**2. Use direct, active voice.**
- Prefer: "Acme Mail can read email now." / "We need five pieces before the loop is complete." / "The recommended option is A."
- Avoid: "The current state is such that email can be read by Acme Mail." / "There are a number of required pieces before completion is achieved."

The passive restraint from the Complexity check still holds: when the agent is missing and the document does not supply it, point out the passive rather than inventing a subject. In a team working document the agent is usually the team, so "we" is recoverable.

**3. Prefer short sentences and concrete nouns.** Break up dense or abstract writing into short, specific statements.
- Prefer: "We need five pieces." / "We can build them in three orders." / "The main difference is when we can test Gmail."
- Avoid: "The overall system requires a number of components before the end-to-end workflow can be considered complete."

**4. Make the structure obvious.** Use headings and labeled sections for the problem, the options, the tradeoffs, the decision, and the work that does not wait. For short docs, this usually means: Decision, Options, Tradeoffs, Recommendation, Follow-up work.

**5. Keep technical names exact.** Do not rename Acme Mail or other product names unless the user asks. Preserve the required product names exactly.

**6. Make tradeoffs explicit.** A good docs rewrite is not just clearer; it also explains the cost of each option. Use language like:
- Good: this option lets us test Gmail sooner.
- Tradeoff: this option delays the actual reply path.
- Risk: this can drift from the source of truth.

**7. Remove AI-style filler.** Remove or rewrite patterns such as vague significance language; abstract "landscape" or "evolving" phrasing; promotional phrasing; "At its core" or "what really matters" framing; unnecessary hedging; and repetitive summary paragraphs that do not add information.

**8. Keep the intended tone.** The document should sound like a team working document, not a blog post and not a sales page. It should be calm, factual, direct, and practical.

**9. Prefer decision-oriented wording.** Use wording that helps the reader decide quickly: choose A, B, or C; recommendation; implication; next step; why it matters.

**10. Preserve the author's meaning.** Do not convert a decision memo into a marketing memo or a polished essay. Keep the actual substance.

### Output in docs mode

Produce the same report as the standard pass: findings ordered by severity, the Ambiguity Load with the counts behind it, then the tightened text and any Assumed readings, and recompute the load against the rewrite. The score counts the same four categories; a structural move (a new heading, a reordered section, a paragraph turned into steps) shows in the tightened text and is not a scored finding. The tightened text in this mode is:

1. A concise, cleaned-up version of the document
2. No extra commentary unless needed
3. Normal Markdown headings and lists
4. Clear sentence-to-sentence logic
5. Explicit decisions and tradeoffs

### Example transformation

Before:
> Today Acme Mail can read mail. It cannot yet write a reply for you. Five parts are missing, and they can be built in three orders.

After:
> Acme Mail can read email now. It cannot write a reply for you yet. We need five pieces before the loop is complete. We can build them in three orders.

Before:
> The team sees the whole flow early, just without the AI writing.

After:
> The team can see the whole flow early, but the AI is not writing the reply yet.

### Working rule

If a sentence sounds like it was generated to sound polished instead of to help a person decide, rewrite it to sound direct, brief, and factual.

The goal is not to sound clever. The goal is to make the next decision obvious.
