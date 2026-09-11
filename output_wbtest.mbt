///|
test "JSON preserves offsets beyond JS safe integer range and unknown PID" {
  let j = event_json(Issue(fault("test", 9007199254740993L, None)))
  assert_eq(j, {
    "schema": 1,
    "type": "issue",
    "code": "test",
    "offset": "9007199254740993",
    "pid": (None : Int?).to_json(),
  })
  let j = event_json(
    MediaClock(pid=256, offset=188L, {
      segment: 0,
      relative_ticks: 20L,
      delta_ticks: 20L,
      wrapped: true,
    }),
  )
  assert_eq(j, {
    "schema": 1,
    "type": "pcr",
    "pid": 256,
    "offset": "188",
    "segment": 0,
    "relative_ticks": "20",
    "delta_ticks": "20",
    "wrapped": true,
    "tick_rate": 27000000,
  })
}

///|
test "summary JSON reflects real program maps" {
  let i = Inspector::new().unwrap()
  i.feed(
    cat(psi_packet(0, 0, pat_section()), psi_packet(4096, 0, pmt_section())),
    fn(_) { () },
  )
  let expected : Json = {
    "schema": 1,
    "type": "summary",
    "packets": "2",
    "programs": [{ "program": 7, "pmt_pid": 4096 }],
    "maps": [
      {
        "program": 7,
        "version": 0,
        "pcr_pid": 256,
        "descriptors": [],
        "streams": [
          { "pid": 256, "stream_type": 2, "descriptors": [] },
          { "pid": 257, "stream_type": 3, "descriptors": [] },
        ],
      },
    ],
  }
  assert_eq(i.summary_json(), expected)
}
