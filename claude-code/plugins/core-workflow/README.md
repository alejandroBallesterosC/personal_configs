# core-workflow

A lean set of commands, skills, and an agent for the day-to-day work that still benefits from a bit of structure: TDD, debugging, plan review, research rigor, LaTeX reports, understanding a codebase, and reviewing what collaborators have pushed.

No hooks. No workflow state machines. Skills are checklists Claude applies directly; commands are one-shot orchestrations of parallel subagents.

## Commands

| Command | Purpose |
|---------|---------|
| `/core-workflow:readonly <prompt>` | Run a prompt in read-only mode (no file edits, no git changes) |
| `/core-workflow:research <topic>` | Thorough internet research via waves of parallel `web-researcher` subagents |
| `/core-workflow:understand-repo` | Single-pass codebase understanding: 5 parallel explorers, an architecture diagram, and a prioritized reading list |
| `/core-workflow:compare-branch-to-another <other-branch>` | Compare the current branch against another using 5 parallel analysis agents |
| `/core-workflow:explain-all-changes-since <date-time> [timezone]` | Fetch all remote branches and summarize what collaborators (not you) pushed since a cutoff |
| `/core-workflow:explain-branch-changes-since <date-time-or-commit> [timezone]` | Fetch your branch's upstream and summarize what collaborators pushed to it since a cutoff |

All commands are read-only: no file edits, no commits, no pushes.

## Skills

| Skill | Purpose |
|-------|---------|
| `tdd-discipline` | RED/GREEN/REFACTOR cycle guidance, real-APIs-over-mocks rule, boundary testing |
| `structured-debug` | Hypothesis-driven debugging: the Iron Law, the 3-Fix Rule, tagged instrumentation |
| `using-git-worktrees` | Safe worktree creation with gitignore verification |
| `adversarial-plan-review` | Evidence-to-decision audit, assumption inversion, and cross-artifact consistency checks for critiquing a plan before implementation |
| `research-methodology` | Evidence rigor discipline — what a source proves vs. asserts, gap ratings, overstatement audits |
| `latex-report` | Argument-driven LaTeX report structure, single-voice writing discipline, and the pdflatex/bibtex compile pipeline |

Skills activate automatically when the request matches their description, or can be invoked directly.

## Agent

- `web-researcher` — internet research specialist used by `/research`, spawnable standalone for parallel research tasks.

## Dependencies

None required. `pdflatex`/MacTeX is an optional dependency for the `latex-report` skill's PDF compilation step only — if missing, the skill produces a valid `.tex` file and skips compilation.

## Installation

```
/plugin install core-workflow
```
