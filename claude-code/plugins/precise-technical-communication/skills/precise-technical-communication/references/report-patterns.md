# Report patterns

Use these patterns for complex work. Remove any section that would be empty or would repeat another section.

## Codebase explanation

### Purpose

State what the component does and who or what calls it.

### Entry points

Name the files, functions, routes, commands, jobs, or events that start the behavior.

### Execution flow

Describe the actual sequence in order:

1. Input received and validation performed.
2. Main function or service called.
3. Data transformed or state read.
4. State written or external service called.
5. Output returned or event emitted.

For each step, name the relevant symbol and explain what it does in plain words.

### Branches and configuration

State which feature flags, environment variables, request types, or data conditions change the path.

### Failure behavior

State where errors can occur, how they are handled, whether work is retried, and what the caller receives.

### Evidence

List the decisive files, symbols, tests, logs, or commands.

### Unknowns

State what you did not run or inspect and how that limits the explanation.

## Debugging report

### Conclusion

State the supported cause or the strongest current explanation. Include the conditions under which the problem occurs.

### Reproduction

State:

1. Environment and version.
2. Input or sequence of actions.
3. Expected result.
4. Observed result, including the exact error when useful.
5. Reproduction rate.

### Checks performed

For each material hypothesis, state the check and result. Do not list abandoned guesses that did not affect the conclusion.

### Causal evidence

Explain why the evidence supports the cause. State whether changing the suspected cause removed the reproduced symptom.

### Fix

Name the files and symbols changed. Explain the behavior before and after.

### Verification

Give the commands or procedures, their results, and what they cover.

### Remaining uncertainty

Name untested environments, timing conditions, integrations, or alternative causes.

## Implementation report

### Result

State the behavior now visible to the user or the system.

### Previous behavior

Explain the old path and its problem. Cite the relevant symbols.

### Changes by file

For each material file:

`path/to/file`: Name the changed symbol, what changed, and why.

Group mechanical changes together. Do not describe every changed line.

### Design decisions

State the alternatives that could have changed behavior, the selected option, and the deciding evidence or constraint.

### Compatibility and side effects

State changes to data formats, APIs, configuration, migrations, performance, security, retries, caching, logging, or failure behavior.

### Verification

State the exact checks and results. Separate tests you ran from tests you did not run.

### Remaining risks

Name each supported risk and the condition that would expose it.

## Experiment or data analysis report

### Question

State the question in measurable terms.

### Population and cases

Name the source population. Explain how each case, basket, cohort, or group was assembled. List the members of a small set.

### Data split

Name the dates or records used for construction, tuning, validation, and the final test. State how you prevented final test data from influencing construction, tuning, or threshold choices.

### Metric and criterion

Define the measurement, units, method used to combine results, and the exact condition for success or failure. State whether the criterion was chosen before reviewing the results.

### Procedure

State versions, parameters, random seeds, run count, exclusions, and the result used as the comparison reference.

### Results

For a small set, use a table with one row per case. Include the measured values and the criterion met or missed.

For a large set, link or attach the complete table. Summarize the spread of results, not only the mean. Name important exceptions.

### Interpretation

Explain what the results establish and what they do not establish.

### Limitations

State sample limits, measurement error, missing data, risk that final test data influenced earlier choices, the effect of making many comparisons, changes between test and deployment environments, and any choice made after seeing results when relevant.

## Code review or recommendation

### Decision

State the recommended action and the scope in which it applies.

### Criteria

Name the criteria used to compare options, such as correctness, compatibility, response time, maintenance cost, or migration risk. Define any criterion that is not clear without explanation.

### Options and evidence

For each serious option, state the evidence, benefit, cost, and risk. Do not include an option only to make the preferred one look better.

### Recommendation basis

Explain which criteria determined the recommendation and why.

### Conditions that would change the decision

State the missing evidence, scale, traffic, dependency, or requirement that would justify a different choice.

## Progress update

Use four short parts:

1. **Completed:** The checks or changes completed since the prior update.
2. **Finding:** A concrete result with its evidence.
3. **Effect:** How the finding changes the conclusion, method, or risk.
4. **Next:** The next decisive check or implementation step.

Add **Blocker** only when a blocker exists. State the exact missing access, dependency, data, or decision.
