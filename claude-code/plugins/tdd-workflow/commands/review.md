---
description: Comprehensive code review of implementation
model: opus
argument-hint: <feature>
---

# Code Review

Reviewing the implementation of the most recent feature.

## Process

Use the `code-reviewer` agent to perform comprehensive review of:
1. Changed files (from recent commits)
2. New test coverage
3. Spec compliance
4. CLAUDE.md adherence

## What Gets Reviewed

The code-reviewer will check:

### 1. CLAUDE.md Compliance
- Does code follow project conventions?
- Are patterns consistent with existing code?
- Is naming appropriate?

### 2. Test Coverage
- Are all code paths tested?
- Are edge cases covered?
- Are error paths tested?

### 3. Security
- Is input validated?
- Are secrets protected?
- Is authentication/authorization correct?

### 4. Code Quality
- Is there code duplication?
- Are functions too long?
- Is error handling appropriate?

### 5. Spec Compliance
- Does implementation match specification?
- Are all requirements addressed?
- Are any features missing?

## Output

The review produces confidence-scored findings:

**Only findings with ≥80% confidence are reported.**

Categories:
- ❌ **Critical** - Must fix before merge
- ⚠️ **Warning** - Should fix, but not blocking
- 💡 **Suggestion** - Consider for improvement

## Finding Changes

To see what changed:

```bash
# Recent commits
git log --oneline -10

# Changed files
git diff HEAD~[N] --name-only

# Specific file diff
git diff HEAD~[N] path/to/file
```

## After Review

If critical issues found:
1. Fix each issue
2. Run tests
3. Commit fixes
4. Re-run review

If all clear:
- Implementation is ready for merge
- Create PR with `/commit` or manually

## Next Steps

After successful review:
```bash
# Commit if not already done
/commit

# Create PR
/main-pr
```
