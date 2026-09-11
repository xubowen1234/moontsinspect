///|
fn Inspector::rebuild_media(
  self : Inspector,
  emit : (InspectEvent) -> Unit,
) -> Unit {
  let wanted = FixedArray::make(8192, false)
  let pcrs = FixedArray::make(8192, false)
  let mut count = 0
  for slot in self.slots {
    if slot.section is Some(section) {
      if parse_pmt(section) is Ok(pmt) {
        if pmt.pcr_pid != 8191 {
          pcrs[pmt.pcr_pid] = true
        }
        for stream in pmt.streams {
          if !wanted[stream.pid] {
            if count >= 256 {
              emit(
                Issue(
                  fault(
                    "elementary_stream_limit",
                    section.offset,
                    Some(stream.pid),
                  ),
                ),
              )
            } else {
              wanted[stream.pid] = true
              count = count + 1
            }
          }
        }
      }
    }
  }
  for pid = 0; pid < 8192; pid = pid + 1 {
    // Table changes deliberately reset PES headers, preventing cross-version assembly.
    self.pes[pid] = if wanted[pid] { Some(PesAssembler::new()) } else { None }
    if !pcrs[pid] {
      self.clocks[pid] = None
    }
    self.known_pcr[pid] = pcrs[pid]
  }
}

///|
fn Inspector::observe_media(
  self : Inspector,
  p : Packet,
  event : ContinuityEvent,
  emit : (InspectEvent) -> Unit,
) -> Unit {
  if event == IgnoredNull {
    return
  }
  let lost = match event {
    Gap(..) | Discontinuity | TransportError => true
    _ => false
  }
  if lost {
    if self.pes[p.pid] is Some(a) {
      a.reset()
    }
    if self.clocks[p.pid] is Some(c) {
      c.reset()
    }
  }
  if event == TransportError {
    return
  }
  // Duplicates may carry a refreshed valid PCR, but their PES bytes must not be replayed.
  if self.known_pcr[p.pid] {
    match p.adaptation() {
      Ok(Some(a)) =>
        if a.pcr is Some(ticks) {
          let clock = match self.clocks[p.pid] {
            Some(c) => c
            None => {
              let c = PcrClock::new()
              self.clocks[p.pid] = Some(c)
              c
            }
          }
          match clock.observe(ticks) {
            Ok(sample) => emit(MediaClock(pid=p.pid, offset=p.offset, sample))
            Err(e) => emit(Issue(fault(e.code, p.offset, Some(p.pid))))
          }
        }
      _ => ()
    }
  }
  if event == Duplicate {
    return
  }
  if p.scrambling != 0 {
    if self.pes[p.pid] is Some(a) {
      a.reset()
      emit(Issue(fault("scrambled_pes", p.offset, Some(p.pid))))
    }
    return
  }
  if p.payload.is_empty() {
    return
  }
  if self.pes[p.pid] is Some(a) {
    a.feed(
      p.payload,
      p.payload_start,
      p.offset + (188 - p.payload.length()).to_int64(),
      fn(r) {
        match r {
          Ok(header) => emit(PesTimestamp(pid=p.pid, header))
          Err(e) => emit(Issue(fault(e.code, e.offset, Some(p.pid))))
        }
      },
    )
  }
}
