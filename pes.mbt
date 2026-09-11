///|
pub struct PesHeader {
  stream_id : Int
  packet_length : Int
  pts : Int64?
  dts : Int64?
  header_bytes : Int
  opaque_optional : Bytes
  offset : Int64
} derive(Eq, Debug)

///|
fn has_optional_header(stream_id : Int) -> Bool {
  !(stream_id == 0xbc ||
  stream_id == 0xbe ||
  stream_id == 0xbf ||
  stream_id == 0xf0 ||
  stream_id == 0xf1 ||
  stream_id == 0xff ||
  stream_id == 0xf2 ||
  stream_id == 0xf8)
}

///|
fn timestamp33(
  b : Bytes,
  pos : Int,
  prefix : Int,
  offset : Int64,
) -> Result[Int64, Diagnostic] {
  if b[pos].to_int() >> 4 != prefix ||
    (b[pos].to_int() & 1) != 1 ||
    (b[pos + 2].to_int() & 1) != 1 ||
    (b[pos + 4].to_int() & 1) != 1 {
    return Err(fault("pes_timestamp_marker", offset + pos.to_int64(), None))
  }
  Ok(
    ((b[pos].to_int64() & 14L) << 29) |
    (b[pos + 1].to_int64() << 22) |
    ((b[pos + 2].to_int64() & 254L) << 14) |
    (b[pos + 3].to_int64() << 7) |
    (b[pos + 4].to_int64() >> 1),
  )
}

///|
/// Parse the bounded PES header prefix; elementary payload is neither consumed nor decoded.
/// Non-timestamp optional fields are retained as opaque bytes, not semantically validated.
pub fn parse_pes_header(
  bytes : Bytes,
  offset? : Int64 = 0L,
) -> Result[PesHeader, Diagnostic] {
  if offset < 0L || offset > 9223372036854775543L {
    return Err(fault("offset_range", offset, None))
  }
  if bytes.length() < 6 {
    return Err(fault("pes_header_incomplete", offset, None))
  }
  if bytes[0] != 0 || bytes[1] != 0 || bytes[2] != 1 {
    return Err(fault("pes_prefix", offset, None))
  }
  let stream_id = bytes[3].to_int()
  let packet_length = (bytes[4].to_int() << 8) | bytes[5].to_int()
  if !has_optional_header(stream_id) {
    return Ok({
      stream_id,
      packet_length,
      pts: None,
      dts: None,
      header_bytes: 6,
      opaque_optional: b"",
      offset,
    })
  }
  if bytes.length() < 9 {
    return Err(fault("pes_header_incomplete", offset, None))
  }
  if (bytes[6].to_int() & 0xc0) != 0x80 {
    return Err(fault("pes_marker", offset + 6L, None))
  }
  let length = bytes[8].to_int()
  if packet_length != 0 && packet_length < 3 + length {
    return Err(fault("pes_packet_length", offset + 4L, None))
  }
  let flags = bytes[7].to_int() >> 6
  if flags == 1 || (flags == 2 && length < 5) || (flags == 3 && length < 10) {
    return Err(fault("pes_timestamp_length", offset + 7L, None))
  }
  if bytes.length() < 9 + length {
    return Err(fault("pes_header_incomplete", offset, None))
  }
  let mut pts = None
  let mut dts = None
  let mut pos = 9
  if flags >= 2 {
    match timestamp33(bytes, pos, flags, offset) {
      Ok(t) => pts = Some(t)
      Err(e) => return Err(e)
    }
    pos = pos + 5
  }
  if flags == 3 {
    match timestamp33(bytes, pos, 1, offset) {
      Ok(t) => dts = Some(t)
      Err(e) => return Err(e)
    }
    pos = pos + 5
  }
  Ok({
    stream_id,
    packet_length,
    pts,
    dts,
    header_bytes: 9 + length,
    opaque_optional: bytes.view(start=pos, end=9 + length).to_owned(),
    offset,
  })
}
