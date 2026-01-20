# Parallel Claude Code Orchestrator Specification

> **Status**: Draft
> **Created**: 2026-01-19
> **Author**: jandro
> **Related**: `claude-code/plugins/tdd-workflow/`

## 1. Executive Summary

This specification defines a CLI tool that orchestrates multiple parallel Claude Code instances for TDD-driven development workflows. The tool manages git worktrees, tmux sessions, and provides a unified interface for monitoring and evaluating parallel implementations.

### Goals

1. **Parallel Exploration**: Run 3+ Claude instances exploring different aspects of a codebase simultaneously
2. **Best-of-N Implementation**: Generate N parallel implementations of the same spec, select the best
3. **Adversarial Review**: Multi-stage review where reviewers challenge each other's findings
4. **Subtask Decomposition**: Split large features into independent subtasks executed in parallel

### Non-Goals

- Replacing Claude Code's built-in subagent system (complementary, not replacement)
- Building a general-purpose agent orchestration framework
- Supporting non-Claude Code agents (initially)

---

## 2. Background & Research

### Expert Practices

| Source | Key Insight |
|--------|-------------|
| **Boris Cherny** | Runs 5 parallel local instances + 5-10 web sessions using separate git checkouts |
| **Anthropic Multi-Agent System** | Orchestrator-worker pattern with 3-5 parallel subagents outperforms single-agent by 90.2% |
| **Simon Willison** | Sweet spot is 2-3 concurrent agents; beyond that coordination overhead exceeds benefits |
| **Best-of-N Research** | N=8 samples significantly outperforms greedy decoding for code generation |

### Existing Tools

| Tool | Approach | Limitations |
|------|----------|-------------|
| **Claude Squad** | Go TUI, tmux sessions, git worktrees | No spec-based orchestration, no evaluation |
| **Agent of Empires** | Rust TUI, tmux wrapper | No TDD integration, no winner selection |
| **Claude-Flow** | MCP server, swarm intelligence | Complex, enterprise-focused, overkill for TDD |
| **libtmux** | Python API for tmux | Low-level, requires building everything |

### Decision: Build on Claude Squad OR libtmux

**Option A: Extend Claude Squad**
- Pros: Session management, worktrees, TUI already built
- Cons: Go codebase, may need significant modifications

**Option B: Build with libtmux**
- Pros: Python (matches Claude Agent SDK), full control, simpler
- Cons: More code to write, no existing TUI

**Recommendation**: Start with **libtmux** for tighter integration with:
- Claude Agent SDK (Python)
- Existing tdd-workflow plugin patterns
- Custom evaluation and selection logic

---

## 3. Architecture

### High-Level Design

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         tdd-parallel CLI                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │ Orchestrator│───▶│   Spawner   │───▶│  Evaluator  │                 │
│  │   (main)    │    │ (workers)   │    │  (select)   │                 │
│  └─────────────┘    └─────────────┘    └─────────────┘                 │
│         │                  │                  │                         │
│         ▼                  ▼                  ▼                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │   Config    │    │   tmux      │    │    Git      │                 │
│  │   Loader    │    │   Manager   │    │   Manager   │                 │
│  └─────────────┘    └─────────────┘    └─────────────┘                 │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
            ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
            │  Worker 1   │ │  Worker 2   │ │  Worker 3   │
            │ (worktree)  │ │ (worktree)  │ │ (worktree)  │
            │ (tmux pane) │ │ (tmux pane) │ │ (tmux pane) │
            │ (claude)    │ │ (claude)    │ │ (claude)    │
            └─────────────┘ └─────────────┘ └─────────────┘
```

### Component Responsibilities

| Component | Responsibility |
|-----------|----------------|
| **Orchestrator** | Main control loop, state management, user interaction |
| **Config Loader** | Read specs, plans, and workflow configuration |
| **Spawner** | Create worktrees, tmux panes, launch Claude instances |
| **tmux Manager** | Pane creation, layout, output capture, session lifecycle |
| **Git Manager** | Worktree creation/cleanup, branch management, merging |
| **Evaluator** | Run tests, compare implementations, select winner |

### Data Flow

```
1. User invokes: tdd-parallel implement user-auth --best-of 3

2. Orchestrator:
   ├── Loads spec from docs/specs/user-auth.md
   ├── Loads plan from docs/plans/user-auth-plan.md
   └── Validates prerequisites

