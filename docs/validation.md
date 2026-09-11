# Validation and publication gates — 2026-09-11

## Local results

Run \scripts\verify-local.ps1 from PowerShell (the script resolves its own repository root), or execute the equivalent commands in .github/workflows/ci.yml.

- moon fmt --check: PASS.
- wasm-gc, wasm, js: each passed check --deny-warn, build, all **48** tests, and the real inventory example. These are the same 48 cases across three backends, not 144 unique tests.
- native: check --deny-warn PASS; build/test/example **NOT RUN successfully** because the local Windows environment has no C compiler. CI's native matrix entry must run them; no continue-on-error or skip is configured there.
- Public API regeneration: moon info plus tracked interface diff PASS.
- Actual linked Node CLI smoke tests: PASS (inventory/events, usage, missing file).
- Independent ffprobe fixture comparison: PASS (program, PMT/PCR/ES PIDs, first PTS/DTS).
- Process-level fault injection: PASS (drop, duplicate, triple repeat, truncation, PAT CRC, sync corruption).

The PowerShell gate exits with an error on failed commands. Without a local compiler it explicitly warns; use -RequireNative to make that absence fatal. ffprobe is mandatory, not a silently skipped oracle.

## CI contract and remaining uncertainty

The workflow covers four backends on Ubuntu 24.04 and records the actual tool versions. GitHub Actions are pinned to reviewed commit SHAs. The official MoonBit Unix installer is guarded by its reviewed SHA-256; a changed installer requires a deliberate review and checksum update, not bypassing the check.

The installer currently selects the **latest** official MoonBit bundle. Attempts to verify immutable historical binary URLs for the local version returned HTTP 403, so this workflow does not pretend to be a fully pinned compiler reproduction. Local versions are recorded in README. A newer compiler may expose compatibility changes; a green CI run must be obtained before release. Node uses the 24 major line; Ubuntu ffprobe is version-reported rather than byte-identical to the Windows fixture generator.

CI configuration is present; **no remote CI run has happened yet**. Do not show a green badge or treat configuration review as executed CI.

## External gates not completed locally

- New public GitHub repository, authorized active account, owner/push rights, and post-push author/committer mapping.
- Green remote CI including native runtime tests and a release pointing to the tested commit.
- Participant-confirmed name/contact and a strict-validated application with a real verified public repository URL.
- MoonCakes package publication (separate participant authorization/manual step).
- Competition acceptance. Search evidence is not organizer approval.

Repository-local Git identity is xubowen / 279239855+xubowen1234@users.noreply.github.com, matching the fetched public account ID for xubowen1234. Both Git identities are checked before each local commit. This local configuration is not proof of remote GitHub contribution attribution.
