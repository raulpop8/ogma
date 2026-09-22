# Ogma — Product & Build Specification

> **Status:** Working specification  
> **Purpose:** Single source of truth for planning and building Ogma.  
> **Primary implementation target:** Codex working directly in the repository.  
> **Last updated:** 2026-09-22

---

## 1. Project Identity

- **Product name:** Ogma
- **Project name:** Ogma
- **Platform:** macOS
- **Bundle identifier:** `com.raulpop.Ogma`
- **Primary language:** Swift
- **UI:** SwiftUI where appropriate, AppKit where macOS-specific behavior requires it
- **Minimum macOS target:** macOS 14 unless a required API forces a newer version
- **Distribution:** To be decided later. Direct signed/notarized distribution is acceptable if Mac App Store sandboxing becomes restrictive.
- **Repository/project naming:** Use `Ogma` consistently. Do not create temporary project names such as `EmojiApp`, `TextExpander`, `EmojiPicker`, etc.

### Name and brand rationale

Ogma is intentionally prioritized for:

- memorability
- ease of pronunciation
- ease of typing
- a strong standalone product identity
- room to grow beyond emoji into snippets, shortcuts, and text actions

The brand has a subtle connection to writing, language, speech, and Ogham, but the application should **not** look mythological, medieval, Celtic-themed, or fantasy-themed.

---

## 2. Product Summary

Ogma is a lightweight native macOS utility that helps users type faster.

The first feature is a system-wide emoji picker triggered directly while typing.

Example:

```text
Hello :smile
```

While the user types `smile`, Ogma displays a small autocomplete popup near the current text caret:

```text
😊  smiling face
😃  grinning face
😁  beaming face
🙂  slightly smiling face
```

Keyboard behavior:

- `↑` / `↓` changes the selected result
- `Enter` / `Return` inserts the selected emoji
- `Escape` cancels the picker

After selection:

```text
Hello :smile
```

becomes:

```text
Hello 😊
```

Ogma must not steal focus from the application in which the user is typing.

---

## 3. Long-Term Product Direction

Ogma should later evolve into a lightweight text expander and text-command utility.

Examples:

```text
/email
→ my@email.com
```

```text
/phone
→ saved phone number
```

```text
/address
→ saved address
```

```text
/signature
→ multi-line signature
```

```text
/thanks
→ Thanks for getting in touch!
```

```text
/date
→ current date
```

Users should eventually be able to create arbitrary custom shortcuts and replacement text.

The architecture should make this future direction easy, but **the emoji picker is the first development milestone**.

Do not build every future feature before the emoji MVP works end-to-end.

---

## 4. Product Principles

Ogma should feel:

- small
- fast
- native
- quiet
- keyboard-first
- precise
- useful
- unobtrusive

The app should appear when needed, perform an action, and disappear.

It should not behave like a dashboard, launcher, or large productivity suite.

### Core principles

1. **Stay out of the user's way.**
2. **Do not steal focus.**
3. **Do not interfere with normal typing when inactive.**
4. **Use native macOS behavior where possible.**
5. **Avoid unnecessary dependencies.**
6. **Avoid unnecessary abstraction.**
7. **Do not behave like a keylogger.**
8. **Build the smallest reliable end-to-end flow first.**

---

## 5. MVP Definition

The first milestone is complete when the following flow works reliably:

1. Launch Ogma.
2. Ogma appears in the macOS menu bar.
3. User grants required permissions.
4. User opens Notes or another standard text editor.
5. User types:

```text
:smile
```

6. Ogma shows a floating list of matching emoji near the typing caret.
7. User presses `↑` / `↓` to change selection.
8. User presses `Enter`.
9. The typed trigger is replaced by the selected emoji:

```text
😊
```

10. Ogma disappears.
11. The target application remains focused.
12. `Escape` cancels the picker.
13. Normal typing continues to work while Ogma is inactive.

---

## 6. MVP Non-Goals

Do **not** delay the first milestone by implementing:

- cloud sync
- accounts
- Supabase
- Firebase
- CloudKit sync
- analytics
- App Store analytics
- plugin systems
- AI functionality
- snippet folders
- advanced snippet variables
- custom themes
- marketplace features
- team sharing
- onboarding polish beyond what permissions require
- advanced branding assets
- updater systems
- import/export
- mobile versions
- Windows versions
- iOS versions

These can be considered later.

---

## 7. Technical Stack

Use native macOS technologies.

