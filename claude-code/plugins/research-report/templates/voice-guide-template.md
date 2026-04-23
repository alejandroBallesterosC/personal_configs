<!-- ABOUTME: Voice guide template for research-report Phase S writing. -->
<!-- ABOUTME: Filled in once at start of Phase S by the orchestrator; read by narrative-writer before each chapter and by narrative-editor during reader passes. -->

# Voice Guide: <TOPIC_PLACEHOLDER>

This document records the voice and terminology decisions for this report. The narrative-writer reads it before drafting each chapter so the prose stays consistent across the whole report. The narrative-editor reads it during reader passes to verify consistency.

Keep this short — under one page. Decisions, not explanations.

## Audience

Who is this report written for? (e.g., technical practitioners, executives evaluating a market, policy analysts.) The audience determines vocabulary and how much background to assume.

## Level of Formality

Pick one and stick to it across all chapters:

- [ ] Academic / peer-review register (impersonal, hedged, citation-dense)
- [ ] Trade-publication register (declarative, audience-aware, fewer hedges, examples)
- [ ] Executive-brief register (assertive, conclusion-first, minimal jargon)
- [ ] Other: _________

## Person and Voice

- **Self-reference:** how does the report refer to itself? Pick one:
  - "This report ..."
  - "We ..." (first-plural editorial)
  - Impersonal — the report does not refer to itself
- **Reader-reference:** does the report address the reader? ("you", "the reader", or never)
- **Narrator stance:** are conclusions stated as the report's view, or attributed to the evidence?
  - "The evidence suggests X." (impersonal, attributed)
  - "We conclude X." (editorial, owned)
  - "X." (declarative, no attribution — strongest, requires very tight evidence)

## Hedging Conventions

When evidence is qualified or uncertain, use a consistent vocabulary instead of mixing words at random:

- Strong evidence: "shows", "demonstrates", "establishes"
- Moderate evidence: "indicates", "suggests", "points to"
- Weak or contested: "may", "appears to", "is consistent with"
- Mixed evidence: "evidence is mixed; on balance ..."

Never weaken qualifications inherited from the evidence pool to make prose flow better. If a pool entry has `gap_rating: WIDE`, the prose must reflect that.

## Terminology Decisions

When sources use different vocabulary for the same concept, lock in one term and use it consistently. Document the choice and the discarded alternatives so the writer doesn't drift.

| Concept | Term we use | Discarded alternatives | Notes |
|---------|------------|----------------------|-------|
| <e.g., AI agent> | "agent" | "autonomous system", "AI assistant" | Reserve "agent" for systems that take actions; use "model" for inference-only. |
| ... | ... | ... | ... |

## Citation Density

Roughly how many `\cite{}` per paragraph in body chapters? (e.g., "every claim cited; typically 1-3 cites per paragraph"). This sets the writer's expectation.

## What to Avoid

- Generic AI-writing tells: avoid "delve", "leverage", "navigate the landscape", "in today's rapidly evolving"
- Empty transitions: avoid "Furthermore,", "Moreover,", "Additionally," at paragraph starts unless they actually mark logical addition
- Hedging soup: avoid stacked hedges ("may potentially possibly")
- Section openings that summarize what's about to come — let the prose do the work

## Headline Argument (one sentence)

What is the report's overall argument? This is what the front Synthesis and back Conclusions both reflect. Drafted at start of Phase S; revised once after the body is written if the evidence shifted it.

> <one-sentence headline argument>
