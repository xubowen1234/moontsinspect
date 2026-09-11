///|
/// Single elementary PID header reassembler. Never buffers elementary media payload.
pub struct PesAssembler {
  priv buffer : Array[Byte]
  priv mut collecting : Bool
  priv mut offset : Int64
}

///|
pub fn PesAssembler::new() -> PesAssembler {
  { buffer: [], collecting: false, offset: 0L }
}

///|
pub fn PesAssembler::reset(self : PesAssembler) -> Unit {
  self.buffer.clear()
  self.collecting = false
}

///|
pub fn PesAssembler::buffered(self : PesAssembler) -> Int {
  self.buffer.length()
}

///|
/// Caller resets on continuity loss, skips scrambled/TEI data, and removes duplicate packets.
pub fn PesAssembler::feed(
  self : PesAssembler,
  payload : Bytes,
  start : Bool,
  offset : Int64,
  emit : (Result[PesHeader, Diagnostic]) -> Unit,
) -> Unit {
  if offset < 0L || offset > 9223372036854775543L || payload.length() > 184 {
    self.reset()
    emit(Err(fault("pes_input_range", offset, None)))
    return
  }
  if start {
    if self.collecting {
      emit(Err(fault("pes_header_incomplete", self.offset, None)))
    }
    self.reset()
    self.collecting = true
    self.offset = offset
  }
  if !self.collecting {
    return
  }
  for byte in payload {
    self.buffer.push(byte)
    let n = self.buffer.length()
    if n < 6 {
      continue
    }
    if n == 6 || n == 9 || (n > 9 && n == 9 + self.buffer[8].to_int()) {
      let result = parse_pes_header(
        Bytes::from_array(self.buffer[:]),
        offset=self.offset,
      )
      match result {
        Err({ code: "pes_header_incomplete", .. }) => ()
        _ => {
          self.reset()
          emit(result)
          return
        }
      }
    }
  }
}

///|
pub fn PesAssembler::finish(self : PesAssembler) -> Result[Unit, Diagnostic] {
  if self.collecting {
    self.reset()
    Err(fault("pes_header_incomplete", self.offset, None))
  } else {
    Ok(())
  }
}
