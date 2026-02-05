# ABOUTME: Command to conduct thorough research and review of the dev workflow plugin
# ABOUTME: Compares plugin against best practices from Anthropic docs and power users

---
description: Research best practices and holistically review the dev workflow plugin
model: opus
---

# Review dev Workflow Plugin

Conduct thorough research and provide holistic feedback on the dev workflow plugin.

## Research Phase (Parallel Subagents)

Launch the following research subagents in parallel using subagents:

### 1. Official Anthropic Research
Research best practices for agentic long-horizon coding with Claude Code from official Anthropic sources:
- Official Anthropic documentation on Claude Code best practices
- Anthropic blog posts about agentic coding, long-horizon tasks, Claude Code workflows
- Anthropic's guidance on multi-turn conversations, tool use, and agent design
- Official guides on dev, testing workflows, or iterative development with Claude
- How to structure long-running coding tasks
- Best practices for context management
- How to design effective agent workflows
- Recommended patterns for iterative development
- Quality assurance and verification approaches

### 2. Power User Insights Research
Research insights and best practices from Claude Code power users:
- Boris Cherny - tweets, blog posts, content about Claude Code usage patterns
- Thariq Shihab - content about Claude Code and agentic workflows
- Other notable Claude Code power users and their shared insights
- Community discussions about effective Claude Code workflows
- Real-world tips for long-horizon agentic coding
- Common pitfalls and how to avoid them
- Patterns that experienced users have found effective

### 3. dev Workflow Plugin Analysis
Thoroughly explore the dev workflow plugin at `claude-code/plugins/dev-workflow/`:
- Overall plugin structure and architecture
- All commands - their purpose and implementation
- All agents - their roles, tools, and configurations
- All skills - how they activate and what they provide
- All hooks - event types, triggers, and behaviors
- README and documentation quality
- How workflow phases connect and transition
- State management and context preservation mechanisms
- Integration points with other plugins

### 4. Plugin Dependencies Analysis
Explore dependencies and related plugins that dev workflow relies on:
- ralph-loop plugin (required for Phases 7, 8, 9)
- Other plugins in `claude-code/plugins/` that interact with dev workflow
- Shared components in `claude-code/commands/`
- MCP server configurations that support the workflow
- How plugins interconnect
- Shared patterns across plugins

## Synthesis Phase

After all research completes, synthesize findings into holistic feedback:

### What is Good?
Identify strengths that align with best practices:
- Patterns that match official Anthropic recommendations
- Implementation choices that power users would approve
- Innovative solutions to common challenges
- Well-designed architecture decisions

### What Could Be Improved?
Identify gaps and areas for enhancement:
- Deviations from best practices
- Missing features that power users rely on
- Potential issues or edge cases not handled
- Documentation or usability gaps

### Priority Recommendations
Rank improvements by:
1. **Critical** - Issues that could cause workflow failures
2. **High Priority** - Significant quality or UX improvements
3. **Medium Priority** - Nice-to-have enhancements
4. **Lower Priority** - Polish and refinements

Provide specific, actionable recommendations for each priority level.
