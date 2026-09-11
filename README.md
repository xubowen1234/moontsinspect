# MoonTSInspect

原创 MoonBit **离线 MPEG-2 Transport Stream 结构与媒体时钟检查库**。面向录制/转封装流水线、媒体工具与 SDK 作者。输入保存的 TS 字节，输出节目清单、逐 PID 连续性问题、PCR 相对时钟与 PES 时间戳。

**开发状态：本地实现与测试，尚未创建新远程仓库、发布 Release 或上传 MoonCakes。** 本地检查不代表比赛审核通过。

## 三个真实用途

1. **盘点节目**：PAT → PMT → PCR/音视频 PID、stream_type、未知 descriptor。
2. **定位损坏**：删包/过量重复包、CRC 损坏、截断、TEI、加扰内容、同步丢失；给出偏移和 PID，不把合法计数器回绕或一次重复包误判为丢包。
3. **分析媒体时间**：PCR 27 MHz 相对分段与回绕；PES 33 位 PTS/DTS。正常 PTS 显示重排序不判为错误，无网络到达时间则不声称测量网络抖动。

## 本地运行

已测试工具链：Moon CLI 0.1.20260713 / moonc v0.10.4+2cc641edf；CLI 使用 Node.js，交叉测试额外需要 ffprobe。不要将下面的模块名误当成已经可从 MoonCakes 安装。

在本仓库根目录执行：

```sh
moon test --target wasm-gc
moon run examples/inventory --target wasm-gc
moon run cmd/inspect --target js -- --summary fixtures/synthetic.ts
node scripts/cli-smoke.cjs
node scripts/crosscheck.cjs
```

样本清单：节目 7；PMT PID 4096；PCR/视频 PID 256（MPEG-2 video）；音频 PID 257（MPEG audio）。真实 fixture 来自 FFmpeg 合成色块和正弦波，不是第三方录影。交叉脚本将清单与首个 PTS/DTS 和 ffprobe 比较，并实测故障注入。

### 库 API

```moonbit
let inspector = @ts.Inspector::new().unwrap()
inspector.feed(bytes, fn(event) { println(@ts.event_json(event).stringify()) })
inspector.finish(fn(event) { println(@ts.event_json(event).stringify()) })
let inventory = inspector.program_maps()
```

在调用方 moon.pkg 中 import `xubowen1234/moontsinspect` 并命名为 @ts；完整、可运行的调用方见 [examples/inventory](examples/inventory/main.mbt)。底层也开放 parse_packet、parse_section、parse_pat、parse_pmt、parse_pes_header 及独立状态机。生成的 [公共接口](pkg.generated.mbti) 列出实际导出，不用 README 描述代替 API。

## 验收

PowerShell 一键执行：`./scripts/verify-local.ps1`。48 个测试在 wasm-gc、wasm、JS 三后端各自通过；native 仅静态检查通过，运行验证留给 CI。实际执行状态及发布前缺口见 [验收说明](docs/validation.md)。

## CLI

```sh
moon run cmd/inspect --target js -- recording.ts
moon run cmd/inspect --target js -- --summary recording.ts
moon run cmd/inspect --target js -- --recover recording.ts
```

默认输出 NDJSON 事件；--summary 仅输出问题和最终清单。退出码：0=未发现已实现检查项的问题；1=诊断问题；2=参数/文件 IO 失败。0 **不等于所有标准合规**。大整数偏移/时钟输出为十进制字符串，见 [输出契约](docs/output-schema.md)。

默认严格对齐；--recover 每次最多跳过 65536 字节，连续验证三个完整 packet 后再对齐。失步会清除拼接基线并输出诊断；恢复后仍以退出码 1 提醒输入曾有损坏。末尾不足三包的未确认对齐不猜测接受。

## 范围与限制

- 仅 188 字节 TS；不是 192/204 字节变体、M3U8/HLS 下载器、PCAP 分析器、播放器或通用 framing 库。
- PAT 多节表原子激活；PMT 仅规范的单节。只对声明为已支持 PES 类型的流解析 PES，其他 stream_type 保留在清单中而不猜测。
- Adaptation extension、非时间戳 PES optional 字段、未知 descriptor **保留但不做完整语义验证**。
- 不解密、不解码音视频、不执行广播合规认证；不推断缺失的外部 HLS 初始化信息。
- PCR 使用最近模差，超过半个回绕周期的采样间隙无法确定实际时钟绕回次数。
- 对同步前/丢包后的字节不臆造节目表；EOF 的 missing 诊断是“此输入中未观察到”，不是对整个原始频道的断言。

[架构与预算](docs/architecture.md) · [规范依据](docs/protocol-baseline.md) · [查重记录](docs/competition/duplicate-check.md) · [来源与许可证](THIRD_PARTY.md) · [AI 使用说明](AI_USAGE.md) · [安全边界](SECURITY.md)

License: MIT。