### Required

- Swift
- SwiftUI
- AppKit where necessary
- Core Graphics event APIs where necessary
- macOS Accessibility APIs where necessary
- ServiceManagement only if Launch at Login is implemented

### Do not use

- Electron
- React Native
- Flutter
- Tauri
- a browser/webview as the main application UI

### Dependency rule

Prefer Apple frameworks.

Do not add a third-party dependency unless it provides a significant benefit.

Before introducing a dependency, explain why it is needed.

---

## 8. Suggested Project Structure

This is guidance, not a rigid requirement.

```text
Ogma/
├── App/
│   ├── OgmaApp.swift
│   ├── AppState.swift
│   └── MenuBarController.swift
│
├── Models/
│   ├── EmojiItem.swift
│   └── TextSnippet.swift
│
├── Services/
│   ├── GlobalKeyboardMonitor.swift
│   ├── TriggerEngine.swift
│   ├── EmojiSearchService.swift
│   ├── TextInsertionService.swift
│   ├── AccessibilityService.swift
│   └── PermissionService.swift
│
├── UI/
│   ├── EmojiPickerView.swift
│   ├── EmojiPanelController.swift
│   ├── SettingsView.swift
│   ├── GeneralSettingsView.swift
│   ├── SnippetsSettingsView.swift
│   └── PermissionsView.swift
│
└── Resources/
    └── emoji.json
```

Keep responsibilities separated:

- keyboard monitoring
- trigger parsing
- emoji search
- popup presentation
- accessibility
- text insertion
- permissions
- settings

Do not create generic protocol layers without an actual need.

---

## 9. Menu-Bar Application Behavior

Ogma should primarily live in the macOS menu bar.

During normal operation:

- no standard app window should remain open
- the app should ideally not appear in the Dock
- the menu-bar item should remain available while Ogma runs

### Initial menu-bar items

For MVP:

- Enable / Disable Ogma
- Settings…
- Quit Ogma

Possible future items:

- Pause
- Launch at Login
- Check for Updates
- About Ogma

Use a simple temporary menu-bar symbol until the final Ogma mark is available.

---

## 10. Global Keyboard Monitoring

Ogma must detect relevant typing while another application is focused.

Use the appropriate native macOS mechanism, likely `CGEventTap`.

### Requirements

- event-driven
- no continuous polling
- low idle CPU usage
- do not store general typing history
- do not log typed content
- do not activate Ogma when triggers are detected

### Initial trigger

Typing:

```text
:
```

begins emoji-search mode when context is appropriate.

Ogma then tracks:

```text
:
:s
:sm
:smi
:smil
:smile
```

Only the minimal temporary buffer needed for the active trigger should be kept.

When the trigger is cancelled or completed, discard the temporary buffer.

---

## 11. Trigger Engine

Create a dedicated `TriggerEngine`.

Do not place trigger parsing inside SwiftUI views.

The trigger engine should eventually support multiple trigger families.

### Emoji trigger

```text
:query
```

Example:

```text
:coffee
```

### Future snippet trigger

```text
/shortcut
```

Example:

```text
/email
```

### Trigger state should include

- current trigger character
- current query
- active mode
- typed character count
- whether a trigger is active
- current selection
- cancellation state

### Cancellation conditions

Cancel the active trigger when appropriate, including:

- `Escape`
- user deletes past the trigger
- unsupported character
- focus/context change
- secure field is detected
- certain whitespace/terminating characters

The first implementation does not need perfect contextual intelligence.

Use reasonable, easy-to-improve rules.

---

## 12. Trigger Context

Avoid activating Ogma unnecessarily for ordinary colons.

Examples where triggering may be undesirable:

- URLs
- timestamps
- code
- punctuation-heavy text
- certain numeric contexts

Do not attempt to solve every edge case before MVP.

Implement conservative rules that can be improved later.

---

## 13. Emoji Data

Keep emoji data outside Swift source files.

Use a bundled resource such as:

```text
emoji.json
```

### Suggested model

```swift
struct EmojiItem: Identifiable, Codable, Hashable {
    let id: String
    let emoji: String
    let name: String
    let keywords: [String]
    let aliases: [String]
}
```

Use Unicode / CLDR-style:

- names
- keywords
- aliases

Do not scatter hard-coded emoji mappings across the codebase.

The resource should be replaceable independently of search logic.

---

## 14. Emoji Search

Search should consider:

- aliases
- names
- keywords

