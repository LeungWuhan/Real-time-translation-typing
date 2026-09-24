# 实时打字翻译 / Real-time-translation-typing

基于 [sxzxs/Real-time-translation-typing](https://github.com/sxzxs/Real-time-translation-typing) 的个人增强版：**打字即翻译**，并针对 4K 屏、百度接口、网页版实时翻译、长句发音、鼠标取词等做了一系列修复与增强。

![图 1](images/cd51c69e870ecaf0daa9a115145ac94fc979770772a913fe31d85c015000d6ed.gif)

![图 0](images/16771b28ffa808f0c407a1248a0c8a1775923cd97135443f8899d0adb9a668bc.png)

---

## 目录

- [一、两个版本](#一两个版本)
- [二、运行环境](#二运行环境)
- [三、快捷键](#三快捷键)
- [四、配置文件 `config/setting.json`](#四配置文件-configsettingjson)
- [五、功能详解](#五功能详解)
- [六、auto copy 鼠标增强](#六auto-copy-鼠标增强)
- [七、本分支的改进记录](#七本分支的改进记录)
- [八、常见问题](#八常见问题)
- [九、文件说明](#九文件说明)

---

## 一、两个版本

| 版本 | 文件 | 翻译方式 | 依赖 | 说明 |
|-|-|-|-|-|
| **API 版** | `实时打字翻译-API.ah2` / `实时打字翻译-API.exe` | 直连翻译接口（百度 / 有道 / 谷歌 / 搜狗） | 需要对应 API key | 轻量、稳定，推荐日常使用 |
| **网页版** | `点我点我.ah2` | **百度走 API 线程**（用你的 key）＋ **deepl 走 WebView2 网页** | deepl 需要 WebView2 Runtime | 多一个 deepl，鼠标取词体验更好 |

> 两个版本可以同时运行，但注意它们的全局热键别冲突（见下方快捷键表）。

---

## 二、运行环境

| 项目 | 要求 |
|-|-|
| 系统 | Windows 10 及以上 |
| 源码运行 | [AutoHotkey v2H](https://github.com/thqby/AutoHotkey_H/releases)（本仓库自带 `AutoHotkey2.exe`） |
| 鼠标增强脚本 | AutoHotkey **v1**（本仓库自带 `AutoHotkey1.exe`） |
| 网页版 deepl | [WebView2 Runtime](https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/3c9f7ac6-fb0a-4eb7-b1fd-44c57613a3f5/MicrosoftEdgeWebView2RuntimeInstallerX64.exe) |

> **首次启动网页版会等二十几秒**：因为它要在后台预加载「百度」和「deepl」两个网页实例，加载完才会响应。你可以改成按需加载（见 [F7 说明](#5-f7--网页调试)）。

---

## 三、快捷键

### API 版（`实时打字翻译-API.ah2` / `.exe`）

| 快捷键 | 功能 |
|-|-|
| `Alt + Y` | 打开/关闭翻译框（在光标处弹出） |
| `空格` | 当 `is_real_time_translate = 0` 时，末尾按空格主动触发翻译 |
| `Tab` | 在 `all_api` 里已开启（`is_open:1`）的 API 间切换 |
| `Enter` | 把**译文**发送到目标窗口（用剪贴板模拟） |
| `Ctrl + Enter` | 把**原文**发送到目标窗口 |
| `Alt + Enter` | 发音（中英文都支持，长句也支持） |
| `Esc` | 关闭翻译框 |

### 网页版（`点我点我.ah2`）

| 快捷键 | 作用范围 | 功能 |
|-|-|-|
| `Alt + Y` | 全局 | 打开/关闭翻译框 |
| **`F9`** | 全局 | **用网页翻译鼠标选中的词语**（选中文字 → 按 F9） |
| `Ctrl + Alt + Q` | 全局 | **用网页翻译剪贴板文本** |
| `F7` / `Ctrl + F7` | 全局 | **固定打开百度网页窗口**（调试/看原网页） |
| `Tab` | 翻译框内 | 在 `baidu` / `deepl` 之间切换 |
| `Enter` | 翻译框内 | 输出译文 |
| `Ctrl + Enter` | 翻译框内 | 输出原文 |
| `Alt + Enter` | 翻译框内 | 发音 |
| `Ctrl + C` | 翻译框内 | 复制结果 |
| `Ctrl + V` | 翻译框内 | 把剪贴板内容输入翻译框 |
| `Ctrl + Alt + Enter` | 翻译框内 | 把译文转成 `snake_case`（小写下划线）并复制 |
| `Esc` | 全局 | 关闭翻译框 |

---

## 四、配置文件 `config/setting.json`

修改后**必须重启程序**才会生效（配置只在启动时读取一次）。

```jsonc
{
    "cd" : "baidu",              // 默认使用的翻译 API
    "ui_scale" : 1,              // 字号缩放倍数（见下）
    "all_api" : ["baidu", "youdao", "google"],  // API 版按 Tab 的切换顺序
    "youdao": { "is_open" : 1 },
    "baidu" : {
        "is_open" : 1,           // 1 = 参与 Tab 切换
        "BaiduFanyiAPPID" : "你的APPID",
        "BaiduFanyiAPPSEC": "你的密钥",
        "is_real_time_translate" : 1   // 1 = 打字即翻译；0 = 需按空格
    },
    "sougou" : { "is_open" : 1, "is_real_time_translate" : 0 },
    "google" : { "is_open" : 0, "is_real_time_translate" : 0 }
}
```

### 字段说明

| 字段 | 说明 |
|-|-|
| `cd` | 默认 API，可选 `baidu` / `youdao` / `sougou` / `google` |
| `ui_scale` | 手动字号倍数，最终字号 = `20 × (显示器DPI/96) × ui_scale` |
| `all_api` | **API 版**按 Tab 的切换列表 |
| `is_open` | 是否参与 Tab 切换 |
| `is_real_time_translate` | `1`=打字即翻译（费额度），`0`=末尾按空格才翻译 |
| `BaiduFanyiAPPID` / `BaiduFanyiAPPSEC` | 百度翻译开放平台的 APPID 和密钥 |

### 百度 API 申请

1. 打开 https://fanyi-api.baidu.com/ ，注册并申请「通用文本翻译」；
2. 免费额度约 100 万字符/月；
3. 把 APPID 和密钥填进 `setting.json` 的 `baidu` 节点；
4. 若报错，ToolTip 会直接显示百度错误码：
   - `52003` = APPID/密钥错误
   - `54001` = 签名错误
   - `54003` = 请求频率超限

### `ui_scale` 怎么调

`最终字号 = 20 × (显示器DPI/96) × ui_scale`，DPI 会自动读取，一般只需微调 `ui_scale`：

| 屏幕情况 | 建议 `ui_scale` | 最终字号 |
|-|-|-|
| 1080p / 2K | 1.0 | 20~27px |
| 4K + Windows 150% | 1.0 | 30px |
| 4K + Windows 175% | 1.0 ~ 1.15 | 35~40px |
| 4K + Windows 100% | 1.5 ~ 2.0 | 30~40px |

---

## 五、功能详解

### 1. 打字实时翻译

- 按 `Alt+Y` 在**当前光标位置**弹出翻译框；
- 打字时会根据当前 API 实时翻译，译文以提示气泡显示，并自动进入剪贴板；
- 按 `Enter` 把译文发送到原来的窗口，`Ctrl+Enter` 发送原文。

### 2. 百度 API（已修复）

- 旧的示例密钥已失效，现在会显示真实错误码，方便排查；
- 请求 URL 里的 `q` 会做 URL 编码，签名用原文 UTF-8，符合百度要求；
- 改用 HTTPS 接口并带 User-Agent；
- 多行结果会全部拼接返回。

### 3. 4K / 高 DPI 自适应

- 以前字号、边距、圆角、输入法候选框位置都是写死的物理像素，4K 上非常小；
- 现在统一按 `GetScale() = 显示器DPI/96 × ui_scale` 缩放：
  - 字号、内边距、圆角、边框；
  - 中文输入法组字窗 / 候选框位置；
  - 提示气泡的偏移。

### 4. 网页取词 / 剪贴板翻译（网页版）

- **选中任意窗口里的词语 → 按 `F9`**：
  1. 自动 `Ctrl+C` 复制选中内容；
  2. 打开百度 WebView2 窗口；
  3. 聚焦并全选网页里的「原文」输入框；
  4. 自动 `Ctrl+A` → `Ctrl+V` 粘贴并翻译，结果直接显示在网页里。
- **`Ctrl+Alt+Q`**：同样用**网页**翻译剪贴板里的文本。
- 网页窗口宽度按屏幕自适应（`Min(3000, 屏宽-60)`），比原来的 2000 更宽。

### 5. F7 / 网页调试

- `F7` 或 `Ctrl+F7` **固定打开百度网页窗口**，不看当前 API；
- 启动时已预加载，所以是**秒开**；
- 如果你不想要预加载、想改成首次按 F7 时才加载（启动更快），告诉我即可。

### 6. 发音（已修复长句）

- `Alt+Enter` 朗读译文；
- 英文用百度 `gettts` 的 `lan=en`，中文用 `lan=zh`，**长短句都支持**；
- 播放时间按文本长度自适应，长句不会被截断。

### 7. 翻译网页版 deepl

- 网页版按 `Tab` 可切到 `deepl`，走 WebView2 网页翻译；
- 已更新到 deepl 最新的页面选择器。

---

## 六、auto copy 鼠标增强

由 `auto copy（用1）.ahk` 提供（用 `AutoHotkey1.exe` 运行）：

| 操作 | 功能 |
|-|-|
| 双击鼠标右键 | 复制 |
| 单击鼠标中键（<0.3秒） | 粘贴 |
| 长按鼠标中键（>0.3秒） | 剪切 |
| 长按鼠标右键（>1秒） | 删除 |
| 单击鼠标右键 | 正常右键 |
| `Ctrl` + 鼠标右键 | 全选 |
| `Ctrl + 1` | 暂停脚本 |
| `Ctrl + 2` | 退出脚本 |

> 说明：早期版本还有「按住左键 2 秒翻译」功能，因左键不灵已删除。鼠标取词改由网页版的 **`F9`** 完成。

---

## 七、本分支的改进记录

### 1. 修复百度翻译 id/key 不生效

**原因**：仓库自带示例密钥已失效（百度返回 `52003 UNAUTHORIZED USER`），且原 `baiducd()` 用 `catch { result := '' }` 把错误吞掉，界面只看到空白。

**改动**（`thread.ah2` 的 `baiducd()`）：
- 未填密钥时返回「未配置百度 APPID / 密钥」；
- `q` 做 URL 编码，签名仍用原文 UTF-8；
- 接口改 HTTPS，加 User-Agent；
- 出错时把 `error_code: error_msg` 显示到提示里；
- 多行 `trans_result` 全部拼接。

### 2. 4K / 高 DPI 字号适配（两版通用）

- 新增 `GetScale(hwnd)`：`显示器DPI/96 × ui_scale`，多显示器各自生效；
- `Edit_box.draw()` 缩放字号/内边距/圆角/边框；
- `Edit_box.set_imm()` 缩放输入法候选框；
- 提示气泡偏移缩放；
- 新增配置项 `ui_scale`。

### 3. 修复网页版实时翻译（`点我点我.ah2`）

**原因**：网页版原来爬百度/有道网页，页面改版后选择器全部失效。

**改动（混合方案）**：
- `baidu` 改用与 API 版相同的 zmq + `thread.ah2` 后台线程，稳定实时翻译；
- `deepl` 继续走 WebView2；
- `Tab` 只在 `baidu` / `deepl` 间切换；
- 新增 `cd()` / `get_result()`，统一各功能的取词与取译文逻辑；
- 更新 deepl 选择器为 `d-textarea[name="source"]` / `[name="target"]`。

### 4. F7 秒开百度网页

- 启动时预加载百度 + deepl 两个网页实例（启动会多等二十几秒）；
- `F7` / `Ctrl+F7` 固定打开百度网页，秒开；
- `ensure_deepl()` 作为 deepl 的兜底按需加载。

### 5. 修复发音（含长句不能发音）

**原因**：中文接口 `api.oick.cn` 已 404；有道 `dictvoice` 超过约 17 字直接 `HTTP 500`；`PlayMedia()` 默认只等 5 秒。

**改动**：统一改用百度 `https://fanyi.baidu.com/gettts?...`，长短句都支持；播放时间按文本长度自适应。

### 6. 鼠标取词（`F9`）与百度网页输入修复

**原因**：百度首页改版，输入框变成 React + Ant Design 的 `textarea[placeholder="原文"]`，旧的 `#baidu_translate_input` 已不存在，直接赋 `.value` 也不生效。

**改动**：
- 热键 `F9` → `fanyi_selection()`：复制选中内容 → 打开百度网页 → **聚焦并全选**「原文」输入框 → 延迟 200ms → `Ctrl+V` 粘贴；
- 网页注入脚本带重试，页面没渲染完也能等到；
- `set_input_box()` 增加转义，避免文本里的引号/换行破坏注入的 JS。

### 7. 涉及文件

| 文件 | 改动 |
|-|-|
| `thread.ah2` | 增强 `baiducd()`（URL 编码、HTTPS、报错可见、多行结果） |
| `实时打字翻译-API.ah2` | 新增 `GetScale()` 与 DPI 缩放；发音改百度 `gettts` |
| `点我点我.ah2`（原 `用2的打开方式打开.ah2` / `web.ah2`） | Tab 只切 baidu/deepl；baidu 走 API；F7 固定开百度；网页预加载；DPI 缩放；发音修复；`F9` 鼠标取词 |
| `auto copy（用1）.ahk` | 删除左键长按翻译，保留鼠标增强 |
| `utility/网页翻译集合.ah2` | 更新 deepl 选择器、修复百度页面输入/输出 |
| `config/setting.json` | 百度 `is_open`/`is_real_time_translate` 置 1、填入密钥；新增 `ui_scale` |

---

## 八、常见问题

**Q：按 `Alt+Y` 没反应？**
A：确认脚本已运行；API 版的 `!y` 和网页版的 `!y` 是全局热键，若两个都在跑会互相抢，建议只留一个。

**Q：百度没翻译 / 显示错误码？**
A：按提示的 `error_code` 排查；`52003` 是密钥错，重新申请并填入 `setting.json` 后**重启**。

**Q：`F9` 没反应 / 粘贴不进去？**
A：
1. 确认先选中了文字；
2. 网页版需要 WebView2 Runtime；
3. 网页加载慢时，把 `点我点我.ah2` 里 `fanyi_selection()` 的 `Sleep(200)` 调大（如 `400`）。

**Q：网页版启动很慢？**
A：因为预加载了百度和 deepl 两个网页实例。想更快可以改成按需加载（去掉 `Edit_box.__New` 里 deepl 的预加载块即可）。

**Q：改完 `setting.json` 没生效？**
A：配置只在启动时读取，**必须重启程序**。

---

## 九、文件说明

| 文件 | 说明 |
|-|-|
| `实时打字翻译-API.ah2` | API 版源码（用 `AutoHotkey2.exe` 运行） |
| `实时打字翻译-API.exe` | API 版编译版 |
| `点我点我.ah2` | 网页版源码（百度 API + deepl 网页） |
| `thread.ah2` | API 版 / 网页版共用的后台翻译线程（zmq） |
| `auto copy（用1）.ahk` | 鼠标增强脚本（用 `AutoHotkey1.exe` 运行） |
| `utility/网页翻译集合.ah2` | WebView2 网页翻译类（百度 / deepl / 有道 / 搜狗） |
| `config/setting.json` | 配置文件 |
| `lib/` | 依赖库（D2D 渲染、zmq、WebView2、日志等） |

---

> 参考：原项目 <https://github.com/sxzxs/Real-time-translation-typing>
