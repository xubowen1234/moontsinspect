///|
fn cat(a : Bytes, b : Bytes) -> Bytes {
  Bytes::from_array((a.to_array() + b.to_array())[:])
}

///|
fn pat_section() -> Bytes {
  b"\x00\xb0\x0d\x00\x01\xc1\x00\x00\x00\x07\xf0\x00\x2e\x62\xef\xa0"
}

///|
test "PSI every split including length header and pointer completion" {
  let section = pat_section()
  for n = 1; n < section.length(); n = n + 1 {
    let a = SectionAssembler::new(0).unwrap()
    let out = []
    a.feed(cat(b"\x00", section.view(end=n).to_owned()), true, 4L, fn(r) {
      out.push(r)
    })
    assert_eq(out.length(), 0)
    a.feed(section.view(start=n).to_owned(), false, 192L, fn(r) { out.push(r) })
    assert_eq(out.length(), 1)
    assert_eq(out[0].unwrap().offset, 5L)
    assert_eq(a.finish(), Ok(()))
    let a = SectionAssembler::new(0).unwrap()
    let out = []
    a.feed(cat(b"\x00", section.view(end=n).to_owned()), true, 4L, fn(r) {
      out.push(r)
    })
    let tail = section.view(start=n).to_owned()
    let prefix = Bytes::make(1, tail.length().to_byte())
    a.feed(cat(cat(prefix, tail), section), true, 192L, fn(r) { out.push(r) })
    assert_eq(out.length(), 2)
    assert_eq(out[1].unwrap().offset, 193L + tail.length().to_int64())
  }
}

///|
test "multiple sections stuffing acquisition and invalid pointers" {
  let a = SectionAssembler::new(0).unwrap()
  let out = []
  a.feed(b"ignored", false, 0L, fn(r) { out.push(r) })
  a.feed(
    cat(cat(b"\x00", pat_section()), cat(pat_section(), b"\xff\xff")),
    true,
    4L,
    fn(r) { out.push(r) },
  )
  assert_eq(out.length(), 2)
  a.feed(b"\xffabc", true, 192L, fn(r) { out.push(r) })
  assert_true(out[2] is Err({ code: "psi_pointer", .. }))
  a.feed(b"\x00\x00\xbf\xff", true, 380L, fn(r) { out.push(r) })
  assert_true(out[3] is Err({ code: "section_size", .. }))
  assert_eq(a.buffered(), 0)
}

///|
test "missing continuation must not join a new version" {
  let a = SectionAssembler::new(0).unwrap()
  let out = []
  a.feed(b"\x00\x00\xb0", true, 4L, fn(r) { out.push(r) })
  a.feed(cat(b"\x00", pat_section()), true, 192L, fn(r) { out.push(r) })
  assert_true(out[0] is Err({ code: "psi_incomplete", .. }))
  assert_eq(a.buffered(), 0)
  a.feed(b"\x00\x00", true, 380L, fn(r) { out.push(r) })
  assert_true(a.finish() is Err({ code: "psi_incomplete", offset: 381L, .. }))
}
