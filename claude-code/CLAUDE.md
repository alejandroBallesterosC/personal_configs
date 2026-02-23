# Writing code

- We prefer simple, clean, maintainable solutions over clever or complex ones, even if the latter are more concise or performant. Readability and maintainability are primary concerns.
- Make the smallest reasonable changes to get to the desired outcome. You MUST ask permission before reimplementing features or systems from scratch instead of updating the existing implementation.
- NEVER make code changes that aren't directly related to the task you're currently assigned. If you notice something that should be fixed but is unrelated to your current task, document it in a new github issue instead of fixing it immediately.
- NEVER remove code comments unless you can prove that they are actively false. Comments are important documentation and should be preserved even if they seem redundant or unnecessary to you.
- All code files should start with a brief 2 line comment explaining what the file does. Each line of the comment should start with the string "ABOUTME: " to make it easy to grep for.
- When writing comments, avoid referring to temporal context about refactors or recent changes. Comments should be evergreen and describe the code as it is, not how it evolved or was recently changed.
- Always strongly prefer using real data and real APIs for testing. Only Implement a mock mode when integrating with other internal components or services that are being developed in parallel (in the same code base) or external API integrations are not working after many attempts. ALWAYS tell the user when you have tested with a mock rather than with a real API.
- NEVER name things as 'improved' or 'new' or 'enhanced', etc. Code naming should be evergreen. What is new someday will be "old" someday.

# Getting help

- ALWAYS ask for clarification rather than making assumptions.
- If you're having trouble with something, it's ok to stop and ask for help. Especially if it's something your human might be better at.

# Testing

- Tests MUST cover the functionality being implemented.
- NEVER ignore the output of the system or the tests - Logs and messages often contain CRITICAL information.
- TEST OUTPUT MUST BE PRISTINE TO PASS
- If the logs are supposed to contain errors, capture and test it.

## We practice TDD. That means:

- Write tests before writing the implementation code
- Implementations should pass all tests
- Refactor code continuously while ensuring tests still pass

### TDD Implementation Process

- Write a failing test that defines a desired function or improvement
- Run the test to confirm it fails as expected
- Write the implementation
- Run the test to confirm success
- Refactor code to improve simplicity, readability, extensibiliy, and modularity while keeping tests green
- Repeat the cycle for each new feature or bugfix

# Specific Technologies

- When using Python always follow best practices in: @~/.claude/docs/python.md
- When using UV (Python dependency management tool) always follow best practices in: @~/.claude/docs/using-uv.md
- When using Docker with UV (Docker + Python dependency management tool) always follow best practices in: @~/.claude/docs/docker-uv.md

# Learning-Focused Error Response

When encountering tool failures (biome, ruff, pytest, etc.):

- Treat each failure as a learning opportunity, not an obstacle
- Research the specific error before attempting fixes
- Explain what you learned about the tool/codebase
- Build competence with development tools rather than avoiding them

Remember: Quality tools are guardrails that help you, not barriers that block you.

# Searching the Internet
- When searching the internet always spawn 4-5 parallel Claude Sonnet subagents to thoroughly research credible sources that are not stale to prevent bloating your context.

# Exploring Codebases
- When exploring a codebase/repo always spawn 4-5 parallel Claude Sonnet subagents to thoroughly explore various parts/components in parallel and prevent bloating your context. If the instructions youre following suggest to use a different specialized subagent for codebase exploreation you may also do so.

# Other things

- When searching or modifying code, use ast-grep often. ast-grep matches against the abstract syntax tree (AST) and allows safe, language-aware queries and rewrites.
- NEVER disable functionality instead of fixing the root cause problem
- NEVER create duplicate templates/files to work around issues - fix the original
- NEVER claim something is "working" when functionality is disabled or broken
- NEVER use emojis in pull request titles, descriptions or github comments, or documentation files, you can only use the red X or the green check mark emoji in code and even those should be used very rarely
- ALWAYS identify and fix the root cause of template/compilation errors

Problem-Solving Approach:

- When directed to or in scope, FIX problems rather than working around them
- MAINTAIN code quality and avoid technical debt
- USE proper debugging to find root causes
- AVOID shortcuts that break user experience