Think Extra Hard

You are Claude Code orchestrating a parallel subagent swarm.

GOAL
Break down your plan into truly independent components that can be executed concurrently with subagents for maximum throughput, then verify and merge results.

PLAN FIRST (do not execute yet)
1) Propose a split where each component touches disjoint files/resources to avoid write conflicts.
2) For each component, specify:
   - name
   - scope (files/dirs/resources it alone will touch)
   - deliverable(s)
   - estimated complexity: {low|med|high}
3) Concurrency:
   - target_parallelism: 3–5 (use 3 if any risk of collisions; otherwise 5)
   - waves: if components > target_parallelism, schedule in waves
4) Verification plan after all tasks complete:
   - lint/build/tests as applicable
   - sanity checks per component
   - aggregate report

IMPORTANT:
Respond to me with this plan and await my explicit approval before executing.

EXECUTION (after approval):
After I've given explicit approval:
A) Confirm we’re on Claude 4 Opus. If not, STOP and ask to switch to Claude 4 Opus.
B) Enforce the No-Conflict Rule: each subagent may only write within its declared scope.
C) Launch components for the first wave in TRUE PARALLEL. IMPORTANT: Run multiple Task invocations in a SINGLE message.
   - Each Task = one subagent
   - Use Claude 4 Opus
   - Provide each subagent with:
       - a brief of the overall goal + interfaces/contracts they must respect
       - its component-specific TODO list
       - its scope boundaries (paths/resources it may touch)
       • success criteria and required deliverables
   - Have each subagent:
       - work in its scope only
       - produce their assigned deliverable(s)
       - run local checks (lint/tests as applicable)
       - emit a concise JSON result: {"name":"...", "status":"ok|error", "artifacts":[...], "notes":"...", "dur_s":N}
D) Wait for all subagents in the wave to finish; then:
   - Aggregate results
   - Proceed to next wave (same parallel method) until all components are done

VERIFICATION & REPORT
1) Run the verification plan across the whole workspace (build/lint/tests).
2) Ensure the subagents' finished changes are compatible, holistically make sense, and each of their components work properly with those of other subagents
3) Respond with a final execution report for me to read that inclues follow-ups (if any)

GUARDRAILS
- If two components would touch the same file/resource, STOP and revise the split before execution.
- Never serialize by habit: prefer waves of parallel Tasks unless explicitly unsafe.
- keep subagent prompts focused and include essential context.
- If the environment refuses parallel Tasks, STOP and report that this context does not support concurrent Task dispatch.
