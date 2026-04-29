# AGENTS.md

## Project Structure
- `/backend` → API, business logic, database, auth, server-side (Node.js/Express)
- `/flutter_app` → Flutter mobile app, UI, client-side services, assets

## Critical Rules
- Backend work MUST stay in `/backend`; Flutter work in `/flutter_app`
- Never mix backend/Flutter changes in same commit unless task requires full-stack
- Do not create new root-level directories without explicit approval
- Keep repository root clean: only documentation and project-level config

## Developer Commands

### Backend (`/backend`)
- Install: `npm install`
- Dev server: `npm run dev` (starts `src/index.js`)
- Test: `npm test` (Jest, excludes `src/index.js` & storage service)
- Entry point: `backend/src/index.js`
- Required `.env` vars: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `GOOGLE_CLOUD_VISION_API_KEY`, `JWT_SECRET`

### Flutter (`/flutter_app`)
- Run: `flutter run` or `flutter run -d <device_id>`
- Test: `flutter test`
- Analyze: `flutter analyze`
- Format: `flutter format .`
- Build APK: `flutter build apk --debug` or `--release`
- Main entry: `lib/main.dart`
- State management: Riverpod (`flutter_riverpod`)
- Primary locale: Arabic (`Locale('ar')`), with English fallback
- RTL implementation: Uses `flutter_localizations` + `Directionality` widget

## Architecture Notes
1. **OCR Flow**: Camera → Image → Base64 → Google Cloud Vision API (via AWS Proxy) → Extract text → Parse medications → User confirms
   - **AWS Relay Required**: Mobile App → AWS Proxy Server (Global) → Google Cloud Vision → AWS Proxy → Mobile App (to bypass regional blocking in Sudan)
2. **Search Algorithm**: 
   - Compares extracted meds against pharmacy inventories
   - Sorts by: (1) most medications matched, (2) nearest distance
   - Starts in user's city, expand to nearby cities
   - Distance via lat/lng (OSM Nominatim for geocoding)
3. **Auth System**: Hybrid - Firebase (primary) + WhatsApp (fallback for service failures)
4. **Pharmacy Approval**: Manual admin approval required before pharmacy goes live
5. **Firebase**: Used for cloud messaging (FCM)
6. **Regulatory Safety**: High-risk medications trigger "Triple-Leg" driver trip: [Customer → Pharmacy → Customer]
7. **Core Workflow**: Scan → Verify → Broadcast Quote → Live Bids → Order → Regulatory Delivery

## Testing (TDD Required)
1. Write tests FIRST based on `@MVP-Plan.md` and `@SPEC.md`
   - Backend: `backend/tests/`
   - Flutter: `flutter_app/test/`
   - Full-stack: both locations
2. Test coverage must include:
   - Normal cases (happy path)
   - Edge cases (boundary, empty, null)
   - Error cases (invalid input, network failures, validation)
3. Run tests BEFORE implementation (should fail RED)
4. Implement minimum code to pass tests (GREEN)
5. Run tests AFTER implementation:
   - Backend: `npm test`
   - Flutter: `flutter test` + `flutter analyze`
6. **HARD RULE**: ALL TESTS MUST PASS before proceeding
   - No exceptions: 100% pass rate required
   - Fix failing tests before continuing
   - Run full test suite after each phase
   - Never skip/ignore failing tests

## Work Tree Protection
- ALWAYS inspect state before destructive commands:
  ```bash
  git status --short
  git diff
  git diff --staged
  ```
- NEVER run these without explicit user approval (work may be lost):
  - `git checkout .`, `git checkout -- <file>`
  - `git restore .`, `git restore <file>`
  - `git reset --hard`
  - `git clean -fd`, `git clean -fdx`
  - `git stash -u`, `git stash --all`
  - `git rebase`, `git merge`
  - `git switch <branch>`, `git checkout <branch>`
- Before switching branches:
  1. Check `git status --short`
  2. If changes, stop and report
  3. Ask user: commit, stash, or cancel
  4. Never choose automatically
- Before editing/replacing any file:
  - Check for uncommitted changes
  - Preserve user edits
  - Prefer small targeted edits over full rewrites
  - Never overwrite just to "simplify" task
- Uncommitted user work > task completion speed
- If risk of data loss, STOP and ask

## Source Control
- Branches:
  - `main`: production-ready
  - `dev`: integration branch
  - Task branches: `feature/<name>`, `fix/<name>`, `refactor/<name>`
- Commits:
  - Use clear scoped commits:
    - `feat(backend): add clinic filtering`
    - `fix(flutter): resolve login token handling`
    - `refactor(api): simplify auth middleware`
  - Avoid vague commits: `update`, `changes`, `fix stuff`, `final`
  - Never mix unrelated changes
  - Never commit secrets, tokens, `.env`, build folders, IDE files
  - Don't commit lockfile changes unless expected
  - Run relevant tests/analysis before committing when possible

## Code Quality
- Keep changes focused and minimal
- Prefer readable code over clever code
- Keep business logic out of Flutter UI widgets
- Keep database access out of controllers when service layer exists
- Avoid large refactors unless explicitly requested
- Do not rename files, classes, routes, or public APIs without clear reason

## Agent Behavior
- ALWAYS use appropriate skill:
  - Backend/Node.js → `nodejs-backend` skill
  - Flutter UI/UX → `flutter-frontend-design` skill
  - Flutter architecture/code → `flutter-code-structure` skill
- EXPLICITLY state skill being used when starting task
- Explain risky operations before doing them
- Ask before destructive operations
- Preserve existing project style
- Do not silently change architecture
- Do not assume uncommitted changes are disposable
- When unsure, STOP and ask