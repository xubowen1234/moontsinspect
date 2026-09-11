///|
/// Atomic long-table version collector. One active and one candidate version, at most 512 sections.
/// Table-specific semantics must be checked with parse_pat/parse_pmt before accept.
pub struct TableCollector {
  priv table_id : Int
  priv mut active_sections : Array[LongSection]
  priv pending : FixedArray[LongSection?]
  priv mut key : (Int, Int, Int)?
  priv mut count : Int
}

///|
pub fn TableCollector::new(table_id : Int) -> TableCollector {
  {
    table_id,
    active_sections: [],
    pending: FixedArray::make(256, None),
    key: None,
    count: 0,
  }
}

///|
pub fn TableCollector::active(self : TableCollector) -> Array[LongSection] {
  self.active_sections.copy()
}

///|
pub fn TableCollector::discard_pending(self : TableCollector) -> Unit {
  for i = 0; i < 256; i = i + 1 {
    self.pending[i] = None
  }
  self.count = 0
  self.key = None
}

///|
/// A new version is activated only after all its numbered sections arrive; next tables are ignored.
pub fn TableCollector::accept(
  self : TableCollector,
  section : LongSection,
) -> Result[Array[LongSection]?, Diagnostic] {
  if section.table_id != self.table_id {
    return Err(fault("table_id", section.offset, None))
  }
  if !section.current {
    return Ok(None)
  }
  if !self.active_sections.is_empty() {
    let a = self.active_sections[0]
    if a.extension == section.extension && a.version == section.version {
      if a.last_number != section.last_number ||
        self.active_sections[section.number].bytes != section.bytes {
        return Err(fault("table_version_conflict", section.offset, None))
      }
      return Ok(None)
    }
  }
  let key = (section.extension, section.version, section.last_number)
  match self.key {
    Some((ext, ver, last)) => {
      if ext == section.extension &&
        ver == section.version &&
        last != section.last_number {
        return Err(fault("table_version_conflict", section.offset, None))
      }
      if self.key != Some(key) {
        self.discard_pending()
      }
    }
    None => ()
  }
  self.key = Some(key)
  match self.pending[section.number] {
    Some(old) => {
      if old.bytes != section.bytes {
        return Err(fault("table_version_conflict", section.offset, None))
      }
      return Ok(None)
    }
    None => {
      self.pending[section.number] = Some(section)
      self.count = self.count + 1
    }
  }
  if self.count != section.last_number + 1 {
    return Ok(None)
  }
  let result = []
  for i = 0; i <= section.last_number; i = i + 1 {
    match self.pending[i] {
      Some(s) => result.push(s)
      None => return Ok(None)
    }
  }
  self.active_sections = result.copy()
  self.discard_pending()
  Ok(Some(result))
}
