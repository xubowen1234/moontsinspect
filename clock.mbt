///|
pub struct ClockSample {
  segment : Int
  relative_ticks : Int64
  delta_ticks : Int64
  wrapped : Bool
} derive(Eq, Debug)

///|
/// Relative PCR clock in 27 MHz ticks. No arrival-time or network jitter interpretation.
pub struct PcrClock {
  priv mut previous : Int64?
  priv mut relative : Int64
  priv mut segment : Int
}

///|
pub fn PcrClock::new() -> PcrClock {
  { previous: None, relative: 0L, segment: 0, }
}

///|
pub fn PcrClock::reset(self : PcrClock) -> Unit {
  self.previous = None
  self.relative = 0L
  if self.segment < 2147483647 {
    self.segment = self.segment + 1
  }
}

///|
/// Uses nearest signed modular difference. Gaps of half a wrap period or more are ambiguous.
/// Negative deltas start a fresh segment and are returned as clock_backward rather than hidden.
pub fn PcrClock::observe(
  self : PcrClock,
  ticks : Int64,
  discontinuity? : Bool = false,
) -> Result[ClockSample, Diagnostic] {
  let modulus = 2576980377600L
  if ticks < 0L || ticks >= modulus {
    return Err(fault("pcr_range", 0L, None))
  }
  if discontinuity {
    self.reset()
  }
  match self.previous {
    None => {
      self.previous = Some(ticks)
      Ok({
        segment: self.segment,
        relative_ticks: 0L,
        delta_ticks: 0L,
        wrapped: false,
      })
    }
    Some(prev) => {
      let raw = ticks - prev
      if raw == modulus / 2L || raw == 0L - modulus / 2L {
        self.reset()
        self.previous = Some(ticks)
        return Err(fault("clock_ambiguous", 0L, None))
      }
      let delta = if raw < 0L - modulus / 2L {
        raw + modulus
      } else if raw > modulus / 2L {
        raw - modulus
      } else {
        raw
      }
      if delta < 0L {
        self.reset()
        self.previous = Some(ticks)
        return Err(fault("clock_backward", 0L, None))
      }
      if self.relative > 9223372036854775807L - delta {
        self.reset()
        self.previous = Some(ticks)
        return Err(fault("clock_overflow", 0L, None))
      }
      self.relative = self.relative + delta
      self.previous = Some(ticks)
      Ok({
        segment: self.segment,
        relative_ticks: self.relative,
        delta_ticks: delta,
        wrapped: raw < 0L,
      })
    }
  }
}
