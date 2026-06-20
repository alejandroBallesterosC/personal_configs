# Precise technical communication

This package gives Claude Code standing rules for explaining technical work in plain, exact, and auditable language.

The main skill is `skills/precise-technical-communication/SKILL.md`. Supporting files provide report structures and worked examples. The optional output style applies a shorter form of the same rules to every Claude Code response.

## Install as a plugin (recommended)

This package is a Claude Code plugin in the `personal_configs` marketplace:

```text
/plugin marketplace add alejandroBallesterosC/personal_configs
/plugin install precise-technical-communication
```

The skill loads automatically when the request matches its description, and can be invoked directly with `/precise-technical-communication`.

## Install as a personal skill

Copy the folder to your personal Claude Code skills directory:

```bash
mkdir -p ~/.claude/skills/precise-technical-communication
cp -R skills/precise-technical-communication/. ~/.claude/skills/precise-technical-communication/
```

The skill will be available in all projects. Claude can load it automatically when the request matches its description. You can also invoke it directly:

```text
/precise-technical-communication
```

## Install for one project

From the project root:

```bash
mkdir -p .claude/skills/precise-technical-communication
cp -R skills/precise-technical-communication/. .claude/skills/precise-technical-communication/
```

Commit the `.claude/skills/precise-technical-communication` directory when the whole team should use it.

## Optional output style for every response

A skill loads when Claude or the user invokes it. An output style applies communication rules to every response.

Copy the optional file to the personal output styles directory:

```bash
mkdir -p ~/.claude/output-styles
cp optional/precise-technical-communication-output-style.md ~/.claude/output-styles/
```

Open `/config`, select `Precise technical communication` as the output style, then start a new session or run `/clear`.

The output style sets `keep-coding-instructions: true`, so Claude Code keeps its normal software engineering instructions.

## Evaluate the skill

Use the prompts and checks in `EVALUATION.md`. Test in fresh sessions with the skill enabled and disabled so prior conversation context does not hide gaps in the skill.

## Design choices

The skill combines plain writing rules with a technical reporting protocol. It requires scope, method, evidence, definitions, assumptions, verification, and limitations. It uses binary checks instead of a subjective writing score.

The design was informed by the supplied `plain-writing` skill and by the MIT licensed Stop Slop project by Hardik Pandya. The reporting and evidence rules are original to this package.
