///|
test "table activation is complete ordered atomic and version wrap safe" {
  let c = TableCollector::new(0)
  let v31 = long_section(0, 1, 31, 0, 0, b"\x00\x07\xf0\x00")
  assert_true(c.accept(v31).unwrap() is Some(_))
  let s0 = long_section(0, 1, 0, 0, 1, b"\x00\x07\xf0\x01")
  let s1 = long_section(0, 1, 0, 1, 1, b"\x00\x08\xf0\x02")
  assert_eq(c.accept(s1), Ok(None))
  assert_eq(c.active()[0].version, 31)
  assert_eq(c.accept(v31), Ok(None))
  let sections = c.accept(s0).unwrap().unwrap()
  assert_eq(sections.length(), 2)
  assert_eq(sections[0].number, 0)
  assert_eq(c.active()[0].version, 0)
  assert_eq(c.accept(s1), Ok(None))
  sections.clear()
  assert_eq(c.active().length(), 2)
}

///|
test "current-next and content conflicts cannot overwrite active table" {
  let c = TableCollector::new(0)
  assert_eq(c.accept(long_section(0, 1, 0, 0, 0, b"", current=false)), Ok(None))
  assert_eq(c.active().length(), 0)
  c.accept(long_section(0, 1, 0, 0, 0, b"")).unwrap() |> ignore
  assert_true(
    c.accept(long_section(0, 1, 0, 0, 0, b"\x00\x07\xf0\x00"))
    is Err({ code: "table_version_conflict", .. }),
  )
  c.accept(long_section(0, 1, 1, 0, 1, b"")).unwrap() |> ignore
  assert_true(c.accept(long_section(0, 1, 1, 0, 2, b"")) is Err(_))
  assert_eq(c.active()[0].version, 0)
  c.discard_pending()
  assert_true(c.accept(long_section(0, 1, 1, 0, 0, b"")).unwrap() is Some(_))
}