Examples:

```text
smile
happy
laugh
heart
dog
coffee
party
```

### Ranking order

Use a lightweight ranking system, roughly:

1. exact alias
2. exact name
3. prefix alias
4. prefix name
5. prefix keyword
6. substring
7. lightweight fuzzy match

Do not add a heavy search framework.

### Result count

Show approximately:

```text
6–8 results
```

Search should update after every relevant keystroke and feel instantaneous.

### Future search capabilities

Architecture may later support:

- recent emoji
- favorites
- custom aliases
- multiple languages
- ranking personalization

Do not implement these yet.

---

## 15. Emoji Popup

The popup should be implemented with AppKit where appropriate, likely using a non-activating `NSPanel`.

### Requirements

The panel must:

- not steal keyboard focus
- not activate Ogma
- appear quickly
- remain visually above the current application where appropriate
- disappear immediately when cancelled
- support keyboard selection
- stay inside visible screen bounds
- work across multiple displays

### Example appearance

```text
┌────────────────────────────┐
│ 😊  smiling face           │
│ 😃  grinning face          │
│ 😁  beaming face           │
│ 🙂  slightly smiling face  │
└────────────────────────────┘
```

The selected row should have a subtle native highlight.

### Do not include

- separate search field
- toolbar
- header
- unnecessary buttons

The user is already typing the search query in the active application.

---

## 16. Popup Keyboard Interaction

While the popup is visible:

### Arrow Down

Select next result.

### Arrow Up

Select previous result.

### Enter / Return

Insert the selected result.

### Escape

Cancel and hide the popup.

### Optional later

- `Tab` to accept
- mouse click on result

Keyboard behavior has priority over mouse behavior.

---

## 17. Caret Positioning

Ogma should attempt to show the popup near the active insertion caret.

Create a dedicated `AccessibilityService`.

Responsibilities may include:

- identify active application
- find focused UI element
- retrieve selected text/caret information
- obtain caret or selection bounds
- convert coordinates correctly
- detect secure text fields where possible

Do not mix Accessibility logic into the popup UI itself.

### Fallback behavior

Some applications may not expose reliable caret geometry.

If caret bounds cannot be obtained:

- position near the mouse pointer, or
- use another sensible location on the active display

Caret-positioning issues must **not** prevent the emoji picker from functioning.

---

## 18. Text Insertion

Create a dedicated:

```text
TextInsertionService
```

The rest of Ogma should not need to know which insertion strategy is used.

### Required behavior

Typing:

```text
:coffee
```

and selecting coffee must produce:

```text
☕
```

not:

```text
:coffee☕
```

The full typed trigger must be removed before or as the replacement is inserted.

### Potential strategies

- Accessibility-based text replacement
- synthetic keyboard events
- clipboard + paste fallback

For MVP, choose the simplest reliable approach.

The design should allow insertion strategies to change later.

---

## 19. Clipboard Fallback

If using clipboard-based insertion:

1. capture existing clipboard state when feasible
2. place replacement text on the clipboard
3. remove typed trigger text
4. paste replacement into target application
5. restore previous clipboard contents safely

Do not permanently overwrite the user's clipboard.

Do not restore the clipboard so quickly that the target application misses the paste.

Avoid fragile timing where possible.

---

## 20. Trigger Deletion

Ogma needs to know how many typed characters belong to the active trigger.

Example:

```text
:smile
```

must be removed before inserting:

```text
😊
```

The trigger engine should track the relevant typed length.

Be careful with Unicode/grapheme behavior.

For MVP, ASCII search queries are sufficient.

---

## 21. Permissions

Ogma will likely require:

- Input Monitoring
- Accessibility

Create a dedicated:

```text
PermissionService
```

### Permission UX

Explain permissions clearly.

Suggested concepts:

#### Input Monitoring

> Ogma detects shortcuts such as `:smile` while you type.

#### Accessibility

> Ogma uses Accessibility to position suggestions and insert selected text into the active app.

### Requirements

- detect current permission state
- provide a way to open the relevant System Settings section when appropriate
- do not repeatedly nag the user
- degrade gracefully when permission is missing
- explain which functionality is unavailable

---

## 22. Privacy

This is a core product requirement.

Ogma monitors keyboard events, but it must **not behave like a keylogger**.

### Ogma must never

- store everything the user types
- save general typing history
- send typed content to a server
- log typed text
- include typed text in analytics
- record passwords
- intentionally inspect secure field contents
- save clipboard text for diagnostics

