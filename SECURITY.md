# Security scope

This library parses potentially damaged offline media bytes, not trusted instructions. It never executes byte content, follows URLs, downloads media, or decrypts packets. The CLI opens only the explicit input file in read mode and writes diagnostics to stdout/stderr.

Input lengths, PID allocation, section sizes, headers, scan counts and media state are bounded. The process owner should still apply filesystem permissions, CPU/time limits and output quotas for hostile or very large files. No guarantee is made against all denial-of-service cases, runtime bugs or resource exhaustion in user callbacks.

Do not use absence of issues as authorization, authenticity, encryption-integrity, playback-safety or broadcast-compliance evidence. Integer offsets and time values should remain exact integers in consumers.

For a suspected issue, provide a minimal legally redistributable synthetic sample, toolchain version, target, expected/actual output and reproduction command. Do not publish private recordings or secrets. A private reporting channel will be designated only after the public project is created; none is invented here.
