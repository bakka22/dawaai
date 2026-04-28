# AGENTS.md

## Project Structure

This repository has two main directories:

```text
/backend      → API, business logic, database, auth, server-side configuration
/flutter_app  → Flutter mobile application, UI, client-side services, app assets
```

Rules:
- Backend work must stay inside `/backend`.
- Flutter work must stay inside `/flutter_app`.
- Do not mix backend and Flutter changes in the same commit unless the task explicitly requires a full-stack change.
- Do not create new root-level directories unless explicitly approved.
- Keep the repository root clean. Root files should be limited to documentation and project-level config.

---

## Work Tree Safety Rules — Critical

The work tree must be protected at all times.

Before running any command that can overwrite, discard, reset, switch, clean, rebase, merge, or otherwise modify existing work, the agent must first inspect the current state:

```bash
git status --short
git diff
git diff --staged
```

The agent must not proceed if there are uncommitted changes that are unrelated to the current task.

### Forbidden without explicit user approval

Never run these commands unless the user clearly approves after being warned that work may be lost:

```bash
git checkout .
git checkout -- <file>
git restore .
git restore <file>
git reset --hard
git clean -fd
git clean -fdx
git stash -u
git stash --all
git rebase
git merge
git switch <branch>
git checkout <branch>
```

### Branch switching rule

Before switching branches:

1. Run `git status --short`.
2. If there are changes, stop and report them.
3. Ask the user whether to commit, stash, or cancel.
4. Do not choose automatically.

### File overwrite rule

Before editing or replacing any file:

- Check whether the file has uncommitted changes.
- Preserve user edits.
- Prefer small targeted edits over full-file rewrites.
- Never overwrite a file just to “simplify” the task.

### User work protection rule

Uncommitted user work is more important than completing the task quickly.

If there is any risk of data loss, stop and ask.

---

## Source Control Rules

### Branches

- `main` must remain production-ready.
- `dev` is the integration branch.
- Use short task branches:

```text
feature/<name>
fix/<name>
refactor/<name>
```

### Commits

Use clear scoped commits:

```text
feat(backend): add clinic filtering
fix(flutter): resolve login token handling
refactor(api): simplify auth middleware
```

Avoid vague commits such as:

```text
update
changes
fix stuff
final
```

### Commit discipline

- Do not mix unrelated changes in one commit.
- Do not commit secrets, tokens, `.env`, generated build folders, or local IDE files.
- Do not commit dependency lockfile changes unless they are expected.
- Run relevant tests or analysis before committing when possible.

---

## Flutter App Commands

Run from `/flutter_app`:

```bash
flutter run
flutter run -d <device_id>
flutter build apk --debug
flutter build apk --release
flutter test
flutter analyze
flutter format .
```

---

## Backend Commands

Run from `/backend`:

```bash
npm install           # Install dependencies
npm run dev          # Start development server
npm test             # Run tests
```

**Entry point**: `backend/src/index.js`

---

## Testing Rules

- Run the smallest relevant test first.
- For Flutter UI changes, run `flutter analyze` and relevant widget tests.
- For backend logic, run service/API tests where available.
- Do not ignore failing tests unless the failure is clearly unrelated and reported.

---

## Environment and Secrets

- Never commit `.env`, private keys, tokens, certificates, or credentials.
- Keep `.env.example` updated with required variable names only.
- Do not hardcode API URLs, database credentials, or secret keys.

---

## Code Quality Rules

- Keep changes focused and minimal.
- Prefer readable code over clever code.
- Keep business logic out of Flutter UI widgets.
- Keep database access out of controllers when a service layer exists.
- Avoid large refactors unless explicitly requested.
- Do not rename files, classes, routes, or public APIs without a clear reason.

---

## Agent Behavior Rules

- **Always use the appropriate skill for each task:**
  - Backend/Node.js tasks → use `nodejs-backend` skill
  - Flutter UI/UX tasks → use `flutter-frontend-design` skill
  - Flutter architecture/code tasks → use `flutter-code-structure` skill

- **Explicitly state the skill being used** when starting work on any task.

- Explain risky operations before doing them.
- Ask before destructive operations.
- Preserve existing project style.
- Do not silently change architecture.
- Do not assume uncommitted changes are disposable.
- When unsure, stop and ask.

---

## Project-Specific Details

### Environment Variables (Backend)

Create `.env` in `/backend`:
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` (PostgreSQL)
- `GOOGLE_CLOUD_VISION_API_KEY` (for OCR)
- `JWT_SECRET`

### Key Architecture Notes

1. **OCR Flow**: Camera → Image → Base64 → Google Cloud Vision API → Extract text → Parse medications → User confirms

2. **Search Algorithm**:
   - Backend compares extracted medications against pharmacy inventories
   - Sort by: (1) most medications matched, (2) nearest distance
   - Search starts in user's city, option to expand to nearby cities
   - Distance calculated via lat/lng coordinates (OSM Nominatim for geocoding)

3. **Pharmacy Approval**: Manual admin approval required before pharmacy goes live

4. **Arabic RTL**: Use `flutter_localizations` and `Directionality` widget for full RTL support
