
# Parallel Multi-Aspect Code Review

**Feature**: $ARGUMENTS

## Objective

Perform comprehensive code review using **5 parallel reviewer agents**, each focusing on a different aspect. Consolidate findings and address critical issues.

---

## LAUNCHING 5 PARALLEL REVIEW AGENTS

Launch all 5 agents **IN PARALLEL** using a single message with 5 Task tool calls.

Use `subagent_type: "code-reviewer"` for all 5 agents, each with a different focus:

### Agent 1: Security Review

```
Feature: $ARGUMENTS

REVIEW FOCUS: Security

Review the implementation for security concerns:

1. **Input Validation**
   - Are all inputs validated?
   - Are there injection vulnerabilities (SQL, XSS, command)?
   - Are inputs sanitized before use?

2. **Authentication & Authorization**
   - Are auth checks in place where needed?
   - Are permissions properly verified?
   - Are there authorization bypasses?

3. **Data Protection**
   - Is sensitive data encrypted?
   - Are secrets properly handled (not hardcoded)?
   - Is PII protected?

4. **API Security**
   - Are API keys protected?
   - Are rate limits in place?
   - Is CORS configured properly?

Report findings with severity:
- 🔴 CRITICAL: Must fix (security vulnerability)
- 🟡 WARNING: Should fix (security concern)
- 🔵 SUGGESTION: Consider (security improvement)
```

### Agent 2: Performance Review

```
Feature: $ARGUMENTS

REVIEW FOCUS: Performance

Review the implementation for performance concerns:

1. **Algorithmic Complexity**
   - Are there O(n²) or worse algorithms?
   - Can any operations be optimized?
   - Are there unnecessary iterations?

2. **Database/Storage**
   - Are queries efficient (N+1 problems)?
   - Are indexes used appropriately?
   - Is data fetched efficiently?

3. **Memory Usage**
   - Are there memory leaks?
   - Are large objects handled properly?
   - Is streaming used where appropriate?

4. **API Calls**
   - Are external calls batched where possible?
   - Is caching used appropriately?
   - Are there unnecessary API calls?

Report findings with impact:
- 🔴 CRITICAL: Significant performance impact
- 🟡 WARNING: Noticeable performance impact
- 🔵 SUGGESTION: Minor optimization opportunity
```

### Agent 3: Code Quality Review

```
Feature: $ARGUMENTS

REVIEW FOCUS: Code Quality

Review the implementation for code quality:

1. **CLAUDE.md Compliance**
   - Does code follow project conventions?
   - Are naming conventions followed?
   - Is code style consistent?

2. **Code Organization**
   - Is code well-structured?
   - Are responsibilities properly separated?
   - Is there code duplication?

3. **Error Handling**
   - Are errors handled appropriately?
   - Are error messages helpful?
   - Is error propagation correct?

4. **Maintainability**
   - Is code readable?
   - Are complex sections documented?
   - Is the code easy to modify?

Report findings with confidence scores (only report ≥80%):
- 🔴 CRITICAL: Significant quality issue
- 🟡 WARNING: Quality concern
- 🔵 SUGGESTION: Quality improvement
```

### Agent 4: Test Coverage Review

```
Feature: $ARGUMENTS

REVIEW FOCUS: Test Coverage

Review the tests for completeness:

1. **Code Path Coverage**
   - Are all code paths tested?
   - Are conditional branches covered?
   - Are loops tested (0, 1, many)?

2. **Edge Case Coverage**
   - Are boundary conditions tested?
   - Are null/empty inputs tested?
   - Are error conditions tested?

3. **Integration Coverage**
   - Are component interactions tested?
   - Are external integrations tested?
   - Are E2E scenarios covered?

4. **Test Quality**
   - Are tests meaningful (not just for coverage)?
   - Are assertions specific?
   - Are tests independent?

Report findings:
- 🔴 CRITICAL: Missing critical test coverage
- 🟡 WARNING: Incomplete test coverage
- 🔵 SUGGESTION: Additional test opportunity
```

### Agent 5: Spec Compliance Review

```
Feature: $ARGUMENTS

REVIEW FOCUS: Spec Compliance

Review implementation against docs/workflow-$ARGUMENTS/specs/$ARGUMENTS-specs.md:

1. **Functional Requirements**
   - Are all requirements implemented?
   - Does behavior match specification?
   - Are all user stories addressed?

2. **Non-Functional Requirements**
   - Are performance requirements met?
   - Are security requirements met?
   - Are scalability requirements met?

3. **Edge Cases**
   - Are specified edge cases handled?
   - Is error handling per spec?
   - Are boundary conditions correct?

4. **API Contracts**
   - Do interfaces match spec?
   - Are data formats correct?
   - Are error responses per spec?

Report findings:
- 🔴 CRITICAL: Spec violation
- 🟡 WARNING: Partial compliance
- 🔵 SUGGESTION: Spec enhancement opportunity
```

---

## CONSOLIDATION

After all 5 agents complete, consolidate findings:

### Categorize All Findings

```markdown
## Code Review Summary: $ARGUMENTS

### 🔴 CRITICAL Issues (Must Fix)

#### Security
- [Finding]: [Details]

#### Performance
- [Finding]: [Details]

#### Code Quality
- [Finding]: [Details]

#### Test Coverage
- [Finding]: [Details]

#### Spec Compliance
- [Finding]: [Details]

### 🟡 WARNINGS (Should Fix)
[Categorized list]

### 🔵 SUGGESTIONS (Nice to Have)
[Categorized list]

### Summary
- Critical issues: [count]
- Warnings: [count]
- Suggestions: [count]
```

### Present to User

Show the consolidated review findings to the user.

---

## OUTPUT

```markdown
## Review Complete: $ARGUMENTS

### Review Agents
- ✅ Security Review: [N findings]
- ✅ Performance Review: [N findings]
- ✅ Code Quality Review: [N findings]
- ✅ Test Coverage Review: [N findings]
- ✅ Spec Compliance Review: [N findings]

### Critical Issues: [count]
[List with details]

### Warnings: [count]
[Summary]

### Suggestions: [count]
[Summary]
```

---

## Final Step

Review complete. This is Phase 9 (final phase). Address Critical issues and complete the workflow.
