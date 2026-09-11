# Contributing

Use the explicit MoonBit toolchain version recorded in README and run scripts/verify-local.ps1 on Windows or the commands in CI. Add regressions at the layer that owns the invariant, and a process/independent-fixture test when the issue crosses layers. Keep unknown/unsupported protocol behavior explicit rather than guessing.

Meaningful commits contain a complete reviewable engineering change with tests or reproducible evidence. Do not pad history with empty, format-only, metadata-only or repeated tiny fixes. No historical author rewriting or backdated commits.

For this participant's workflow, configure Git only within the repository, never globally; check author and committer before each commit. Before a push verify the active GitHub account, repository owner/permission and remote commit attribution separately. Never commit login tokens, contact forms or personal application documents.

Do not introduce a dependency, fixture or port without source/license review. Run the real inventory example on all supported backends and preserve CLI schema compatibility or explicitly bump schema.
