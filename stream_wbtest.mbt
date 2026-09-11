///|
test "all chunk boundaries preserve packets and offsets" {
  let bytes = Bytes::from_array(
    (packet_bytes(0, 0).to_array() + packet_bytes(257, 1).to_array())[:],
  )
  for split = 0; split <= bytes.length(); split = split + 1 {
    let reader = PacketReader::new()
    let results = []
    reader.feed(bytes.view(end=split).to_owned(), fn(r) { results.push(r) })
    assert_true(reader.buffered() < 188)
    reader.feed(bytes.view(start=split).to_owned(), fn(r) { results.push(r) })
    assert_eq(results.length(), 2)
    assert_eq(results[0].unwrap().pid, 0)
    assert_eq(results[1].unwrap().offset, 188L)
    assert_eq(reader.finish(), Ok(()))
  }
}

///|
test "stream fails once and exposes truncated tail" {
  let r = PacketReader::new()
  let results = []
  r.feed(b"x", fn(x) { results.push(x) })
  assert_true(results[0] is Err({ code: "sync_byte", offset: 0L, .. }))
  r.feed(b"", fn(x) { results.push(x) })
  assert_true(results[1] is Err({ code: "reader_closed", .. }))
  let r = PacketReader::new()
  r.feed(b"\x47\x00", fn(_) { () })
  assert_true(r.finish() is Err({ code: "trailing_bytes", .. }))
  assert_eq(r.buffered(), 0)
  assert_true(r.finish() is Err({ code: "reader_closed", .. }))
}
