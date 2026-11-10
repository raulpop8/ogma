# Ogma website

The presentation website is **https://raulpop8.github.io/ogma/**. It is a static site hosted by **GitHub Pages**, built directly from this repository. There is no separate website builder, backend, package manager, or paid hosting project.

## Where to edit

- `docs/index.html`: page content, styles, theme switching, and download links.
- `docs/assets/`: the Ogma logos and favicons.
- `README.md`: the GitHub project introduction; keep its platform and download information aligned with the website.
- `docs/appcast.xml`: the **macOS Sparkle update feed**. This is app release infrastructure, not website copy. Leave it unchanged for website-only work.

The site uses Ogma's existing purple branding, supports light and dark themes, and uses system fonts and local assets. It has no analytics or third-party script dependencies.

## Preview

From the repository root:

```sh
python3 -m http.server 8000 --directory docs
```

Open **http://localhost:8000**. Check desktop and narrow phone layouts, both themes, keyboard navigation, and download links. Stop the server with Control-C.

## Publish

Commit the reviewed website files to `main` and push them to GitHub. GitHub Pages is configured to publish **`main` → `/docs`**. Check the Pages deployment in GitHub Actions, then verify the public URL.

A website publication does not release or update either desktop app. App release instructions are in [RELEASING.md](RELEASING.md).

## Download destinations

- macOS: **https://github.com/raulpop8/ogma/releases/latest**. Mac releases currently contain the signed, notarized DMG.
- Windows: **https://apps.microsoft.com/detail/9N271VJTZDCH**. The Store listing is named **Ogma Typing**, published by **Raul Pop**.

Do not replace the Windows download link with an unsigned CI artifact or Store submission MSIX. Do not put Windows packages in the Mac Sparkle feed. Avoid hard-coding app versions in marketing copy unless they are verified published versions.
