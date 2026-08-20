---
name: writing-style
description: >-
  How every sentence Molcajete writes reads — Simplified Technical English per
  ASD-STE100: active voice, one meaning per word, simple tenses, short sentences,
  no phrasal verbs. Holds the four accuracy rules that outrank every length cap,
  how to explain a new concept, how to show a computed value and a code block,
  and the rule that an opaque ID never appears without its name. Pairs with
  output-economy, which governs how much gets written. Loaded by every command.
---

# Writing Style

Molcajete writes in Simplified Technical English. The standard is **ASD-STE100**, Issue 9 (January 2025), published by ASD, the AeroSpace and Defence Industries Association of Europe.

This skill owns how a sentence reads. The `output-economy` skill owns how much gets written. Neither one decides the other's half.

## The Rule

**Every document Molcajete generates and every message Molcajete prints uses Simplified Technical English.**

The six rules below do not all bind the same surfaces. Rules 1, 2, and 6 bind everything. Rules 3, 4, and 5 bind what a person reads.

| Rule | Binds |
|---|---|
| 1. Simplified Technical English | Every surface — spec files, plans, reviews, README files, changelog entries, commit messages, code comments, reports, question briefs |
| 2. Accuracy outranks every length cap | Every surface |
| 3. Explain a new concept at ELI10 | Reader-facing output only — screen replies, reviews, walkthroughs, plan prose |
| 4. Give every computed value a worked example | Reader-facing output only |
| 5. Present every code block the same way | Reader-facing output only |
| 6. Name the concept before the identifier | Every surface, except the three carve-outs in 6.1 |

A spec file states behavior. It does not teach, and rule 3 applied to a `UC-XXXX` file pads every scenario.

## Why

Molcajete writes for two readers, and an ambiguous sentence hurts both.

The first reader is the next agent. It parses the spec, the plan, and the code comments with no back-channel. When a use case says "the record is updated", the agent cannot ask which component updates it, so it guesses.

The second reader is a person who did not write the document, and who often does not read English as a first language. ASD built this standard for that reader.

## 1. Write in Simplified Technical English

| Rule | Do | Do not |
|---|---|---|
| One word, one meaning | Pick one verb for one action and use it every time. Always "check", never a mix of "check", "verify", and "confirm" for the same action. | Rotate synonyms for the same idea across a document |
| One part of speech per word | "Apply oil to the valve" — `oil` is a noun | "Oil the valve" — `oil` becomes a verb |
| Active voice | "The adapter writes the record." | "The record is written." |
| Simple tenses | "We received the report." | "We have received the report." (See rule 2.2 for the one exception.) |
| One instruction per sentence | "Open the file. Read line 3." | "Open the file and read line 3, then check if it matches." |
| Sentence length | 20 words maximum for an instruction. 25 words maximum for a description. | Long sentences that chain subordinate clauses |
| Noun clusters | 3 words maximum: "fuel pump valve" | 4 or more: "high pressure fuel pump inlet valve assembly" |
| No ellipsis | Keep the subject, the verb, and the article, even when the sentence gets longer | Drop words to save space. "Files not backed up will be lost" hides which files. |
| Paragraph limits | One topic per paragraph. 6 sentences maximum. | Paragraphs that carry more than one topic |
| Lists for sequences | Use a numbered or bulleted list for 3 or more steps or conditions | Bury a sequence in one prose sentence |
| Domain terms | Keep the technical nouns and verbs the domain needs. Define each one once in `specs/GLOSSARY.md`. | Use jargon and never define it |

### 1.1 Words and shapes to avoid

- **No phrasal verb.** Write "start", not "spin up". Write "remove", not "take off". Write "read", not "dive into".
- **No semicolon.** Write two sentences instead.
- **No marketing adjective.** "Seamless", "robust", "powerful", and "blazing-fast" claim quality instead of showing it.
- **Use a verb for an action.** Write "analyze the log", not "perform an analysis of the log".

## 2. Accuracy Outranks Every Length Cap

A length cap makes each of these easy to break. Accuracy wins. Write the longer sentence.

