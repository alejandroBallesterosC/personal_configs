# ABOUTME: Command to conduct thorough research and review of the playwright plugin
# ABOUTME: Compares plugin against best practices from Anthropic docs and power users

---
description: Research best practices and holistically review the playwright plugin
model: opus
---

# Review playwright Plugin

The playwright plugin contains a playwright skill meant to do the following:

I find that when I use some of my claude code workflows to do test driven development of a feature that involves backend logic and frontend ui/design changes the result is not always great and the ui may not look good due to weird spacing, indentation, orientation, or alignment of text that is not visually optimal. Additionally, there can be poor visual organization of ui components and sometimes the components are not functional. Claude should inspect the final product of what the ui looks like, how it functions, wether the design and visual orientation of components are great, wether the ui components function as expected, wether things are unexpectedly not rendering, and wether a feature that required a frontend ui change and a backend logic change works end to end as expected, but it doesn't have the tools to do this built in by default and doesnt always do this. We want to ensure claude does these things to inspect the final product of a ui change/implementation or a feature that involved a ui change/implementation and backend logic change, so it can ensure the final result is guaranteed to work end to end as expected, and look great from a ui/front end perspective. Not all implementations or changes I use claude for require frontend/ui changes but some do, and that's when this is important.

## Research Phase (Parallel Sonnet Subagents)

Conduct the following research in parallel by launching parallel sonnet subagents:

### 1. Official Anthropic Research
Research current best practices for agentic long-horizon coding and frontend/ui implementations/changes with Claude Code from up to date Anthropic sanctioned/supported sources as well as high-credibility claude code power users:
- Official Anthropic documentation on Claude Code best practices
- Anthropic blog posts about agentic coding, long-horizon tasks, Claude Code workflows that involve frontend/ ui changes or implementations
- Anthropic's guidance on multi-turn conversations, tool use, and agent design
- Official guides on dev, testing workflows, or iterative development with Claude
- How to structure long-running coding tasks that involve frontend/ ui changes or implementations
- Best practices for context management and skill design/use
- Best practices for plugin design/use
- How to design effective agent workflows for the highest quality frontend/ui outputs
- Recommended patterns
- Quality assurance and verification approaches

### 2. Reputable Power User Insights Research
Research up to date insights and current best practices from Claude Code power users:
- Boris Cherny - tweets, blog posts, content about Claude Code usage patterns
- Thariq Shihab - tweets, blog posts, content about Claude Code and agentic workflows
- Other reputable top tier programmers that are Claude Code power users and their shared insights from blogs and tweets
- Community discussions about effective Claude Code workflows that involve frontend/ui changes
- Real-world tips for long-horizon agentic coding
- Common pitfalls and how to avoid them
- Patterns that experienced users have found effective


## Explore & Review Plugin Phase (Parallel Sonnet Subagents)

Launch the following in parallel using sonnet subagents to explore the playwright plugin in this repo:

### 1. Playwright Plugin Analysis
Thoroughly explore the playwright plugin at `claude-code/plugins/playwright/`:
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

### 2. Plugin Dependencies and References Analysis
Explore dependencies and related plugins that playwright relies on:
- ralph-loop plugin and any mentions of skills, plugins, mcps, agents, or hooks that are external to the plugin but used in the plugin
- Other plugins in `claude-code/plugins/` that interact with playwright
- Shared components in `claude-code/commands/`
- MCP server configurations that support the workflow
- How plugins interconnect
- Shared patterns across plugins

## Synthesis Phase

After all research and analysis completes, synthesize findings into holistic feedback:

### What is Good?
Identify strengths that align with best practices:
- Patterns that match official Anthropic recommendations
- Implementation choices that power users would approve for a plugin like this
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
