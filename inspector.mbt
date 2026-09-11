///|
pub(all) enum InspectEvent {
  Issue(Diagnostic)
  ProgramsChanged(Array[ProgramRef])
  ProgramMapChanged(Pmt)
  MediaClock(pid~ : Int, offset~ : Int64, ClockSample)
  PesTimestamp(pid~ : Int, PesHeader)
} derive(Eq, Debug)

///|
priv struct ProgramSlot {
  reference : ProgramRef
  mut section : LongSection?
}

///|
/// Bounded offline inspection session. Issues are streamed, never accumulated internally.
pub struct Inspector {
  priv reader : PacketReader
  priv continuity : Continuity
  priv pat_assembler : SectionAssembler
  priv pat_table : TableCollector
  priv assemblers : FixedArray[SectionAssembler?]
  priv slots : Array[ProgramSlot]
  priv pes : FixedArray[PesAssembler?]
  priv clocks : FixedArray[PcrClock?]
  priv known_pcr : FixedArray[Bool]
  priv max_programs : Int
  priv mut packets : Int64
  priv mut closed : Bool
}

///|
pub fn Inspector::new(
  max_programs? : Int = 64,
) -> Result[Inspector, Diagnostic] {
  if max_programs < 1 || max_programs > 256 {
    return Err(fault("program_limit_range", 0L, None))
  }
  Ok({
    reader: PacketReader::new(),
    continuity: Continuity::new(),
    pat_assembler: SectionAssembler::new(0).unwrap(),
    pat_table: TableCollector::new(0),
    assemblers: FixedArray::make(8192, None),
    slots: [],
    pes: FixedArray::make(8192, None),
    clocks: FixedArray::make(8192, None),
    known_pcr: FixedArray::make(8192, false),
    max_programs,
    packets: 0L,
    closed: false,
  })
}

///|
pub fn Inspector::packet_count(self : Inspector) -> Int64 {
  self.packets
}

///|
/// Returns independent mutable arrays; callers cannot change the inspector's active tables.
pub fn Inspector::programs(self : Inspector) -> Array[ProgramRef] {
  self.slots.map(fn(s) { s.reference })
}

///|
pub fn Inspector::program_maps(self : Inspector) -> Array[Pmt] {
  let result = []
  for slot in self.slots {
    match slot.section {
      Some(s) =>
        match parse_pmt(s) {
          Ok(p) => result.push(p)
          Err(_) => ()
        }
      None => ()
    }
  }
  result
}

///|
fn Inspector::on_section(
  self : Inspector,
  pid : Int,
  result : Result[LongSection, Diagnostic],
  emit : (InspectEvent) -> Unit,
) -> Unit {
  let section = match result {
    Ok(s) => s
    Err(e) => {
      emit(Issue(e))
      return
    }
  }
  if pid == 0 {
    match parse_pat(section) {
      Err(e) => {
        emit(Issue(e))
        return
      }
      Ok(_) => ()
    }
    let sections = match self.pat_table.accept(section) {
      Err(e) => {
        emit(Issue(e))
        return
      }
      Ok(None) => return
      Ok(Some(s)) => s
    }
    let references : Array[ProgramRef] = []
    for s in sections {
      let pat = match parse_pat(s) {
        Ok(p) => p
        Err(e) => {
          emit(Issue(e))
          return
        }
      }
      for p in pat.programs {
        if references.length() >= self.max_programs {
          emit(Issue(fault("program_limit", s.offset, Some(0))))
          return
        }
        for old in references {
          if p.number == old.number {
            emit(Issue(fault("pat_duplicate_program", s.offset, Some(0))))
            return
          }
        }
        references.push(p)
      }
    }
    let next : Array[ProgramSlot] = []
    for p in references {
      let mut preserved = None
      for old in self.slots {
        if old.reference == p {
          preserved = old.section
        }
      }
      next.push({ reference: p, section: preserved })
    }
    // Rebuild bounded per-PMT-PID assemblers on a complete PAT activation.
    for old in self.slots {
      self.assemblers[old.reference.pmt_pid] = None
    }
    self.slots.clear()
    for slot in next {
      let pid = slot.reference.pmt_pid
      if self.assemblers[pid] is None {
        self.assemblers[pid] = Some(SectionAssembler::new(pid).unwrap())
      }
      self.slots.push(slot)
    }
    self.rebuild_media(emit)
    emit(ProgramsChanged(self.programs()))
  } else {
    if section.table_id != 2 {
      return
    }
    let pmt = match parse_pmt(section) {
      Ok(p) => p
      Err(e) => {
        emit(Issue(e))
        return
      }
    }
    if !section.current {
      return
    }
    for slot in self.slots {
      if slot.reference.pmt_pid == pid &&
        slot.reference.number == section.extension {
        match slot.section {
          Some(old) =>
            if old.version == section.version {
              if old.bytes != section.bytes {
                emit(
                  Issue(
                    fault("table_version_conflict", section.offset, Some(pid)),
                  ),
                )
              }
              return
            }
          None => ()
        }
        slot.section = Some(section)
        self.rebuild_media(emit)
        emit(ProgramMapChanged(pmt))
        return
      }
    }
    emit(Issue(fault("pmt_unreferenced_program", section.offset, Some(pid))))
  }
}