1. **Keep every hedge exactly as strong as it was.** "The request may have failed" must never become "the request failed". A shorter sentence that drops a hedge states a different fact.
2. **Keep the present perfect where it carries current relevance.** "The job has completed, and its output is ready" says more than "the job completed". This is the one exception to the simple-tense rule in the table above.
3. **Never rewrite quoted material.** Code, logs, error strings, file contents, command output, and the reader's own words stay exact.
4. **Never drop a number, a condition, a scope limit, or a safety warning to shorten a sentence.** Write the longer sentence, and say why it is longer.

## 3. Explain a New Concept at ELI10

ELI10 means "explain like I am 10 years old". Explain a concept the first time it appears. Do not explain what the reader already uses.

- Explain an algorithm, a library, a protocol, a pattern, or a math technique that is new to the conversation.
- Expand an acronym on first use. Write the full words one time, then use the short form.
- Give one concrete example with real values. An example teaches faster than a definition.
- Name every symbol in a formula before the formula appears.
- Show the middle step. The step an expert skips is the step a learner needs.
- Accuracy beats simplicity. Never make a statement false to make it simple. When you simplify, say what you left out.

**The line between the two lists is ownership.** The reader built the host project. Explaining their own code back to them wastes their time and reads as condescension.

| Explain it | Do not explain it |
|---|---|
| Mutation testing, and what a surviving mutant proves | The host project's test command |
| Hexagonal architecture, and what a driving port is | Which host module owns which adapter |
| Base-62 encoding, and why an ID is 4 characters | What `FEAT-0Fy0` refers to in this project |
| The EARS requirement syntax | The wording of an existing `FR-XXXX` |

## 4. Give Every Computed Value a Worked Example

A formula alone is a claim. A formula with real numbers substituted is a proof the reader can check.

1. Name every symbol before the formula appears.
2. Show the formula.
3. Substitute real values from the project, never invented ones.
4. Show the middle step. Never jump from the inputs to the result.
5. Comment each line with what that line computes.

**Example — why a touched file fails the coverage gate.**

The gate is four-dimensional. Every touched file must meet the floor on lines, statements, branches, and functions. Three inputs decide one dimension:

- `covered` — how many units of that dimension the scoped test run exercised.
- `total` — how many units the file holds.
- `floor` — the threshold for that dimension, from `testing.thresholds` in `.molcajete/settings.json`. The default is 80.

```text
percent = covered / total * 100
pass    = percent >= floor, for every one of the four dimensions
```

```text
# A file with 3 conditionals holds 6 branches. The run exercised 4 of them.
percent = 4 / 6 * 100        # = 0.667 * 100 = 66.7 percent on branches

# The floor is 80 for every dimension.
66.7 >= 80                   # false — the branches dimension fails

# Lines on the same file: 48 of 50 statements ran.
percent = 48 / 50 * 100      # = 96.0 percent on lines — passes

# The gate needs all four. One failing dimension fails the file.
pass = false
```

Read the middle step: `4 / 6 = 0.667`, then `0.667 * 100 = 66.7`. A file at 96 percent lines and 66.7 percent branches does not pass. Two uncovered branches, not two uncovered lines, are what the Implementer must resolve.

**Why:** a formula hides its rounding, its unit conversions, and its exponents. Real numbers expose all three.

## 5. Present Every Code Block the Same Way

- Put a language tag on the fence. Write ` ```go `, not ` ``` `.
- Format the body. Match the formatter the host project uses for that language.
- Comment each block of work inside the snippet, in that language's own comment syntax.
- Caption the block with the file and the line range when the code comes from the repository. Write it as `src/auth/otp.ts:44-61`, which the terminal makes clickable.
- Mark an edit. Say which lines are new and which are the current code, so the reader does not diff by eye.

**Why:** a code block in a reply carries no surrounding file to explain it. The comment is the only context the reader gets, and the caption is the only way back to the source.

This rule covers code **shown to the reader**. Code **committed to the repository** follows the `principles` skill, rules 5.1 to 5.5, which is a stricter standard.

## 6. Name the Concept Before the Identifier

Write the name first. Put the identifier in parentheses after it.

