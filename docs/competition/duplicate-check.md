# MoonURI 驳回复盘与换题查重证据

检查日期：2026-09-11（Asia/Shanghai）。状态：**新候选建议，等待参赛者明确确认；没有开始新项目实现，没有获得主办方预审通过。**

## 1. 纠正此前结论

用户提供的邮件截图明确否决了 MoonURI 的创新性/必要性，指出解析、组件拆分、百分号编码、相对引用与现有生态高度重合。本次撤回“重合风险低到中”的旧结论，不通过改名、增加边界测试或堆提交重新包装 URI 项目。

旧审查的问题是没有充分检查独立 URI 库及框架内可复用能力，将缺少 moon search 命令、未找到完全同定位项目当作低重合证据。此次已在永久登记册增加 MoonURI 驳回指纹，原仓库/历史均保留。本轮检索的是 2026-09-11 状态；不能用今天的最新版本反推旧检查当天的版本或断言主办方具体参照了哪一个仓库。

## 2. 方法和可重放证据

- 按 moonbit-hackathon-builder 读取固定九月要求、环境预检、永久登记册，并使用已安装 osc2026-guide 的 Project Research Guide。后者覆盖 OSC/八月，九月日期和门槛仍以 builder 固定规则为准；使用 skill 不代表组委会人工审查。
- 实际运行 moon version --all 和 moon search --help。本机 moon 0.1.20260713 / moonc v0.10.4；moon search 不存在，错误已确认。
- 替代方式：直接请求 MoonCakes 搜索 API，GET https://mooncakes.io/api/v0/search?kw=KEYWORD&limit=N；47 次查询均返回 HTTP 200，去重得到 430 个包的元数据。并不等于 430 个包都经过源码审查。
- 完整查询/原始 JSON：candidate-search.json。检索词：`vcd`、`waveform`、`value change dump`、`verilog`、`simulation trace`、`datalog`、`logic programming`、`pubgrub`、`dependency solver`、`mpeg`、`transport stream`、`gerber`、`pcb`、`bidi`、`bidirectional text`、`timecode`、`edl`、`ucum`、`dimensional analysis`、`unification`、`term rewriting`、`Petri`、`uri`、`url`、`percent encoding`、`MoonTSInspect`、`mpegts`、`mpeg-ts`、`MPEG-2`、`demux`、`demultiplexer`、`PAT PMT`、`program clock reference`、`continuity counter`、`hls`、`video`、`media`、`crc`、`moon_rodio`、`symphonia`、`pcap`、`ffmpeg`、`TSDuck`、`PES`、`MPEG transport`、`stream_type`、`parse_ts`。
- 检查实际 MoonCakes docs 页面、相关 GitHub 默认分支/维护状态、README、接口和部分实现。索引：inspections.json、source-index.json；源码树及取得的文档快照同目录保存，仅作本地证据，不作为新项目源码。
- GitHub 仓库搜索5组：MoonBit mpeg、MoonBit transport stream、MoonBit demux、mpegts language:MoonBit、mpeg language:MoonBit。均 HTTP 200，total_count=0，incomplete_results=false，见 github-search.json。仓库元数据搜索不是 GitHub 全量代码搜索。
- 正面需求来源：RFC 8216 §3.2 对 TS segment 的 PAT/PMT 和初始化关系有明确要求；已取得 https://www.rfc-editor.org/rfc/rfc8216.txt ，本地 rfc8216.txt。只据此证明 segment 字节结构是不同于 M3U8 文本的工作对象，不据此宣称已经实现完整 MPEG-2 规范。

## 3. 当前直接重合与重点相邻项目

