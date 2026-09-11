# Protocol baseline

Original implementation against ITU-T H.222.0 (08/2018), clauses 2.4.3 (TS, adaptation, PES), 2.4.4 (PSI/PAT/PMT), Annex A (CRC). This is an explicit baseline, not a claim to implement the latest full standard.

Source: https://www.itu.int/rec/dologin_pub.asp?id=T-REC-H.222.0-201808-S!!PDF-E&lang=e&type=items
Retrieved 2026-09-11; the standard PDF/text is kept outside this repository, not redistributed.

Scope: 188-byte packets; opaque unknown descriptors; no codecs, scrambling decryption, network arrival timing, or TR 101 290 certification. RFC 8216 section 3.2 motivates TS inspection for HLS but is not a replacement for H.222.0.

Implemented subset: packet/adaptation structural checks and PCR/OPCR decoding; bounded long PSI reassembly with MPEG-2 CRC; PAT and single-section PMT; current table-version activation; per-PID continuity; bounded PES header and PTS/DTS extraction; relative PCR segmentation; explicit sync recovery. Fragmented PSI/PES error locations map back to the original TS byte offsets. See architecture.md and README for unsupported semantics; passing these checks is not full standard certification.
