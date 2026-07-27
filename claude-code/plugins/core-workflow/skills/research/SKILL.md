---
name: research
description: Conduct thorough internet research on a topic using waves of parallel subagents. User-invoked only.
disable-model-invocation: true
argument-hint: <question or topic to research>
allowed-tools: Agent, Read
disallowed-tools: Edit, Write, NotebookEdit, Bash
effort: xhigh
---

# Thorough Internet Research

You will conduct thorough internet research to answer the following question or investigate the following topic:

**$ARGUMENTS**

This is a research-only task: the only output is a well-sourced answer. `disallowed-tools` blocks edits and shell access for the duration.

## Research Strategy

Research runs in waves of parallel `web-researcher` subagents, each assigned a different angle. The user invoked this skill to get a wide, parallel sweep, so delegate rather than researching serially yourself.

### Wave Planning

Before each wave, identify the distinct research angles the question needs. One subagent per angle — the angles set the count, not a fixed number. Four to six angles is typical; use fewer for a narrow question and more when the question genuinely spans more ground. Angles worth considering:

- Different facets of the question (performance, security, developer experience)
- Different source types (official docs, community experience, benchmarks, case studies)
- Competing or alternative approaches
- Known pitfalls, limitations, or controversies
- Real-world production usage and lessons learned
- Historical context and evolution of the topic

Angles should not overlap. Two subagents assigned the same ground return the same sources twice.

### Wave Execution

Launch each wave's subagents in a single message (all in parallel) using the Agent tool:

```
subagent_type: "web-researcher"
prompt: |
  Research question: [the overall question]
  Research focus: [the specific angle for this agent]
  Context: [any relevant context from previous waves]
```

### Wave Synthesis

After each wave: collect the findings, note where independent sources corroborate each other, note where they conflict, and identify which important aspects remain uncovered.

### Deciding When to Stop

Launch another wave only when a significant gap remains — an uncovered facet, an unresolved conflict between sources, or a load-bearing claim resting on a single source. One to three waves is typical. Stop when the remaining gaps are minor or tangential, and say what they are rather than launching a wave to close them.

## Final Output

Present findings directly in your response:

```markdown
# Research: [Topic/Question]

## Answer
[Direct answer — lead with the recommendation or conclusion]

## Key Findings

### [Category]
- [Finding] ([source URL])

## Trade-offs and Considerations
[Nuances, trade-offs, and caveats that affect the decision]

## Sources
[The most credible and relevant sources, with URLs and dates]

## Confidence Level
[High/Medium/Low, and what would raise it]
```

The user wants an answer, not a literature review. Lead with the conclusion and support it with evidence. Keep each finding to a sentence or two, and keep the whole answer to what a reader needs to act on — a couple of screens, not an exhaustive dump of everything the subagents returned. Attribute every factual claim to a source, and mark claims you could not verify as unverified rather than dropping or softening them.
