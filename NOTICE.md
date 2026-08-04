# NOTICE

This repository packages and redistributes upstream software published by the
[crate-ci](https://github.com/crate-ci) organisation. The Apache-2.0 license in
[`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does **not**
cover any upstream-derived asset — the redistributed bytes carry their own
license, recorded below.

The package logo is an original mark authored for this repository — upstream
publishes none — and is used for catalog identification only. No endorsement is
implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `typos` | `ghcr.io/ocx-contrib/crate-ci/typos` | `Apache-2.0` |

---

## `typos`

Upstream: <https://github.com/crate-ci/typos>
Published to `ghcr.io/ocx-contrib/crate-ci/typos`.

| Component | SPDX | Holder |
|---|---|---|
| typos | **Apache-2.0** | The typos authors (crate-ci) |

Verified at the Phase 1.5 license gate:

```
$ gh api repos/crate-ci/typos/license --jq '{spdx: .license.spdx_id, path: .path}'
{"path":"LICENSE-APACHE","spdx":"Apache-2.0"}
```

Upstream is **dual-licensed `MIT OR Apache-2.0`** — both `LICENSE-APACHE` and
`LICENSE-MIT` sit at the root of its source repository. Apache-2.0 is the arm
recorded here and in the published OCI annotation
`org.opencontainers.image.licenses`; the MIT arm remains available to anyone who
prefers it. Either way the license is permissive and grants redistribution of
the compiled binary subject to its notice-retention conditions.

Those conditions are satisfied in place: every upstream release archive ships
the full text of **both** licenses (`LICENSE-APACHE`, `LICENSE-MIT`) beside the
executable, and both are republished unmodified inside the OCX bundle. The
canonical texts are
<https://github.com/crate-ci/typos/blob/master/LICENSE-APACHE> and
<https://github.com/crate-ci/typos/blob/master/LICENSE-MIT>.

The published binaries are statically linked Rust builds that vendor
third-party crates under permissive licenses, enumerated in upstream's
`Cargo.lock` and gated by its `deny.toml`. The correction dictionary compiled
into the binary is assembled from the `typos-dict`, `codespell-dict`,
`misspell-dict`, `wikipedia-dict` and `varcon` crates, all of which live in the
same upstream repository and inherit its workspace license
(`license = "MIT OR Apache-2.0"` in the root `Cargo.toml`). `varcon`'s source
data set (`crates/varcon/assets/varcon.txt`) carries its own upstream notice in
the `README` beside it.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
