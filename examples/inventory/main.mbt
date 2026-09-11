///|
/// Build a TS payload packet around an independently muxed PSI section.
fn packet(pid : Int, section : Bytes) -> Bytes {
  let a : FixedArray[Byte] = FixedArray::make(188, b'\xff')
  a[0] = 0x47
  a[1] = ((pid >> 8) | 0x40).to_byte()
  a[2] = pid.to_byte()
  a[3] = 0x10
  a[4] = 0
  for i = 0; i < section.length(); i = i + 1 {
    a[i + 5] = section[i]
  }
  Bytes::from_array(a[:])
}

///|
fn main {
  let inspector = @ts.Inspector::new().unwrap()
  let emit = fn(e : @ts.InspectEvent) { println(@ts.event_json(e).stringify()) }
  inspector.feed(
    packet(
      0, b"\x00\xb0\x0d\x00\x01\xc1\x00\x00\x00\x07\xf0\x00\x2e\x62\xef\xa0",
    ),
    emit,
  )
  inspector.feed(
    packet(
      4096, b"\x02\xb0\x17\x00\x07\xc1\x00\x00\xe1\x00\xf0\x00\x02\xe1\x00\xf0\x00\x03\xe1\x01\xf0\x00\xfc\x59\xd0\xb2",
    ),
    emit,
  )
  inspector.finish(emit)
  println(inspector.summary_json().stringify())
}
