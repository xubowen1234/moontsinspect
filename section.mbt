///|
/// MPEG-2 PSI CRC-32: poly 04C11DB7, init FFFFFFFF, non-reflected, xorout 0.
pub fn mpeg_crc32(bytes : Bytes) -> UInt {
  let mut crc = 0xffffffffU
  for b in bytes {
    crc = crc ^ (b.to_uint() << 24)
    for _i = 0; _i < 8; _i = _i + 1 {
      crc = if (crc & 0x80000000U) != 0U {
        (crc << 1) ^ 0x04c11db7U
      } else {
        crc << 1
      }
    }
  }
  crc
}

///|
pub struct LongSection {
  table_id : Int
  extension : Int
  version : Int
  current : Bool
  number : Int
  last_number : Int
  body : Bytes
  bytes : Bytes
  offset : Int64
} derive(Eq, Debug)

///|
/// Long PSI section limited to 1024 total bytes (PAT/PMT profile).
pub fn parse_section(
  bytes : Bytes,
  offset? : Int64 = 0L,
  pid? : Int = 0,
) -> Result[LongSection, Diagnostic] {
  if offset < 0L || offset > 9223372036854774783L {
    return Err(fault("offset_range", offset, Some(pid)))
  }
  if bytes.length() < 12 || bytes.length() > 1024 {
    return Err(fault("section_size", offset, Some(pid)))
  }
  let length = ((bytes[1].to_int() & 15) << 8) | bytes[2].to_int()
  if length + 3 != bytes.length() {
    return Err(fault("section_length", offset + 1L, Some(pid)))
  }
  if (bytes[1].to_int() & 0xb0) != 0xb0 || (bytes[5].to_int() & 0xc0) != 0xc0 {
    return Err(fault("section_reserved", offset, Some(pid)))
  }
  if bytes[6] > bytes[7] {
    return Err(fault("section_number", offset + 6L, Some(pid)))
  }
  if mpeg_crc32(bytes) != 0U {
    return Err(fault("section_crc", offset, Some(pid)))
  }
  Ok({
    table_id: bytes[0].to_int(),
    extension: (bytes[3].to_int() << 8) | bytes[4].to_int(),
    version: (bytes[5].to_int() >> 1) & 31,
    current: (bytes[5].to_int() & 1) != 0,
    number: bytes[6].to_int(),
    last_number: bytes[7].to_int(),
    body: bytes.view(start=8, end=bytes.length() - 4).to_owned(),
    bytes,
    offset,
  })
}
