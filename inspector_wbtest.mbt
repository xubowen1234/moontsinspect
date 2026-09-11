///|
fn psi_packet(pid : Int, cc : Int, section : Bytes) -> Bytes {
  packet_bytes(pid, cc, payload=cat(b"\x00", section), start=true)
}

///|
test "inspection produces inventory and snapshots cannot mutate its state" {
  let i = Inspector::new().unwrap()
  let events = []
  i.feed(
    cat(psi_packet(0, 0, pat_section()), psi_packet(4096, 0, pmt_section())),
    fn(e) { events.push(e) },
  )
  assert_eq(i.packet_count(), 2L)
  assert_eq(i.programs()[0].number, 7)
  assert_eq(i.program_maps()[0].streams.length(), 2)
  let maps = i.program_maps()
  maps[0].streams.clear()
  i.programs().clear()
  assert_eq(i.program_maps()[0].streams.length(), 2)
  assert_eq(i.programs().length(), 1)
  i.finish(fn(e) { events.push(e) })
  assert_eq(events.length(), 2)
}

///|
test "PAT updates revoke old PMTs and missing PMT is reported only at EOF" {
  let i = Inspector::new().unwrap()
  let events = []
  i.feed(
    cat(psi_packet(0, 0, pat_section()), psi_packet(4096, 0, pmt_section())),
    fn(e) { events.push(e) },
  )
  let newer = long_section(0, 1, 1, 0, 0, b"\x00\x07\xf0\x01")
  i.feed(psi_packet(0, 1, newer.bytes), fn(e) { events.push(e) })
  assert_eq(i.program_maps().length(), 0)
  assert_eq(events.length(), 3)
  i.finish(fn(e) { events.push(e) })
  assert_true(events[3] is Issue({ code: "pmt_missing", pid: Some(4097), .. }))
}

///|
test "program budget and scrambled PSI fail explicitly" {
  assert_true(Inspector::new(max_programs=0) is Err(_))
  let i = Inspector::new(max_programs=1).unwrap()
  let events = []
  let section = long_section(0, 1, 0, 0, 0, b"\x00\x07\xf0\x00\x00\x08\xf0\x01")
  i.feed(psi_packet(0, 0, section.bytes), fn(e) { events.push(e) })
  assert_true(events[0] is Issue({ code: "program_limit", .. }))
  assert_eq(i.programs().length(), 0)
  let b = psi_packet(0, 1, pat_section()).to_fixedarray()
  b[3] = 0x91
  i.feed(Bytes::from_array(b[:]), fn(e) { events.push(e) })
  assert_true(events[1] is Issue({ code: "scrambled_psi", .. }))
}
