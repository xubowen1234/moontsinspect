///|
/// Strict incremental packet reader. Retains at most 187 bytes between calls.
/// Diagnostics terminate this reader; create another reader to establish a new alignment.
pub struct PacketReader {
  priv pending : Array[Byte]
  priv mut offset : Int64
  priv mut closed : Bool
}

///|
pub fn PacketReader::new() -> PacketReader {
  { pending: [], offset: 0L, closed: false, }
}

///|
/// Synchronous callback avoids accumulating one result per packet in library memory.
pub fn PacketReader::feed(
  self : PacketReader,
  chunk : Bytes,
  emit : (Result[Packet, Diagnostic]) -> Unit,
) -> Unit {
  if self.closed {
    emit(Err(fault("reader_closed", self.offset, None)))
    return
  }
  for byte in chunk {
    if self.pending.is_empty() && byte != 0x47 {
      self.closed = true
      emit(Err(fault("sync_byte", self.offset, None)))
      return
    }
    self.pending.push(byte)
    if self.pending.length() == 188 {
      let result = parse_packet(
        Bytes::from_array(self.pending[:]),
        offset=self.offset,
      )
      self.pending.clear()
      match result {
        Err(_) => {
          self.closed = true
          emit(result)
          return
        }
        Ok(_) => {
          self.offset = self.offset + 188L
          emit(result)
        }
      }
    }
  }
}

///|
/// Finish once: a partial final packet is diagnosed instead of silently dropped.
pub fn PacketReader::finish(self : PacketReader) -> Result[Unit, Diagnostic] {
  if self.closed {
    return Err(fault("reader_closed", self.offset, None))
  }
  self.closed = true
  if !self.pending.is_empty() {
    self.pending.clear()
    Err(fault("trailing_bytes", self.offset, None))
  } else {
    Ok(())
  }
}

///|
pub fn PacketReader::buffered(self : PacketReader) -> Int {
  self.pending.length()
}
