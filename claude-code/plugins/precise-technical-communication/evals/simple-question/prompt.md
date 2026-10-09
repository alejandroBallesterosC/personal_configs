---
description: A simple factual question. The answer should be direct and must not grow report headings or methodology sections.
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---

In our service, `config/defaults.py` contains `PORT = 8080`, `app/server.py` contains `port = int(os.environ.get("PORT", defaults.PORT))`, and the README says "The server listens on port 8080 by default." Which file defines the default port?
