# TDD Workflow Plugin

A planning-heavy, TDD-driven development workflow for Claude Code based on best practices from Boris Cherny, Thariq Shihab, Mo Bitar, and Geoffrey Huntley.

## Quick Start

```bash
/tdd-workflow:start user-authentication
```

This single command guides you through the entire workflow.

## Overview

This plugin implements a 6-phase workflow that front-loads planning to eliminate ambiguity, then executes implementation with strict TDD and autonomous iteration.

## Workflow Phases

```
1. EXPLORE        2. PLAN           3. ARCHITECT      4. REVIEW-PLAN
code-explorer     AskUserQuestion   code-architect    plan-reviewer
agent             (40+ questions)   agent             agent

                  ↓ START FRESH SESSION (recommended)

5. IMPLEMENT                        6. REVIEW
ralph-loop with TDD agents          code-reviewer agent
```

## Commands

| Command | Purpose |
|---------|---------|
| `/tdd-workflow:start <feature>` | **Start full guided workflow** |
| `/tdd-workflow:explore <feature>` | Deep codebase analysis + CLAUDE.md synthesis |
| `/tdd-workflow:plan <feature>` | Interview-based spec development (40+ questions) |
| `/tdd-workflow:architect <feature>` | Technical design from spec + exploration |
| `/tdd-workflow:review-plan <feature>` | Challenge plan, find gaps, ask follow-ups |
| `/tdd-workflow:implement <feature> --max-iterations N` | TDD via ralph-loop |
| `/tdd-workflow:review` | Confidence-scored code review |
| `/tdd-workflow:help` | Show this help |

## Usage

```bash
# 1. Explore codebase
/tdd-workflow:explore user-auth

# 2. Plan feature (answer 10-40 questions)
/tdd-workflow:plan user-auth

# 3. Design architecture
/tdd-workflow:architect user-auth

# 4. Review plan (answer follow-up questions)
/tdd-workflow:review-plan user-auth

# 5. Start fresh session for implementation (recommended)
/clear

# 6. Implement with TDD
/tdd-workflow:implement user-auth --max-iterations 20

# 7. Review implementation
/tdd-workflow:review
```

## Dependencies

- **Required**: `ralph-loop` plugin installed
- **Optional**: Project has test framework (pytest, jest, vitest, go test, cargo test)

## Agents

| Agent | Phase | Purpose |
|-------|-------|---------|
| code-explorer | Explore | Deep codebase analysis, CLAUDE.md synthesis |
| code-architect | Architect | Technical design from spec |
| plan-reviewer | Review Plan | Challenge assumptions, find gaps |
| test-designer | Implement (RED) | Write failing tests only |
| implementer | Implement (GREEN) | Minimal code to pass tests |
| refactorer | Implement (REFACTOR) | Improve while keeping tests green |
| code-reviewer | Review | Confidence-scored findings |

## Skills

| Skill | Purpose |
|-------|---------|
| tdd-workflow-guide | Guides you through each phase of the workflow |
| tdd-guide | TDD cycle guidance (RED → GREEN → REFACTOR) |
| writing-plans | Creating implementation plans with bite-sized tasks |
| writing-claude-md | CLAUDE.md best practices and maintenance |
| infrastructure-as-code | Terraform + AWS best practices |
| using-git-worktrees | Isolated workspace creation for feature work |

> **Note**: For debugging, see the separate `debug-workflow` plugin.

## Philosophy

Based on insights from:
- **Boris Cherny**: Parallel exploration, Opus for everything, shared CLAUDE.md
- **Thariq Shihab**: Interview-first spec development, fresh sessions between phases
- **Mo Bitar**: Interrogation method, pushback on idealistic ideas
- **Geoffrey Huntley**: Ralph Wiggum autonomous loops