3. Spawner:
   ├── Creates 3 git worktrees (.worktrees/worker-{1,2,3})
   ├── Creates tmux session with 4 panes (1 orchestrator + 3 workers)
   └── Launches Claude Code in each worker pane with TDD prompt

4. Orchestrator (monitoring loop):
   ├── Captures output from each pane periodically
   ├── Detects phase transitions (RED/GREEN/REFACTOR)
   ├── Updates status display
   └── Detects completion ("TDD_COMPLETE" or max iterations)

5. Evaluator (on completion):
   ├── Runs test suite in each worktree
   ├── Collects metrics (pass rate, coverage, code quality)
   ├── Selects winner based on criteria
   └── Optionally merges winner to target branch

6. Cleanup:
   ├── Archives losing worktrees (or deletes)
   ├── Merges winning branch
   └── Cleans up tmux session
```

---

## 4. Workflows

### 4.1 Parallel Exploration

**Purpose**: Gather comprehensive codebase context before planning.

**Process**:
1. Spawn 3 parallel explorers with different focus areas:
   - Explorer 1: Architecture & patterns
   - Explorer 2: Testing strategy & coverage
   - Explorer 3: Dependencies & integration points
2. Each writes findings to separate files
3. Orchestrator synthesizes into unified exploration document

**CLI**:
```bash
tdd-parallel explore user-auth --workers 3
```

**Output**:
- `docs/context/user-auth-exploration.md` (synthesized)
- `docs/context/user-auth-arch.md` (worker 1)
- `docs/context/user-auth-tests.md` (worker 2)
- `docs/context/user-auth-deps.md` (worker 3)

### 4.2 Best-of-N Implementation

**Purpose**: Generate multiple implementations, select the best.

**Process**:
1. Create N git worktrees from same base commit
2. Launch Claude Code in each with identical spec/prompt
3. Each implements using TDD (RED-GREEN-REFACTOR)
4. On completion, evaluate all implementations
5. Select winner based on:
   - Test pass rate (primary)
   - Code coverage
   - Code complexity (cyclomatic)
   - Claude self-review score
6. Merge winner to target branch

**CLI**:
```bash
tdd-parallel implement user-auth \
    --best-of 3 \
    --spec docs/specs/user-auth.md \
    --max-iterations 25 \
    --auto-merge
```

**Evaluation Criteria** (configurable weights):

| Criterion | Weight | How Measured |
|-----------|--------|--------------|
| Tests pass | 40% | pytest exit code |
| Coverage | 20% | pytest-cov percentage |
| Complexity | 15% | radon cc average |
| Self-review | 15% | Claude rates own code 1-10 |
| Speed | 10% | Iterations to complete |

### 4.3 Adversarial Review

**Purpose**: High-quality code review through challenge/response.

**Process**:
1. **Stage 1 (Find)**: Spawn 3-5 reviewer agents in parallel
   - Each reviews changed files independently
   - Produces list of findings with confidence scores
2. **Stage 2 (Challenge)**: Spawn 3-5 challenger agents
   - Each challenges a different reviewer's findings
   - Marks findings as: CONFIRMED, REJECTED, NEEDS_CLARIFICATION
3. **Synthesis**: Merge findings that survived challenge
   - Report only findings with ≥2 confirmations
   - Or confidence ≥90%

**CLI**:
```bash
tdd-parallel review \
    --reviewers 5 \
    --challengers 5 \
    --min-confidence 80
```

**Output**:
```markdown
# Code Review: user-auth

## Critical (must fix)
- [ ] SQL injection in login handler (3/5 reviewers, 2/3 challengers confirmed)

## Warnings (should fix)
- [ ] Missing rate limiting on auth endpoints (4/5 reviewers, all confirmed)

## Rejected Findings
- "Unused import" - REJECTED: import used in type hint
```

### 4.4 Subtask Decomposition

**Purpose**: Parallelize implementation of independent subtasks.

**Process**:
1. Orchestrator (or user) decomposes plan into independent subtasks
2. Each subtask assigned to a worker with its own worktree
3. Workers implement in parallel
4. On completion, merge all branches (resolve conflicts if any)

**CLI**:
```bash
tdd-parallel implement user-auth \
    --decompose \
    --workers 3 \
    --plan docs/plans/user-auth-plan.md
