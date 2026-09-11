///|
pub(all) enum ContinuityEvent {
  First
  Continuous
  Duplicate
  Discontinuity
  IgnoredNull
  TransportError
  Gap(expected~ : Int, actual~ : Int)
} derive(Eq, Debug)

///|
priv struct PidState {
  previous : Packet
  duplicated : Bool
}

///|
/// One slot per legal PID. Packet history is bounded by the TS PID namespace.
pub struct Continuity {
  priv states : FixedArray[PidState?]
}

///|
pub fn Continuity::new() -> Continuity {
  { states: FixedArray::make(8192, None) }
}

///|
fn same_duplicate(a : Packet, b : Packet, has_pcr : Bool) -> Bool {
  for i = 0; i < 188; i = i + 1 {
    // H.222.0 permits a fresh PCR, but not a changed OPCR, in a duplicate packet.
    if has_pcr && i >= 6 && i < 12 {
      continue
    }
    if a.raw[i] != b.raw[i] {
      return false
    }
  }
  true
}

///|
/// Check continuity independently of PSI/PES parsing. At most one consecutive duplicate is legal.
pub fn Continuity::observe(
  self : Continuity,
  packet : Packet,
) -> Result[ContinuityEvent, Diagnostic] {
  let pid = packet.pid
  if pid == 8191 {
    return Ok(IgnoredNull)
  }
  if packet.transport_error {
    self.states[pid] = None
    return Ok(TransportError)
  }
  let adaptation = match packet.adaptation() {
    Err(e) => {
      self.states[pid] = None
      return Err(e)
    }
    Ok(a) => a
  }
  let discontinuity = match adaptation {
    Some(a) => a.discontinuity
    None => false
  }
  let has_pcr = match adaptation {
    Some(a) => a.pcr is Some(_)
    None => false
  }
  let prev = self.states[pid]
  self.states[pid] = Some({ previous: packet, duplicated: false })
  if discontinuity {
    return Ok(Discontinuity)
  }
  match prev {
    None => Ok(First)
    Some(state) => {
      let old = state.previous
      let payload = (packet.adaptation_control & 1) != 0
      let expected = if payload {
        (old.continuity + 1) % 16
      } else {
        old.continuity
      }
      if payload &&
        packet.continuity == old.continuity &&
        !state.duplicated &&
        same_duplicate(old, packet, has_pcr) {
        self.states[pid] = Some({ previous: packet, duplicated: true })
        Ok(Duplicate)
      } else if packet.continuity == expected {
        Ok(Continuous)
      } else {
        Ok(Gap(expected~, actual=packet.continuity))
      }
    }
  }
}

///|
/// Explicitly discard one PID's baseline after an external loss or seek.
pub fn Continuity::reset_pid(
  self : Continuity,
  pid : Int,
) -> Result[Unit, Diagnostic] {
  if pid < 0 || pid > 8191 {
    return Err(fault("pid_range", 0L, Some(pid)))
  }
  self.states[pid] = None
  Ok(())
}
