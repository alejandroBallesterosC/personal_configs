# AGENTS.md Quality Criteria

Judge each file on these six criteria. For each one, report whether the file meets it and, where it falls short, the specific gap: the missing command, the stale path, the padded section. A named gap can be fixed and re-checked; a point score cannot.

## 1. Commands and workflows

All essential commands are documented with context:
- Build, test, lint, and deploy commands present
- Development workflow clear
- Common operations documented

## 2. Architecture clarity

A clear codebase map:
- Key directories explained
- Module relationships documented
- Entry points identified
- Data flow described where relevant

## 3. Non-obvious patterns

Gotchas and quirks captured:
- Known issues documented
- Workarounds explained
- Edge cases noted
- "Why we do it this way" for unusual patterns

## 4. Conciseness

Dense, valuable content:
- No filler or obvious info
- Each line adds value
- No redundancy with code comments

## 5. Currency

Reflects the current codebase:
- Commands work as documented
- File references accurate
- Tech stack current

## 6. Actionability

Instructions are executable:
- Commands can be copy-pasted
- Steps are concrete
- Paths are real

## Assessment Process

1. Read the AGENTS.md file completely
2. Cross-reference with actual codebase:
   - Run documented commands (mentally or actually)
   - Check if referenced files exist
   - Verify architecture descriptions
3. For each criterion, note whether the file meets it and the specific gaps where it does not
4. Propose concrete improvements

## Red Flags

- Commands that would fail (wrong paths, missing deps)
- References to deleted files/folders
- Outdated tech versions
- Copy-paste from templates without customization
- Generic advice not specific to the project
- "TODO" items never completed
- Duplicate info across multiple AGENTS.md files
