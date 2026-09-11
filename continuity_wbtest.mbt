///|
test "continuity interleaving wrap adaptation only and explicit reset" {
  let c = Continuity::new()
  assert_eq(c.observe(parse_packet(packet_bytes(10, 15)).unwrap()), Ok(First))
  assert_eq(c.observe(parse_packet(packet_bytes(11, 4)).unwrap()), Ok(First))
  assert_eq(
    c.observe(parse_packet(packet_bytes(10, 0)).unwrap()),
    Ok(Continuous),
  )
  assert_eq(
    c.observe(parse_packet(adapted_bytes(10, 0, b"\x00")).unwrap()),
    Ok(Continuous),
  )
  assert_eq(
    c.observe(parse_packet(packet_bytes(10, 2)).unwrap()),
    Ok(Gap(expected=1, actual=2)),
  )
  assert_eq(
    c.observe(
      parse_packet(adapted_bytes(10, 9, b"\x80", payload=b"a")).unwrap(),
    ),
    Ok(Discontinuity),
  )
  assert_eq(
    c.observe(parse_packet(packet_bytes(10, 10)).unwrap()),
    Ok(Continuous),
  )
  c.reset_pid(10).unwrap()
  assert_eq(c.observe(parse_packet(packet_bytes(10, 5)).unwrap()), Ok(First))
  assert_true(c.reset_pid(-1) is Err(_))
}

///|
test "one identical duplicate allowed but triple and changed payload rejected" {
  let c = Continuity::new()
  let p = parse_packet(packet_bytes(10, 0, payload=b"a")).unwrap()
  assert_eq(c.observe(p), Ok(First))
  assert_eq(c.observe(p), Ok(Duplicate))
  assert_eq(c.observe(p), Ok(Gap(expected=1, actual=0)))
  let p = parse_packet(packet_bytes(10, 0, payload=b"b")).unwrap()
  assert_eq(c.observe(p), Ok(Gap(expected=1, actual=0)))
}

///|
test "duplicate may refresh PCR; null and TEI do not poison baseline" {
  let c = Continuity::new()
  let a = parse_packet(
    adapted_bytes(10, 0, b"\x10\x00\x00\x00\x00\x7e\x00", payload=b"a"),
  ).unwrap()
  let b = parse_packet(
    adapted_bytes(10, 0, b"\x10\x00\x00\x00\x00\x7e\x01", payload=b"a"),
  ).unwrap()
  assert_eq(c.observe(a), Ok(First))
  assert_eq(c.observe(b), Ok(Duplicate))
  assert_eq(
    c.observe(parse_packet(packet_bytes(8191, 7)).unwrap()),
    Ok(IgnoredNull),
  )
  let b = packet_bytes(10, 4).to_fixedarray()
  b[1] = 0x80
  assert_eq(
    c.observe(parse_packet(Bytes::from_array(b[:])).unwrap()),
    Ok(TransportError),
  )
  assert_eq(c.observe(a), Ok(First))
}
