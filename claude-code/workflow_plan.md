# Building a planning-heavy, TDD-driven Claude Code workflow

Claude Code workflows achieve exceptional results when they **front-load planning through structured user interviews, enforce TDD feedback loops, and manage context intelligently through subagents and persistent files**. This report synthesizes insights from Boris Cherny (Claude Code creator), Thariq Shihab (Anthropic engineer), official documentation, and expert practitioners to provide a complete workflow blueprint.

## The interview-first planning approach transforms outcomes

Boris Cherny emphasizes that "a good plan is really important to avoid issues down the line," while Thariq Shihab's spec-based development method has garnered **1.7 million views** on X for good reason: it inverts the traditional prompting relationship by having Claude interview *you*.

**Thariq's exact workflow:**
1. Start with a minimal spec or prompt
2. Ask Claude to interview you using the `AskUserQuestionTool`
3. For large features, expect **40+ questions** covering technical implementation, UI/UX, concerns, and tradeoffs
4. Start a fresh session to execute the completed spec

The interview command Thariq uses (saved as a slash command):

```markdown
---
description: Interview me about the plan
model: opus
---

Read this plan file $1 and interview me in detail using the AskUserQuestionTool about 
literally anything: technical implementation, UI & UX, concerns, tradeoffs, etc. 
but make sure the questions are not obvious.

Be very in-depth and continue interviewing me continually until it's complete, 
then write the spec to the file.
```

Mo Bitar refined this into a conversational "interrogation method" where Claude asks **one question at a time** like a journalist, producing 1,000-line transcripts that leave no gaps. The key instruction: "ask questions in all caps, record answers to transcript file, cover feature, UX, UI, architecture, API, security, edge cases, test requirements, and pushback on idealistic ideas."

## CLAUDE.md persists across context compaction—use it strategically

A critical finding from official documentation: **CLAUDE.md is automatically re-injected after context compaction**. This makes it the primary mechanism for persistent project memory. The file hierarchy works as follows:

| Location | Scope | Best Use |
|----------|-------|----------|
| `~/.claude/CLAUDE.md` | Global (all projects) | Personal coding preferences |
| `./CLAUDE.md` | Project root | Team-shared conventions, checked into git |
| `./CLAUDE.local.md` | Project root (gitignored) | Personal project overrides |
| `.claude/rules/*.md` | Path-specific | Context-aware rules using frontmatter patterns |

Boris Cherny's team maintains a shared CLAUDE.md that the entire Claude Code team contributes to multiple times weekly. Their practice: **whenever Claude makes an error, add a rule to prevent it next time**. This creates a self-improving system where code review becomes training data.

Keep CLAUDE.md under **300 lines** (HumanLayer keeps theirs under 60). Every instruction should be actionable. Use imports for progressive disclosure:

```markdown
# Core project conventions
See @docs/architecture.md for system design
See @docs/testing-guide.md for TDD workflow

## Commands  
- `npm run test:watch`: TDD mode
- `npm run typecheck`: Run before commits

## Code Style
- Use ES modules, destructure imports
- Type hints required on all functions
```

For complex plans that must survive compaction, **write them to external files** (`Plan.md`, `SPEC.md`) rather than relying on conversation context. These files can be referenced in new sessions and serve as checklists.

## Structuring subagents for context isolation and TDD

Subagents are Claude Code's mechanism for preventing context pollution—each operates in its own context window and returns only summaries to the main conversation. Official documentation recommends using subagents "to verify details or investigate particular questions, especially early on in a conversation."

**Built-in subagents by model and purpose:**

| Subagent | Model | Tools | When to Use |
|----------|-------|-------|-------------|
| Explore | Haiku | Glob, Grep, Read, limited Bash | Fast codebase searching |
| Plan | Sonnet | Read, Glob, Grep, Bash | Read-only research during planning |
| General-purpose | Sonnet | All tools | Complex multi-step tasks |

For TDD workflows, create specialized subagents that enforce phase separation. The problem with single-context TDD is implementation knowledge "bleeds" into test logic. The solution is **subagent orchestration**:

```markdown
# .claude/agents/test-designer.md
---
name: test-designer
description: Design failing tests for RED phase. Cannot access implementation code.
tools: Read, Grep, Glob
model: sonnet
---

You are a test specification designer. Your role is strictly RED phase:
1. Analyze requirements provided
2. Design comprehensive test cases including edge cases
3. Write failing tests that define expected behavior
4. You CANNOT write implementation code—only tests

Output failing tests with clear assertions that document expected behavior.
```

```markdown
# .claude/agents/implementer.md
---
name: minimal-implementer  
description: GREEN phase only. Write minimal code to pass existing tests.
tools: Read, Write, Bash
model: sonnet
---

You implement the GREEN phase of TDD:
1. Read the failing tests
2. Write MINIMAL code to make tests pass
3. Run tests after each change
4. Stop when all tests are green
5. Do NOT refactor, do NOT add untested features
```

