///|
fn stamp_bytes(value : Int64, prefix : Int) -> Bytes {
  let a : Array[Byte] = [
    ((prefix << 4) | (((value >> 30).to_int() & 7) << 1) | 1).to_byte(),
    (value >> 22).to_byte(),
    (((value >> 15).to_int() << 1) | 1).to_byte(),
    (value >> 7).to_byte(),
    ((value.to_int() << 1) | 1).to_byte(),
  ]
  Bytes::from_array(a[:])
}

///|
test "PES timestamps retain 33 bits and permit presentation reordering" {
  let b = cat(
    b"\x00\x00\x01\xe0\x00\x00\x80\xc0\x0a",
    cat(stamp_bytes(8589934591L, 3), stamp_bytes(123L, 1)),
  )
  let p = parse_pes_header(b).unwrap()
  assert_eq(p.pts, Some(8589934591L))
  assert_eq(p.dts, Some(123L))
  assert_eq(p.header_bytes, 19)
  // A later packet's lower PTS can be normal frame reordering, not a parse error.
  let p = parse_pes_header(
    cat(b"\x00\x00\x01\xe0\x00\x00\x80\x80\x05", stamp_bytes(40L, 2)),
  ).unwrap()
  assert_eq(p.pts, Some(40L))
}

///|
test "PES every truncated prefix and marker corruption" {
  let b = cat(b"\x00\x00\x01\xe0\x00\x00\x80\x80\x05", stamp_bytes(90L, 2))
  for n = 0; n < b.length(); n = n + 1 {
    assert_true(parse_pes_header(b.view(end=n).to_owned()) is Err(_))
  }
  for i in [9, 11, 13] {
    let a = b.to_fixedarray()
    a[i] = (a[i].to_int() & 0xfe).to_byte()
    assert_true(
      parse_pes_header(Bytes::from_array(a[:]))
      is Err({ code: "pes_timestamp_marker", .. }),
    )
  }
  assert_true(
    parse_pes_header(b"\x00\x00\x01\xe0\x00\x01\x80\x00\x00")
    is Err({ code: "pes_packet_length", .. }),
  )
  assert_true(
    parse_pes_header(b"\x00\x00\x01\xe0\x00\x00\x80\x40\x00") is Err(_),
  )
}

///|
test "PES padding stream has no optional header" {
  let p = parse_pes_header(b"\x00\x00\x01\xbe\x00\x10").unwrap()
  assert_eq(p.header_bytes, 6)
  assert_eq(p.pts, None)
}
