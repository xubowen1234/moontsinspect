///|
test "recovery rejects false sync and preserves absolute offsets across every split" {
  let p = packet_bytes(10, 0)
  let bytes = cat(b"\x47junk", cat(p, cat(p, p)))
  for n = 0; n <= bytes.length(); n = n + 1 {
    let r = RecoveryReader::new(5).unwrap()
    let out = []
    r.feed(bytes.view(end=n).to_owned(), fn(e) { out.push(e) })
    assert_true(r.buffered() < 564)
    r.feed(bytes.view(start=n).to_owned(), fn(e) { out.push(e) })
    assert_true(out[0] is Err({ code: "sync_lost", offset: 0L, .. }))
    assert_true(out[1] is Err({ code: "sync_recovered", offset: 5L, .. }))
    assert_eq(out[2].unwrap().offset, 5L)
    assert_eq(out[4].unwrap().offset, 381L)
    assert_eq(r.finish(), Ok(()))
  }
}

///|
test "recovery enforces scan budgets and refuses unconfirmed two packet tail" {
  let r = RecoveryReader::new(3).unwrap()
  let out = []
  r.feed(Bytes::make(600, 0), fn(e) { out.push(e) })
  assert_true(out[1] is Err({ code: "sync_scan_limit", .. }))
  assert_eq(r.buffered(), 0)
  assert_true(RecoveryReader::new(0) is Err(_))
  let r = RecoveryReader::new(10).unwrap()
  r.feed(cat(packet_bytes(1, 0), packet_bytes(1, 1)), fn(e) { out.push(e) })
  assert_true(r.finish() is Err({ code: "recovery_unconfirmed_tail", .. }))
}

///|
test "opt-in inspector recovery retains program inventory after leading junk" {
  let i = Inspector::new(recover_scan_limit=5).unwrap()
  let events = []
  let bytes = cat(
    b"junk!",
    cat(
      psi_packet(0, 0, pat_section()),
      cat(psi_packet(4096, 0, pmt_section()), packet_bytes(8191, 0)),
    ),
  )
  i.feed(bytes, fn(e) { events.push(e) })
  i.finish(fn(e) { events.push(e) })
  assert_eq(i.packet_count(), 3L)
  assert_eq(i.program_maps()[0].section.extension, 7)
  assert_true(events[1] is Issue({ code: "sync_recovered", offset: 5L, .. }))
}
