///|
fn descriptor_json(d : Descriptor) -> Json {
  let bytes = d.data.to_array().map(fn(b) { b.to_int() })
  { "tag": d.tag, "bytes": bytes.to_json() }
}

///|
fn program_ref_json(p : ProgramRef) -> Json {
  { "program": p.number, "pmt_pid": p.pmt_pid }
}

///|
fn pmt_json(p : Pmt) -> Json {
  let streams : Array[Json] = p.streams.map(fn(s) {
    let descriptors = s.descriptors.map(descriptor_json)
    {
      "pid": s.pid,
      "stream_type": s.stream_type,
      "descriptors": descriptors.to_json(),
    }
  })
  let descriptors = p.descriptors.map(descriptor_json)
  {
    "program": p.section.extension,
    "version": p.section.version,
    "pcr_pid": p.pcr_pid,
    "streams": streams.to_json(),
    "descriptors": descriptors.to_json(),
  }
}

///|
fn optional_ticks(value : Int64?) -> Json {
  match value {
    Some(t) => t.to_string().to_json()
    None => (None : Int?).to_json()
  }
}

///|
/// Version 1 NDJSON event schema. Int64 byte offsets and clock ticks are decimal strings.
pub fn event_json(event : InspectEvent) -> Json {
  match event {
    Issue(e) =>
      {
        "schema": 1,
        "type": "issue",
        "code": e.code,
        "offset": e.offset.to_string(),
        "pid": e.pid.to_json(),
      }
    ProgramsChanged(refs) =>
      {
        "schema": 1,
        "type": "pat",
        "programs": refs.map(program_ref_json).to_json(),
      }
    ProgramMapChanged(pmt) =>
      { "schema": 1, "type": "pmt", "map": pmt_json(pmt) }
    MediaClock(pid~, offset~, sample) =>
      {
        "schema": 1,
        "type": "pcr",
        "pid": pid,
        "offset": offset.to_string(),
        "segment": sample.segment,
        "relative_ticks": sample.relative_ticks.to_string(),
        "delta_ticks": sample.delta_ticks.to_string(),
        "wrapped": sample.wrapped,
        "tick_rate": 27000000,
      }
    PesTimestamp(pid~, header) =>
      {
        "schema": 1,
        "type": "pes",
        "pid": pid,
        "offset": header.offset.to_string(),
        "stream_id": header.stream_id,
        "pts": optional_ticks(header.pts),
        "dts": optional_ticks(header.dts),
        "tick_rate": 90000,
      }
  }
}

///|
pub fn Inspector::summary_json(self : Inspector) -> Json {
  {
    "schema": 1,
    "type": "summary",
    "packets": self.packet_count().to_string(),
    "programs": self.programs().map(program_ref_json).to_json(),
    "maps": self.program_maps().map(pmt_json).to_json(),
  }
}
