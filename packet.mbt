///|
/// A positioned, machine-readable failure. Offset is an absolute input byte offset.
pub(all) struct Diagnostic {
  code : String
  offset : Int64
  pid : Int?
} derive(Eq, Debug)

///|
/// Parsed 188-byte TS packet. The owned input and payload cannot alias caller mutation.
pub struct Packet {
  offset : Int64
  pid : Int
  continuity : Int
  payload_start : Bool
  transport_error : Bool
  scrambling : Int
  adaptation_control : Int
  payload : Bytes
  raw : Bytes
} derive(Eq, Debug)

///|
fn fault(code : String, offset : Int64, pid : Int?) -> Diagnostic {
  { code, offset, pid }
}

///|
/// Parse one complete packet, without guessing alignment or discarding trailing data.
pub fn parse_packet(
  input : Bytes,
  offset? : Int64 = 0L,
) -> Result[Packet, Diagnostic] {
  if offset < 0L || offset > 9223372036854775619L {
    return Err(fault("offset_range", offset, None))
  }
  if input.length() != 188 {
    return Err(fault("packet_size", offset, None))
  }
  if input[0] != 0x47 {
    return Err(fault("sync_byte", offset, None))
  }
  let b1 = input[1].to_int()
  let b3 = input[3].to_int()
  let pid = ((b1 & 0x1f) << 8) | input[2].to_int()
  let control = (b3 >> 4) & 3
  if control == 0 {
    return Err(fault("adaptation_control", offset + 3L, Some(pid)))
  }
  let mut start = 4
  if (control & 2) != 0 {
    let len = input[4].to_int()
    if (control == 2 && len != 183) || (control == 3 && len > 182) {
      return Err(fault("adaptation_length", offset + 4L, Some(pid)))
    }
    start = 5 + len
  }
  Ok({
    offset,
    pid,
    continuity: b3 & 15,
    payload_start: (b1 & 0x40) != 0,
    transport_error: (b1 & 0x80) != 0,
    scrambling: b3 >> 6,
    adaptation_control: control,
    raw: input,
    payload: if (control & 1) != 0 {
      input.view(start~).to_owned()
    } else {
      b""
    },
  })
}
