///|
pub struct ProgramRef {
  number : Int
  pmt_pid : Int
} derive(Eq, Debug)

///|
pub struct Pat {
  section : LongSection
  programs : Array[ProgramRef]
  network_pid : Int?
} derive(Eq, Debug)

///|
pub struct Descriptor {
  tag : Int
  data : Bytes
} derive(Eq, Debug)

///|
pub struct ElementaryStream {
  stream_type : Int
  pid : Int
  descriptors : Array[Descriptor]
} derive(Eq, Debug)

///|
pub struct Pmt {
  section : LongSection
  pcr_pid : Int
  descriptors : Array[Descriptor]
  streams : Array[ElementaryStream]
} derive(Eq, Debug)

///|
fn pid13(b : Bytes, i : Int) -> Int {
  ((b[i].to_int() & 31) << 8) | b[i + 1].to_int()
}

///|
pub fn parse_pat(section : LongSection) -> Result[Pat, Diagnostic] {
  let bad = fault("pat_syntax", section.offset, Some(0))
  if section.table_id != 0 ||
    (section.bytes[1].to_int() & 0x40) != 0 ||
    section.body.length() % 4 != 0 {
    return Err(bad)
  }
  let programs : Array[ProgramRef] = []
  let mut network_pid = None
  let b = section.body
  for i = 0; i < b.length(); i = i + 4 {
    let number = (b[i].to_int() << 8) | b[i + 1].to_int()
    let pid = pid13(b, i + 2)
    if (b[i + 2].to_int() & 0xe0) != 0xe0 || pid < 16 || pid == 8191 {
      return Err(bad)
    }
    if number == 0 {
      if network_pid is Some(_) {
        return Err(fault("pat_duplicate_program", section.offset, Some(0)))
      }
      network_pid = Some(pid)
    } else {
      for p in programs {
        if p.number == number {
          return Err(fault("pat_duplicate_program", section.offset, Some(0)))
        }
      }
      programs.push({ number, pmt_pid: pid })
    }
  }
  Ok({ section, programs, network_pid })
}

///|
fn descriptors(
  bytes : Bytes,
  offset : Int64,
) -> Result[Array[Descriptor], Diagnostic] {
  let result = []
  let mut pos = 0
  while pos < bytes.length() {
    if pos + 2 > bytes.length() {
      return Err(fault("descriptor_length", offset + pos.to_int64(), None))
    }
    let end = pos + 2 + bytes[pos + 1].to_int()
    if end > bytes.length() {
      return Err(fault("descriptor_length", offset + pos.to_int64(), None))
    }
    result.push({
      tag: bytes[pos].to_int(),
      data: bytes.view(start=pos + 2, end~).to_owned(),
    })
    pos = end
  }
  Ok(result)
}

///|
pub fn parse_pmt(section : LongSection) -> Result[Pmt, Diagnostic] {
  let bad = fault("pmt_syntax", section.offset, None)
  let b = section.body
  if section.table_id != 2 ||
    (section.bytes[1].to_int() & 0x40) != 0 ||
    section.extension == 0 ||
    section.number != 0 ||
    section.last_number != 0 ||
    b.length() < 4 {
    return Err(bad)
  }
  if (b[0].to_int() & 0xe0) != 0xe0 || (b[2].to_int() & 0xf0) != 0xf0 {
    return Err(bad)
  }
  let pcr_pid = pid13(b, 0)
  if pcr_pid < 16 {
    return Err(bad)
  }
  let info_end = 4 + (((b[2].to_int() & 15) << 8) | b[3].to_int())
  if info_end > b.length() {
    return Err(bad)
  }
  let program_descriptors = match
    descriptors(b.view(start=4, end=info_end).to_owned(), section.offset + 12L) {
    Ok(x) => x
    Err(e) => return Err(e)
  }
  let streams : Array[ElementaryStream] = []
  let mut pos = info_end
  while pos < b.length() {
    if pos + 5 > b.length() {
      return Err(bad)
    }
    let pid = pid13(b, pos + 1)
    if (b[pos + 1].to_int() & 0xe0) != 0xe0 ||
      (b[pos + 3].to_int() & 0xf0) != 0xf0 ||
      pid < 16 ||
      pid == 8191 {
      return Err(bad)
    }
    let end = pos +
      5 +
      (((b[pos + 3].to_int() & 15) << 8) | b[pos + 4].to_int())
    if end > b.length() {
      return Err(bad)
    }
    for s in streams {
      if s.pid == pid {
        return Err(fault("pmt_duplicate_pid", section.offset, Some(pid)))
      }
    }
    let desc = match
      descriptors(
        b.view(start=pos + 5, end~).to_owned(),
        section.offset + 13L + pos.to_int64(),
      ) {
      Ok(x) => x
      Err(e) => return Err(e)
    }
    streams.push({ stream_type: b[pos].to_int(), pid, descriptors: desc })
    pos = end
  }
  Ok({ section, pcr_pid, descriptors: program_descriptors, streams })
}