### Ogma may retain

Only the minimal temporary buffer required to understand the currently active Ogma trigger.

When the trigger ends, discard it.

### Network behavior

For MVP:

- no accounts
- no backend
- no network requests
- no analytics
- no cloud synchronization

---

## 23. Secure Fields

When macOS Accessibility APIs allow it, detect secure/password fields.

If a secure field is active:

- do not activate Ogma
- cancel an active trigger if necessary
- do not inspect contents
- do not store contents
- do not manipulate contents

---

## 24. Text Snippet Architecture

Text snippets are a later milestone but should fit naturally into the architecture.

### Suggested model

```swift
struct TextSnippet: Identifiable, Codable, Hashable {
    var id: UUID
    var trigger: String
    var replacement: String
    var isEnabled: Bool
}
```

### Examples

```text
/email
→ hello@example.com
```

```text
/thanks
→ Thanks for getting in touch!
```

```text
/signature
→ multi-line replacement text
```

### Future snippet management

Settings should eventually support:

- create
- edit
- delete
- enable
- disable

### Persistence

Use a lightweight local mechanism such as:

- Codable
- local JSON/plist file
- UserDefaults where appropriate

Do not add a database just for snippets.

---

## 25. Future Dynamic Snippets

Do not implement these in MVP, but avoid architecture choices that make them impossible.

Potential future features:

```text
/date
/time
/clipboard
```

Possible later additions:

- current date/time
- clipboard insertion
- snippet variables
- categories
- folders
- favorites
- imports/exports
- per-app exclusions
- multiple trigger characters
- application-specific rules

---

## 26. Settings

Use a native macOS Settings window.

SwiftUI is appropriate.

Possible sections:

- General
- Emoji
- Snippets
- Permissions
- About

### MVP settings

Only include settings that are useful now, such as:

- Enable Ogma
- Emoji trigger character — default `:`
- Launch at Login if straightforward

Do not spend excessive time styling the Settings screen.

Use standard macOS controls.

---

## 27. Launch at Login

If implemented, use Apple's current recommended APIs such as ServiceManagement.

Do not add a third-party login-item framework.

If Launch at Login becomes a distraction during MVP, defer it.

---

## 28. Target Applications

Aim for compatibility with common macOS applications such as:

- Notes
- Safari
- Chrome
- Messages
- Mail
- Xcode
- Slack
- Discord
- Electron applications where possible
- standard `NSTextField`
- standard `NSTextView`

Do not attempt to solve every compatibility issue before MVP.

### Expected harder cases

- Terminal applications
- unusual custom editors
- games
- remote desktop software
- applications with incomplete Accessibility support

Document limitations rather than overengineering around them.

---

## 29. Performance

Ogma should consume almost no CPU while idle.

### Requirements

- event-driven keyboard monitoring
- no constant Accessibility polling
- no continuous active-app scanning
- emoji search only while trigger is active
- low memory usage
- effectively instant search
- popup should appear without obvious delay

---

## 30. Error Handling

Ogma must not crash if:

- Accessibility permission is removed
- Input Monitoring is denied
- active application closes
- focused element disappears
- caret coordinates cannot be obtained
- emoji resource fails to load
- clipboard preservation fails
- target application rejects an insertion method

Fail gracefully and preserve normal user typing whenever possible.

---

## 31. Logging

Development logging may include events such as:

```text
keyboard monitor started
permissions missing
emoji data loaded
panel shown
panel hidden
insert operation succeeded
insert operation failed
```
Do **not** log:

- search query contents
- surrounding text
- focused field contents
- clipboard contents
- password contents
- arbitrary keystrokes

---

# Brand Specification

## 32. Brand Direction

Ogma should look like a modern native macOS utility with a subtle connection to writing and historical Ogham.

The selected primary brand mark is the **Monogram O**: a clean circular `O` symbol with a short horizontal bar beneath it. Use this mark consistently for the app icon, menu-bar identity, wordmark lockups, and other primary branding.

The broader visual idea remains:

> **modern writing mark**

Reference concepts:

- a clean monogram
- text insertion and writing
- glyphs
- precise geometric forms
- keyboard commands
- text transformation

Ogham should remain a secondary historical/reference element rather than the primary logo.

Do not turn the interface into mythology-themed decoration.

### Canonical Visual Reference

The primary visual reference for Ogma branding is:

