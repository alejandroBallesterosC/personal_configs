---
name: clear-writing
description: >-
  Write and communicate in a clear, plain style with no slop. Use this when writing
  any prose for a user or teammate, such as documents, reports,
  summaries, research notes, proposals, emails, Slack messages, commit and PR
  descriptions, or a chat reply that explains something. Also use it whenever a
  user asks you to simplify, tighten, clean up, reword, or make writing clearer.
  Apply it to open-ended and complex explanations, where the risk of vague
  jargon and missing information is highest. Default to this style for all prose
  unless the user asks for a different one. Do not apply it to code.
---

# Clear writing

Use this skill when producing written artifacts, writing prose, explaining things in conversation.
The goal is text a reader can read once and understand, with no vague jargon and no
missing information. AI writing often sounds elaborate but leaves out the critical
point and hides behind generic high probability words. This skill exists to stop that.

It combines two sources: a plain-writing style guide and the stop-slop pattern list.
The core rules are below. The exhaustive lists of banned phrases and structures live in
the files in reference/, which should be loaded when editing or reviewing a longer piece.

## When to use it

Use this skill for two jobs.

1. Written artifacts. Any document, report, email, Slack post, README, documentation, or note you produce for a person.
2. Communication. Any time you explain a complex or open-ended idea in chat, including plans, tradeoffs, and answers to hard questions.

When you explain something, you should state the actual point, name the specific thing, and include the information the reader needs to act. You should NOT pad the explanation with words that sound smart but carry no meaning. This does not mean you should
not use technical or complex words, it just means you need to be intentional and precise with your language. Use specific technical words when you are communicating a specific technical thing, dont use overly complex words all the time vaguely.

## The rules

1. Use simple, everyday words. Prefer the common word over the fancy one. Write
   "use" rather than "leverage". Avoid the words AI tools overuse, e.g.,
   "delve", "robust", "landscape", "seamless", and "leverage". Repeat a word
   rather than swap in a synonym just to avoid repeating it.

2. State the point first. Lead with the actual claim, decision, or answer. Do
   not open with a phrase that announces you are about to make a point, e.g.,
   "Here's the thing" or "It's worth noting". Cut the runway and say the thing.

3. Write complete sentences. Each sentence states one clear thing and has a
   subject and a verb. Do not write fragments for drama. Do not stitch several
   ideas into one dense line with colons or semicolons. If a sentence states
   two things, split it into two sentences.

4. No dashes, and limit colons. Do not use em dashes or en dashes, including in
   number ranges. Join clauses with a period or with a word such as "and".
   Write ranges with the word "to", e.g., "0.94 to 0.96". Use a colon only to
   introduce a list, not to set up a point. Use straight quotes, not curly
   quotes.

5. No jargon without a plain definition. Do not use field shorthand when a
   plain phrase works. If a technical term is truly needed, say it once and
   explain it in plain words. A sentence full of terms with no definition reads as slop.

6. Include the critical information. Plain does not mean vague or short. When you
   explain a complex idea, name the specific numbers, tradeoffs, risks, and
   next steps the reader needs. Instead of compressing an idea into one cramped
   sentence, expand it so each point gets its own sentence or bullet. Clarity
   comes before both shortness and length.

7. Be specific, not sweeping. Do not announce that something is important,
   deep, or structural without naming the specific thing, e.g., "the
   implications are significant". Name the implication. Avoid lazy extremes
   like "every", "always", and "never" doing vague work. Use the specific case.

8. No analogies or imagery. Do not explain something by comparing it to a
   different thing. Do not use a metaphor or a phrase meant to sound clever.
   Describe the actual thing in literal terms.

9. Name the actor. Do not give an inanimate thing a human verb, e.g., "the
   data tells us" or "the decision emerges". A person does the action. Write
   "you can read the logs" rather than "the logs become searchable records". A
   common phrase like "the paper argues" is fine.

10. Use active voice. Find who did the action and put them at the front of the
    sentence. Do not hide the actor with passive voice, e.g., "the decision was
    reached".

11. Do not use the contrast or pivot patterns. Do not write "not X, it's Y".
    Do not set up a statement and undercut it in the next sentence. Do not list
    what a thing is not before saying what it is. State Y directly.

12. Cut filler and puffery. Remove words that add nothing, e.g., "really",
    "just", "actually", "at the end of the day". Do not say something "matters"
    or "carries weight". Do not use "a testament to", "pivotal", or "renowned".
    State the point or cut the sentence.

13. Do not invent hyphenated adjectives. A common compound like "well-crafted"
    is fine. Do not coin a phrase by joining words with a hyphen to sound
    compact. If you would not find it in a dictionary or hear it in speech,
    write it out.

14. Attribute claims. Do not hide a claim behind a vague source, e.g., "experts
    say" or "studies show". Name the source, or cut the claim.

15. Keep formatting plain. Use sentence case in a heading. Do not bold the
    first phrase of every bullet as decoration. Do not stack rhetorical
    questions to sound thoughtful. State the problem directly.

16. Keep lists honest. Do not pad a list to three items for rhythm. Use two
    items or one when that is what you have. When you have several distinct
    things, give each its own bullet or sentence rather than one long line.

## Self-check before sending

Run these checks on any prose before you deliver it. Fix what fails.

- Did you state the main point in the first sentence or two? If it is buried, move
  it up.
- Is there jargon a reader could not define? Define it in plain words or cut it.
- Did you leave out a number, tradeoff, risk, or next step the reader needs? Add
  it.
- Any em dash or en dash? Remove it. Any curly quote? Make it straight.
- Any throat-clearing opener like "Here's what" or "It's worth noting"? Cut to
  the point.
- Any "not X, it's Y" contrast or a setup-then-undercut pivot? State Y directly.
- Any inanimate thing doing a human verb? Name the person, or use "you".
- Any passive voice hiding the actor? Put the actor at the front.
- Any vague declarative that announces importance without the specific thing?
  Name the thing.
- Any adverb or filler word doing empty work ("really", "just", "actually")?
  Delete it.
- Any three-item list padded for rhythm? Cut it to what is real.
- Any fragment for drama, or a punchy one-liner ending? Make it a full sentence.

## Scoring a draft

For a longer artifact, rate the draft 1 to 10 on each dimension. Below 35 out of
50 means revise before sending.

- Directness. Does it state points, or announce that it will make them?
- Clarity. Could a reader who is new to this understand it on one read?
- Completeness. Is any critical number, tradeoff, or next step missing?
- Plainness. Is it free of jargon, filler, and clever phrasing?
- Density. Is there anything I can cut without losing meaning?

## Reference files

Load these when you edit or review a longer piece, or when you need the full list.

- `references/banned-phrases.md`. Throat-clearing openers, emphasis crutches,
  business jargon and plain replacements, adverbs, meta-commentary, and vague
  declaratives to cut.
- `references/banned-structures.md`. Binary contrasts, negative listing,
  dramatic fragmentation, rhetorical setups, false agency, passive voice, and
  the sentence and rhythm patterns to avoid.
- `references/examples.md`. Before and after pairs that show each fix.