```

**Decomposition Rules**:
- Subtasks must be independent (no shared files)
- Each subtask has its own test file
- Orchestrator validates independence before spawning

---

## 5. CLI Interface

### Commands

```
tdd-parallel <command> [options]

Commands:
  explore      Parallel codebase exploration
  implement    Best-of-N or decomposed implementation
  review       Adversarial multi-stage code review
  status       Show status of running orchestration
  attach       Attach to worker pane
  evaluate     Manually trigger evaluation
  cleanup      Remove worktrees and tmux session
  config       Manage configuration

Global Options:
  --verbose, -v      Verbose output
  --config, -c       Path to config file
  --dry-run          Show what would be done without doing it
```

### Command: `explore`

```
tdd-parallel explore <feature> [options]

Arguments:
  feature            Feature name for file naming

Options:
  --workers, -n      Number of parallel explorers (default: 3)
  --focus            Comma-separated focus areas (arch,tests,deps,patterns)
  --output, -o       Output directory (default: docs/context/)
  --synthesize       Combine findings into single document (default: true)

Example:
  tdd-parallel explore user-auth --workers 3 --focus arch,tests,deps
```

### Command: `implement`

```
tdd-parallel implement <feature> [options]

Arguments:
  feature            Feature name

Options:
  --best-of, -n      Number of parallel implementations (default: 3)
  --decompose        Split into subtasks instead of best-of-N
  --spec, -s         Path to spec file (required)
  --plan, -p         Path to plan file (optional, required for --decompose)
  --max-iterations   Max iterations per worker (default: 25)
  --auto-merge       Automatically merge winner (default: false)
  --target-branch    Branch to merge into (default: current branch)
  --keep-losers      Keep losing worktrees for inspection (default: false)

Example:
  tdd-parallel implement user-auth \
      --best-of 3 \
      --spec docs/specs/user-auth.md \
      --max-iterations 30 \
      --auto-merge
```

### Command: `review`

```
tdd-parallel review [options]

Options:
  --reviewers, -r    Number of reviewer agents (default: 5)
  --challengers, -c  Number of challenger agents (default: 5)
  --stages           Number of challenge stages (default: 1)
  --min-confidence   Minimum confidence to report (default: 80)
  --files            Specific files to review (default: changed files)
  --output, -o       Output file for review report

Example:
  tdd-parallel review --reviewers 5 --challengers 5 --min-confidence 80
```

### Command: `status`

```
tdd-parallel status [session-name]

Shows:
  - Active workers and their status
  - Current TDD phase per worker
  - Test results
  - Iteration count
  - Estimated completion

Example output:
  Session: tdd-user-auth (best-of-3)
  Started: 10 minutes ago

  Worker 1: GREEN phase, 12/25 iterations, 8 tests passing
  Worker 2: REFACTOR phase, 15/25 iterations, 10 tests passing
  Worker 3: RED phase, 11/25 iterations, 7 tests passing
```

### Command: `attach`

```
tdd-parallel attach <worker-number>

Attaches terminal to specified worker's tmux pane.
Use Ctrl-B D to detach back to orchestrator.

Example:
  tdd-parallel attach 2
```

---

## 6. Configuration

### Config File: `~/.config/tdd-parallel/config.toml`

```toml
[general]
default_workers = 3
max_iterations = 25
worktree_dir = ".worktrees"
auto_cleanup = true

[tmux]
session_prefix = "tdd"
layout = "tiled"  # or "main-horizontal", "main-vertical"
orchestrator_height = 30  # percent

[git]
branch_prefix = "tdd"
auto_merge = false
keep_losers = false

[evaluation]
test_command = "pytest"
coverage_command = "pytest --cov"
complexity_command = "radon cc -a"

[evaluation.weights]
tests_pass = 40
coverage = 20
complexity = 15
self_review = 15
speed = 10

[claude]
model = "opus"
dangerously_skip_permissions = true
completion_marker = "TDD_COMPLETE"

[explore.focus_areas]
architecture = "Analyze architecture, layers, boundaries, data flow"
testing = "Analyze test framework, patterns, coverage approach"
dependencies = "Analyze internal/external dependencies, integration points"
patterns = "Identify coding patterns, conventions, idioms"
```

### Project-Level Override: `.tdd-parallel.toml`

Placed in project root to override global settings:

```toml
[evaluation]
test_command = "npm test"
coverage_command = "npm run coverage"

