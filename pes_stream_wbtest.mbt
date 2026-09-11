///|
test "PES all split positions and payload is discarded immediately" {
  let b = cat(b"\x00\x00\x01\xe0\x00\x00\x80\x80\x05", stamp_bytes(90000L, 2))
  for n = 1; n < b.length(); n = n + 1 {
    let a = PesAssembler::new()
    let out = []
    a.feed(b.view(end=n).to_owned(), true, 12L, fn(r) { out.push(r) })
    assert_eq(out.length(), 0)
    a.feed(cat(b.view(start=n).to_owned(), b"not buffered"), false, 192L, fn(
      r,
    ) {
      out.push(r)
    })
    assert_eq(out.length(), 1)
    assert_eq(out[0].unwrap().pts, Some(90000L))
    assert_eq(out[0].unwrap().offset, 12L)
    assert_eq(a.buffered(), 0)
    assert_eq(a.finish(), Ok(()))
  }
}

///|
test "maximum optional header is bounded and reset cannot join old data" {
  let a = PesAssembler::new()
  let out = []
  let b = cat(b"\x00\x00\x01\xe0\x00\x00\x80\x00\xff", Bytes::make(255, 0xff))
  a.feed(b.view(end=184).to_owned(), true, 4L, fn(r) { out.push(r) })
  assert_eq(a.buffered(), 184)
  a.feed(b.view(start=184).to_owned(), false, 192L, fn(r) { out.push(r) })
  assert_eq(out[0].unwrap().header_bytes, 264)
  assert_eq(a.buffered(), 0)
  a.feed(b"\x00\x00", true, 380L, fn(r) { out.push(r) })
  a.reset()
  a.feed(b"\x01\xe0", false, 568L, fn(r) { out.push(r) })
  assert_eq(a.finish(), Ok(()))
  a.feed(b"\x00", true, 756L, fn(r) { out.push(r) })
  assert_true(a.finish() is Err(_))
}
