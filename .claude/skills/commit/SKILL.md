---
name: commit
description: Creates atomic Conventional Commits from uncommitted changes in this repository. Use when the user asks to "commit", "commit my changes", "make the commits", "stage and commit", or otherwise requests turning working-tree changes into one or more commits following the project's commit convention.
---

# Commit

Turn the current uncommitted diff into one or more **atomic** commits that follow the project's Conventional Commits convention.

## Convention (authoritative for this repo)

```
type(scope): short description in English

Optional body in English

Optional footer
```

### Allowed types

| Type | Usage |
|------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Refactoring with no behavior change |
| `docs` | Documentation only |
| `test` | Adding or modifying tests |
| `chore` | Maintenance (deps, CI, config) |
| `style` | Formatting, linting (no logic change) |

### Rules (non-negotiable)

1. **English** for the message — even if the user speaks another language.
2. **Atomic** — one commit = one logical change. Never mix `feat` + `fix` in the same commit.
3. **Scope** optional, in parentheses, names the module/area: `feat(vault): add withdraw instruction`.
4. **Subject line** — imperative mood, lowercase after the prefix, **≤ 72 characters**, no trailing period.
5. **Body defaults to empty.** Only add one if a reviewer reading just the subject line would miss load-bearing context (workaround, hidden constraint, surprising decision). If you write a body, keep it to **1–2 short sentences about WHY**, never WHAT. If the body paraphrases the diff or restates the subject, delete it.
6. **Never** use `--no-verify`, `--amend`, or any flag that bypasses hooks/signing unless the user explicitly asks.
7. **Never** add a `Co-Authored-By: Claude …` trailer (or any other AI attribution) to commit messages. Keep commits authored solely by the human user.

## Workflow

Copy this checklist and tick items as you go:

```
- [ ] 1. Read working-tree state (status + full diff + recent log)
- [ ] 2. Group changes into atomic logical units
- [ ] 3. Confirm the plan with the user if >1 commit
- [ ] 4. For each unit: stage specific files → commit → verify
- [ ] 5. Report final `git log` and `git status`
```

### Step 1 — Read state

Run in parallel:

```bash
git status                  # untracked + modified (never -uall)
git diff HEAD               # full unstaged + staged diff
git log --oneline -10       # match existing style
```

If the repo has **no commits yet** (`git log` fails), everything is a single initial commit — skip grouping and use `chore: initial commit` or a more descriptive `feat:` if the first commit introduces a clear feature.

### Step 2 — Group into atomic units

Separate commits whenever changes fall into different types or unrelated scopes. Examples of signals to split:

- A bug fix mixed with a new feature → 2 commits (`fix:` + `feat:`).
- Source code + unrelated dependency bumps → 2 commits (`feat:` + `chore:`).
- Refactor of module A + refactor of module B with no shared intent → 2 commits.

Keep them **together** when:

- Tests accompany the feature/fix they cover → single `feat:` or `fix:` with the tests included.
- A rename touches many files for the same reason → single `refactor:`.

### Step 3 — Confirm (only if multiple commits)

If the plan produces more than one commit, briefly list the planned commits (type, scope, subject) to the user and wait for confirmation. For a single commit, proceed.

### Step 4 — Stage and commit, one unit at a time

- Stage **specific files** — `git add path/one path/two`. Do **not** use `git add -A` or `git add .` (risk of including secrets, caches, or unrelated changes).
- Never stage `.env`, credentials, private keys, large binaries, or `.DS_Store`. If any such file is present, warn the user and skip it.
- Commit with a HEREDOC so formatting is preserved:

```bash
git commit -m "$(cat <<'EOF'
type(scope): subject in imperative mood

Optional body explaining the why.
EOF
)"
```

Do **not** append a `Co-Authored-By` trailer or any AI-attribution line.

- If a pre-commit hook fails: fix the underlying issue, re-stage, create a **new** commit. Never `--amend` to hide the failure.

### Step 5 — Verify

After the last commit, run `git status` and `git log --oneline -<N>` (where N = number of commits just created) and report both to the user.

## Examples

**Single feature with tests** (one commit, no body — subject is self-contained):

```
feat(wallet): add SOL balance polling
```

**Bug fix that stands alone** (one commit):

```
fix(rpc): handle 429 by backing off before retrying
```

**Commit where a body IS justified** (non-obvious workaround):

```
refactor(build): disable script sandboxing for SwiftLint phase

Xcode sandbox forbids scripts from scanning $SRCROOT without
declaring every file as input, which is impractical for linters.
```

**Mixed diff split into three atomic commits**:

```
feat(send): add amount validation for SOL transfers
fix(ui): correct address truncation for devnet pubkeys
chore(deps): bump solana-sdk to 2.0.3
```

**Docs-only change**:

```
docs(readme): document devnet setup steps
```

**Refactor with no behavior change**:

```
refactor(transactions): extract fee estimation into FeeService
```

## Anti-patterns

- ✗ `update stuff` — no type, vague.
- ✗ `feat: Added new feature.` — capitalized, past tense, trailing period.
- ✗ `feat(wallet): add balance polling and fix address truncation` — two logical changes in one commit.
- ✗ `feat: ajoute le polling du solde` — not English.
- ✗ `git add -A && git commit -m "wip"` — bulk staging and non-conventional message.
- ✗ `git commit --no-verify` — bypasses hooks; only if the user explicitly asks.
- ✗ Adding `Co-Authored-By: Claude …` or any AI-attribution trailer — forbidden in this repo.
- ✗ Body that paraphrases the diff or restates the subject — the reader can see the diff. Delete the body.
- ✗ Body longer than 2 short sentences — if it's that long, it belongs in a PR description, not a commit message.

## Boundary conditions

- **Nothing to commit** → report "working tree clean" and stop. Do not create an empty commit.
- **User explicitly asks to commit secrets/binaries** → warn once, then proceed only on confirmation.
- **Merge conflict in progress** → stop and ask the user how to proceed; do not `git commit` blindly.
- **Detached HEAD or unexpected branch** → surface it before committing.
- **User did not ask to push** → never push after committing.
