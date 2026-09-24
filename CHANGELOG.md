# Ogma Development Log

> Keep this file updated in the same commit as every meaningful code, design, documentation, configuration, or resource change.

```md
## YYYY-MM-DD

- `commit number` — **commit title**
  - description / list of changes
```

---

## 2026-09-24

- **fix: keep suggestions next to the caret**
  - Removed the extra panel-width offset after device testing showed the popup too far to the right.

- **fix: keep suggestions clear of the typing area**
  - Position the popup to the side of the caret when screen space allows, with screen-aware fallbacks.

- **feat: add custom slash shortcuts**
  - Added create, edit, delete, and enable controls for locally saved text shortcuts.
  - Reused the existing trigger engine and non-activating popup for `/shortcut` suggestions.
  - Added shortcut search and persistence checks; manual cross-app and multiline testing remains.

## 2026-09-23

- **feat: add native emoji picker MVP**
  - Added the Swift/AppKit menu-bar app, trigger handling, bundled emoji search, non-activating popup, Accessibility integration, and direct text insertion.
  - Verified the core emoji flow on the development Mac and added lightweight trigger/search checks.
  - Configured automatic Apple Development signing for local testing.
  - Moved the newer product specification into `Resources/` as the single working copy and added the moodboard at its referenced path.

## 2026-09-22

- `7ff5994` — **docs: add product specification**
  - Added `Product Specification.md` as the authoritative product and build specification for Ogma (moved into `Resources/` on 2026-09-23).
  - Updated visual-reference paths to the renamed `Resources/moodboard.png` location.
  - Preserved the Monogram O branding direction, product architecture, MVP scope, privacy requirements, and Codex implementation guidance.

- **docs: add repository development log**
  - Added the root-level `CHANGELOG.md` as the ongoing record of Ogma development.
  - Adopted the same date-grouped, commit-oriented format used by the GoPlaces development log.
  - Established the rule that meaningful project changes should update this log as part of the same commit.

- **chore: initialize Ogma project structure**
  - Created the GitHub repository at `raulpop8/ogma` with `main` as the default branch.
  - Renamed the project specification to `Product Specification.md`.
  - Renamed the design/resources directory to `Resources/` for product, branding, and visual reference assets.
  - Kept the product identity fixed as Ogma for macOS with bundle identifier `com.raulpop.Ogma`.

- **design: establish initial Ogma brand direction**
  - Selected the Monogram O as the primary Ogma logo direction.
  - Defined light, dark, minimal, glyph, and menu-bar treatments around the same monogram.
  - Established the current Ogma palette: Ink `#18161F`, Parchment `#F3EFE7`, Violet `#7567F8`, Stone `#9C96A7`, and Gold `#D4A853`.
  - Kept SF Pro/system typography for the macOS interface and SF Mono for shortcuts and code-like text.
  - Retained Ogham as a secondary historical/visual reference rather than the primary logo.
