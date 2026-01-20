---
name: tdd-workflow-guide
description: Guide for using the TDD workflow plugin. Activates when starting or navigating the TDD workflow phases.
---

# TDD Workflow Guide Skill

This skill provides guidance for navigating the TDD workflow plugin's phases. Based on practices from Boris Cherny (Claude Code creator), Thariq Shihab (Anthropic), Mo Bitar, and Geoffrey Huntley.

## When to Activate

Activate when:
- User invokes `/tdd-workflow:start`
- User asks about the TDD workflow process
- Navigating between workflow phases
- User seems lost in the workflow
- Transitioning from planning to implementation

**Announce at start:** "I'm using the tdd-workflow-guide skill to help navigate this workflow."

## Workflow Overview

```
┌─────────┐    ┌──────┐    ┌───────────┐    ┌─────────────┐
│ EXPLORE │───▶│ PLAN │───▶│ ARCHITECT │───▶│ REVIEW-PLAN │
└─────────┘    └──────┘    └───────────┘    └─────────────┘
                                                   │
                              ⚠️ FRESH SESSION     │
                              RECOMMENDED          │
                                                   ▼
                           ┌────────┐    ┌───────────┐
                           │ REVIEW │◀───│ IMPLEMENT │
                           └────────┘    └───────────┘
```

## Phase Responsibilities

### Phase 1: EXPLORE
**Purpose**: Understand the codebase before planning

**What happens**:
- Code-explorer agent analyzes architecture
- Identifies patterns and conventions
- Finds related code for reference
- Checks/updates CLAUDE.md

**Output**: `docs/context/<feature>-exploration.md`

**Command**: `/tdd-workflow:explore <feature>`

**When complete**: User has full context of relevant codebase areas

---

### Phase 2: PLAN
**Purpose**: Create unambiguous specification through interview

**What happens**:
- Ask 40+ questions ONE AT A TIME
- Cover 9 domains (functionality, constraints, UX, edge cases, security, testing, integration, performance, deployment)
- Challenge assumptions
- Pushback on idealistic ideas

**Output**:
- `docs/specs/<feature>.md` (specification)
- `docs/plans/<feature>-tests.md` (test cases)

**Command**: `/tdd-workflow:plan <feature>`

**When complete**: User has answered all questions, spec is comprehensive

---

### Phase 3: ARCHITECT
**Purpose**: Design technical implementation

**What happens**:
- Read exploration and spec
- Design components and interfaces
- Plan data flow
- Define testing strategy

**Output**:
- `docs/plans/<feature>-arch.md` (architecture)
- `docs/plans/<feature>-plan.md` (implementation plan)

**Command**: `/tdd-workflow:architect <feature>`

**When complete**: Technical design is documented and ready for review

---

### Phase 4: REVIEW-PLAN
**Purpose**: Challenge and validate before implementation

**What happens**:
- Challenge assumptions
- Identify gaps
- Ask follow-up questions
- Get explicit approval

**Output**: User approval to proceed

**Command**: `/tdd-workflow:review-plan <feature>`

**When complete**: All blockers resolved, user approves plan

---

### ⚠️ FRESH SESSION TRANSITION

**Why**: Thariq Shihab recommends starting fresh for implementation
- Prevents context pollution
- Implementation starts clean with just spec files
- Avoids carrying planning baggage into coding

**How**:
```
/clear
```

Then load the spec:
```
/tdd-workflow:implement <feature> --max-iterations N
```

---

### Phase 5: IMPLEMENT
**Purpose**: TDD implementation via ralph-loop

**What happens**:
- Reads all planning artifacts
- Invokes ralph-loop with TDD prompt
- Iterates: RED → GREEN → REFACTOR
- Commits at each phase transition

**Output**: Working code with full test coverage

**Command**: `/tdd-workflow:implement <feature> --max-iterations N`

**Required**: `--max-iterations` flag (safety limit)

**Suggested values**:
- Small feature (1-3 files): 10-15
- Medium feature (4-10 files): 20-30
- Large feature (10+ files): 40-50

**When complete**: "TDD_COMPLETE" output, all tests pass

---

### Phase 6: REVIEW
**Purpose**: Verify implementation quality

**What happens**:
- Check CLAUDE.md compliance
- Verify test coverage
- Security review
- Spec compliance check
- Confidence-scored findings

**Output**: Review report with Critical/Warning/Suggestion findings

**Command**: `/tdd-workflow:review`

**When complete**: All critical issues resolved

---

## Guiding Users Through Phases

### Starting the Workflow

When user invokes `/tdd-workflow:start <feature>`:

1. Acknowledge the feature
2. Explain the workflow overview
3. Start Phase 1: EXPLORE immediately
4. After each phase, prompt for next phase

### Phase Transitions

After completing each phase:

```markdown
## ✅ Phase [N] Complete

[Summary of what was accomplished]

### Output Files
- [list of files created]

### Next Step

Ready to proceed to Phase [N+1]: [PHASE_NAME]?

[Brief description of what will happen next]

To continue: `/tdd-workflow:[next-command] <feature>`
```

### Handling User Questions

If user asks about process:
- Explain current phase
- Show progress in workflow
- Clarify what's needed to proceed

If user seems lost:
- Show workflow diagram
- Identify current position
- Suggest next action

If user wants to skip phases:
- Warn about consequences
- Allow if they insist
- Document what was skipped

### Error Recovery

If a phase fails or user wants to redo:

```markdown
## Phase Recovery Options

1. **Redo current phase**: `/tdd-workflow:[current] <feature>`
2. **Go back one phase**: [explain what to redo]
3. **Start over**: `/tdd-workflow:start <feature>`
```

## Key Quotes to Remember

> "A good plan is really important to avoid issues down the line." - Boris Cherny

> "Start a fresh session to execute the completed spec." - Thariq Shihab

> "Ask questions in all caps, record answers, cover feature, UX, UI, architecture, API, security, edge cases, test requirements, and pushback on idealistic ideas." - Mo Bitar

> "Give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

## Quick Reference

| Phase | Command | Key Action |
|-------|---------|------------|
| 1. Explore | `/tdd-workflow:explore <f>` | Understand codebase |
| 2. Plan | `/tdd-workflow:plan <f>` | Interview (40+ questions) |
| 3. Architect | `/tdd-workflow:architect <f>` | Design technical approach |
| 4. Review Plan | `/tdd-workflow:review-plan <f>` | Challenge & approve |
| 5. Implement | `/tdd-workflow:implement <f> --max-iterations N` | TDD via ralph-loop |
| 6. Review | `/tdd-workflow:review` | Verify quality |

## Dependencies

- **Required**: `ralph-loop` plugin for Phase 5
- **Optional**: Test framework (pytest, jest, vitest, go test, cargo test)

## Integration with Debug Workflow

If bugs are discovered during implementation or review:

```
/debug-workflow:debug <bug description>
```

This switches to the hypothesis-driven debugging workflow.
