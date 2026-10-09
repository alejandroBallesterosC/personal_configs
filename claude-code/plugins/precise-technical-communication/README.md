# Precise technical communication

This package gives Claude Code standing rules for explaining technical work in plain, exact, and auditable language.

The main skill is `skills/precise-technical-communication/SKILL.md`. Supporting files provide report structures and worked examples. The output style applies a shorter form of the same rules to every Claude Code response.

## Install as a plugin (recommended)

This package is a Claude Code plugin in the `personal_configs` marketplace:

```text
/plugin install precise-technical-communication --marketplace alejandroBallesterosC/personal_configs
```

The skill loads automatically when the request matches its description, and can be invoked directly with `/precise-technical-communication:precise-technical-communication`.

Installing the plugin also turns on the output style. It sets `force-for-plugin: true`, so Claude Code applies it whenever the plugin is enabled, overriding your own `outputStyle` setting. It shapes the main conversation, not subagents. Its text is part of every request, so it costs context on every turn. To use only the skill, install it as a personal skill instead.

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

## Output style for a personal install

A skill loads when Claude or the user invokes it. An output style applies communication rules to every response. The plugin applies the style automatically; for a personal install, copy the file to the personal output styles directory:

```bash
mkdir -p ~/.claude/output-styles
cp output-styles/precise-technical-communication-output-style.md ~/.claude/output-styles/
```

Open `/config`, select `Precise technical communication` as the output style, then start a new session or run `/clear`.

The output style sets `keep-coding-instructions: true`, which keeps Claude Code's built-in software engineering instructions when Claude Code uses its full system prompt. Current models (Opus 5.5, Sonnet 5.5, Haiku 5.5, and Fable) get a shorter system prompt by default that does not contain those instructions, so on them the field has no effect.

## Evaluate the skill

`EVALUATION.md` lists the evaluation prompts and checks. Three of them run as automated `claude plugin eval` cases in `evals/`, each with and without the plugin; the rest stay manual because they need a real repository or session. Re-run the suite when a new model ships, pinning `--model`, to see which behaviors the model now does on its own and which still need the plugin.

## Design choices

The skill combines plain writing rules with a technical reporting protocol. It requires scope, method, evidence, definitions, assumptions, verification, and limitations. It uses binary checks instead of a subjective writing score.

The design was informed by the supplied `plain-writing` skill and by the MIT licensed Stop Slop project by Hardik Pandya. The reporting and evidence rules are original to this package.