| 包及观察版本 | GitHub owner | 最后 push（UTC）/归档状态 | 具体功能与判定 | 来源 |
|---|---|---|---|---|
| bobzhang/uri@0.1.1 | moonbit-community | 2026-09-10T00:12:00Z / archived=false | 直接重合：公开 API 有 parse、resolve、Uri::normalize、encode/decode、parse_query、authority/host/port。 | [包页面](https://mooncakes.io/docs/bobzhang/uri) · [仓库](https://github.com/moonbit-community/uri) |
| kaashyapan/uri@0.1.5 | kaashyapan | 2026-09-09T10:00:36Z / archived=false | 直接重合：URI parse/build、编码解码、authority 和相对引用解析；不是仅名称相同。 | [包页面](https://mooncakes.io/docs/kaashyapan/uri) · [仓库](https://github.com/kaashyapan/uri) |
| marianoguerra/uri@0.1.2 | marianoguerra | 2026-09-08T22:18:59Z / archived=false | 直接重合：RFC3986/3987 URI/IRI、组件编码表、resolve；标明 fluent-uri 移植来源。 | [包页面](https://mooncakes.io/docs/marianoguerra/uri) · [仓库](https://github.com/marianoguerra/uri-mb) |
| tonyfettes/url@0.3.4 | moonbit-community | 2026-09-11T07:36:35Z / archived=false | 直接重合：WHATWG URL、base-relative parsing、IPv4/IPv6 Host、UrlSearchParams。 | [包页面](https://mooncakes.io/docs/tonyfettes/url) · [仓库](https://github.com/moonbit-community/tonyfettes-url) |
| lqhy1234567/moonbit-vcd@0.3.1 | lqhy1234567 | 2026-08-24T13:09:41Z / archived=false | 否决 VCD 候选：波形解析、索引、边沿/频率、协议解码、断言与比较已覆盖主要工作流。 | [包页面](https://mooncakes.io/docs/lqhy1234567/moonbit-vcd) · [仓库](https://github.com/lqhy1234567/moonbit-vcd) |
| haol-05/moondatalog@0.1.1 | haol-05 | 2026-08-17T14:12:46Z / archived=false | 否决 Datalog 候选：递归半朴素求值、分层否定、聚合、静态检查已有实现。 | [包页面](https://mooncakes.io/docs/haol-05/moondatalog) · [仓库](https://github.com/haol-05/moondatalog) |
| python123/moondepsolve@0.3.1 | python123-ops | 2026-07-10T03:12:47Z / archived=false | 否决依赖求解候选：SemVer、依赖解析、锁文件、冲突报告、升级计划已覆盖核心。 | [包页面](https://mooncakes.io/docs/python123/moondepsolve) · [仓库](https://github.com/python123-ops/moondepsolve) |
| chenqi-arch/moonhls@0.2.0 | chenqi-arch | 2026-08-18T03:23:18Z / archived=false | 重点相邻：输入为 M3U8 文本，操作 playlist/segment 元数据；已读取根公开 API 和12个非测试实现文件，未发现 TS 字节级 PAT/PMT/CC/PCR 引擎。不要重写其 M3U8 功能。 | [包页面](https://mooncakes.io/docs/chenqi-arch/moonhls) · [仓库](https://github.com/chenqi-arch/moonhls.git) |
| trkbt10/isobmff@0.1.0 | trkbt10 | 2026-03-26T03:38:51Z / archived=false | 相邻：ISO BMFF box/track/duration 元数据解析，不是 MPEG-2 TS 的 PID/PSI/连续计数状态机。README、全部公开接口和目录树级检查。 | [包页面](https://mooncakes.io/docs/trkbt10/isobmff) · [仓库](https://github.com/trkbt10/isobmff) |
| gaato/discord@0.1.0 | gaato | 2026-08-30T13:47:31Z / archived=false | 相邻：voice API 包含 RTP、Ogg/Opus 音频处理；检查 voice 公开接口、README、目录树，不宣称全仓源码审计。 | [包页面](https://mooncakes.io/docs/gaato/discord) · [仓库](https://github.com/gaato/discord.mbt) |
| gmlewis/crc32@0.8.18 | gmlewis | 2026-09-03T17:43:56Z / archived=false | 可复用算法候选，不是 TS 分析器。现有实现参数和源码许可证需另审，不能把任意 CRC32 当作 MPEG-2 PSI CRC；不复制其参考代码。 | [包页面](https://mooncakes.io/docs/gmlewis/crc32) · [仓库](https://github.com/gmlewis/moonbit-crc32) |
| moonbitlang/core@0.1.20260908+1634b282e | moonbitlang | 2026-09-11T08:46:53Z / archived=false | 基础设施：检查当前目录树、README、Bytes 接口；未定位 TS 专用包。不是全体标准库逐函数审计。 | [包页面](https://mooncakes.io/docs/moonbitlang/core) · [仓库](https://github.com/moonbitlang/core) |
| Milky2018/moon_rodio@0.3.5 | moonbit-community | 2026-09-07T08:27:51Z / archived=false | 相邻：native WAV/MP3/FLAC/Vorbis/MP4A 解码和播放；读取 decoder 公开接口、README、目录树，未定位 TS 节目结构分析 API。 | [包页面](https://mooncakes.io/docs/Milky2018/moon_rodio) · [仓库](https://github.com/moonbit-community/moon_rodio) |
| cghyyrrt/moonbit-pcap@0.1.2 | cghyyrrt | 2026-08-24T13:05:55Z / archived=false | 相邻且需保持边界：PCAP/PCAPNG、网络协议、重组和流量统计。README 和目录树检查，不做 PCAP/TCP 重组替代品。 | [包页面](https://mooncakes.io/docs/cghyyrrt/moonbit-pcap) · [仓库](https://github.com/cghyyrrt/moonbit-pcap) |
| usagi-star/mooncap@0.1.0 | usagi-star | 2026-08-01T06:13:31Z / archived=false | 相邻：离线 PCAP/PCAPNG、网络解码、TCP 范围累积。README 和目录树检查，输入/核心协议与 TS 节目表不同。 | [包页面](https://mooncakes.io/docs/usagi-star/mooncap) · [仓库](https://github.com/usagi-star/mooncap) |

版本/时间只作为维护信号，不等于质量认证。上表也不是主办方原邮件点名名单。

## 4. 四个不同领域候选的指纹对比

| 维度 | VCD 波形工具 | Datalog 引擎 | 依赖约束求解器 | MoonTSInspect（建议） |
|---|---|---|---|---|
| 领域 | 数字电路仿真 | 逻辑程序/关系查询 | 包管理 | 媒体传输流容器分析 |
| 用户 | FPGA/RTL 开发者 | 静态分析、图查询作者 | 包管理工具作者 | 媒体工具、转封装流水线、离线质检作者 |
| 工作流 | VCD→信号索引→波形查询 | facts/rules→求值→关系结果 | 版本/约束→解算→锁定或冲突 | 保存的 TS 字节→节目表重建→PID连续性/媒体时钟分析→可定位诊断 |
| 核心数据 | 信号、逻辑值、仿真时间 | 元组、谓词、规则 | 包版本、依赖、约束 | TS packet、PID、PAT/PMT section、CC、PCR、PTS/DTS |
| 中央算法 | 波形索引、边沿分析 | 半朴素递归、分层否定 | 版本约束传播/冲突回溯 | 有界 PSI 跨包组装、节目映射版本管理、每PID状态机、时间戳回绕处理 |
| 输出 | 波形事件/断言结果 | 关系/推导结果 | 锁文件/冲突解释 | 节目/轨道清单，packet offset/PID问题位置，媒体时钟区间 |
| 验收演示 | 找时钟异常 | 递归可达查询 | 依赖冲突解释 | 定位损坏节目表、丢包/重复包和时钟断点，不解码画面 |
| 非目标 | 媒体容器 | 包管理 | 图任务排程 | 播放器、编解码器、M3U8解析、通用网络框架、PCAP、直播传输 |
| 决定 | 拒绝：已有 moonbit-vcd | 拒绝：已有 moondatalog | 拒绝：已有 moondepsolve | 已查范围未识别直接实现，建议确认后进入设计实现 |

Gerber、Unicode bidi、timecode/EDL 也检出了对应能力，故不作为换名备选。UCUM 虽精确关键词无结果，但有计量/单位类相邻包，本轮未完成其语义查重，不推荐直接开工。

## 5. 为什么不只给相邻包加一个功能

MoonHLS 已解决 playlist 元数据；不应再建另一套 M3U8 parser。建议的新核心接受 Bytes，不接受 playlist 文本，以 TS 节目表、PID 与媒体时钟为模型，可服务独立录制文件和非 HLS 的多节目流。它可被 MoonHLS 用户调用，但不应把二进制 TS 引擎和所有节目分析强制并入 M3U8 数据模型。将来可做使用现有 MoonHLS 的示例适配，而不是复写它。

这仍是独立库必要性的工程论证，不代表上游已经同意合作。若后续发现已有 TS 库，或者主办方认为应该扩展既有项目，应停止独立选题并优先协作。没有联系或获得任何上游背书。

## 6. 永久登记册对照

基线：技能永久登记册（本地只读快照留存在研究目录）；逐条主项目边界表：registry-comparison.md。候选不以 URI/URL、OpenAPI、benchmark、任务DAG、许可证、账本、队列、日历、分块同步、文字补丁、Petri网、Sieve邮件规则、身份标识格式或日志为核心。

特别区分 MoonWire：后者是自定义固定头/长度/校验和帧编解码；新候选不能停留在188字节包拆解，必须完成跨包节目表和PID/媒体时钟语义才有新增价值。区分 MoonBench：PCR/PTS 是媒体流自带的时钟，不是代码运行性能样本；不得加入基准框架作为核心卖点。区分网络抓包工具：不读取PCAP、不重组TCP、不做流量安全评分。

本轮 122 个此前未登记的搜索命中已以 external-checked / metadata-only 追加登记；不能把模糊命中的说明自动等价为已深入验证的成熟功能。

## 7. 建议范围及三个真实验收场景（未实现）

1. **节目盘点**：录制工具作者输入本地多节目TS样本，得到PAT→PMT→音视频PID映射、未知stream_type保留和节目表版本更新轨迹；不能靠几个手工头部样例冒充完整结果。
2. **片段故障定位**：媒体流水线维护者输入故意删除、重复、截断packet的fixture，得到精确偏移/PID、CC异常和受影响section；合法adaptation-only、discontinuity与counter回绕不能误报。HLS初始化字节若由外部提供，必须显式输入，不武断要求每段都内置PAT/PMT。
3. **时间戳分析**：转封装工具作者输入含PCR/PTS回绕和显式时钟断点的样本，得到分段后的相对媒体时间；区分正常回绕与不合理倒退。不以PTS乱序直接判定错误（存在画面重排序），无到达时间测量时不声称测出广播PCR抖动。

v1建议：188字节TS、结构/长度上限、可分块输入、PSI组装/PAT/PMT、CRC校验、PID连续性、PCR和PES时间戳、CLI与库、稳定诊断。未知descriptor透传；192/204字节变体、加密解密、音视频解码、DVB SI完整解释、复用器、TR101290认证、联网下载/播放不承诺。具体协议细节须在编码前补齐可获取的H.222.0/ISO13818规范依据与标准支持表；RFC8216不能替代全套TS规范。

## 8. 限制、决策、复核

- MoonCakes搜索为模糊排序；simulation trace、url、stream_type触及返回上限。精确TS词为0不是不存在证明。无全站完整包索引或全GitHub代码证明，私有/未索引/新发布项目不可排除。
- GitHub raw来源读取曾断连，改用GitHub内容API取得关键文件；失败请求不算已检查。TSDuck/FFmpeg参考文件尚未完整取得，不列为已审查的实现来源。
- 已获取的15个重点仓库证据深度不同，上表逐项注明；不能宣称430个包源码全审、生态唯一或保证通过。
- 结论：本地查重支持**推荐 MoonTSInspect 作为待确认方向**；不是项目已选定、实现完成或赛事通过。落实独立必要性、规范细节与外部交叉测试后才具备提交说服力。
- skill要求参赛者确认具体方向后，才登记reserved并开始实现。本次尚未创建新项目Git仓库、commit、remote、push或MoonCakes发布。
- 确认后、正式申报前（最迟2026-09-24截止前）各复查一次同名词、核心API和相邻仓库；若发现核心工作流重合，重新裁决，不沿用本报告结论。

## 实施状态更新（2026-09-11）
参与者已确认 MoonTSInspect。已登记 reserved/in-progress 并建立独立本地仓库；上文“待确认”描述是研究完成时的历史状态。复查结果见 confirmation-recheck.json。本地开发不代表远程发布或赛事已通过。
