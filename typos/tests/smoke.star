# typos/tests/smoke.star — stable across upstream typos releases.
#
# Asserts the contract (exit-code POLARITY, version shape, the COMPUTED set of
# corrections over a hermetic fixture, and the record COUNT), never
# help/version prose.
#
# EXIT POLARITY IS INVERTED and that is the whole point of this file. typos
# exits 0 when it finds NOTHING and 2 when it finds typos — upstream's README
# states it outright: "`--format json` to get jsonlines with exit code 0 on no
# errors, code 2 on typos, anything else is an error." So `expect.ok()` on the
# detection run would be backwards, and a bare `exit != 0` check would pass on
# a binary that crashed. Both runs below pin an EXACT exit code.
#
# HERMETIC BY CONSTRUCTION. `--isolated` ignores implicit configuration files
# (`.typos.toml`, `_typos.toml`, `pyproject.toml`) that the walker would
# otherwise pick up from any ancestor of the scratch root, and `--no-ignore`
# stops an ancestor `.gitignore`/`.ignore` from excluding the fixtures. The
# dictionary is compiled into the binary, so nothing here touches the network
# — in a bare `alpine:3.20` container or anywhere else.

TYPOS = "typos.exe" if ocx.target_platform.os == ocx.os.Windows else "typos"

# Tier 1 + 2: liveness on the composed PATH + version SHAPE. Not the banner and
# not the exact version — the digits are the contract. (`--version` prints
# `typos-cli <V>`; asserting that prefix would break on a rename.)
r_version = ocx.run(TYPOS, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ─── Hermetic fixtures ──────────────────────────────────────────────────────
#
# A source file with THREE misspellings drawn from the most stable corner of
# the dictionary. Three rather than one so the assertion is on a count the
# binary had to compute, and spread over three lines so the reported
# `line_num`s are distinguishable. Verified identical on v1.47.2 (the declared
# floor) and v1.49.0 (the head).
ocx.write_file("bad.rs", """fn main() {
    // teh quick brown fox
    let recieve = 1;
    let seperate = 2;
}
""")

# THE NEGATIVE CONTROL's fixture: same shape, same file type, no misspelling.
# Without it, a checker that flagged nothing at all — a broken dictionary, an
# empty walk, a binary that read no bytes — would sail through the run above,
# because "found no typos" is this tool's SUCCESS code.
ocx.write_file("good.rs", """fn main() {
    let value = 1;
    let total = value + 2;
}
""")

# Tier 3a: detection. `--format json` emits one JSON object per finding, and
# `--sort` makes the order deterministic. Paths are relative to the run's cwd,
# which defaults to the scratch root — correct on Windows too, no separator
# juggling.
r_bad = ocx.run(TYPOS, "--isolated", "--no-ignore", "--format", "json", "--sort", "bad.rs")

# Exactly 2 — the documented "typos found" code. `expect.ne(0)` would also pass
# on a panic, a missing dictionary, or an unreadable file.
expect.eq(r_bad.exit_code, 2)

# The COUNT, not merely "something was reported". Each of the three findings is
# one jsonlines record.
BAD_LINES = [l for l in r_bad.stdout.split("\n") if l.strip() != ""]
expect.eq(len(BAD_LINES), 3)

# The corrections themselves. `the`/`receive`/`separate` appear NOWHERE in this
# script's input — the fixture contains only the misspellings — so emitting
# them is proof the embedded dictionary was consulted and matched, rather than
# the input being echoed back.
expect.matches(r_bad.stdout, r'"typo":"teh".*"corrections":\["the"\]')
expect.matches(r_bad.stdout, r'"typo":"recieve".*"corrections":\["receive"\]')
expect.matches(r_bad.stdout, r'"typo":"seperate".*"corrections":\["separate"\]')

# Tier 3b: THE NEGATIVE CONTROL. A clean file must exit 0 and report nothing —
# this is what makes the run above evidence of DISCRIMINATION rather than of a
# tool that flags everything it is shown.
r_good = ocx.run(TYPOS, "--isolated", "--no-ignore", "--format", "json", "--sort", "good.rs")
expect.eq(r_good.exit_code, 0)
expect.eq(r_good.stdout.strip(), "")

# No Tier 4: metadata.json declares PATH only (proven by Tier 1 liveness).
