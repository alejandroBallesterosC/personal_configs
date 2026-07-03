---
name: latex-report
description: Argument-driven LaTeX report writing and compilation — single-voice writing discipline, rigor-preservation checks, and the pdflatex/bibtex compile pipeline. Use when writing a research report as a LaTeX document or compiling .tex files to PDF.
---

# LaTeX Report Skill

Guidance for writing an argument-driven research report in LaTeX and compiling it to PDF. Covers three things: the report's structure, the single-voice writing discipline, and the compile pipeline. Apply directly — no separate agents or phases needed.

**Announce at start:** "I'm using the latex-report skill for this report."

## Structure

Use `references/report-template.tex` as the starting skeleton. It defines an argument-driven structure:

- **Synthesis** (front executive summary — written last, after the body and conclusions, so it accurately reflects what was actually argued): Summary, Key Takeaways, Conclusions & Recommendations Preview, Confidence & Limitations.
- **Background & Context**: why the question matters, prior state of understanding, key terminology.
- **Body chapters**: each chapter heading is a sentence that takes a position, not a topic bucket (bad: "The State of LLM Agents"; good: "LLM agents have not crossed the reliability threshold for production autonomy"). Each chapter defends its heading with cited evidence and closes with an interpretive paragraph — the so-what, not a summary.
- **Conclusions & Recommendations** (back-loaded, written after the body): the unified position the chapters jointly earned, paired recommendations, and conditions under which the argument could change.
- **Open Questions**: what remains unsettled and what would settle it.
- **Methodology appendix**: sources consulted, credibility hierarchy used, audit trail.

Typical chapter count: 3-7, capped at 8. Prefer deeper chapters over more chapters for long topics.

## Single-Voice Writing Discipline

Before writing, decide (and write down, even briefly) the voice: audience, formality register, self-reference style ("this report..." vs "we..." vs impersonal), and hedging vocabulary tiers (strong: "shows/demonstrates/establishes"; moderate: "indicates/suggests"; weak: "may/appears to"). Use `references/voice-guide-template.md` as a starting checklist if the report is substantial enough to warrant writing this down. Keep it under one page — decisions, not explanations.

Writing rules:
- Every paragraph makes a claim and cites evidence *for* that claim. A paragraph that's just sequential cite-statements ("Source X says Y. Source Z says W.") is notes, not writing — rewrite it to lead with the claim.
- Every section/chapter closes with an interpretive paragraph, not a summary — state the judgment, the so-what.
- Maximum 4-5 sentences per paragraph.
- Use itemize/enumerate for any list of 3+ items — don't inline lists as comma-separated prose.
- Every factual claim has an inline `\cite{key}`.
- Preserve qualifications and evidence-gap ratings from your research (see the `research-methodology` skill) — if a finding only supports a claim with a MODERATE or WIDE gap, the prose must reflect that, not round it up to certainty.
- If drafting multiple chapters, draft them sequentially rather than in parallel so a single voice carries through.

### Self-Editing for Flow Without Losing Rigor

After a first draft, do a cold read-through as if seeing it for the first time: does it build one argument across chapters, or read as parallel essays? Any fact-dump paragraphs? Any place a reader would get lost? Fix flow and engagement issues (reordering, transitions, rewriting openings/closings) freely.

But never, while doing this: drop a `\cite{}`, weaken a qualification (turning "may" into "does," or dropping a regime qualifier like "in 2024 US data only"), or add a claim your evidence doesn't support. Before finalizing, spot-check by counting `\cite{}` keys before and after your edit pass — the count after must be `>=` the count before:

```bash
grep -oE '\\cite\{[^}]+\}' report.tex | sed 's/\\cite{//;s/}//' | tr ',' '\n' | sed 's/^ *//;s/ *$//' | sort -u | wc -l
```

If any hedging word ("may", "appears to") disappeared between drafts, verify the underlying evidence actually justified strengthening it — if not, restore the hedge.

## Compiling to PDF

MacTeX/`pdflatex` is an optional dependency for this skill only — if it's missing, skip compilation and say so; the `.tex` file is still valid and can be compiled manually later.

1. **Check prerequisites**: `command -v pdflatex`. If missing, report "pdflatex not installed — skipping PDF compilation, .tex is valid and can be compiled manually (brew install --cask mactex-no-gui)" and stop here, successfully.
2. **Pre-compile formatting fixes**: escape unescaped special characters in text content (`% & $ # _ ^ { } ~ \`), fix malformed table environments (missing `\\`, wrong column counts), ensure every `\begin{...}` has a matching `\end{...}`, verify `\bibliography{sources}` points to an existing `.bib` file.
3. **Run the compile pipeline** from the directory containing the `.tex` file (required for `\bibliography{}` to resolve):
   ```bash
   cd /path/to/report/dir && pdflatex -interaction=nonstopmode report.tex && bibtex report && pdflatex -interaction=nonstopmode report.tex && pdflatex -interaction=nonstopmode report.tex
   ```
   The triple pass is standard: first builds structure, `bibtex` resolves references, second pass incorporates them, third pass fixes cross-references. If `sources.bib` is empty, skip `bibtex` and just run `pdflatex` twice.
4. **On error**: read the `.log` file, fix the `.tex`/`.bib`, re-run. Retry up to 3 times. Common errors: `Undefined control sequence` (missing `\usepackage` or typo), `Missing $ inserted` (unescaped `_`/`^` outside math mode), `File not found` (wrong bibliography/include path), `Overfull \hbox` (long URLs — wrap in `\url{}`).
5. **Clean up** auxiliary files after success: `rm -f *.aux *.bbl *.blg *.log *.out *.toc`. Keep the `.pdf`, `.tex`, and `.bib`.

Never modify the document's substantive content while compiling — only formatting and compilation fixes.
