///|
test "public packet API exposes read-only structural information" {
  let bytes = Bytes::makei(188, fn(i) {
    match i {
      0 => 0x47
      1 => 0x1f
      2 => 0xff
      3 => 0x10
      _ => 0xff
    }
  })
  let p = @moontsinspect.parse_packet(bytes).unwrap()
  assert_eq(p.pid, 8191)
  assert_eq(p.payload.length(), 184)
  assert_eq(
    @moontsinspect.Continuity::new().observe(p).unwrap(),
    @moontsinspect.IgnoredNull,
  )
}
