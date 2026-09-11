///|
fn long_section(
  table : Int,
  extension : Int,
  version : Int,
  number : Int,
  last : Int,
  body : Bytes,
  current? : Bool = true,
) -> LongSection {
  let length = body.length() + 9
  let head : Array[Byte] = [
    table.to_byte(),
    (0xb0 | (length >> 8)).to_byte(),
    length.to_byte(),
    (extension >> 8).to_byte(),
    extension.to_byte(),
    (0xc0 | (version << 1) | (if current { 1 } else { 0 })).to_byte(),
    number.to_byte(),
    last.to_byte(),
  ]
  parse_section(with_crc(cat(Bytes::from_array(head[:]), body))).unwrap()
}

///|
fn pmt_section() -> Bytes {
  b"\x02\xb0\x17\x00\x07\xc1\x00\x00\xe1\x00\xf0\x00\x02\xe1\x00\xf0\x00\x03\xe1\x01\xf0\x00\xfc\x59\xd0\xb2"
}

///|
test "independent PAT and PMT agree with ffprobe inventory" {
  let pat = parse_pat(parse_section(pat_section()).unwrap()).unwrap()
  assert_eq(pat.programs, [{ number: 7, pmt_pid: 4096, }])
  assert_eq(pat.network_pid, None)
  let pmt = parse_pmt(parse_section(pmt_section()).unwrap()).unwrap()
  assert_eq(pmt.section.extension, 7)
  assert_eq(pmt.pcr_pid, 256)
  assert_eq(pmt.streams.length(), 2)
  assert_eq(pmt.streams[0].pid, 256)
  assert_eq(pmt.streams[0].stream_type, 2)
  assert_eq(pmt.streams[1].pid, 257)
  assert_eq(pmt.streams[1].stream_type, 3)
}

///|
test "PAT distinguishes network PID rejects duplicate programs and reserved PIDs" {
  let p = parse_pat(
    long_section(0, 1, 0, 0, 0, b"\x00\x00\xe0\x10\x00\x01\xf0\x00"),
  ).unwrap()
  assert_eq(p.network_pid, Some(16))
  assert_eq(p.programs.length(), 1)
  assert_true(
    parse_pat(long_section(0, 1, 0, 0, 0, b"\x00\x01\xf0\x00\x00\x01\xf0\x01"))
    is Err(_),
  )
  assert_true(
    parse_pat(long_section(0, 1, 0, 0, 0, b"\x00\x01\xff\xff")) is Err(_),
  )
  assert_true(parse_pat(long_section(0, 1, 0, 0, 0, b"x")) is Err(_))
}

///|
test "PMT preserves unknown types and descriptor bytes with bounded loops" {
  let body = b"\xff\xff\xf0\x03\xfa\x01z\xfe\xe1\x00\xf0\x03\xfb\x01q"
  let p = parse_pmt(long_section(2, 1, 0, 0, 0, body)).unwrap()
  assert_eq(p.pcr_pid, 8191)
  assert_eq(p.descriptors, [{ tag: 250, data: b"z", }])
  assert_eq(p.streams[0].stream_type, 254)
  assert_eq(p.streams[0].descriptors, [{ tag: 251, data: b"q", }])
  assert_true(
    parse_pmt(long_section(2, 1, 0, 0, 0, b"\xe1\x00\xf0\x02\xfa\x05"))
    is Err(_),
  )
  assert_true(
    parse_pmt(long_section(2, 0, 0, 0, 0, b"\xe1\x00\xf0\x00")) is Err(_),
  )
  assert_true(
    parse_pmt(long_section(2, 1, 0, 1, 1, b"\xe1\x00\xf0\x00")) is Err(_),
  )
}
