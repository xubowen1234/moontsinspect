///|
test "long duplicate runs cannot alternate between accepted and rejected" {
  let c = Continuity::new()
  let p = parse_packet(packet_bytes(20, 0)).unwrap()
  assert_eq(c.observe(p), Ok(First))
  assert_eq(c.observe(p), Ok(Duplicate))
  for _i = 0; _i < 10; _i = _i + 1 {
    assert_eq(c.observe(p), Ok(Gap(expected=1, actual=0)))
  }
  assert_eq(
    c.observe(parse_packet(packet_bytes(20, 1)).unwrap()),
    Ok(Continuous),
  )
}

///|
test "private sections and future stream types must not be guessed to be PES" {
  for kind in [5, 11, 13, 0xfe] {
    let i = Inspector::new().unwrap()
    let events = []
    i.feed(psi_packet(0, 0, pat_section()), fn(e) { events.push(e) })
    let body = cat(
      b"\xff\xff\xf0\x00",
      cat(Bytes::make(1, kind.to_byte()), b"\xe1\x00\xf0\x00"),
    )
    let section = long_section(2, 7, 0, 0, 0, body)
    i.feed(psi_packet(4096, 0, section.bytes), fn(e) { events.push(e) })
    i.feed(packet_bytes(256, 0, payload=b"not a PES header", start=true), fn(
      e,
    ) {
      events.push(e)
    })
    i.finish(fn(e) { events.push(e) })
    assert_eq(events.length(), 2)
    assert_eq(i.program_maps()[0].streams[0].stream_type, kind)
  }
}

///|
test "malformed adaptation invalidates pending PES and clocks" {
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
  let bad = packet_bytes(256, 1).to_fixedarray()
  bad[3] = 0x31
  bad[4] = 1
  bad[5] = 0x10
  i.feed(Bytes::from_array(bad[:]), fn(e) { events.push(e) })
  i.feed(packet_bytes(256, 2, payload=b"\x01\xe0"), fn(e) { events.push(e) })
  i.finish(fn(e) { events.push(e) })
  assert_eq(events.length(), 3)
  assert_true(events[2] is Issue({ code: "adaptation_truncated", .. }))
}

///|
test "seeded packet mutation corpus never panics and obeys payload bounds" {
  let mut seed = 0x713ab9e1U
  for _case = 0; _case < 3000; _case = _case + 1 {
    let bytes = FixedArray::make(188, b'\x00')
    for i = 0; i < 188; i = i + 1 {
      seed = seed * 1664525U + 1013904223U
      bytes[i] = (seed >> 24).to_byte()
    }
    bytes[0] = 0x47
    match parse_packet(Bytes::from_array(bytes[:])) {
      Ok(p) => {
        assert_true(p.payload.length() <= 184)
        ignore(p.adaptation())
      }
      Err(_) => ()
    }
  }
}

///|
test "PSI and PES arbitrary bounded byte strings never panic" {
  let mut seed = 17U
  for n = 0; n <= 1100; n = n + 1 {
    let bytes = Bytes::makei(n, fn(_) {
      seed = seed * 1664525U + 1013904223U
      (seed >> 24).to_byte()
    })
    ignore(parse_pes_header(bytes))
    match parse_section(bytes) {
      Ok(s) => {
        ignore(parse_pat(s))
        ignore(parse_pmt(s))
      }
      Err(_) => ()
    }
  }
}