## The Ralph Wiggum loop enables autonomous iteration

The Ralph Wiggum pattern, created by Geoffrey Huntley and packaged into an official plugin by Boris Cherny, implements **autonomous iteration loops** where Claude works on a task continuously until completion criteria are met.

**How it works:** The plugin uses a Stop hook that intercepts Claude's exit attempts (exit code 2), feeds the same prompt back, and lets Claude observe its own modifications through git history and file changes. The prompt stays constant, but the codebase evolves.

**Installation:**
```bash
/plugin marketplace add anthropics/claude-code
/plugin install ralph-wiggum
```

**Commands:**
- `/ralph-loop "<prompt>" --max-iterations N` — Start autonomous loop
- `/ralph-loop "<prompt>" --max-iterations N --completion-promise "DONE"` — Stop when Claude outputs exact text
- `/cancel-ralph` — Kill active loop

**Critical safety rule:** ALWAYS set `--max-iterations`. This is your primary safety net. Fifty-iteration loops can cost **$50-100+** in API credits. The `--completion-promise` flag uses exact string matching and shouldn't be relied upon alone.

For TDD-driven implementation with Ralph Wiggum:

```bash
/ralph-loop "Implement user authentication following strict TDD:

RED PHASE:
1. Write ONE failing test for next requirement
2. Run tests, confirm it fails

GREEN PHASE:
3. Write MINIMAL code to pass the test
4. Run tests

REFACTOR PHASE:
5. Refactor if needed, keeping tests green

Requirements:
- JWT token generation
- Password hashing with bcrypt
- Login endpoint with validation
- Protected route middleware

Continue until all requirements have passing tests.
When complete, output: <promise>TDD_COMPLETE</promise>" --max-iterations 30 --completion-promise "TDD_COMPLETE"
```

Real-world results demonstrate the pattern's power: Geoffrey Huntley built an entire programming language compiler over a 3-month loop. A Y Combinator hackathon team shipped 6 repositories overnight for $297 in API costs.

## Complete workflow structure with slash commands

Based on all sources, here's the recommended workflow structure:

### Phase 1: Planning (invest heavily)

Create `.claude/commands/plan-feature.md`:
```markdown
---
description: Deep planning through user interview
model: opus
---

# Feature Planning Interview

You are conducting a comprehensive planning interview. Your goal is to produce 
a complete, unambiguous specification before any code is written.

## Interview Process

Use AskUserQuestionTool to interview me about: $ARGUMENTS

Ask questions ONE AT A TIME about:
1. Core functionality and user goals
2. Technical constraints and preferences  
3. UI/UX requirements (if applicable)
4. Edge cases and error handling
5. Security considerations
6. Testing requirements
7. Integration points with existing code
8. Performance requirements
9. Deployment considerations

Ask NON-OBVIOUS questions. Challenge idealistic assumptions.
Continue until you have complete clarity on ALL aspects.

When interview is complete:
1. Write comprehensive spec to `docs/specs/$ARGUMENTS.md`
2. Create implementation plan in `docs/plans/$ARGUMENTS-plan.md` with phases
3. Define test cases in `docs/plans/$ARGUMENTS-tests.md`

Output "PLANNING_COMPLETE" when done.
```

### Phase 2: Implementation (TDD with Ralph Wiggum)

Create `.claude/commands/implement-tdd.md`:
```markdown
---
description: TDD implementation of a planned feature
model: opus
---

# TDD Implementation

Read the specification at docs/specs/$ARGUMENTS.md
Read the plan at docs/plans/$ARGUMENTS-plan.md  
Read the test requirements at docs/plans/$ARGUMENTS-tests.md

Follow STRICT Test-Driven Development:

## For each requirement in the plan:

### RED PHASE
- Write ONE failing test that defines expected behavior
- Use the test-designer subagent for complex test design
- Run tests, confirm failure with meaningful assertion message
- Commit: `git commit -m "red: test for <requirement>"`

### GREEN PHASE  
- Write MINIMAL code to pass the test
- No extra features, no premature optimization
- Run tests after each change
- Commit when green: `git commit -m "green: <requirement>"`

### REFACTOR PHASE
- Improve code quality while keeping tests green
- Apply DRY, extract functions, improve naming
- Run tests after each refactor
- Commit: `git commit -m "refactor: <description>"`

## Verification
After each major component, use the code-reviewer subagent to verify quality.

Continue until all planned requirements have passing tests.
Output "IMPLEMENTATION_COMPLETE" when done.
```

### Phase 3: Review (multi-agent verification)

