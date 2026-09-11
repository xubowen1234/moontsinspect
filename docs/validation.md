# Validation and publication gates — 2026-09-11

## Local results

Run ./scripts/verify-local.ps1 from PowerShell (the script resolves its own repository root), or execute the equivalent commands in .github/workflows/ci.yml.

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

The first remote run (34593958334) failed at formatting: the earlier local 0.10.4 formatter differs from the CI 0.10.12 formatter. An isolated local 0.10.12 toolchain was installed without changing the global SDK; source formatting was regenerated and toolchain.json plus an executable version gate now prevent accidental formatter/compiler drift. The installer still uses the official latest download endpoint; if it changes, the exact-version check fails and requires deliberate review. Repair run https://github.com/xubowen1234/moontsinspect/actions/runs/34594535601 passed for b12648a9c954f0ca6ff6836c0592a23c17cd48dd, including native runtime check/build/test/example and the JS CLI/ffprobe checks. Any later release commit must obtain its own green run.

## External gates not completed locally

- Public repository and permission VERIFIED: xubowen1234/moontsinspect, ADMIN. Initial 21 commits map both author and committer to xubowen1234 in the GitHub API. Authentication is scoped per command process; global active account is not switched.
- Green remote CI including native runtime tests is now evidenced by the repair run above. Release creation must target a commit with its own successful validation.
- Participant authorized reusing the previous MoonURI application identity/contact. Application is outside Git; its final claims must match the eventual tested release.
- MoonCakes package publication (separate participant authorization/manual step).
- Competition acceptance. Search evidence is not organizer approval.

Repository-local Git identity is xubowen / 279239855+xubowen1234@users.noreply.github.com, matching the fetched public account ID for xubowen1234. Both Git identities are checked before each local commit. This local configuration is not proof of remote GitHub contribution attribution.

## Read-only release preflight

Run `node scripts/release-preflight.cjs` with the intended account authenticated in the current process. It rejects a dirty tree, wrong origin/actor/owner, a private repo, insufficient permission, a default-branch/HEAD mismatch, any author/committer attribution mismatch across paginated history, or missing successful CI for the exact HEAD. It creates no tag, release or package and does not switch global accounts. Save its JSON output outside the repository as release evidence. This is separate from the manual meaningful-commit review.
