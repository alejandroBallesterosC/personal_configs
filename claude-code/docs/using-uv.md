### uv Field Manual (Code‑Gen Ready, Bootstrap‑free)

*Assumption: `uv` is already installed and available on `PATH`.*

---

## 0 — Sanity Check

```bash
uv --version               # verify installation; exits 0
```

If the command fails, halt and report to the user.

---

## 1 — Daily Workflows

### 1.1 Project ("cargo‑style") Flow

```bash
uv init myproj                     # ① create pyproject.toml + .venv
cd myproj
uv add ruff pytest httpx           # ② fast resolver + lock update
uv run pytest -q                   # ③ run tests in project venv
uv lock                            # ④ refresh uv.lock (if needed)
uv sync --locked                   # ⑤ reproducible install (CI‑safe)
```

### 1.2 Script‑Centric Flow (PEP 723)

```bash
echo 'print("hi")' > hello.py
uv run hello.py                    # zero‑dep script, auto‑env
uv add --script hello.py rich      # embeds dep metadata
uv run --with rich hello.py        # transient deps, no state
```

### 1.3 CLI Tools (pipx Replacement)

```bash
uvx ruff check .                   # ephemeral run
uv tool install ruff               # user‑wide persistent install
uv tool list                       # audit installed CLIs
uv tool update --all               # keep them fresh
```

### 1.4 Python Version Management

```bash
uv python install 3.10 3.11 3.12
uv python pin 3.12                 # writes .python-version
uv run --python 3.10 script.py
```

### 1.5 Dependencies
- Add runtime: `uv add <pkg>`
- Add to group: `uv add --group dev <pkg>` (groups: `dev`, `test`, `docs`, etc.)
- Remove: `uv remove <pkg>`
- Declare deps in `pyproject.toml` (`[project]`, `[project.optional-dependencies]`, and `[dependency-groups]`)

### 1.6 Environment
- Create: `uv venv` (writes `.venv/`; add to `.gitignore`)
- Activate: `source .venv/bin/activate` (Linux/macOS) or `.venv\Scripts\activate` (Windows)


---


## 2 — CI/CD Recipes

### 2.1 GitHub Actions

```yaml
# .github/workflows/test.yml
name: tests
on: [push]
jobs:
  pytest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5       # installs uv, restores cache
      - run: uv python install            # obey .python-version
      - run: uv sync --locked             # restore env
      - run: uv run pytest -q
```

### 2.2 Docker

```dockerfile
FROM ghcr.io/astral-sh/uv:0.7.4 AS uv
FROM python:3.12-slim

COPY --from=uv /usr/local/bin/uv /usr/local/bin/uv
COPY pyproject.toml uv.lock /app/
WORKDIR /app
RUN uv sync --production --locked
COPY . /app
CMD ["uv", "run", "python", "-m", "myapp"]
```

---

## 3 — Migration Matrix

| Legacy Tool / Concept | One‑Shot Replacement        | Notes                 |
| --------------------- | --------------------------- | --------------------- |
| `python -m venv`      | `uv venv`                   | 10× faster create     |
| `pip install`         | `uv add` + `uv sync`        |                       |
| `pip-tools compile`   | `uv pip compile` (implicit) | via `uv lock`         |
| `pipx run`            | `uvx` / `uv tool run`       | no global Python req. |
| `poetry add`          | `uv add`                    | pyproject native      |

---

## 4 — Troubleshooting Fast‑Path

| Symptom                    | Resolution                                                     |
| -------------------------- | -------------------------------------------------------------- |
| `Python X.Y not found`     | `uv python install X.Y` or set `UV_PYTHON`                     |
| Proxy throttling downloads | `UV_HTTP_TIMEOUT=120 UV_INDEX_URL=https://mirror.local/simple` |
| C‑extension build errors   | `unset UV_NO_BUILD_ISOLATION`                                  |
| Need fresh env             | `uv cache clean && rm -rf .venv && uv sync`                    |
| Still stuck?               | `RUST_LOG=debug uv ...` and open a GitHub issue                |

---

## 5 — Exec Pitch (30 s)

```text
• 10–100× faster dependency & env management in one binary.
• Universal lockfile ⇒ identical builds on macOS / Linux / Windows / ARM / x86.
• Backed by the Ruff team; shipping new releases ~monthly.
```

---

## 6 — Agent Cheat‑Sheet (Copy/Paste)

```bash
# new project
a=$PWD && uv init myproj && cd myproj && uv add requests rich

# add deps
uv add <pkg>

# remove deps
uv remove <pkg>

# create venv
uv venv

# sync reqs to venv
uv sync

# test run
uv run python -m myproj ...

# lock + CI restore
uv lock && uv sync --locked

# adhoc script
uv add --script tool.py httpx
uv run tool.py

# manage CLI tools
uvx ruff check .
uv tool install pre-commit

# Python versions
uv python install 3.12
uv python pin 3.12
```

---

*End of manual*
