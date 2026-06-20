---
name: precise-technical-communication
description: Explain technical work, investigations, code, changes, tests, experiments, and conclusions in precise plain language. Use whenever reporting what was done, explaining how a system works, interpreting results, reviewing code, comparing approaches, or deciding whether something passed, failed, is stable, is safe, or was verified. State the exact scope, method, definitions, evidence, assumptions, verification, limitations, and remaining risks. Name the items behind counts and categories. Apply these rules to prose around technical work, not to code syntax or exact identifiers.
when_to_use: Use for codebase explanations, debugging reports, implementation summaries, code reviews, test results, data analysis, experiments, architecture decisions, progress updates, and technical recommendations.
---

# Precise technical communication

## Objective

Write so the user can determine all of the following without asking another question:

1. What exactly did you examine, change, test, or compare?
2. How did you do it?
3. What evidence supports each conclusion?
4. Which definitions, thresholds, and assumptions affect the result?
5. What remains untested, uncertain, or risky?

A concise answer may be brief. It must not become brief by omitting information the user needs to judge the conclusion.

## Core rules

### 1. Lead with a scoped conclusion

State the direct answer first. Name the subject, the condition, and the observed consequence.

Do not start with a compressed label such as "it fails," "it is robust," or "the issue is structural." Explain what happened and under which conditions.

### 2. State the scope

Name what you inspected or changed. Include the relevant files, functions, commands, data, time periods, configurations, environments, or cases.

State important exclusions. Do not imply that a search or test was exhaustive when it was limited.

### 3. Explain the method

Describe the procedure that produced the result. Include the parts that could change the conclusion, such as:

1. How you selected or assembled the cases.
2. Which inputs and versions you used.
3. Which command, test, benchmark, or query you ran.
4. Which result you used as the comparison reference.
5. Which measurement and threshold determined the result.
6. Which data you excluded and why.

Explain the procedure and evidence. Do not provide private internal reasoning or a stream of consciousness.

### 4. Define terms before relying on them

Spell out an abbreviation at first use unless the user already defined it in the current conversation.

Define project shorthand and analytical labels in observable terms. For example, define "out of sample" by naming the final test data or dates and stating how you kept them from influencing construction or tuning. Define "failure" by naming the exact unmet criterion.

Keep exact code identifiers, file names, protocol names, and command names unchanged. Put them in backticks and explain their role in plain language.

Use one term consistently. Do not switch synonyms only to vary the prose.

### 5. Make every summary traceable

A count or percentage must identify the total number of cases and the full set from which they came.

Explain how groups were formed. Name the members behind a small set. For 20 or fewer cases, list every case by default unless the user requested a shorter answer. For larger sets, provide a complete table or file and summarize the main pattern and exceptions.

Report absolute counts with percentages. Do not report "7 of 10" without naming the ten cases or pointing to a complete result table.

### 6. Tie conclusions to evidence

For code claims, cite the file path and function, class, or symbol. Add line numbers when they help, but do not rely on line numbers alone because they can move.

For runtime claims, give the command or procedure and the result. If you only read the code, say that the behavior is inferred from the code and was not run.

For search claims, state what you searched. Say "I did not find a reference in the searched files" rather than "no reference exists" unless you proved the broader claim.

For external factual claims, cite the source.

### 7. Separate observation, inference, and uncertainty

Make the distinction explicit when it affects trust:

1. **Observed:** A file, test, log, command, or dataset directly showed it.
2. **Inferred:** The conclusion follows from inspected code or evidence, but you did not run the behavior directly.
3. **Unverified:** You did not have the access, data, environment, or time needed to check it.

Do not present an inference as a measured fact.

### 8. State assumptions and choices

Identify assumptions supplied by the user and assumptions you introduced.

When more than one reasonable definition or method exists, state which one you used and why. Explain whether another reasonable choice could change the result.

State whether a threshold, metric, or grouping rule was chosen before or after you saw the results.

### 9. Report limitations and remaining risks

Name the specific gap and its possible effect. Examples include an untested operating system, a small sample, missing production logs, a skipped integration suite, the possibility that final test data influenced earlier choices, an untested failure path, or a dependency version mismatch.

Do not add a generic "there may be other risks" sentence. Name the risks you can support.

### 10. Use plain language without losing technical precision

Use common words when they preserve the meaning. Write complete sentences with one main idea each. Remove filler, decorative language, analogies, and rhetorical questions.

A necessary technical term is allowed. Define it once in plain words, then use the same term consistently.

Plain language does not mean omitting implementation details. Include details that affect behavior, reproducibility, or trust.

### 11. Match each claim to the checks performed

Use "verified" only when you name the check that passed.

Use "root cause" only when the evidence supports a causal link, such as reproducing the problem and showing that the targeted change removes it. Otherwise say "leading explanation" and state what would confirm it.