`Resources/moodboard.png`

Codex and other implementation work should consult this moodboard when creating or selecting:

- app icon assets
- light/dark logo variations
- minimal and glyph-style logo variations
- menu-bar icon assets
- typography treatments
- brand colors
- branded UI states
- marketing or presentation visuals

The moodboard establishes the selected **Monogram O** direction.

If the moodboard and this written specification ever conflict, follow the written specification unless a later project decision explicitly overrides it.

---

## 33. Ogham Reference

The letters in "OGMA" may be represented in Ogham as:

```text
ᚑᚌᚋᚐ
```

With optional beginning/end feather marks:

```text
᚛ᚑᚌᚋᚐ᚜
```

This may be used as a **secondary decorative branding element**, not as the main functional UI or primary app icon.

Potential uses:

- About Ogma
- website footer
- README
- marketing artwork
- onboarding
- brand graphics

Do not overuse it.

---

## 34. App Icon Direction

The selected Ogma app-icon direction is the **Monogram O** shown in `Resources/moodboard.png`.

Use a standard macOS rounded-square composition.

### Primary mark

The primary symbol consists of:

- a clean circular `O`
- a short horizontal bar centered beneath the circle
- simple, geometric construction
- strong legibility at small sizes

The mark should remain recognizable in full-color app-icon form and as a simplified monochrome menu-bar symbol.

### Approved visual variations

The same Monogram O may be adapted into:

- dark version
- light version
- minimal version
- violet/accent version
- gold/glyph version
- monochrome menu-bar version

These should all remain visibly the same logo rather than becoming unrelated symbols.

### Desired characteristics

- dark Ogma Ink background for the primary app icon
- white/violet Monogram O for the primary treatment
- readable at very small sizes
- minimal
- geometric
- modern
- distinctive
- no text inside the icon
- no emoji inside the icon

### Avoid

- replacing the Monogram O with an Ogham-stroke logo
- Celtic knots
- swords
- shields
- fantasy motifs
- rune-heavy visuals
- literal mythology illustration
- detailed characters
- emoji as the app icon

Use `Resources/moodboard.png` as the visual reference when implementing these assets.

For MVP, a temporary asset is acceptable if final production icon files have not yet been supplied, but the final branding direction is no longer open.

---

## 35. Menu-Bar Icon

Use a simplified monochrome version of the **Monogram O** brand mark.

Requirements:

- template-style monochrome macOS asset
- circular `O` plus the short underline/bar
- readable at normal menu-bar size
- very simple geometry
- automatically adapts to Light/Dark mode
- visually consistent with `Resources/moodboard.png`
- no wordmark
- no emoji

Until the final vector/template asset exists, an appropriate temporary system symbol may be used during development.

---

## 36. Typography

Use native macOS typography.

### UI

Use:

```text
SF Pro / system font
```

for normal interface text.

### Triggers and code-like content

Use:

```text
SF Mono
```

where monospace improves clarity.

Examples:

```text
:smile
:coffee
/email
/signature
```

Do not bundle decorative fonts for MVP.

Do not use Celtic/fantasy display fonts.

The Ogma wordmark should remain simple and modern initially.

---

## 37. Brand Colors

Use these as reference brand colors.

| Role | Hex |
|---|---|
| Ogma Ink | `#18161F` |
| Warm Parchment | `#F3EFE7` |
| Ogma Violet | `#7567F8` |
| Stone | `#9C96A7` |
| Ogma Gold | `#D4A853` |

### Usage

**Ogma Violet** is the primary accent.

Possible uses:

- selected states
- small accent details
- onboarding
- marketing
- branding

**Ogma Gold** should be used sparingly, primarily for branding rather than ordinary controls.

### Important

Most functional UI should still use semantic macOS system colors.

Do not hard-code brand colors throughout unrelated SwiftUI views.

If custom colors become necessary, define them centrally.

---

## 38. Native macOS Appearance

Ogma must respect:

- Light Mode
- Dark Mode
- system accent behavior where appropriate
- native control appearance
- native spacing
- native materials
- native typography
- native hover behavior
- native selection behavior

Do not make the popup look like a web component.

Do not make the entire app purple.

Brand should support the native macOS UI, not replace it.

---

# Development Plan

## 39. Implementation Order

Implement in this order:

