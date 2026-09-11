// Host boundary only: file IO and exit codes. All TS inspection lives in MoonBit.
///|
extern "js" fn open_file(path : String) -> Int =
  #| (path) => { try { return require('node:fs').openSync(path, 'r'); }
  #| catch (e) { console.error('moontsinspect: ' + e.code + ': ' + path); process.exitCode = 2; return -1; } }

///|
extern "js" fn read_chunk(fd : Int) -> Bytes =
  #| (fd) => { try { const b = Buffer.allocUnsafe(65536); const n = require('node:fs').readSync(fd, b, 0, b.length, null); return b.subarray(0, n); }
  #| catch (e) { console.error('moontsinspect: read: ' + e.code); process.exitCode = 2; return new Uint8Array(0); } }

///|
extern "js" fn close_file(fd : Int) -> Unit =
  #| (fd) => { try { require('node:fs').closeSync(fd); } catch(e) { console.error('moontsinspect: close: ' + e.code); process.exitCode = 2; } }

///|
extern "js" fn exit_code(code : Int) -> Unit =
  #| (code) => { if (process.exitCode !== 2) process.exitCode = code; }

///|
extern "js" fn io_failed() -> Bool =
  #| () => process.exitCode === 2

///|
extern "js" fn usage_error() -> Unit =
  #| () => console.error('Usage: moontsinspect [--summary] FILE.ts (NDJSON output; 188-byte TS only)')

///|
fn main {
  let args = @env.args()
  let mut summary_only = false
  let mut path = None
  for i = 2; i < args.length(); i = i + 1 {
    if args[i] == "--summary" && !summary_only {
      summary_only = true
    } else if args[i] == "--help" {
      usage_error()
      return
    } else if path is None && !args[i].has_prefix("--") {
      path = Some(args[i])
    } else {
      usage_error()
      exit_code(2)
      return
    }
  }
  let file = match path {
    Some(p) => p
    None => {
      usage_error()
      exit_code(2)
      return
    }
  }
  let fd = open_file(file)
  if fd < 0 {
    return
  }
  let inspector = @ts.Inspector::new().unwrap()
  let mut issues = 0L
  let emit = fn(event : @ts.InspectEvent) {
    let issue = event is @ts.Issue(_)
    if issue {
      issues = issues + 1L
    }
    if !summary_only || issue {
      println(@ts.event_json(event).stringify())
    }
  }
  while true {
    let chunk = read_chunk(fd)
    if chunk.is_empty() {
      break
    }
    inspector.feed(chunk, emit)
  }
  close_file(fd)
  if io_failed() {
    return
  }
  inspector.finish(emit)
  println(inspector.summary_json().stringify())
  exit_code(if issues > 0L { 1 } else { 0 })
}