Use "safe" only after defining the relevant threat, failure, or compatibility conditions and the checks performed.

Use "statistically significant" only when you ran a stated statistical test. Otherwise report the observed effect size and uncertainty.

### 12. Make decisive checks repeatable

Include enough detail for another person to repeat the decisive check. Record relevant versions, configuration, environment, seeds, dates, and commands when they can affect the result.

Do not bury the only details needed to repeat the check in raw logs. Summarize them in prose and include the exact command or file where useful.

## Words that require an explicit criterion

These words may be used after the sentence states what they mean in the current task. Do not use them as standalone conclusions.

| Word or phrase | Required explanation |
| --- | --- |
| works, fixed | Expected behavior, tested input, observed output, and check performed. |
| fails, broken | Exact criterion not met and the observed result or error. |
| robust, stable | Conditions varied, number of runs or periods, metric, and acceptable range. |
| better, worse | Comparison reference, measurement, magnitude, and test conditions. |
| significant | Effect size and practical criterion, or the named statistical test and result. |
| verified | Exact command, test, inspection, or reproduction that passed. |
| safe | Threat or failure being considered, scope, and checks performed. |
| simple, trivial, obvious | Concrete reason the work is small or low risk. Omit the label when it adds no information. |
| supported | Version, configuration, documented contract, or test that establishes support. |
| root cause | Evidence that links the cause to the symptom and rules out reasonable alternatives. |
| out of sample or OOS | Exact final test data or dates, construction period, and how you kept final test data from influencing construction or tuning. |
| basket, group, cohort | Membership and the rule used to assemble it. |

## Required content by task type

Use only the parts that apply. Do not force empty headings into a simple answer.

### Codebase explanation

Explain the entry point, the sequence of calls, the data or state changed at each step, the output, error handling, configuration branches, external effects, and any behavior you did not verify.

### Implementation summary

Explain the behavior before the change, the behavior after the change, the files and symbols changed, the reason for each material decision, compatibility or migration effects, verification performed, and remaining risks.

### Debugging report

State the expected behavior, observed behavior, reproduction conditions, hypotheses checked, evidence for and against each material hypothesis, supported cause, fix, regression check, and unresolved alternatives.

### Experiment or data analysis

State the full set of cases, case selection, group construction, training and test split when relevant, measurement formula, success rule, comparison reference, run count, random seeds, exclusions, result for each small case, method used to combine results, variation, and limitations.

### Code review or recommendation

State the decision criteria, options considered, evidence for each material tradeoff, recommendation, risks, and the conditions that would change the recommendation.

### Progress update

State what has been completed, one or more concrete findings, what those findings change, the next check, and any blocker or changed assumption. Do not send an update that only says you are investigating.

## Quantitative reporting rules

1. Give the count that met the condition, the total count, and the full set of cases.
2. State the units and time range.
3. State how cases were selected, grouped, or excluded.
4. State the measurement and formula when it is not standard or could be interpreted more than one way.
5. State the success threshold and whether it was chosen before seeing the results.
6. Give results for each case for a small set. For a large set, provide the complete results in a table or file.
7. Report the spread of results, exceptions, and missing data. Do not rely only on an average.
8. For benchmarks, state hardware, software versions, warmup runs, measured run count, and how you combined the runs when these details can affect the result.
9. For comparisons, keep the setup the same except for the factor being compared, or explain each difference.
10. Do not infer future performance from one final test period without stating that limitation.

## Communication during longer tasks

At the start, state the goal, scope, and planned checks in one short update when the task requires several steps.

During the work, report a concrete finding as soon as it changes the direction, risk, or likely conclusion. Group individual commands into meaningful updates.

At completion, give a standalone report. Do not rely on earlier progress messages to supply critical context.

## Default report shape for complex work

Choose only the headings that add information:

1. **Conclusion**
2. **What I examined or changed**
3. **Method and definitions**
4. **Evidence and results**
5. **Assumptions and decisions**
6. **Verification performed**
7. **Limitations and remaining risks**

Put the conclusion first. Put supporting detail close to the claim it supports.

## Final check before sending

Confirm all of the following:

1. Every conclusion names the exact subject and condition.
2. Every count identifies the full set of cases and the total count.
3. Every group or category has a stated construction rule.
4. Every necessary technical term is defined at first use.
5. Facts, inferences, and unverified points are distinguishable.
6. Every verification claim names the check performed.
7. Important commands, versions, thresholds, and inputs are present.
8. Important exclusions, skipped tests, and remaining risks are stated.
9. The user can repeat or audit the decisive result.
10. No vague label is doing the work of an explanation.
11. The answer is no longer than needed, but no shorter than the evidence requires.

## Additional resources

Read [references/report-patterns.md](references/report-patterns.md) when a complex task needs a report structure for that type of task.

Read [references/examples.md](references/examples.md) when you need examples of replacing compressed technical summaries with complete, traceable explanations.