///|
fn Inspector::on_packet(
  self : Inspector,
  p : Packet,
  emit : (InspectEvent) -> Unit,
) -> Unit {
  self.packets = self.packets + 1L
  let assembler = if p.pid == 0 {
    Some(self.pat_assembler)
  } else {
    self.assemblers[p.pid]
  }
  let event = match self.continuity.observe(p) {
    Err(e) => {
      if assembler is Some(a) {
        a.reset()
      }
      emit(Issue(e))
      return
    }
    Ok(e) => e
  }
  self.observe_media(p, event, emit)
  match event {
    Duplicate | IgnoredNull => return
    Gap(..) => {
      if assembler is Some(a) {
        a.reset()
      }
      emit(Issue(fault("continuity_gap", p.offset, Some(p.pid))))
    }
    Discontinuity => if assembler is Some(a) { a.reset() }
    TransportError => {
      if assembler is Some(a) {
        a.reset()
      }
      emit(Issue(fault("transport_error", p.offset, Some(p.pid))))
      return
    }
    _ => ()
  }
  if p.scrambling != 0 {
    if assembler is Some(a) {
      a.reset()
      emit(Issue(fault("scrambled_psi", p.offset, Some(p.pid))))
    }
    return
  }
  if p.payload.is_empty() {
    return
  }
  if assembler is Some(a) {
    a.feed(
      p.payload,
      p.payload_start,
      p.offset + (188 - p.payload.length()).to_int64(),
      fn(r) { self.on_section(p.pid, r, emit) },
    )
  }
}

///|
pub fn Inspector::feed(
  self : Inspector,
  bytes : Bytes,
  emit : (InspectEvent) -> Unit,
) -> Unit {
  if self.closed {
    emit(Issue(fault("inspector_closed", 0L, None)))
    return
  }
  self.reader.feed(bytes, fn(r) {
    match r {
      Ok(p) => self.on_packet(p, emit)
      Err(e) => emit(Issue(e))
    }
  })
}

///|
/// Missing PAT/PMT is reported at EOF, not prematurely while acquiring a stream.
pub fn Inspector::finish(
  self : Inspector,
  emit : (InspectEvent) -> Unit,
) -> Unit {
  if self.closed {
    emit(Issue(fault("inspector_closed", 0L, None)))
    return
  }
  self.closed = true
  match self.reader.finish() {
    Err(e) => emit(Issue(e))
    Ok(_) => ()
  }
  match self.pat_assembler.finish() {
    Err(e) => emit(Issue(e))
    Ok(_) => ()
  }
  if self.pat_table.active().is_empty() {
    emit(Issue(fault("pat_missing", 0L, Some(0))))
  }
  for slot in self.slots {
    if slot.section is None {
      emit(Issue(fault("pmt_missing", 0L, Some(slot.reference.pmt_pid))))
    }
  }
  for pes in self.pes {
    if pes is Some(a) {
      match a.finish() {
        Err(e) => emit(Issue(e))
        Ok(_) => ()
      }
    }
  }
  for assembler in self.assemblers {
    if assembler is Some(a) {
      match a.finish() {
        Err(e) => emit(Issue(e))
        Ok(_) => ()
      }
    }
  }
}
