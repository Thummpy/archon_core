# Commit-Close $ARGUMENTS

Review changes, run validation, create an enriched conventional commit, push, create a PR, and close the associated issue. This is the terminal lifecycle command — use it when work on an issue is complete.

Accepts `--skip-validate` to bypass the validation gate (use for WIP commits, documentation-only changes, or when validation is not yet configured).

## Instructions

### Step 1 — Review Changes

Run these commands to understand what will be committed:

1. `git status` — see staged, unstaged, and untracked files.
2. `git diff --cached` — review staged changes in detail.
3. `git diff` — review unstaged changes that may also need staging.
4. `git ls-files --others --exclude-standard` — check for new untracked files.

If there are unstaged changes that belong in this commit, stage them. If there are changes that belong in a separate commit, leave them unstaged and note this.

**Do NOT stage:**
- `.env` or credential files
- Large binary files
- Files unrelated to the current task

### Step 2 — Run Validation

Unless `$ARGUMENTS` contains `--skip-validate`:

1. Run `.claude/scripts/validate.sh --skip-integration` (lint, type check, unit tests, build — no integration tests).
2. If validation **fails**: **stop**. Show the failure output. Do not proceed to commit message generation. Tell the developer to fix the failures or re-run with `--skip-validate` if this is intentional.
3. If validation **passes** (including graceful skips for unconfigured steps or missing directories): proceed to the next step.

If `--skip-validate` is present, note it in the commit flow and proceed directly.

### Step 3 — Generate Commit Message

Create a conventional commit message with these components:

**Subject line** (required):
- Format: `type(scope): concise description`
- Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`
- Scope is the primary module, directory, or component affected (e.g., `feat(api): add rate limiting`)
- Omit scope if the change is truly cross-cutting
- Under 72 characters
- Imperative mood ("add", not "added" or "adds")

**Body** (required for non-trivial changes):
- Blank line after subject
- Explain WHY the change was made, not just what changed
- Reference the motivation: what problem does this solve, what feature does this enable

**Context footer** (if `.claude/` files were modified):
- List each AI context file that changed and what changed
- This matters because the git log is long-term memory — future sessions use it to understand when and why rules, commands, or docs evolved

```
Context:
- Updated .claude/rules/testing.md with new assertion patterns
- Added .claude/commands/prime-api.md for API subsystem context
```

**What counts as AI context changes:**
- `.claude/rules/` — conventions added, updated, or removed
- `.claude/commands/` — slash commands created or modified
- `.claude/docs/` — reference docs added or updated
- `.claude/CLAUDE.md` — global rules changes

**Refs footer** (if a ticket exists):
- `Refs: #123` or similar GitHub Issue reference

### Step 4 — Preview Message

Log the generated commit message so the developer can see it in the output, then proceed directly to execution.

```
type(scope): subject line

Body explaining why.

Context:
- .claude/ changes listed here

Refs: ticket-number
```

### Step 5 — Handoff

Write `.claude/HANDOFF.md` to capture session state for the next session. Follow the same process as `/handoff`:

1. Run `git diff --stat`, `git log --oneline -20`, and `git ls-files --others --exclude-standard` to gather context.
2. Write a concise handoff document covering: Goal, What Was Done, Key Decisions, Current State, Next Steps, and Issue Tracker Status.
3. Stage `.claude/HANDOFF.md` so it is included in the commit.

Keep the handoff under 100 lines. Omit empty sections.

### Step 6 — Clean Up PRP

If a PRP file was used for this work, remove it before committing. Only remove PRPs associated with the current issue — do not touch PRPs for other issues.

1. **Detect the issue number** using the same logic as Step 9:
   a. `$ARGUMENTS` — if a number was passed (e.g., `/commit-close 4`), use that.
   b. The current branch name — if it matches `feat/issue-<number>-*`, extract the number.
2. If an issue number was found, check for `.claude/prps/<issue-number>.md` (e.g., `.claude/prps/4.md`).
3. As a fallback, also check for PRPs matching the slugified branch name (exclude `templates/`).
4. If a matching PRP is found, run `git rm <prp-file>` to stage the removal.
5. PRPs are working documents — git history preserves them if ever needed.
6. If no PRP is found, skip this step silently.

### Step 7 — Update README if Needed

1. Read `README.md` and review the staged changes (`git diff --cached`).
2. Check whether the changes in this commit affect any of:
   - Setup or installation steps
   - Architecture or component structure
   - Public API surface or endpoints
   - Tech stack (new dependencies, removed tools)
   - Environment variables or configuration
3. If any of those areas changed, update the relevant sections of `README.md` to reflect the current state and stage it.
4. If nothing README-relevant changed, skip this step silently.

### Step 8 — Execute Commit

Run `SKIP_VALIDATE=1 git commit` with the generated message. The `SKIP_VALIDATE=1` prefix bypasses the pre-commit hook since validation already ran in Step 2. This single commit includes feature changes, the handoff, the PRP removal, and any README updates. Record the commit hash for use in later steps.

### Step 9 — Push

Push the current branch to the remote:

1. `git branch --show-current` — get the branch name.
2. If the branch is `main` or `master`, **warn the developer** and ask for confirmation before pushing.
3. Otherwise, run `git push -u origin <branch>`.
4. Report the push result.

### Step 10 — Close Issue (conditional)

If a GitHub issue is associated with this work, handle closure based on the branch context:

1. **Detection** — check these sources in order:
   a. `$ARGUMENTS` — if a number was passed (e.g., `/commit-close 4`), use that.
   b. The `Refs:` footer in the commit message (e.g., `Refs: #4` means issue 4).
   c. The current branch name — if it matches a pattern like `feat/issue-4-*` or `fix/4-description`, extract the number.
2. **If on `main` or `master`** (direct push, no PR): run `gh issue close <number> --comment "Closed by commit <hash>"` where `<hash>` is the commit hash from Step 8.
3. **If on a feature branch**: do NOT close the issue. Record the issue number — Step 11 will include `Closes #<number>` in the PR body, which auto-closes the issue when the PR merges.
4. If no issue number is detected, skip this step silently.

### Step 11 — Create Pull Request

If the current branch is not `main` or `master`, create a pull request:

1. **Generate the PR title** from the conventional commit subject line used in Step 3 (e.g., `feat(commands): enhance plan-feature and commit-close workflows`).
2. **Generate the PR body** with:
   - A `## Summary` section listing commits on this branch: `git log main..HEAD --pretty=format:"- %s"`
   - A `Closes #<issue-number>` line if an issue number was detected in Step 10
3. **Create the PR**:
   ```
   gh pr create --title "<title>" --body "<body>" --delete-branch
   ```
   The `--delete-branch` flag configures the branch to be deleted automatically when the PR is merged.
4. **Report the PR URL** returned by `gh pr create`.
5. If PR creation fails (e.g., a PR already exists for this branch), report the error but do not fail the overall command. Suggest `gh pr view` to check the existing PR.