1. Inspect repository and current Xcode project.
2. Create/use project named `Ogma`.
3. Set bundle identifier to `com.raulpop.Ogma`.
4. Configure menu-bar application behavior.
5. Implement global keyboard monitoring.
6. Detect `:` trigger.
7. Maintain query state.
8. Add/load emoji dataset.
9. Implement emoji search and ranking.
10. Build floating non-activating popup.
11. Implement Up / Down / Enter / Escape.
12. Insert selected emoji into active application.
13. Improve popup positioning with Accessibility APIs.
14. Implement permission handling.
15. Add basic Settings.
16. Add `TextSnippet` model and `/trigger` architecture only after emoji MVP works.
17. Document compatibility limitations.
18. Polish only after the end-to-end core flow is stable.

---

## 40. Development Workflow for Codex

Codex will work directly in the repository.

### Before modifying anything

- inspect the repository
- inspect the current Xcode project
- reuse existing project structure if present
- do not create a second project unnecessarily

If the repository is empty, create the required native macOS project using:

```text
Project: Ogma
Product: Ogma
Bundle ID: com.raulpop.Ogma
Platform: macOS
```

### Working style

Prefer:

```text
inspect
implement
build
test
fix
continue
```

Do not spend large amounts of output explaining what will be done.

Do not repeat the specification unless necessary.

Do not ask minor architecture questions.

When an implementation detail is ambiguous, choose the simplest reasonable native macOS solution.

Ask only when a decision materially changes the product and cannot reasonably be inferred.

---

## 41. Build Discipline

After meaningful changes:

1. build the project
2. inspect compiler errors
3. fix them
4. build again

Do not leave the repository knowingly broken.

Do not claim the project builds unless a build was actually run.

Use the available Xcode tooling appropriately.

---

## 42. Coding Standards

Write production-quality Swift without overengineering.

Prefer:

- clear code
- small focused files
- explicit responsibilities
- native APIs
- simple data flow

Avoid:

- oversized god objects
- unnecessary protocols
- unnecessary dependency injection frameworks
- generic architecture for hypothetical future needs
- large third-party packages for small tasks

Comments should explain non-obvious macOS behavior, not narrate obvious code.

Do not rewrite working code purely for stylistic reasons.

When debugging:

1. identify the root cause
2. make the smallest reasonable fix
3. rebuild
4. verify behavior

---

## 43. Testing

Add lightweight unit tests where they have clear value.

Good early targets:

- `TriggerEngine`
- `EmojiSearchService`
- search ranking
- cancellation behavior
- query-state transitions

Do not spend excessive effort unit-testing AppKit integration.

Manual integration testing is expected for:

- global keyboard monitoring
- Input Monitoring permissions
- Accessibility permissions
- caret positioning
- popup behavior
- cross-application insertion
- clipboard restoration
- multi-display positioning

---

## 44. MVP Manual Test Checklist

Before declaring the first milestone complete, manually verify:

### App lifecycle

- [ ] Ogma launches
- [ ] menu-bar item appears
- [ ] app does not unnecessarily show in Dock
- [ ] Settings opens
- [ ] Quit works

### Permissions

- [ ] Input Monitoring state can be detected
- [ ] Accessibility state can be detected
- [ ] user can reach relevant System Settings
- [ ] missing permissions fail gracefully

### Trigger

- [ ] typing `:` can activate emoji mode
- [ ] query updates as letters are typed
- [ ] deleting characters updates query
- [ ] deleting past trigger cancels
- [ ] `Escape` cancels
- [ ] inactive Ogma does not interfere with typing

### Search

- [ ] `:smile` finds sensible emoji
- [ ] `:coffee` finds coffee
- [ ] search ranking is stable
- [ ] results update immediately
- [ ] only a reasonable number of results are shown

### Popup

- [ ] popup appears without activating Ogma
- [ ] active app remains focused
- [ ] popup appears on correct display
- [ ] popup stays inside visible screen bounds
- [ ] fallback positioning works when caret coordinates are unavailable

### Selection

- [ ] `↓` moves selection down
- [ ] `↑` moves selection up
- [ ] Return selects current result
- [ ] Escape hides popup

### Insertion

- [ ] trigger text is removed
- [ ] selected emoji is inserted
- [ ] clipboard contents are preserved if clipboard strategy is used

### Privacy

- [ ] no arbitrary typing is stored
- [ ] no search queries are written to logs
- [ ] no clipboard content is logged
- [ ] secure fields are ignored where detectable

---

## 45. First-Milestone Stop Condition

