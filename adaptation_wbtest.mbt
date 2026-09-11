///|
fn adapted_bytes(
  pid : Int,
  cc : Int,
  fields : Bytes,
  payload? : Bytes = b"",
  start? : Bool = false,
) -> Bytes {
  let a = packet_bytes(pid, cc, start~).to_fixedarray()
  let has_payload = payload.length() > 0
  a[3] = ((if has_payload { 0x30 } else { 0x20 }) | cc).to_byte()
  let len = if has_payload { 183 - payload.length() } else { 183 }
  a[4] = len.to_byte()
  for i = 0; i < fields.length(); i = i + 1 {
    a[5 + i] = fields[i]
  }
  for i = 0; i < payload.length(); i = i + 1 {
    a[5 + len + i] = payload[i]
  }
  Bytes::from_array(a[:])
}

///|
test "adaptation PCR flags private data and signed splice" {
  let b = adapted_bytes(
    100,
    0,
    b"\xf6\x00\x00\x00\x00\x7e\x2a\xfe\x03abc",
    payload=b"x",
  )
  let a = parse_packet(b).unwrap().adaptation().unwrap().unwrap()
  assert_true(a.discontinuity && a.random_access)
  assert_eq(a.pcr, Some(42L))
  assert_eq(a.splice_countdown, Some(-2))
  assert_eq(a.private_data, b"abc")
}

///|
test "optional fields never extend beyond adaptation field" {
  for flag in [0x10, 0x08, 4, 2, 1] {
    let b = packet_bytes(100, 0).to_fixedarray()
    b[3] = 0x30
    b[4] = 1
    b[5] = flag.to_byte()
    assert_true(
      parse_packet(Bytes::from_array(b[:])).unwrap().adaptation() is Err(_),
    )
  }
  let b = adapted_bytes(100, 0, b"\x10\x00\x00\x00\x00\x7f\xff")
  assert_true(
    parse_packet(b).unwrap().adaptation() is Err({ code: "pcr_encoding", .. }),
  )
  let b = adapted_bytes(100, 0, b"\x00\x00")
  assert_true(
    parse_packet(b).unwrap().adaptation()
    is Err({ code: "adaptation_stuffing", .. }),
  )
}

///|
test "extension stays opaque and PCR maximum is exact" {
  let b = adapted_bytes(
    100, 0, b"\x19\xff\xff\xff\xff\xff\x2b\x00\x00\x00\x00\x7e\x00\x02\x00\x01",
  )
  let a = parse_packet(b).unwrap().adaptation().unwrap().unwrap()
  assert_eq(a.pcr, Some(2576980377599L))
  assert_eq(a.opcr, Some(0L))
  assert_eq(a.extension, b"\x00\x01")
  assert_eq(
    parse_packet(packet_bytes(1, 0)).unwrap().adaptation().unwrap(),
    None,
  )
}
