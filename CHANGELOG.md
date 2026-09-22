# Ogma Development Log

> Keep this file updated in the same commit as every meaningful code, design, documentation, configuration, or resource change.

```md
## YYYY-MM-DD

- `commit number` — **commit title**
  - description / list of changes
```

---

## 2026-09-22

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
