///|
/// Bounded single-PID long-PSI assembler. Caller must remove duplicates and reset on loss.
pub struct SectionAssembler {
  priv pid : Int
  priv buffer : Array[Byte]
  priv mut start_offset : Int64
}

///|
pub fn SectionAssembler::new(pid : Int) -> Result[SectionAssembler, Diagnostic] {
  if pid < 0 || pid >= 8191 {
    return Err(fault("pid_range", 0L, Some(pid)))
  }
  Ok({ pid, buffer: [], start_offset: 0L })
}

///|
pub fn SectionAssembler::reset(self : SectionAssembler) -> Unit {
  self.buffer.clear()
}

///|
pub fn SectionAssembler::buffered(self : SectionAssembler) -> Int {
  self.buffer.length()
}

///|
fn SectionAssembler::consume(
  self : SectionAssembler,
  data : Bytes,
  offset : Int64,
  new_sections : Bool,
  emit : (Result[LongSection, Diagnostic]) -> Unit,
) -> Bool {
  let mut allow_new = new_sections
  for i = 0; i < data.length(); i = i + 1 {
    let byte = data[i]
    if self.buffer.is_empty() {
      if byte == 0xff || !allow_new {
        for j = i; j < data.length(); j = j + 1 {
          if data[j] != 0xff {
            emit(
              Err(fault("psi_stuffing", offset + j.to_int64(), Some(self.pid))),
            )
            return false
          }
        }
        return true
      }
      self.start_offset = offset + i.to_int64()
    }
    self.buffer.push(byte)
    if self.buffer.length() >= 3 {
      let total = 3 +
        (((self.buffer[1].to_int() & 15) << 8) | self.buffer[2].to_int())
      if total < 12 || total > 1024 {
        self.reset()
        emit(Err(fault("section_size", self.start_offset, Some(self.pid))))
        return false
      }
      if self.buffer.length() == total {
        let section = Bytes::from_array(self.buffer[:])
        self.reset()
        emit(parse_section(section, offset=self.start_offset, pid=self.pid))
        allow_new = new_sections
      }
    }
  }
  true
}

///|
/// offset points to the first payload byte, including pointer_field when start is true.
/// Empty or non-start payloads during initial acquisition are ignored.
pub fn SectionAssembler::feed(
  self : SectionAssembler,
  payload : Bytes,
  start : Bool,
  offset : Int64,
  emit : (Result[LongSection, Diagnostic]) -> Unit,
) -> Unit {
  if offset < 0L || offset > 9223372036854774783L || payload.length() > 184 {
    self.reset()
    emit(Err(fault("psi_input_range", offset, Some(self.pid))))
    return
  }
  if payload.is_empty() {
    return
  }
  if start {
    let boundary = 1 + payload[0].to_int()
    if boundary >= payload.length() {
      self.reset()
      emit(Err(fault("psi_pointer", offset, Some(self.pid))))
      return
    }
    if !self.buffer.is_empty() {
      let good = self.consume(
        payload.view(start=1, end=boundary).to_owned(),
        offset + 1L,
        false,
        emit,
      )
      if !good {
        self.reset()
        return
      }
      if !self.buffer.is_empty() {
        self.reset()
        emit(Err(fault("psi_incomplete", offset, Some(self.pid))))
        return
      }
    }
    ignore(
      self.consume(
        payload.view(start=boundary).to_owned(),
        offset + boundary.to_int64(),
        true,
        emit,
      ),
    )
  } else if !self.buffer.is_empty() {
    ignore(self.consume(payload, offset, false, emit))
  }
}

///|
pub fn SectionAssembler::finish(
  self : SectionAssembler,
) -> Result[Unit, Diagnostic] {
  if self.buffer.is_empty() {
    Ok(())
  } else {
    self.reset()
    Err(fault("psi_incomplete", self.start_offset, Some(self.pid)))
  }
}