[claude]
max_iterations = 40  # Larger project needs more
```

---

## 7. Integration with tdd-workflow Plugin

### New Commands

Add to `claude-code/plugins/tdd-workflow/commands/`:

#### `parallel-explore.md`

```markdown
---
description: Parallel codebase exploration using tdd-parallel CLI
model: opus
argument-hint: <feature>
---

# Parallel Exploration

Launching parallel exploration for: **$ARGUMENTS**

## Prerequisites

Ensure `tdd-parallel` CLI is installed:
```bash
pip install tdd-parallel
# or
uv add tdd-parallel
```

## Execution

Run the following command in your terminal:

```bash
tdd-parallel explore $ARGUMENTS --workers 3 --synthesize
```

This will:
1. Create 3 parallel Claude instances
2. Each explores different aspects (architecture, testing, dependencies)
3. Synthesize findings into `docs/context/$ARGUMENTS-exploration.md`

## After Completion

Proceed with planning:
```
/tdd-workflow:plan $ARGUMENTS
```
```

#### `parallel-implement.md`

```markdown
---
description: Best-of-N parallel TDD implementation
model: opus
argument-hint: <feature> --best-of <N>
---

# Parallel Implementation

Launching best-of-N implementation for: **$ARGUMENTS**

## Prerequisites

Verify planning artifacts exist:
- `docs/specs/$ARGUMENTS.md`
- `docs/plans/$ARGUMENTS-plan.md`
- `docs/plans/$ARGUMENTS-arch.md`

## Execution

Parse the --best-of argument and run:

```bash
tdd-parallel implement $ARGUMENTS \
    --best-of [N] \
    --spec docs/specs/$ARGUMENTS.md \
    --plan docs/plans/$ARGUMENTS-plan.md \
    --max-iterations 25
```

## Monitoring

The CLI will show:
- Orchestrator status in top pane
- Worker progress in bottom panes
- Real-time test results

## Evaluation

On completion, the CLI will:
1. Run tests in all worktrees
2. Measure coverage and complexity
3. Select winner
4. Optionally merge to current branch

## After Completion

Review the implementation:
```
/tdd-workflow:review
```
```

### Updated help.md

Add to the Skills section:

```markdown
## CLI Tools

The plugin integrates with `tdd-parallel` CLI for parallel workflows:

| Command | Purpose |
|---------|---------|
| `tdd-parallel explore` | Parallel codebase exploration |
| `tdd-parallel implement --best-of N` | Best-of-N parallel implementation |
| `tdd-parallel review --adversarial` | Multi-stage adversarial review |
```

---

## 8. Technical Implementation

### Dependencies

```toml
[project]
name = "tdd-parallel"
version = "0.1.0"
requires-python = ">=3.11"

[project.dependencies]
libtmux = ">=0.37.0"
click = ">=8.0.0"
rich = ">=13.0.0"           # TUI components
toml = ">=0.10.0"           # Config parsing
gitpython = ">=3.1.0"       # Git operations
pydantic = ">=2.0.0"        # Config validation

[project.optional-dependencies]
dev = [
    "pytest",
    "pytest-cov",
    "ruff",
    "mypy",
]

[project.scripts]
tdd-parallel = "tdd_parallel.cli:main"
```

### Module Structure

```
tdd_parallel/
├── __init__.py
├── cli.py                 # Click CLI definition
├── orchestrator.py        # Main control loop
├── config.py              # Configuration loading
├── tmux_manager.py        # libtmux wrapper
├── git_manager.py         # Worktree management
├── spawner.py             # Worker creation
├── evaluator.py           # Implementation evaluation
├── prompts/               # Claude prompt templates
│   ├── explore.py
│   ├── implement.py
│   └── review.py
├── models/                # Pydantic models
│   ├── config.py
│   ├── worker.py
│   └── evaluation.py
└── ui/                    # Rich TUI components
    ├── status.py
    └── progress.py
