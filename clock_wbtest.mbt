///|
test "PCR wrap and explicit discontinuity define relative segments" {
  let c = PcrClock::new()
  assert_eq(c.observe(2576980377590L).unwrap().relative_ticks, 0L)
  let x = c.observe(10L).unwrap()
  assert_eq(x.delta_ticks, 20L)
  assert_true(x.wrapped)
  assert_eq(x.segment, 0)
  let x = c.observe(3L, discontinuity=true).unwrap()
  assert_eq(x.segment, 1)
  assert_eq(x.relative_ticks, 0L)
  assert_eq(c.observe(27000003L).unwrap().relative_ticks, 27000000L)
}

///|
test "backwards ambiguous invalid and overflowing clocks are not silently accepted" {
  let c = PcrClock::new()
  c.observe(100L).unwrap() |> ignore
  assert_true(c.observe(90L) is Err({ code: "clock_backward", .. }))
  assert_eq(c.observe(100L).unwrap().segment, 1)
  assert_true(c.observe(-1L) is Err({ code: "pcr_range", .. }))
  assert_true(c.observe(2576980377600L) is Err(_))
  let c = PcrClock::new()
  c.observe(0L).unwrap() |> ignore
  assert_true(c.observe(1288490188800L) is Err({ code: "clock_ambiguous", .. }))
  c.relative = 9223372036854775807L
  assert_true(c.observe(1288490188801L) is Err({ code: "clock_overflow", .. }))
}
