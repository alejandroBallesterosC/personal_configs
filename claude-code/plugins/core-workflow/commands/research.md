---
description: Conduct thorough internet research on a topic using waves of parallel subagents
argument-hint: <question or topic to research>
allowed-tools: Agent, Read
---

# Thorough Internet Research

You will conduct thorough internet research to answer the following question or investigate the following topic:

**$ARGUMENTS**

## Rules

- **DO NOT** edit any files
- **DO NOT** make any git commits or changes
- **DO NOT** modify any code
- This is a **research-only** task — your only output is a well-sourced answer

## Research Strategy

You will conduct research in **waves** of 4-6 parallel `web-researcher` subagents, each assigned a different angle or focus area. After each wave, synthesize findings and determine if more research is needed.

### Wave Planning

Before each wave, analyze the question and identify 4-6 distinct research angles. Good angles include:
- Different facets of the question (e.g., performance, security, developer experience)
- Different source types (official docs, community experience, benchmarks, case studies)
- Competing or alternative approaches
- Known pitfalls, limitations, or controversies
- Real-world production usage and lessons learned
- Historical context and evolution of the topic

### Wave Execution

For each wave, launch **4-6 subagents in a single message** (all in parallel) using the Agent tool:

```
subagent_type: "web-researcher"
prompt: |
  Research question: [the overall question]
  Research focus: [the specific angle for this agent]
  Context: [any relevant context from previous waves]
```

### Wave Synthesis

After each wave completes:

1. **Collect findings** from all subagents
2. **Identify convergence** — where do multiple sources agree?
3. **Identify conflicts** — where do sources disagree?
4. **Identify gaps** — what important aspects haven't been covered yet?
5. **Assess confidence** — are you confident enough to answer the question?

### Deciding When to Stop

Continue launching waves until you are **confident** in your answer. You should feel confident when:
- Multiple independent sources corroborate key findings
- Major alternative viewpoints have been explored
- Known pitfalls and limitations have been identified
- You can clearly articulate trade-offs
- Remaining gaps are minor or tangential

Typically 1-3 waves are sufficient. Launch additional waves only if significant gaps remain.

## Final Output

Once confident, present your findings to the user as a clear, well-organized answer:

```markdown
# Research: [Topic/Question]

## Answer
[Direct, clear answer to the question — lead with the recommendation or conclusion]

## Key Findings

### [Category 1]
- [Finding] ([source URL])
- [Finding] ([source URL])

### [Category 2]
- [Finding] ([source URL])
- [Finding] ([source URL])

## Trade-offs and Considerations
[Important nuances, trade-offs, or caveats the user should know about]

## Sources
[Consolidated list of the most credible and relevant sources with URLs and dates]

## Confidence Level
[High/Medium/Low — with brief explanation of what would increase confidence]
```

**Keep the final answer focused and actionable.** The user wants an answer, not a literature review. Lead with the conclusion, support it with evidence, and note important caveats.
