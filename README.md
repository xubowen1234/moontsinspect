# MoonTSInspect

原创 MoonBit 离线 MPEG-2 Transport Stream 检查库（开发中）。
核心对象是 TS packet、节目表、PID 连续性和媒体时钟，不是播放器、M3U8 解析器或通用分帧库。

## 本地运行

使用 MoonBit 工具链，运行 执行：

```
moon check --target wasm-gc --deny-warn
moon test --target wasm-gc
```

当前实现边界随功能提交更新。仅支持 188 字节 packet；不承诺广播合规认证。
新包尚未发布，不能把本地构建等同于 MoonCakes 可安装。
查重依据见 [查重记录](docs/competition/duplicate-check.md)，不是赛事通过保证。