```

### Key Classes

```python
# orchestrator.py
class Orchestrator:
    """Main control loop for parallel workflows."""

    def __init__(self, config: Config):
        self.config = config
        self.tmux = TmuxManager(config.tmux)
        self.git = GitManager(config.git)
        self.spawner = Spawner(self.tmux, self.git)
        self.evaluator = Evaluator(config.evaluation)
        self.workers: list[Worker] = []

    async def run_best_of_n(
        self,
        feature: str,
        spec_path: Path,
        n: int,
        max_iterations: int
    ) -> EvaluationResult:
        """Execute best-of-N implementation workflow."""
        ...

    async def run_exploration(
        self,
        feature: str,
        focus_areas: list[str],
        n: int
    ) -> ExplorationResult:
        """Execute parallel exploration workflow."""
        ...

    async def run_adversarial_review(
        self,
        files: list[Path],
        num_reviewers: int,
        num_challengers: int
    ) -> ReviewResult:
        """Execute adversarial review workflow."""
        ...
```

```python
# tmux_manager.py
class TmuxManager:
    """Wrapper around libtmux for session/pane management."""

    def __init__(self, config: TmuxConfig):
        self.server = libtmux.Server()
        self.config = config
        self.session: Optional[libtmux.Session] = None

    def create_session(self, name: str, num_workers: int) -> None:
        """Create tmux session with orchestrator + worker panes."""
        ...

    def send_to_worker(self, worker_id: int, command: str) -> None:
        """Send command to specific worker pane."""
        ...

    def capture_output(self, worker_id: int, lines: int = 50) -> str:
        """Capture recent output from worker pane."""
        ...

    def detect_completion(self, worker_id: int, marker: str) -> bool:
        """Check if worker has output completion marker."""
        ...
```

```python
# evaluator.py
@dataclass
class EvaluationResult:
    worker_id: int
    tests_passed: bool
    test_count: int
    coverage_percent: float
    complexity_score: float
    self_review_score: float
    iterations: int
    total_score: float

class Evaluator:
    """Evaluate and compare implementations."""

    def __init__(self, config: EvaluationConfig):
        self.config = config

    async def evaluate_worker(self, worktree: Path) -> EvaluationResult:
        """Run all evaluation metrics on a single worktree."""
        ...

    async def evaluate_all(self, worktrees: list[Path]) -> list[EvaluationResult]:
        """Evaluate all worktrees in parallel."""
        ...

    def select_winner(self, results: list[EvaluationResult]) -> EvaluationResult:
        """Select best implementation based on weighted scores."""
        ...
```

---

## 9. UI Design

### Orchestrator Pane Display

```
┌─────────────────────────────────────────────────────────────────────────┐
│ 🎯 TDD Parallel: user-auth (best-of-3)                    [10:32 elapsed]│
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│ Worker 1 ████████████░░░░░░░░ 60%  GREEN   12/25 iter  8 tests ✓       │
│ Worker 2 ██████████████████░░ 90%  REFACT  22/25 iter  10 tests ✓      │
│ Worker 3 ████████░░░░░░░░░░░░ 40%  RED     10/25 iter  6 tests ✓       │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│ Latest Activity:                                                        │
│ [W2] Committed: refactor: extract token validation                      │
│ [W1] Running tests... 8/8 passed                                        │
│ [W3] Writing test for password reset                                    │
├─────────────────────────────────────────────────────────────────────────┤
│ Commands: [1-3] attach worker | [e] evaluate now | [q] quit             │
└─────────────────────────────────────────────────────────────────────────┘
```

### Worker Pane Display

Standard Claude Code output - no modifications needed.

### Evaluation Report

```
┌─────────────────────────────────────────────────────────────────────────┐
│ 🏆 Evaluation Complete: user-auth                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│ Rank │ Worker │ Tests │ Coverage │ Complexity │ Self-Review │ Score    │
│ ─────┼────────┼───────┼──────────┼────────────┼─────────────┼────────  │
│  1   │   2    │ 10/10 │   92%    │    A       │    9/10     │  94.2    │
│  2   │   1    │  8/8  │   85%    │    B       │    8/10     │  82.5    │
│  3   │   3    │  6/6  │   78%    │    B       │    7/10     │  71.3    │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│ Winner: Worker 2 (branch: tdd/user-auth-impl-2)                         │
│                                                                         │
│ [m] Merge to main | [d] Show diff | [k] Keep all | [c] Cleanup losers   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 10. Testing Strategy

### Unit Tests

```python
# tests/test_tmux_manager.py
def test_create_session_with_workers():
    """Session should have orchestrator + N worker panes."""
    manager = TmuxManager(config)
    manager.create_session("test", num_workers=3)

    assert manager.session is not None
    assert len(manager.session.windows) == 1
    assert len(manager.session.windows[0].panes) == 4  # 1 + 3

def test_send_to_worker():
    """Commands should reach correct worker pane."""
    ...

def test_capture_output():
    """Should capture recent pane output."""
    ...
```

