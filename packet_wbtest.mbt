///|
fn packet_bytes(
  pid : Int,
  cc : Int,
  payload? : Bytes = b"",
  start? : Bool = false,
) -> Bytes {
  let b = FixedArray::make(188, b'\xff')
  b[0] = 0x47
  b[1] = ((pid >> 8) | (if start { 0x40 } else { 0 })).to_byte()
  b[2] = pid.to_byte()
  b[3] = (0x10 | cc).to_byte()
  for i = 0; i < payload.length() && i < 184; i = i + 1 {
    b[4 + i] = payload[i]
  }
  Bytes::from_array(b[:])
}

///|
test "packet headers payload and absolute offsets" {
  let b = packet_bytes(0x101, 15, payload=b"abc", start=true)
  let p = parse_packet(b, offset=376L).unwrap()
  assert_eq(p.pid, 257)
  assert_eq(p.continuity, 15)
  assert_true(p.payload_start)
  assert_eq(p.payload.length(), 184)
  assert_eq(p.payload[0], 97)
  assert_eq(p.offset, 376L)
  let changed = b.to_fixedarray()
  changed[4] = 0
  assert_eq(p.payload[0], 97)
  assert_eq(p.raw[4], 97)
}

///|
test "packet input is exact and offset addition safe" {
  for n = 0; n < 188; n = n + 1 {
    assert_true(parse_packet(Bytes::make(n, 0x47)) is Err(_))
  }
  assert_true(parse_packet(Bytes::make(189, 0x47)) is Err(_))
  assert_true(parse_packet(packet_bytes(0, 0), offset=-1L) is Err(_))
  assert_true(
    parse_packet(packet_bytes(0, 0), offset=9223372036854775807L) is Err(_),
  )
  let b = packet_bytes(0, 0).to_fixedarray()
  b[0] = 0
  assert_true(
    parse_packet(Bytes::from_array(b[:])) is Err({ code: "sync_byte", .. }),
  )
  b[0] = 0x47
  b[3] = 0
  assert_true(
    parse_packet(Bytes::from_array(b[:]))
    is Err({ code: "adaptation_control", .. }),
  )
}

///|
test "adaptation control determines exact payload boundary" {
  let b = packet_bytes(8191, 3).to_fixedarray()
  b[3] = 0x23
  b[4] = 183
  assert_eq(parse_packet(Bytes::from_array(b[:])).unwrap().payload.length(), 0)
  b[4] = 182
  assert_true(parse_packet(Bytes::from_array(b[:])) is Err(_))
  b[3] = 0x33
  assert_eq(parse_packet(Bytes::from_array(b[:])).unwrap().payload.length(), 1)
  b[4] = 183
  assert_true(parse_packet(Bytes::from_array(b[:])) is Err(_))
  b[4] = 0
  assert_eq(
    parse_packet(Bytes::from_array(b[:])).unwrap().payload.length(),
    183,
  )
}
