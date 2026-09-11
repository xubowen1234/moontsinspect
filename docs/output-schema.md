# NDJSON schema 1

Each line is an independent JSON object with schema=1 and type. Types: issue, pat, pmt, pcr, pes, summary. Fields are exercised in output_wbtest.mbt.

All offsets, packet totals and timestamps use decimal strings: parsing these as JavaScript Number would lose large values. PID, stream_type, version, segment and tick_rate are bounded integers. Null PTS/DTS means absent, not zero. Unknown descriptor values remain arrays of byte integers.

PCR ticks are 27 MHz relative values within a segment; PES PTS/DTS are raw 33-bit 90 kHz values. PCR backward/ambiguous gaps create a new segment and an issue; PTS reordering is not classified as an error. These are not arrival-time jitter measurements.

Issue offsets identify an input location or section/header origin. Metadata absent at EOF uses offset 0 as an unspecified location. A summary inventories the latest complete observed program mapping, not proof of a clean recording; consumers must also examine issue events and process exit status.

Event callbacks are synchronous. Do not recursively call feed/finish from a callback. Consumer-owned accumulation is outside the inspector's memory bound.
