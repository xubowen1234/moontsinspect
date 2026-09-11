# Source and license record

- Project implementation: original MoonBit code developed for this project, MIT. Not a transliteration of TSDuck/FFmpeg/GStreamer implementation source.
- Protocol reference: ITU-T H.222.0 (08/2018), clauses 2.4.3, 2.4.4 and Annex A, obtained from the official ITU source on 2026-09-11. The standard is not relicensed by this project and its PDF/text is NOT included. See docs/protocol-baseline.md.
- Runtime/toolchain: MoonBit and moonbitlang/core, used under their own terms; core package source is Apache-2.0. No copied core implementation is included; only public API usage.
- Fixture: FFmpeg 8.1 generated testsrc2 + sine, no externally sourced recording. Fixture provenance, command and SHA256 are in fixtures/. FFmpeg binaries and implementation are not bundled. ffprobe is an optional external test tool, not a runtime library dependency.
- Research: docs/competition contains factual public package/search metadata and original comparisons. Downloaded third-party README/source files and the full standard are held outside this repository, not redistributed as project code. source-index.json records their original URLs and local research filenames, not bundled source promises.
- CRC algorithm: original implementation of the MPEG-2 bit recurrence and published parameters; no copied generic CRC32 package. Reflected IEEE CRC32 is not substituted for MPEG-2 PSI CRC.

No source-code port is claimed. Unknown future additions require provenance/license review before inclusion.
