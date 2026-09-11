# Architecture and resource model

## Data flow

PacketReader / opt-in RecoveryReader -> Packet -> Continuity -> known-PID routing -> SectionAssembler -> LongSection -> PAT/PMT -> versioned inventory. Declared PES PIDs route through PesAssembler; PCR PIDs route through PcrClock. Inspector streams InspectEvent callbacks; CLI only adds filesystem IO, argument handling and exit codes.

Modules contain original MoonBit implementation. There is no FFI media parser or hidden external demuxer. FFprobe is used only for independent tests.

## Bounds

- Strict reader: <188 pending bytes between calls; recovery reader: <564, scan limit 1..1048576 bytes.
- Continuity: 8192 PID slots, one previous 188-byte packet per observed PID, no unbounded history.
- Long sections: 12..1024 bytes each. Physical byte positions are retained so cross-packet diagnostics do not point into intervening adaptation fields.
- TableCollector: one active and one pending version, <=256 sections each. Complete out-of-order sections are ordered before activation. Conflicting contents under an unchanged version produce an issue.
- Inspector: configurable 1..256 programs (default64), <=256 parsed PES states; each PES header <=264 bytes. Opaque unknown/section-oriented stream types do not get PES state.
- No diagnostic/event list is retained by the library. Callback consumers control their own memory. Snapshot arrays are fresh; mutating them cannot change active inspector tables.
- CLI reads 64 KiB chunks. Bounded internal memory is not a claim of a particular process RSS; MoonBit runtime/GC and subscriber allocations are separate.

## Recovery and assumptions

Continuity loss, TEI, invalid adaptation and scrambling invalidate affected header reconstruction. Recovery mode requires three valid packet structures, never one isolated sync byte. It does not prove that a byte pattern is genuine media, and incomplete unaligned EOF is not guessed.

Callbacks are synchronous and must not recursively feed or finish the same stateful object. Standalone SectionAssembler/PesAssembler callers must apply continuity, duplicate and scrambling policy themselves; Inspector does that integration.

PAT updates can replace PMT PID assignments; absent new PMTs are reported at EOF. PAT/PMT version differences are not treated as numeric monotonic ordering (5-bit version rollover is legal). Partial table candidates cannot overwrite active inventory. A PAT exceeding program budget is rejected with a diagnostic; no partial program list is activated.

## Verification layers

Unit + black-box API tests; all packet/header split positions; deterministic malformed-byte corpus; process-level CLI tests; synthetic TS fixture independent of this parser; FFprobe inventory/first timestamps crosscheck; dropped/duplicated/truncated/CRC/sync mutations. These are complementary evidence, not exhaustive standards certification or a fuzzing proof.
