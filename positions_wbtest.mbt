///|
test "fragmented PES marker error points into the later TS payload" {
  let a = PesAssembler::new()
  let events = []
  let head = b"\x00\x00\x01\xe0\x00\x00\x80\x80\x05"
  a.feed(head, true, 179L, fn(e) { events.push(e) })
  a.feed(b"\x20\x00\x01\x00\x01", false, 200L, fn(e) { events.push(e) })
  assert_true(
    events[0] is Err({ code: "pes_timestamp_marker", offset: 200L, .. }),
  )
}

///|
test "fragmented PMT descriptor error uses actual descriptor location" {
  let s = long_section(2, 7, 0, 0, 0, b"\xe1\x00\xf0\x02\xff\xff")
  let a = SectionAssembler::new(4096).unwrap()
  let sections = []
  a.feed(cat(b"\x00", s.bytes.view(end=12).to_owned()), true, 175L, fn(e) {
    sections.push(e)
  })
  a.feed(s.bytes.view(start=12).to_owned(), false, 200L, fn(e) {
    sections.push(e)
  })
  let result = parse_pmt(sections[0].unwrap())
  assert_true(result is Err({ code: "descriptor_length", offset: 200L, .. }))
}

///|
test "fragmented section header validation maps its actual numbering byte" {
  let a = SectionAssembler::new(0).unwrap()
  let sections = []
  let b = with_crc(b"\x00\xb0\x09\x00\x01\xc1\x02\x00")
  a.feed(cat(b"\x00", b.view(end=5).to_owned()), true, 180L, fn(e) {
    sections.push(e)
  })
  a.feed(b.view(start=5).to_owned(), false, 204L, fn(e) { sections.push(e) })
  assert_true(sections[0] is Err({ code: "section_number", offset: 205L, .. }))
}
