# 永久登记册指纹比较（2026-09-11）

此表保留主项目的核心边界；metadata目录仍见registry-snapshot.md全部原文。共同使用CLI、报告、状态机、Bytes或JSON不构成项目身份相同。VCD、Datalog、依赖求解三个方向均已被外部直接重合否决，不因下表低重合而恢复候选资格。

| 登记项目 | 已保留核心边界 | VCD | Datalog | 依赖求解 | MoonTSInspect |
|---|---|---|---|---|---|
| MoonBench | benchmark frameworks, stopwatches, performance sampling, percentile statistics, historical performance baselines, benchmark snapshot comparison, performance regression detection, CI performance gates, performance-report infrastructure | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 媒体时钟不是代码运行基准；不做性能回归 |
| MoonContract | OpenAPI contract validation, schema-backed deterministic API mocks, OpenAPI case replay, contract-aware local mock server, runtime request/response enforcement | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonRecur | RFC 5545-style civil-calendar recurrence parsing and bounded expansion, Gregorian recurrence selectors, and recurrence exception sets | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonPatch | deterministic unified-diff parsing, validation, contextual application/reversal, and transactional multi-file patch planning | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonChange | deterministic repository change-policy evaluation, code-owner routing, approval/check reconciliation, and change-governance gate reporting over explicit change metadata | 领域和核心数据不同 | 领域和核心数据不同 | 相邻：依赖/软件清单；不能重做已有排程/审计 | 不以该登记项目的工作流或数据为核心 |
| MoonShard | content-defined byte chunking, rolling-fingerprint chunk boundaries, content-addressed chunk manifests, duplicate-aware chunk reuse/transfer planning, and verified reconstruction from chunk inventories | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonDag | MoonFlowGraph-specific duration attachment, CPM earliest/latest/slack analysis, duration-weighted critical paths, and transitive change-impact/rerun planning over an upstream `ExecutionPlan` | 领域和核心数据不同 | 相邻：图/可达性或推理；须排除其特定问题 | 相邻：依赖/软件清单；不能重做已有排程/审计 | 不以该登记项目的工作流或数据为核心 |
| MoonSPDX | SPDX license expression parsing, normalization, policy evaluation, compliant alternative selection, and dependency-inventory license auditing with obligation aggregation | 领域和核心数据不同 | 领域和核心数据不同 | 相邻：依赖/软件清单；不能重做已有排程/审计 | 不以该登记项目的工作流或数据为核心 |
| clbbbb/moonbit-license-audit | general SPDX parsing and normalization, MoonBit project/workspace license auditing, license inventory and obligation reporting, compatibility matrices, finding baselines, and license-remediation/release checklists | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| liyun/moonseal | MoonBit manifest-aware release readiness, license declaration/text checks, dependency health, CycloneDX SBOM generation, SARIF audit output, baseline regression, and in-toto/SLSA provenance generation | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonSPDX Semantic Proof Engine | symbolic Boolean decision diagrams for SPDX expression equivalence/implication proofs and deterministic semantic counterexample generation | 领域和核心数据不同 | 相邻：图/可达性或推理；须排除其特定问题 | 相邻：依赖/软件清单；不能重做已有排程/审计 | 不以该登记项目的工作流或数据为核心 |
| MoonRedact | deterministic sensitive-text span discovery, overlap-aware privacy classification, policy-driven irreversible redaction, and disclosure audit reporting | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonLogfmt Lens | MoonBit-native governance of logfmt records through contracts, semantic classification, sensitive-data redaction, value-free batch profiling, and schema drift analysis | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonLedger | exact fixed-point double-entry journal parsing, posting validation, deterministic ledger application, balance assertions, and financial trial-balance/period reporting | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonQuotaKit | general-purpose quota and rate-limit enforcement, token-bucket/fixed-window/GCRA state machines, atomic multi-dimensional charging, hierarchy, and fair-share quota scheduling | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonLeaseKit | distributed lease lifecycle management, fencing-token safety, leader election, and deterministic lease simulation | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonDispatch | deterministic broker delivery state machines and trace auditing around visibility leases, receipt handles, ACK/NACK/redelivery, dead-letter transitions, queue deduplication, and message-delivery invariants | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不做消息投递/ACK/重试；PID状态不等于broker |
| MoonIndex | embedded positional full-text search with a compact boolean/phrase query language and deterministic ranked explanations | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| Lucius646/MoonSearch | full-text search, inverted indexes, document retrieval, search query parsing, phrase matching, and search ranking | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonPalette | deterministic color-space conversion, perceptual palette interpolation, WCAG contrast analysis, and accessibility-oriented color repair | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| bobzhang/colors | basic color models, RGB/linear-RGB/XYZ/LUV conversion, and general color blending | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonGCode | deterministic G-code modal-machine interpretation, toolpath replay, geometry analysis, and CNC machine-profile safety preflight | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonEDI | deterministic ANSI X12 envelope parsing, control/count validation, and 997 functional acknowledgement generation | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonWire | deterministic length-prefixed binary frame encoding/decoding with magic, metadata, checksum, and stable diagnostics | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 边界重点：不做通用帧库，核心必须是节目表/连续性/媒体时钟 |
| MoonBallot | bounded offline ranked-ballot method comparison with explicit ties/exhaustion and independently replayable IRV transcripts | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonMime (rejected draft) | general MIME type/parameter parser and formatter | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonCookie | Cookie request-header parsing, Set-Cookie attribute parsing, RFC-style domain/path/secure/samesite matching, expiry cleanup, and deterministic Cookie Jar header generation | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonCIDR candidate (duplication gate rejected, local only) | IP/CIDR parsing and pure subnet/range arithmetic as a standalone original competition project | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| xuange1016/ibi-mbt | INI parsing/query inspired by configparser; comments and blank lines skipped. | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonINI | INI-specific lossless concrete-syntax editing with exact untouched text preservation | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonGrapheme (original proposal rejected at duplication gate) | standalone reimplementation of grapheme segmentation plus terminal widths and safe truncation; adding convenience padding or changing Unicode version alone does not establish novelty. | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonPetri | Petri place/transition/token modeling and explicit marking reachability; not a generic BDD/FSM/workflow framework | 领域和核心数据不同 | 相邻：图/可达性或推理；须排除其特定问题 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonIBAN | ISO 13616 IBAN normalization, mod-97 checksum, country-length/BBAN-pattern validation, IBAN check-digit generation, and bank/branch/account field extraction from IBANs | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonCSP | CSP header parser and source-list violation checker in MoonBit | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonLangTag | RFC 5646 language-tag parse/canonicalize/build and RFC 4647 matching. This project does not implement IDNA, URI parsing, CLDR display names, or the full IANA language subtag registry. | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonMRZ | ICAO 9303 TD1/TD2/TD3 MRZ parse/verify/build in MoonBit. This project does not implement OCR, passport-chip BAC/PACE, face matching, barcode rendering, IBAN/mod-97, X12 EDI, or live identity-provider APIs. | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonSieve | Sieve script analysis and bounded offline rule execution; not MoonWire framing, MoonMime parsing or MoonDispatch broker delivery. | 领域和核心数据不同 | 领域和核心数据不同 | 领域和核心数据不同 | 不以该登记项目的工作流或数据为核心 |
| MoonURI（本次追加） | URI/URL组件、编码、相对引用、query | 不同 | 不同 | 不同 | 不解析URL或M3U8；节目数据是TS二进制，不是URI |
