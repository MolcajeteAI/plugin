---
name: writing-style
description: >-
  The writing style that binds every document Molcajete generates and every
  message it prints — Simplified Technical English per ASD-STE100: one meaning
  per word, active voice, simple tenses, short sentences, no idioms. Also
  defines which existing Molcajete rules win when they conflict. Loaded by
  every command.
---

# Writing Style

Molcajete writes in Simplified Technical English. The standard is **ASD-STE100**, Issue 9 (January 2025), published by ASD, the AeroSpace and Defence Industries Association of Europe.

## The Rule

**Every document Molcajete generates and every message Molcajete prints uses Simplified Technical English.** This includes spec files, plans, review documents, README files, changelog entries, commit messages, code comments, test comments, on-screen reports, and question briefs.

## Why

Molcajete writes for two readers, and both are hurt by ambiguous English.

The first reader is the next AI agent. It parses the spec, the plan, and the code comments with no back-channel. It cannot ask what a passive sentence meant. When a use case says "the record is updated", the agent cannot tell which component updates it, so it guesses.

The second reader is a person who did not write the document, and who often does not read English as a first language. ASD built this standard for exactly that reader: a technician who works from a manual, alone, and who cannot call the author.

Simplified Technical English removes the two largest sources of misreading: words that carry more than one meaning, and sentences that permit more than one structure.

## The Rules

| Rule | Do | Do not |
|---|---|---|
| One word, one meaning | Pick one verb for one action and use it every time. Always "check", never a mix of "check", "verify", and "confirm" for the same action. | Rotate synonyms for the same idea across a document |
| One part of speech per word | "Apply oil to the valve" — `oil` is a noun | "Oil the valve" — `oil` becomes a verb |
| Active voice | "The adapter writes the record." | "The record is written." |
| Simple tenses only | "We received the report." | "We have received the report." |
| One instruction per sentence | "Open the file. Read line 3." | "Open the file and read line 3, then check if it matches." |
| Sentence length | 20 words maximum for instructions and procedures. 25 words maximum for descriptions. | Long sentences that chain subordinate clauses |
| Noun clusters | 3 words maximum: "fuel pump valve" | 4 or more: "high pressure fuel pump inlet valve assembly" |
| No ellipsis | Keep the subject, the verb, and the article, even when the sentence gets longer | Drop words to save space. "Files not backed up will be lost" hides which files. |
| Paragraph limits | One topic per paragraph. 6 sentences maximum. | Paragraphs that carry more than one topic |
| Lists for sequences | Use a numbered or bulleted list for 3 or more steps or conditions | Bury a sequence in one prose sentence |
| Domain terms | Keep the technical nouns and verbs the domain needs. Define each one once in `specs/GLOSSARY.md`. | Use jargon and never define it |

## Source and Scope

ASD-STE100 contains 53 writing rules across 9 sections, plus a dictionary of approximately 900 approved words and approximately 1,200 words to avoid.

**This skill applies the writing rules. It does not apply the dictionary.** The dictionary is ASD's own document. Molcajete does not copy it, and Molcajete does not claim that its output is certified Simplified Technical English. Instead, apply the principle behind the dictionary: pick the plainest and most common word available, then use that word the same way every time.

The standard is free. Download it at https://www.asd-ste100.org/ when exact approved wording matters.

`references/writing-rules.md` summarizes the 9 rule sections and cites the sources.

## Where Other Molcajete Rules Win

Simplified Technical English governs the shape of a sentence. It never overrides a rule that governs content. When the two appear to conflict, the rules below win.

- **Volume belongs to another skill.** How much gets written is governed by `output-economy`, never here. Simplified Technical English changes how each sentence reads. Apply it to whatever survives that skill.
- **EARS syntax wins inside requirements.** `When {trigger}, the system shall {response}` is already correct. Never reword an EARS clause to meet a sentence-length limit. Split the requirement instead, because a requirement that needs 30 words is usually two requirements.
- **Plan prose stays narrative.** The `plan-authoring` skill requires flowing explanation, not labeled lists. Shorten the sentences. Do not convert the prose into bullets.
- **Closed vocabularies win.** The step verbs in `usecase-authoring` and the commit verbs in `git-committing` are already one word for one meaning. Use them exactly as written.
- **Question briefs keep their shape.** The `asking-questions` skill sets the brief's structure and its 250-word budget. Simplified Technical English applies to the sentences inside that structure.

## Where This Does Not Apply

- Direct quotations from a user, a source document, or a tool output. Quote them exactly.
- Identifiers, file paths, commands, and code. Never reword them.
- Mermaid diagram labels and the ASCII mockups in a feature's `## UI` section.
- Text the host project supplied. Molcajete does not rewrite what it did not write.

## Self-Check

Before you write a document or print a report, read your longest sentence again. Then confirm:

1. The sentence has one instruction.
2. The sentence names the actor, and the verb is active.
3. The sentence is 20 words or fewer for a procedure, or 25 or fewer for a description.
4. No word in the sentence carries more than one meaning in this document.
5. No noun cluster is longer than 3 words.
6. The tense is simple.

If a sentence fails a check, split it. Do not delete the fact it carries. When a shorter sentence would drop a condition, a scope qualifier, or a number, keep the longer sentence.
