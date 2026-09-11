///|
/// Opt-in resynchronizing reader. Recovery requires THREE complete structurally valid packets.
/// A 564-byte window bounds memory; scan_limit bounds skipped bytes per loss episode.
pub struct RecoveryReader {
  priv buffer : Array[Byte]
  priv mut offset : Int64
  priv mut aligned : Bool
  priv mut closed : Bool
  priv mut loss_reported : Bool
  priv mut skipped : Int
  priv scan_limit : Int
}

///|
pub fn RecoveryReader::new(
  scan_limit : Int,
) -> Result[RecoveryReader, Diagnostic] {
  if scan_limit < 1 || scan_limit > 1048576 {
    return Err(fault("scan_limit_range", 0L, None))
  }
  Ok({
    buffer: [],
    offset: 0L,
    aligned: false,
    closed: false,
    skipped: 0,
    loss_reported: false,
    scan_limit,
  })
}

///|
pub fn RecoveryReader::buffered(self : RecoveryReader) -> Int {
  self.buffer.length()
}

///|
pub fn RecoveryReader::feed(
  self : RecoveryReader,
  bytes : Bytes,
  emit : (Result[Packet, Diagnostic]) -> Unit,
) -> Unit {
  if self.closed {
    emit(Err(fault("reader_closed", self.offset, None)))
    return
  }
  for b in bytes {
    if self.offset > 9223372036854775243L {
      self.closed = true
      self.buffer.clear()
      emit(Err(fault("offset_range", self.offset, None)))
      return
    }
    self.buffer.push(b)
    if self.aligned && self.buffer.length() == 188 {
      let result = parse_packet(
        Bytes::from_array(self.buffer[:]),
        offset=self.offset,
      )
      match result {
        Ok(_) => {
          self.offset = self.offset + 188L
          self.buffer.clear()
          emit(result)
          continue
        }
        Err(_) => {
          self.aligned = false
          self.loss_reported = true
          emit(Err(fault("sync_lost", self.offset, None)))
        }
      }
    }
    if !self.aligned && self.buffer.length() == 564 {
      let candidate = Bytes::from_array(self.buffer[:])
      let packets = []
      for start in [0, 188, 376] {
        match
          parse_packet(
            candidate.view(start~, end=start + 188).to_owned(),
            offset=self.offset + start.to_int64(),
          ) {
          Ok(p) => packets.push(p)
          Err(_) => break
        }
      }
      if packets.length() == 3 {
        self.aligned = true
        if self.skipped > 0 {
          emit(Err(fault("sync_recovered", self.offset, None)))
        }
        self.skipped = 0
        self.loss_reported = false
        self.offset = self.offset + 564L
        self.buffer.clear()
        for p in packets {
          emit(Ok(p))
        }
      } else {
        if !self.loss_reported {
          self.loss_reported = true
          emit(Err(fault("sync_lost", self.offset, None)))
        }
        if self.skipped >= self.scan_limit {
          self.closed = true
          self.buffer.clear()
          emit(Err(fault("sync_scan_limit", self.offset, None)))
          return
        }
        ignore(self.buffer.remove(0))
        self.skipped = self.skipped + 1
        self.offset = self.offset + 1L
      }
    }
  }
}

///|
pub fn RecoveryReader::finish(
  self : RecoveryReader,
) -> Result[Unit, Diagnostic] {
  if self.closed {
    return Err(fault("reader_closed", self.offset, None))
  }
  self.closed = true
  if self.buffer.is_empty() {
    return Ok(())
  }
  self.buffer.clear()
  Err(
    fault(
      if self.aligned {
        "trailing_bytes"
      } else {
        "recovery_unconfirmed_tail"
      },
      self.offset,
      None,
    ),
  )
}
