# ABOUTME: Command to conduct thorough research and review of the Autonomous workflow plugin
# ABOUTME: Compares plugin against best practices from Anthropic docs and power users

---
description: Research best practices and holistically review the Autonomous workflow plugin
model: opus
---

# Review Autonomous Workflow Plugin

Conduct thorough research and provide holistic feedback on the Autonomous workflow plugin in this repo in claude-code/docs/plugins/autonomous-workflow/

## Research Phase (Parallel Subagents)

Conduct the following research in parallel by launching parallel sonnet subagents:

### 1. Official Anthropic Research
Research best practices for agentic long-horizon coding and research with Claude Code from official Anthropic sources:
- Official Anthropic documentation on Claude Code best practices
- Anthropic blog posts about agentic coding, long-horizon tasks, Claude Code workflows
- Anthropic's guidance on multi-turn conversations, tool use, and agent design
- Official guides on dev, testing workflows, or iterative development with Claude
- How to structure long-running coding tasks
- Best practices for context management
- How to design effective agent workflows for the highest quality code and research outputs
- Recommended patterns
- Quality assurance and verification approaches

### 2. Reputable Power User Insights Research
Research insights and best practices from Claude Code power users:
- Boris Cherny - tweets, blog posts, content about Claude Code usage patterns
- Thariq Shihab - tweets, blog posts, content about Claude Code and agentic workflows
- Other reputable top tier programmers that are Claude Code power users and their shared insights from blogs and tweets
- Community discussions about effective Claude Code workflows
- Real-world tips for long-horizon agentic coding
- Common pitfalls and how to avoid them
- Patterns that experienced users have found effective


## Explore & Review Plugin Phase (Parallel Subagents)

Launch the following in parallel using sonnet subagents to explore the autonomous workflow plugin in this repo:

### 1. Autonomous-workflow Plugin Analysis
Thoroughly explore the autonomous workflow plugin at `claude-code/plugins/autonomous-workflow/`:
- Overall plugin structure and architecture
- All commands - their purpose and implementation
- All agents - their roles, tools, and configurations
- All skills - how they activate and what they provide
- All hooks - event types, triggers, and behaviors
- README and documentation quality
- How workflow phases connect and transition
- State management and context preservation mechanisms
- Integration points with other plugins
- Internal consistency within plugin (are there inconsistencies across the plugin?)

### 4. Plugin Dependencies Analysis
Explore dependencies and related plugins that autonomous workflow relies on:
- ralph-loop plugin (required for Phases 7, 8, 9)
- Other plugins in `claude-code/plugins/` that interact with autonomous workflow
- Shared components in `claude-code/commands/`
- MCP server configurations that support the workflow
- How plugins interconnect
- Shared patterns across plugins

## Synthesis Phase

After all research and analysis completes, synthesize findings into holistic feedback:

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
- Internal consistency issues within the plugin
- Possible gaps/flaws in real usage

### Priority Recommendations
Rank improvements by:
1. **Critical** - Issues that could cause workflow failures and inconsistencies
2. **High Priority** - Significant quality or UX improvements
3. **Medium Priority** - Nice-to-have enhancements
4. **Lower Priority** - Polish and refinements

Provide specific, actionable recommendations for each priority level.