Once the emoji MVP works end-to-end, **stop adding unrelated features**.

Do not automatically continue into:

- full snippet management
- dynamic commands
- synchronization
- analytics
- updater
- extensive onboarding
- final icon work
- marketing site
- AI functionality

At that point provide a concise implementation summary containing:

- what was implemented
- important files/classes
- permissions required
- current text-insertion strategy
- applications tested
- known limitations
- important technical decisions
- recommended next milestone

---

# Future Roadmap

## 46. Likely Second Milestone — Text Snippets

After emoji functionality is reliable, implement user-defined slash shortcuts.

Example:

```text
/email
```

becomes:

```text
hello@example.com
```

Required future functionality:

- create snippet
- edit snippet
- delete snippet
- enable/disable snippet
- persist locally
- support multi-line replacement text

The same `TriggerEngine` and `TextInsertionService` should be reused.

Do not build an entirely separate expansion system.

---

## 47. Later Possibilities

Potential future capabilities:

- `/date`
- `/time`
- `/clipboard`
- recent emoji
- favorite emoji
- custom emoji aliases
- multiple trigger characters
- snippet folders
- snippet categories
- import/export
- snippet variables
- per-app exclusions
- per-app behavior
- pause Ogma in selected apps
- keyboard shortcuts
- custom transformations
- additional command types
- update mechanism
- optional advanced actions

These are ideas, not current requirements.

---

# Decisions Already Made

## 48. Locked Decisions

Unless explicitly changed later, treat these as decided:

- Product name is **Ogma**
- Project name is **Ogma**
- Platform is **macOS**
- Bundle identifier is **`com.raulpop.Ogma`**
- Native Swift application
- SwiftUI + AppKit
- Menu-bar utility
- Emoji trigger starts with `:`
- Future text snippets use `/`
- Emoji MVP comes before snippets
- Native macOS appearance
- Privacy-first local operation
- No account/backend/network for MVP
- App icon will not be an emoji
- Primary logo/app-icon direction is the **Monogram O**
- `Resources/moodboard.png` is the canonical visual branding reference
- Ogham remains a subtle secondary branding/reference element
- SF Pro/system font for UI
- SF Mono for shortcut examples
- Ogma Violet `#7567F8` is primary brand accent
- Functional UI should mostly rely on semantic macOS system colors

---

## 49. Open Decisions

These can be decided later:

- final production/exported app-icon asset files based on the Monogram O
- final production/exported menu-bar asset based on the Monogram O
- exact caret-positioning fallback
- preferred text-insertion strategy after real-world testing
- Mac App Store vs direct distribution
- updater system
- final website/domain
- final marketing copy
- whether snippets ship in v1.0 or a later release
- whether Launch at Login ships in MVP
- whether Tab accepts suggestions
- support for localized emoji keywords
- future Windows/mobile versions

Do not block the emoji MVP on these decisions.

---

# Codex Instruction

## 50. How to Use This File

This document is the authoritative working specification for Ogma.

When asked to build Ogma:

1. Read this file first.
2. Inspect the current repository.
3. Follow decisions under **Locked Decisions**.
4. Implement the smallest reliable solution satisfying the current milestone.
5. Prefer native macOS APIs and simple architecture.
6. Build and verify after meaningful changes.
7. Do not invent large new requirements.
8. Do not proceed past the milestone stop condition without instruction.
9. If existing repository code conflicts with this spec, preserve working code where reasonable and adapt incrementally rather than rewriting the project.
10. Keep token usage efficient: act on the specification instead of restating it.

### Current milestone

**Build the system-wide emoji picker MVP.**

The milestone is successful when:

```text
:smile
```

can be typed in a normal macOS text field, Ogma displays a non-activating suggestion popup, and pressing Return replaces the trigger with:

```text
😊
```

while the original application remains focused.

---

# Change Log

## 2026-09-22

Branding update:

- selected the **Monogram O** as Ogma's primary logo/app-icon direction
- set `Resources/moodboard.png` as the canonical visual reference
- aligned app-icon and menu-bar guidance with the Monogram O
- kept Ogham as a secondary brand/reference element

Initial consolidated specification created.

Included:

- Ogma project identity
- emoji picker MVP
- future text snippets
- architecture
- privacy model
- permissions
- popup behavior
- Accessibility/caret positioning
- insertion strategy
- settings
- branding
- typography
- colors
- Ogham-inspired visual direction
- testing
- Codex development workflow
- stop conditions