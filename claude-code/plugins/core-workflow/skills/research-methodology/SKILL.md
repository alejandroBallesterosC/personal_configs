---
name: research-methodology
description: Evidence rigor discipline for research — distinguishing what a source proves from what it merely asserts, rating evidence-to-claim gaps, surfacing load-bearing assumptions, and auditing prose for overstatement. Use when researching a topic, evaluating sources, or reviewing a research-based write-up before trusting or presenting its conclusions.
---

# Research Methodology Skill

A rigor discipline for research: how to evaluate evidence while gathering it, and how to audit written conclusions against that evidence afterward. Apply this directly while researching or reviewing — no separate pipeline or dedicated critic agent needed.

**Announce at start:** "I'm applying the research-methodology skill to this research."

## While Gathering Evidence

Before treating any source as support for a claim, apply this filter:

1. **What does this source actually prove vs. merely assert?** If you cannot clearly separate the source's evidence from its claims, you haven't read it carefully enough. State the narrowest defensible reading of the evidence, and separately note the source's broader assertion if it goes beyond that.

2. **What are the load-bearing assumptions?** Every empirical claim rests on assumptions — about sampling, methodology, generalizability. Identify which ones are load-bearing: if they're wrong, does the conclusion collapse?

3. **Is this finding regime-dependent?** A finding from one set of conditions (time period, geography, sample, technology era) may not transfer to another. State the conditions under which it's valid.

4. **Rate the evidence-to-claim gap**:
   - **TIGHT**: evidence directly supports the claim
   - **MODERATE**: requires non-trivial assumptions to bridge evidence to claim
   - **WIDE**: the claim goes substantially beyond the evidence

The goal is not to find sources that say things. The goal is to find sources that prove things, and to state clearly what they prove vs. what they merely assert.

**Source credibility hierarchy** (prefer higher):
1. Academic papers, official documentation, RFCs
2. Company engineering blogs, published benchmarks
3. Reputable tech journalism (not AI-generated summaries)
4. Community forums (Stack Overflow, HN) — useful for practitioner experience, verify claims independently

Prefer recent sources (last 1-2 years) over older ones unless the older source is foundational. If sources contradict each other, note both rather than silently picking one.

## While Reviewing a Conclusion or Draft (Methodological Critique)

When auditing a claim, argument, or piece of prose against its supporting evidence, check three things:

### 1. Source vs. Claim
For each claim-and-source pair: read the source directly, don't rely on a paraphrase. Does the source actually support the claim as stated? Is the claim's gap rating (TIGHT/MODERATE/WIDE) accurate, or too generous? Should the claim be narrowed, or the confidence downgraded?

### 2. Evidence Set vs. Argument
When several findings are used to support one broader argument, check:
- **Aggregation**: does the argument legitimately generalize from the findings, or overreach?
- **Cherry-picking**: are there findings that weaken or qualify the argument that got ignored?
- **Gap-rating math**: if the supporting findings are mostly MODERATE/WIDE gap, the argument inherits that uncertainty — it can't be stated with more confidence than its weakest load-bearing support.
- **Regime drift**: do the findings' regimes (time, geography, context) match the regime the argument claims to cover?

### 3. Prose vs. Evidence (Overstatement Audit)
When auditing written text against the evidence it cites, watch for:
- **Overstatement**: prose states something with high confidence when the underlying gap rating was MODERATE or WIDE
- **Lost qualification**: prose drops a regime condition present in the source (e.g., source says "US 2024 data only," prose says "globally")
- **Smuggled inference**: prose makes a claim positioned as cited that no source actually supports
- **Source-claim mismatch**: the citation is real, but doesn't say what the prose implies it says
- **Aggregation overreach**: prose generalizes from a few sources to a broader claim than they jointly support

## Anti-Patterns to Flag

- **Appeal to authority**: citing a prestigious source for a claim made in passing, not as a studied finding
- **Cherry-picked statistics**: using one favorable data point from a source with mixed evidence
- **Survivorship bias**: source studied only successful cases and generalized
- **Correlation-as-causation**: source shows association, claim treats it as causal
- **Outdated evidence**: findings superseded by newer evidence or structural change
- **Scope creep**: source studied X in context A, claim applies it to Y in context B
- **Precision theater**: source gives falsely precise numbers given its actual methodology

## Rules

- Never fabricate criticisms — if a source's methodology is sound for the claim being made, say so.
- Never be contrarian for its own sake; the goal is accurate assessment, not maximizing objections.
- Always distinguish "this claim is wrong" from "this claim is right but being cited incorrectly."
- Always name the surviving insight — even flawed evidence usually contains something true within a boundary. State the boundary explicitly rather than discarding the finding outright.
- Every finding you report as established should cite its source and, if publication date is known, note it to flag staleness.