```python
# tests/test_evaluator.py
def test_evaluate_passing_tests():
    """Should correctly parse pytest output."""
    ...

def test_select_winner_by_score():
    """Should select highest weighted score."""
    ...
```

### Integration Tests

```python
# tests/integration/test_best_of_n.py
@pytest.mark.integration
async def test_best_of_n_workflow():
    """Full best-of-N workflow with mock Claude responses."""
    # Uses pytest-tmux or similar fixture
    ...
```

### Manual Testing Checklist

- [ ] Create session with 3 workers
- [ ] Workers receive correct prompts
- [ ] Output capture detects TDD phase transitions
- [ ] Completion detection works
- [ ] Evaluation metrics are accurate
- [ ] Winner selection is correct
- [ ] Merge workflow succeeds
- [ ] Cleanup removes worktrees and session

---

## 11. Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **API rate limits** | Workers stall | High | Stagger worker starts, implement backoff |
| **Worktree conflicts** | Merge failures | Medium | Validate independence before spawning |
| **tmux session leaks** | Resource exhaustion | Medium | Always cleanup on exit, periodic GC |
| **Claude hangs** | Worker never completes | Medium | Timeout per worker, iteration limits |
| **Evaluation flakiness** | Wrong winner selected | Low | Multiple evaluation runs, human confirmation |
| **Cost overrun** | High API bills | Medium | Budget limits, iteration caps, cost estimation |

### Cost Estimation

```
Best-of-3 with 25 iterations each:
- ~75 total iterations
- ~5,000 tokens per iteration (input + output)
- ~375,000 tokens total
- ~$15-25 with Opus (depending on thinking)

Recommendation: Show estimated cost before starting.
```

---

## 12. Implementation Phases

### Phase 1: Core Infrastructure (Week 1)

- [ ] Project setup (uv, pyproject.toml, structure)
- [ ] Config loading and validation
- [ ] TmuxManager with session/pane operations
- [ ] GitManager with worktree operations
- [ ] Basic CLI skeleton with Click

### Phase 2: Best-of-N Workflow (Week 2)

- [ ] Spawner implementation
- [ ] Worker status monitoring
- [ ] Completion detection
- [ ] Evaluator with test/coverage metrics
- [ ] Winner selection logic

### Phase 3: UI & Polish (Week 3)

- [ ] Rich-based orchestrator display
- [ ] Progress bars and status updates
- [ ] Evaluation report display
- [ ] Keyboard shortcuts for interaction

### Phase 4: Additional Workflows (Week 4)

- [ ] Parallel exploration
- [ ] Adversarial review
- [ ] Subtask decomposition
- [ ] tdd-workflow plugin integration

### Phase 5: Testing & Documentation (Week 5)

- [ ] Unit test coverage >80%
- [ ] Integration tests
- [ ] README and usage docs
- [ ] Example workflows

---

## 13. Success Criteria

1. **Functional**: Can run best-of-3 implementation end-to-end
2. **Reliable**: 90%+ success rate without manual intervention
3. **Useful**: Winner selection accuracy >80% (validated by human review)
4. **Efficient**: Reduces iteration cycles by 2x compared to single-agent
5. **Integrated**: Works seamlessly with existing tdd-workflow plugin

---

## 14. Open Questions

1. **Should workers share CLAUDE.md context?** Leaning yes - ensures consistency.
2. **How to handle worker that finishes early?** Wait for all, or start evaluating?
3. **Should adversarial review use same or different model for challengers?** Different (Sonnet for challengers) may be more cost-effective.
4. **Support for non-pytest test runners?** Yes, via config - but pytest first.
5. **Cloud/remote worker support?** Out of scope for v1, but architecture should allow.

---

## 15. References

- [Claude Squad](https://github.com/smtg-ai/claude-squad)
- [Agent of Empires](https://github.com/njbrake/agent-of-empires)
- [libtmux Documentation](https://libtmux.git-pull.com/)
- [Claude Agent SDK](https://github.com/anthropics/claude-agent-sdk-python)
- [Anthropic Multi-Agent Research](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Boris Cherny's Workflow](https://howborisusesclaudecode.com/)
- [Best-of-N Sampling Research](https://arxiv.org/abs/2502.12668)
