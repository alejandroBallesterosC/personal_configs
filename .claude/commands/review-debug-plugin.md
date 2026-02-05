# ABOUTME: Command to conduct thorough research and review of the debug workflow plugin
# ABOUTME: Compares plugin against best practices from Anthropic docs and power users

---
description: Research best practices and holistically review the debug workflow plugin
model: opus
---

# Review Debug Workflow Plugin

Conduct thorough research and provide holistic feedback on the Debug workflow plugin.

## Research Phase (Parallel Subagents)

Launch the following research subagents in parallel:

### 1. Official Anthropic Research
Research best practices for a workflow like this with Claude Code from official Anthropic sources:
- Official Anthropic documentation on Claude Code best practices
- Anthropic blog posts about agentic coding, long-horizon tasks, Claude Code workflows
- Anthropic's guidance on multi-turn conversations, tool use, and agent design
- Official guides on TDD, testing workflows, debugging, or iterative development with Claude
- How to structure debugging centric coding tasks
- Best practices for context management
- How to design effective agent workflows
- Cursor's debug feature
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

### 3. Debug Workflow Plugin Analysis
Thoroughly explore the Debug workflow plugin at `claude-code/plugins/debug-workflow/`:
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
Explore dependencies and related plugins that the debug workflow relies on:
- plugins in `claude-code/plugins/` that interact with the debug workflow
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
