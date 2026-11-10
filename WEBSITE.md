# Ogma website

The public presentation website is **https://ogma.raulpop.ro/**. It is a static site hosted by **Vercel**, connected to this GitHub repository. Pushes to `main` automatically publish the website. Hostico manages the domain DNS; it no longer serves the public Ogma website files.

There is no separate website builder or manual HTML upload step.

## Source and hosting

- Repository: `raulpop8/ogma`, production branch `main`.
- Vercel project: `ogma`, in the `raulpop` team.
- Vercel root directory: `docs`; framework: Other/static; no install or build command; output directory: `.`.
- `docs/index.html`: content, styles, theme switching, and download links.
- `docs/assets/`: Ogma logos and favicons.
- `README.md`: project introduction; keep its download and platform information aligned with the website.

The page retains Ogma's purple branding, supports light and dark themes, and uses system fonts and local assets. It has no analytics or third-party script dependencies.

## Mac update feed: keep GitHub Pages

GitHub Pages also publishes `main` → `/docs` at **https://raulpop8.github.io/ogma/**. This preserves **https://raulpop8.github.io/ogma/appcast.xml**, the Sparkle feed used by already-installed Mac copies.

GitHub Pages must have **no custom domain**. Adding one redirects existing feed requests to that domain, which can disrupt updates during DNS or HTTPS changes. The public website domain belongs to Vercel instead.

`docs/appcast.xml` is app release infrastructure. Keep it unchanged during website-only work. Future website changes publish from the same source to Vercel and GitHub Pages; there is no separate Hostico copy to maintain.

## Preview and publish

From the repository root:

```sh
python3 -m http.server 8000 --directory docs
```

Open **http://localhost:8000**. Check narrow and desktop layouts, both themes, keyboard navigation, and download links. Stop the server with Control-C.

Commit reviewed changes and push to `main`. Check the matching production deployment in Vercel, then verify **https://ogma.raulpop.ro/**. A failed deployment must be investigated; a push alone does not prove publication succeeded. Also verify the GitHub Pages workflow and Mac feed after hosting changes.

Website publication does not release or update either desktop app. See [RELEASING.md](RELEASING.md).

## Domain configuration

Hostico is authoritative for `raulpop.ro`. On 2026-11-10, `ogma.raulpop.ro` was connected to Vercel using an A record to **216.198.79.1**, TTL **300**, as recommended for this project. Its old Hostico AAAA record was removed. Existing SPF/DKIM and unrelated records were preserved.

An A record is used because a CNAME cannot coexist with the subdomain's existing SPF TXT record. Inspect the current project-specific DNS recommendations in Vercel before future changes. Do not copy generic addresses, change nameservers, or alter the main website or email records.

The old A/AAAA records had a four-hour TTL, so some recursive resolvers may retain the previous route during migration. Keep the old Hostico files during that period. They are no longer the source to edit.

## Download destinations

- macOS: **https://github.com/raulpop8/ogma/releases/latest** — signed, notarized DMG.
- Windows: **https://apps.microsoft.com/detail/9N271VJTZDCH** — **Ogma Typing**, published by **Raul Pop**.

Do not advertise unsigned CI artifacts or Store submission MSIX files as Windows installers. Do not put Windows packages in the Mac feed. Avoid hard-coding app versions in marketing copy unless they are verified published versions.