Create `.claude/agents/comprehensive-reviewer.md`:
```markdown
---
name: comprehensive-reviewer
description: Multi-aspect code review with confidence scoring
tools: Read, Grep, Glob, Bash
model: sonnet
---

You perform comprehensive code review. Run these checks:

1. CLAUDE.md COMPLIANCE
   - Compare code against project conventions
   - Flag any violations

2. TEST COVERAGE
   - Verify all code paths have tests
   - Check edge case coverage
   - Run: npm run test:coverage

3. SECURITY REVIEW
   - Check for exposed secrets
   - Validate input sanitization
   - Review authentication/authorization

4. CODE QUALITY
   - Check for code smells
   - Verify error handling
   - Review naming and structure

5. SPEC COMPLIANCE
   - Compare implementation against specification
   - Flag any deviations or missing requirements

Score each finding 0-100 confidence. Report only findings ≥80 confidence.
Organize by: Critical (must fix) → Warnings (should fix) → Suggestions
```

Create `.claude/commands/review-implementation.md`:
```markdown
---
description: Review implementation against spec using Ralph Wiggum
model: opus
---

# Implementation Review Loop

Read specification at docs/specs/$ARGUMENTS.md

## Review Process

1. Use comprehensive-reviewer subagent on all changed files
2. For each critical finding:
   - Fix the issue
   - Add/update tests
   - Run test suite
3. For each warning:
   - Evaluate if fix is warranted
   - Fix if yes, document if no
4. Update documentation for any behavior changes

## Verification
- All tests passing
- No critical findings remain
- Spec compliance verified

Continue reviewing until no critical issues remain.
Output "REVIEW_COMPLETE" when done.
```

## Context management across long sessions

**Context compaction behavior:** Auto-compact triggers at ~95% capacity, preserving architectural decisions, unresolved bugs, and implementation details while discarding verbose tool outputs. The five most recently accessed files are retained alongside the compressed summary.

**Best practices for long-running workflows:**

1. **Manual compact at strategic breakpoints** (~70-80% capacity):
   ```
   /compact Focus on: current phase, test results, remaining tasks, key decisions
   ```

2. **Write state to external files** before complex operations:
   - Plans persist in `docs/plans/`
   - Specs persist in `docs/specs/`
   - Progress tracking in `TODO.md`

3. **Use subagents for verbose operations** like codebase exploration—only results return to main context

4. **Start fresh sessions between phases** per Thariq's recommendation: complete planning, start new session with spec for implementation

5. **Disable unused MCP servers** with `/mcp` before resource-intensive work—a single MCP server with 20 tools can consume ~14,000 tokens

6. **Session handoff pattern** when context exhausted:
   - Ask Claude to write recovery document with all necessary context
   - Review and edit the document  
   - Start fresh session, load document as context

## Official plugins to install

Boris Cherny uses several plugins that align with this workflow:

```bash
# Official plugin marketplace
/plugin marketplace add anthropics/claude-code

# Core workflow plugins
/plugin install ralph-wiggum        # Autonomous iteration loops
/plugin install code-simplifier     # Clean up after long sessions
/plugin install pr-review-toolkit   # Comprehensive multi-agent review

# TDD enforcement (community)
npm install -g tdd-guard           # Blocks implementation without failing tests
```

The **pr-review-toolkit** runs 6 specialized agents in parallel: comment-analyzer, pr-test-analyzer, silent-failure-hunter, type-design-analyzer, code-reviewer, and code-simplifier.

## Hooks configuration for automatic feedback

Configure automatic formatting and testing in `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {"type": "command", "command": "npm run format || true"},
          {"type": "command", "command": "npm run test:affected || true"}
        ]
      }
    ]
  },
  "permissions": {
    "allow": [
      "Bash(npm run test*)",
      "Bash(npm run build*)",
      "Bash(npm run format*)",
      "Bash(git *)"
    ]
  }
}
```

This ensures tests run after every code change, providing immediate TDD feedback without blocking the agent.

## Conclusion: the investment-return structure

The workflow's power comes from its deliberate front-loading. By investing **40+ questions** worth of planning interview before writing code, you eliminate the ambiguity that causes costly rework. TDD then provides continuous verification that implementation matches intent, while Ralph Wiggum enables autonomous iteration toward well-defined goals.

The key insight from Boris Cherny: "Give Claude a way to verify its work. If Claude has that feedback loop, it will **2-3x the quality of the final result**."

Structure your CLAUDE.md for persistence, use subagents for context isolation, write plans to external files, and leverage the Ralph Wiggum loop for both implementation and review phases. The combination produces workflows where overnight runs can complete significant features autonomously—the Y Combinator team's $297 for six shipped repositories demonstrates what's possible when planning, feedback loops, and context management align.