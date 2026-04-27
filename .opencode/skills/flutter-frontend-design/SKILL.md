---
name: flutter-frontend-design
description: Use when designing or improving Flutter frontend UI, screens, widgets, layouts, navigation, responsiveness, visual polish, Arabic/RTL support, and frontend architecture. Focuses on clean mobile UI implementation inside flutter_app only.
license: MIT
compatibility: opencode
metadata:
  stack: flutter-dart
  scope: frontend
---

# Flutter Frontend Design Skill

## Purpose
Use this skill when working on Flutter UI/UX, screens, widgets, navigation, responsive layouts, visual styling, RTL/Arabic interfaces, forms, cards, lists, animations, and frontend refactoring.

This skill applies only to the Flutter app directory:

```text
/flutter_app
```

Do not edit backend code while using this skill.

---

## Critical Scope Rules

- Work only inside `/flutter_app` unless the user explicitly asks otherwise.
- Do not modify `/backend` files.
- Do not change API contracts unless the user explicitly approves it.
- Do not rename routes, models, services, or shared keys without checking usage first.
- Do not remove existing UI behavior unless the user explicitly asks for removal.
- Before editing, inspect the relevant screen, widgets, route definitions, service calls, and state management files.

---

## Work Tree Safety Rules

Before any destructive or source-control-related command, always check the work tree.

Required before running commands such as `git checkout`, `git switch`, `git reset`, `git restore`, `git clean`, `git pull --rebase`, or any command that may overwrite files:

```bash
git status --short
```

Rules:

- Never discard user changes automatically.
- Never run `git checkout .`, `git reset --hard`, `git clean -fd`, or `git restore .` unless the user explicitly confirms after seeing the affected files.
- If there are uncommitted changes, stop and explain the risk.
- Prefer creating a safety branch or stash before switching branches.
- If stashing is needed, use a descriptive stash message:

```bash
git stash push -m "safety: before flutter frontend design changes"
```

- Do not overwrite generated or user-edited Flutter files without checking diffs first.

Useful inspection commands:

```bash
git status --short
git diff -- flutter_app
git diff --stat
```

---

## Flutter UI Design Principles

Prioritize:

- Clear hierarchy: title, subtitle, main action, secondary action.
- Consistent spacing: prefer `const EdgeInsets.all(16)` or reusable spacing constants.
- Reusable widgets instead of duplicated UI blocks.
- Small widgets with clear responsibilities.
- Responsive layouts using `LayoutBuilder`, `MediaQuery`, `Flexible`, `Expanded`, `Wrap`, and scroll views where needed.
- Avoid overflow by testing small screens and long text.
- Use `SafeArea` for screen content.
- Use `ListView`, `CustomScrollView`, or `SingleChildScrollView` only where appropriate.
- Keep business logic out of widgets when possible.

---

## Arabic and RTL Rules

When the UI is Arabic or mixed Arabic/English:

- Support RTL layout using `Directionality` when needed.
- Avoid hardcoded left/right when directional values are better:
  - Prefer `EdgeInsetsDirectional`
  - Prefer `AlignmentDirectional`
  - Prefer `BorderRadiusDirectional` when relevant
- Test long Arabic text and mixed numbers/English words.
- Keep labels readable and avoid cramped cards.

---

## Flutter Code Rules

- Prefer `const` constructors where possible.
- Do not create large build methods; extract widgets.
- Do not perform network calls directly inside `build()`.
- Do not call `setState()` after dispose; check `mounted` when needed.
- Keep API calls in service classes.
- Keep UI state explicit and simple.
- Use meaningful widget names.
- Keep files focused: one major screen or reusable widget per file.

---

## Navigation Rules

- Before changing navigation, inspect existing route names and arguments.
- Do not break existing `Navigator.pushNamed`, `pushReplacementNamed`, or `pop(result)` flows.
- When passing arguments, define the expected shape clearly.
- When returning results from a page, document what result is returned.

---

## Forms and Input Rules

- Use `Form` and `GlobalKey<FormState>` for validated forms.
- Validate required fields before API calls.
- Show loading states during async actions.
- Show clear error messages.
- Disable submit buttons while submitting to prevent duplicate requests.
- Do not store passwords, tokens, or secrets in logs.

---

## Visual Polish Checklist

Before finishing a UI task, check:

- No overflow warnings.
- Loading, empty, success, and error states exist where relevant.
- Buttons have clear labels.
- Text is readable on small screens.
- Cards/lists have consistent spacing.
- Images have placeholders or error handling when possible.
- The screen works in RTL if Arabic is used.

---

## Commands

Run from project root:

```bash
cd flutter_app
flutter analyze
flutter test
flutter format .
```

For code generation when the project uses it:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Do not run build/code generation unless the project requires it or the user asks.

---

## Done Criteria

A Flutter frontend task is done only when:

- The change is limited to `/flutter_app` unless approved otherwise.
- Existing behavior is preserved unless explicitly changed.
- The UI handles loading/error/empty states where relevant.
- The code is formatted.
- `flutter analyze` is clean, or remaining issues are clearly reported.
- Any risky work tree situation was reported before action.
