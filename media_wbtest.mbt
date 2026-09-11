///|
test "session routes only declared PES and PCR with duplicate suppression" {
  let i = Inspector::new().unwrap()
  let events = []
  i.feed(
    cat(psi_packet(0, 0, pat_section()), psi_packet(4096, 0, pmt_section())),
    fn(e) { events.push(e) },
  )
  let pes = cat(b"\x00\x00\x01\xe0\x00\x00\x80\x80\x05", stamp_bytes(90000L, 2))
  let p = adapted_bytes(
    256,
    0,
    b"\x10\x00\x00\x00\x00\x7e\x00",
    payload=pes,
    start=true,
  )
  i.feed(p, fn(e) { events.push(e) })
  assert_true(events[2] is MediaClock(pid=256, offset=376L, _))
  assert_true(events[3] is PesTimestamp(pid=256, { pts: Some(90000L), .. }))
  i.feed(p, fn(e) { events.push(e) })
  assert_eq(events.length(), 5)
  assert_true(events[4] is MediaClock(_, ..))
  i.finish(fn(e) { events.push(e) })
  assert_eq(events.length(), 5)
}

///|
test "PES loss resets partial headers and reports gap at packet offset" {
  let i = Inspector::new().unwrap()
  let events = []
  i.feed(
    cat(psi_packet(0, 0, pat_section()), psi_packet(4096, 0, pmt_section())),
    fn(e) { events.push(e) },
  )
  i.feed(adapted_bytes(256, 0, b"\x00", payload=b"\x00\x00", start=true), fn(
    e,
  ) {
    events.push(e)
  })
  i.feed(packet_bytes(256, 2, payload=b"\x01\xe0"), fn(e) { events.push(e) })
  assert_true(
    events[2]
    is Issue({ code: "continuity_gap", pid: Some(256), offset: 564L, }),
  )
  i.finish(fn(e) { events.push(e) })
  assert_eq(events.length(), 3)
}
