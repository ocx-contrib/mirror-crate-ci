# mirror-crate-ci

OCX mirrors for [crate-ci](https://github.com/crate-ci) tooling. One repository,
one spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [typos](https://github.com/crate-ci/typos) | [`typos/mirror.yml`](typos/mirror.yml) | `ghcr.io/ocx-contrib/crate-ci/typos` | [`ocx.sh/crate-ci/typos`](https://index.ocx.sh/crate-ci/typos) | `Apache-2.0` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

`crate-ci` is the project's own organisation rather than a maintainer's personal
handle, so it is the namespace — and a second crate-ci package is a new sibling
directory here, not a new repository.

## Layout

```
mirror-base.yml         repo-wide policy the spec inherits via `extends:`
typos/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. The logo is **not** — it sits
beside the spec, because a repo-root `logo.*` sits in no workflow's `paths:`
filter, so replacing it would publish nothing until some unrelated edit
happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. `typos/mirror.yml` does not
restate `platforms:` at all; the measured matrix lives in `mirror-base.yml`. A
second package whose measured libc verdict differs must move `platforms:` down
into each spec rather than restate it partially.

## Platforms

Five platform entries: both Linux arches, both macOS arches, and `windows/amd64`.
Every one of the five anchored asset patterns was checked against the full asset
list of **every** in-range release (v1.47.2, v1.48.0, v1.49.0) and matches
exactly one asset each, with no asset left unmatched — a pattern matching zero is
*silently skipped* by the pipeline, not an error, and would ship a missing
platform under a green run.

**`windows/arm64` is deliberately not declared.** Upstream ships no aarch64
Windows asset in any release: the five assets are the two `unknown-linux-musl`
tarballs, the two `apple-darwin` tarballs and the single
`x86_64-pc-windows-msvc` zip. A declared-but-unmatched platform still boots a
real `windows-11-arm` runner and reports SUCCESS having tested nothing, so it is
worse than absent. Nothing else upstream ships is omitted.

**Both Linux keys are bare, because nothing is dynamically linked.**
`os.features` states what an artifact requires *of the host*, never how it was
built — and a `-musl` filename is not evidence either way:

| Key | Asset | Measured (v1.47.2 and v1.49.0) |
|---|---|---|
| `linux/amd64` | `typos-v<V>-x86_64-unknown-linux-musl.tar.gz` | `static-pie linked`, `INTERP` segments **0**, `DT_NEEDED` **0**, no `GLIBC_*` symbol versions → **bare** |
| `linux/arm64` | `typos-v<V>-aarch64-unknown-linux-musl.tar.gz` | `statically linked`, identical on all three counts → **bare** |

Linux is **musl-only on both arches** — upstream ships no gnu build at all — but
both musl builds are *static*, so one artifact per arch covers both userlands.
`+libc.musl` would be a false requirement, hiding the package from every glibc
host it in fact runs on, purely because of a filename. The `alpine:3.20`
container leg on **both** arches is what turns that universality claim into
evidence.

## The binaries claim

Every release archive — `.tar.gz` and `.zip` alike — is **flat**: the executable
sits at the archive root beside `LICENSE-APACHE`, `LICENSE-MIT`, `README.md` and
a `doc/` directory, with **no wrapper directory**. So `strip_components: 0`
serves every platform: the tar members carry a leading `./` (the archive's own
current-directory entry, not a top-level directory) while the zip members do
not, and stripping one component would consume the executable on the zip side.

After extraction the bundle's only PATH entry is a bare `${installPath}`: the
executable *is* at the content root. `bin_scan` only looks *below* an
`${installPath}/<dir>` entry, so `auto`/`verify` is rejected at spec load with
exit 65 (*the verification would inspect no file and pass green whatever the
archive contains*). `typos/mirror.yml` therefore sets `bin_scan: "off"` and
`typos/metadata.json` hand-lists `binaries: ["typos"]` — the blessed shape for
this layout, and `typos` (`typos.exe` on Windows) is the archive's only
mode-0755 entry.

## The smoke test asserts inverted exit polarity

typos exits **0 when it finds nothing** and **2 when it finds typos** — upstream
documents it, and it is why `expect.ok()` on a detection run would be backwards
and a bare "non-zero" check would pass on a crash. `typos/tests/smoke.star` pins
the exact code on both sides.

It is hermetic by construction: the dictionary is compiled into the binary,
`--isolated` ignores any implicit `.typos.toml` an ancestor of the scratch root
might carry, and `--no-ignore` stops an ancestor `.gitignore` from excluding the
fixtures. A three-misspelling fixture must produce exit 2, exactly **3**
jsonlines records, and the corrections `the` / `receive` / `separate` — none of
which appear in the script's input, so emitting them proves the dictionary was
consulted rather than the input echoed. The **negative control** is a clean file
of the same shape, which must exit 0 with empty output; without it a checker
that flagged nothing at all would pass, because "found nothing" is this tool's
success code.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `typos/mirror.yml` | hand | yes — see below |
| `typos/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `typos/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec typos/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; the
redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
