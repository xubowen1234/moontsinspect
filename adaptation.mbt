///|
/// Parsed optional adaptation fields. Extension bytes are opaque, not semantically validated.
pub struct Adaptation {
  discontinuity : Bool
  random_access : Bool
  pcr : Int64?
  opcr : Int64?
  splice_countdown : Int?
  private_data : Bytes
  extension : Bytes
} derive(Eq, Debug)

///|
fn read_clock(
  b : Bytes,
  i : Int,
  offset : Int64,
  pid : Int,
) -> Result[Int64, Diagnostic] {
  let ext = ((b[i + 4].to_int() & 1) << 8) | b[i + 5].to_int()
  if (b[i + 4].to_int() & 0x7e) != 0x7e || ext > 299 {
    return Err(fault("pcr_encoding", offset + i.to_int64() + 4L, Some(pid)))
  }
  let base = (b[i].to_int64() << 25) |
    (b[i + 1].to_int64() << 17) |
    (b[i + 2].to_int64() << 9) |
    (b[i + 3].to_int64() << 1) |
    (b[i + 4].to_int64() >> 7)
  Ok(base * 300L + ext.to_int64())
}

///|
/// Validate lengths, PCR/OPCR encoding and outer stuffing; extension payload is preserved.
pub fn Packet::adaptation(self : Packet) -> Result[Adaptation?, Diagnostic] {
  if (self.adaptation_control & 2) == 0 || self.raw[4] == 0 {
    return Ok(None)
  }
  let b = self.raw
  let end = 5 + b[4].to_int()
  let flags = b[5].to_int()
  let mut pos = 6
  let mut pcr = None
  let mut opcr = None
  for mask in [0x10, 0x08] {
    if (flags & mask) != 0 {
      if pos + 6 > end {
        return Err(
          fault(
            "adaptation_truncated",
            self.offset + pos.to_int64(),
            Some(self.pid),
          ),
        )
      }
      match read_clock(b, pos, self.offset, self.pid) {
        Err(e) => return Err(e)
        Ok(c) => if mask == 0x10 { pcr = Some(c) } else { opcr = Some(c) }
      }
      pos = pos + 6
    }
  }
  let mut splice_countdown = None
  if (flags & 4) != 0 {
    if pos >= end {
      return Err(
        fault(
          "adaptation_truncated",
          self.offset + pos.to_int64(),
          Some(self.pid),
        ),
      )
    }
    let value = b[pos].to_int()
    splice_countdown = Some(if value >= 128 { value - 256 } else { value })
    pos = pos + 1
  }
  let mut private_data = b""
  let mut extension = b""
  for mask in [2, 1] {
    if (flags & mask) != 0 {
      if pos >= end {
        return Err(
          fault(
            "adaptation_truncated",
            self.offset + pos.to_int64(),
            Some(self.pid),
          ),
        )
      }
      let n = b[pos].to_int()
      pos = pos + 1
      if pos + n > end {
        return Err(
          fault(
            "adaptation_truncated",
            self.offset + pos.to_int64(),
            Some(self.pid),
          ),
        )
      }
      let bytes = b.view(start=pos, end=pos + n).to_owned()
      if mask == 2 {
        private_data = bytes
      } else {
        extension = bytes
      }
      pos = pos + n
    }
  }
  for i = pos; i < end; i = i + 1 {
    if b[i] != 0xff {
      return Err(
        fault("adaptation_stuffing", self.offset + i.to_int64(), Some(self.pid)),
      )
    }
  }
  Ok(
    Some({
      discontinuity: (flags & 0x80) != 0,
      random_access: (flags & 0x40) != 0,
      pcr,
      opcr,
      splice_countdown,
      private_data,
      extension,
    }),
  )
}
