# Real-time-translation-typing

# 实时翻译、查询单词软件

##### [基于原项目](https://github.com/sxzxs/Real-time-translation-typing)
##### 新增 Auto copy插件（神来之笔）更好用
  -  双击鼠标右键：复制

  -  单击鼠标中键：粘贴（小于0.3秒）

  -  长按鼠标中键：剪切（大于0.3秒）

  -  长按鼠标右键：删除（大于0.2秒）

  -  ctrl+鼠标右键：全选

  -  ctrl+1：暂停脚本

  -  ctrl+2：退出脚本 
##### 更改
  - 在我的版本里删除了sougou翻译的支持，加载太慢 而且查询有时候出问题
  - 优化了在4k/2k屏幕下打字框偏小的问题、增加了快捷键指南
  - 增加了CTRL F7 网页查询的宽度（无需再展开查看）


![图 1](images/cd51c69e870ecaf0daa9a115145ac94fc979770772a913fe31d85c015000d6ed.gif)  

![图 0](images/16771b28ffa808f0c407a1248a0c8a1775923cd97135443f8899d0adb9a668bc.png)  
## 快捷键
* ALT Y: 打开
* ALT ENTER:发音
* ENTER: 输出翻译文本
* CTRL ENTER: 输出原始文本
* ESC: 退出
* TAB: 切换另一个翻译API
* CTRL F7: 网页版调试
#### 网页版额外快捷键
* CTRL + C :复制结果
* CTRL + ALT + T :翻译当前粘贴板
* CTRL + V:打开状态下，输入粘贴板内容