- Write "odds calibration (FEAT-0Fy0)". Never write "FEAT-0Fy0" alone.
- This rule covers every opaque identifier: `FEAT`, `UC`, `SC`, `FR`, `NFR`, `US`, `ADR`, a task ID, a plan ID, a ticket number, and a commit hash. Write "the plan-dispatch commit (8c7c4f6)", not "8c7c4f6".
- Give the name on the first use in each message, section, or document. After that first use, the identifier alone is enough inside the same message.
- If you cannot name the concept, you have not read it. Read the spec before you cite it. A wrong name is worse than a bare identifier, so verify the name against the source.

**Why:** a bare identifier forces the reader to stop and search the spec tree. A project holds hundreds of them, and no reader keeps them in memory. The search costs more time than the name costs to write.

| Wrong | Right |
|---|---|
| "SC-3Z2P now passes." | "The above-ceiling score scenario (SC-3Z2P) now passes." |
| "This closes UC-0KTg and FR-0Fy0." | "This closes register user (UC-0KTg) and the duplicate-email requirement (FR-0Fy0)." |
| "T-003 failed." | "Expiring the OTP after 10 minutes (T-003) failed." |

### 6.1 Three places keep the bare identifier

Each one holds data or follows a fixed convention. Stripping the identifier there breaks tooling.

- **A machine-readable field.** Examples are `id: UC-0KTg`, `feature: FEAT-0Fy0`, and a `**Covers:**` list. Molcajete parses these fields.
- **A file path.** An example is `specs/features/{module}/FEAT-XXXX-{slug}/UC-XXXX-{slug}.md`.
- **A code comment or a spec heading that the project defines.** An example is `// UC-0KTg: Register User` from the `principles` skill. That format already carries the name.

## Where Other Molcajete Rules Win

Simplified Technical English governs the shape of a sentence. It never overrides a rule that governs content. When the two appear to conflict, the rules below win.

- **Volume belongs to `output-economy`.** That skill decides what gets cut and what is protected. This skill never makes that call. Apply these six rules to whatever survives it.
- **EARS syntax wins inside requirements.** `When {trigger}, the system shall {response}` is already correct. Never reword an EARS clause to meet a sentence-length limit. Split the requirement instead, because a requirement that needs 30 words is usually two requirements.
- **Plan prose stays narrative.** The `plan-authoring` skill requires flowing explanation, not labeled lists. Shorten the sentences. Do not convert the prose into bullets.
- **Closed vocabularies win.** The step verbs in `usecase-authoring` and the commit verbs in `git-committing` are already one word for one meaning. Use them exactly as written.
- **Question briefs keep their shape.** The `asking-questions` skill sets the brief's structure and its 250-word budget. These rules apply to the sentences inside that structure.

## Where This Does Not Apply

- Direct quotations from a user, a source document, or a tool output. Quote them exactly.
- Identifiers, file paths, commands, and code. Never reword them.
- Mermaid diagram labels and the ASCII mockups in a feature's `## UI` section.
- Text the host project supplied. Molcajete does not rewrite what it did not write.

## Precedence

When two rules disagree, resolve in this order. The first line wins.

1. **Accuracy.** A hedge, a number, a condition, a scope limit, a safety warning, and quoted material all survive any rewrite.
2. **These six rules.**
3. **Brevity.**

## Self-Check

Before you write a document or print a report, read your longest sentence again. Then confirm:

1. The sentence has one instruction.
2. The sentence names the actor, and the verb is active.
3. The sentence is 20 words or fewer for a procedure, or 25 or fewer for a description.
4. No word in the sentence carries more than one meaning in this document.
5. No noun cluster is longer than 3 words.
6. The tense is simple, unless rule 2.2 applies.
7. No opaque identifier appears without its name on first use.
8. Every code block carries a language tag and, when it comes from the repository, a `file:line` caption.

If a sentence fails a check, split it. Do not delete the fact it carries. When a shorter sentence would drop a condition, a scope qualifier, or a number, keep the longer sentence.

## About the Standard

ASD-STE100 contains 53 writing rules across 9 sections, plus a dictionary of approximately 900 approved words and approximately 1,200 words to avoid.

**This skill applies the writing rules. It does not apply the dictionary.** The dictionary is ASD's own document. Molcajete does not copy it, and Molcajete does not claim that its output is certified Simplified Technical English. Instead, apply the principle behind the dictionary: pick the plainest and most common word available, then use that word the same way every time.

The standard is free. Download it at https://www.asd-ste100.org/ when exact approved wording matters.