## 网页调用版本(推荐)
目前支持 搜狗、百度、有道
|环境|版本|
|-|-|
|系统|需要**win10**或者安装 **[webview2 runtime](https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/3c9f7ac6-fb0a-4eb7-b1fd-44c57613a3f5/MicrosoftEdgeWebView2RuntimeInstallerX64.exe)**|
|源码运行需要 ahk 版本| [autohotkey v2H](https://github.com/thqby/AutoHotkey_H/releases)|

## API版本(不推荐)
通过配置文件来配置 `/config/setting.json`

* 选择主翻译API
```
    "cd" : "youdao"   ## 目前支持 "baidu", "google"(需要科学上网，且美国节点), "youdao", "sougou"
```
备选API需配置 `is_open` 为 1
如果没反应，可能api在维护，可以切换另一个使用
目前免费的是有道和搜狗和谷歌， 有道是直接调用的api速度比较快，搜狗是爬虫(速度较慢),谷歌需要翻墙
百度结果很不错，但是需要注册(免费100w字符/月)


* 有道词典
```
http://fanyi.youdao.com/translate?smartresult=dict&smartresult=rule&smartresult=ugc&sessionFrom=null
{
    "is_open" : 1
}
```

```
https://fanyi.sogou.com/text?keyword=%E4%BD%A0%E5%A5%BD&transfrom=auto&transto=en&model=general
    "sougou" :
    {
        "is_open" : 1,
        "is_real_time_translate" : 1
    },
```

* 谷歌
```
{
    "is_open" : 0,
    "is_real_time_translate" : 0
}
```

* 百度翻译
需要自己注册后，把key填到配置文件
http://api.fanyi.baidu.com/api/trans/product/index

```
{
    "is_open" : 0,
    "BaiduFanyiAPPID" : "xxxxx",
    "BaiduFanyiAPPSEC": "xxxxx",
    "is_real_time_translate" : 0
}
```
因为百度使用次数有限额，因此通过  `is_baidu_real_time_translate` 来配置是否实时触发翻译
当配置 `0` 时，需要输入 `空格` 键 主动翻译, 建议输入最后键入`空格`

* 切换

按 `tab`键，从配置和打开的API切换

---

# 本分支修改记录（适配 4K + 修复百度 API + 修复网页版实时翻译）

## 一、修复百度翻译 id/key 不生效

**原因**：仓库自带的示例密钥（`20221121001462516` / `f6tS_...`）已失效，百度返回 `52003 UNAUTHORIZED USER`；且原 `baiducd()` 用 `catch { result := '' }` 把错误信息吞掉，界面只看到空白，误以为配置没生效。

**改动 `thread.ah2` 的 `baiducd()`**：
- 未填 APPID/密钥时直接返回提示“未配置百度 APPID / 密钥(settings.json)”；
- 请求 URL 里的 `q` 用 `EncodeDecodeURI()` 做 URL 编码（签名仍用原文 UTF-8，符合百度要求）；
- 接口改为 HTTPS：`https://fanyi-api.baidu.com/api/trans/vip/translate`，并加 User-Agent；
- 出错时把百度的 `error_code: error_msg` 显示到 ToolTip（如 `52003`、`54001` 等）；
- 多行 `trans_result` 全部拼接返回。

**`config/setting.json`**：百度 `is_open` 设为 `1`，填入自己注册的 APPID / 密钥，`is_real_time_translate` 设为 `1`（打字即翻译；设 `0` 则需按 `空格` 触发，省额度）。

> 注册地址：https://fanyi-api.baidu.com/ （免费 100 万字符/月）

## 二、4K / 高 DPI 字号适配（API 版 + 网页版通用）

原来所有尺寸都是写死的物理像素（窗口 1000×100、字号 20、圆角 5、输入法偏移 10/20、ToolTip 偏移 -28），D2D 渲染目标固定 96 DPI、GUI 用 `-DPIScale`，所以在 4K 上显得很小。

- 新增 `GetScale(hwnd)`：`显示器DPI/96 × ui_scale`，按窗口所在显示器自动计算，支持多屏不同缩放；`GetDpiForWindow` 不可用时退回 `A_ScreenDPI`。
- `Edit_box.draw()`：字号 `20×scale`、内边距 `14×scale`、圆角 `8×scale`、边框 `Max(1,scale)`，窗口大小 = 文字宽高 + 2×内边距（现在有真正的内边距）。
- `Edit_box.set_imm()`：中文输入法组字窗/候选框位置按比例缩放。
- `fanyi()`、`tab_send()`、`on_change`：ToolTip 偏移按比例缩放。

### 新增配置项 `ui_scale`

```json
{
    "cd" : "baidu",
    "ui_scale" : 1,
    ...
}
```

最终字号 = `20 × (显示器DPI/96) × ui_scale`。

| 屏幕情况 | 建议 ui_scale | 最终字号 |
|-|-|-|
| 4K + Windows 150% | 1.0 | 30px |
| 4K + Windows 175% | 1.0 | 35px |
| 4K + Windows 175%（想更大） | 1.15 | 40px |
| 4K + Windows 100% | 1.5 ~ 2.0 | 30~40px |

## 三、修复网页版（现名 `点我点我.ah2`）实时翻译

**原因**：网页版原来用 DOM 抓取百度/有道页面（`#baidu_translate_input`、`.output-wrap`、`#js_fanyi_input` 等），页面改版后选择器全部失效；上游后来也把网页版默认 API 缩到只剩 `sougou`/`deepl`。此外原代码测量字号用 40、绘制却用 30，大小不一致。

**改动（混合方案）**：
- `点我点我.ah2` 的 Tab 只在 `baidu` 和 `deepl` 之间切换；
- `baidu` 改用与 API 版相同的 zmq + `thread.ah2` 后台线程（用 `setting.json` 里的密钥），实时翻译稳定可靠；
- `deepl` 继续走 WebView2 网页；
- `Edit_box.draw()` 按当前 API 路由，并对 `is_real_time_translate` 做实时/空格触发判断；
- 新增 `cd()`（发消息给线程）与 `get_result()`（API 语言取剪贴板译文，deepl 取网页回调结果），`send_command / copy / sound_play / serpentine_naming` 统一使用；
- `点我点我.ah2` 也接入 `GetScale()`，字号/内边距/输入法/ToolTip 与 API 版完全一致（同一个 `ui_scale`）；
- 更新 Deepl 网页选择器为最新的 `d-textarea[name="source"]` / `d-textarea[name="target"]`（`utility/网页翻译集合.ah2`）。

## 四、F7 秒开百度网页

- `Edit_box.__New`：**启动时同时预加载百度和 deepl 两个网页实例**（启动会多等二十几秒），F7 秒开百度，切到 deepl 也秒用。
- `ensure_deepl()`：作为兜底，若 deepl 未创建则按需创建（正常启动已预加载）。
- `debug()`：**F7 固定只打开百度网页**，不看当前 API；若百度实例尚未创建则现场创建，失败时提示“打开网页失败: …”。
- 热键：`F7` 和 `Ctrl + F7` 均可。

## 五、修复 ALT+ENTER 发音（中文发音接口失效）

**现象**：按 `ALT + ENTER` 没声音。

**原因**：中文发音用的 `https://api.oick.cn/txt/apiz.php` 已失效（返回 404）；英文用的有道接口正常。英译中的结果多为中文，所以看起来“发音没反应”。

**改动**：中文发音改用有道接口 `https://dict.youdao.com/dictvoice?le=zh&audio=<文本>`（实测可用），英文继续用 `https://dict.youdao.com/dictvoice?audio=<文本>`。API 版和 `点我点我.ah2` 均已同步修改。

## 六、涉及文件清单

| 文件 | 改动 |
|-|-|
| `thread.ah2` | 修复并增强 `baiducd()`（URL 编码、HTTPS、报错可见、多行结果） |
| `实时打字翻译-API.ah2` | 新增 `GetScale()`，DPI/`ui_scale` 缩放（draw/set_imm/ToolTip）；修复 `ALT+ENTER` 中文发音接口 |
| `点我点我.ah2`（原 `用2的打开方式打开.ah2` / `web.ah2`） | Tab 只切 baidu/deepl；baidu 走 API + F7 固定开百度；baidu/deepl 网页启动预加载；DPI 缩放；修复 `ALT+ENTER` 中文发音接口 |
| `utility/网页翻译集合.ah2` | 更新 Deepl 选择器 |
| `config/setting.json` | 百度 `is_open:1`、`is_real_time_translate:1`、填入有效密钥；新增 `ui_scale` |

> 提示：修改 `setting.json` 后需**重启程序**才会生效（配置只在启动时读取一次）。