#Requires AutoHotkey v2+
#include <Direct2DRender>
#include <zmq>
#include <log>
#include <WebView2>
#include <ComVar>
#include <btt>
#include ./utility/网页翻译集合.ah2

logger.is_log_open := false
logger.is_use_editor := true

CoordMode('ToolTip', 'Screen')
CoordMode('Mouse', 'Screen')
OnMessage(WM_CHAR := 0x0102, ON_MESSAGE_WM_CHAR)
OnMessage(WM_IME_CHAR := 0x0286, ON_MESSAGE_WM_IME_CHAR)

main()
main()
{
    btt('加载中。。。',0, 0,,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
    ; 实时翻译 Tab 只在 baidu 和 deepl 之间切换
    global g_all_api := ['baidu', 'deepl']
    global g_is_ime_char := false
    global g_cursor_x := 0
    global g_cursor_y := 0
    global g_window_hwnd := 0

    ; ===== 配置 + zmq 后台翻译线程（与 API 版一致，复用 thread.ah2）=====
    global g_zmq_ctx := zmq_ctx_new()
    global g_sender2plug := Zmq_send2plug()
    global g_thread_plug_cd := Worker('#include ' A_scriptdir '/thread.ah2', string(g_sender2plug.ctx))
    global g_config := Map()
    loadconfig(&g_config, A_ScriptDir . "/config/setting.json")
    global g_current_api := g_all_api[1]
    global g_ui_scale := (g_config.Has('ui_scale') ? g_config['ui_scale'] : 1)

    global g_eb := Edit_box(0, 0, 1000, 100)
    g_eb.hide()
    loop
    {
    } until(g_thread_plug_cd.Ready)
    g_thread_plug_cd['g_config'] := g_config

    Hotkey('!y', (key) => fanyi()) ;打开翻译器
    Hotkey('^!q', (key) => fanyi_clipboard()) ;翻译粘贴板文本
    Hotkey('F9', (key) => fanyi_selection()) ;用网页翻译鼠标选中的词语（F9）
    Hotkey('~Esc', (key) => g_eb.hide()) ;退出
    Hotkey('^f7', (key)  =>g_eb.debug()) ;调试
    Hotkey('f7', (key)  =>g_eb.debug()) ;调试
	HotIfWinActive("ahk_id " g_eb.ui.hwnd)
        Hotkey("!enter", sound_play) ;发音
        Hotkey("enter", (key) => send_command('translate')) ;发送文本
        Hotkey("^enter", (key) => send_command('Primitive')) ;发送原始文本
        Hotkey("~tab", tab_send) ;切换API
        Hotkey("^v", paste) ;粘贴
        Hotkey("^c", copy) ;复制
        ; 这里留一个待实现Hotkey("LButton", copy)
        Hotkey("^!enter", serpentine_naming) ;驼峰命名
    HotIf()

    help_text := '
    (
        欢迎使用实时打字翻译工具
        ALT Y : 打开
        ENTER : 发送结果
        CTRL ENTER : 发送原始文本
        ALT ENTER : 发音
        CTRL F7 : 展示当前API网页原始内容
        ESC : 退出
        PLUS:
        F9 : 用网页翻译鼠标选中的词语
        CTRL + ALT + Q 翻译粘贴板文本
        CTRL + C :复制结果
        CTRL + V:打开状态下，输入粘贴板内容
    )'
    btt(help_text,0, 0,,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
}

fanyi_clipboard(*)
{
    fanyi()
    g_eb.text := A_Clipboard
    g_eb.draw()
}

;用 WebView2 打开并翻译鼠标当前选中的词语（快捷键 Ctrl+Alt+T）
fanyi_selection(*)
{
    global g_eb
    text := ''
    if(WinActive('ahk_id ' g_eb.ui.hwnd))
    {
        ;翻译框自身激活时用框内文本
        text := g_eb.text
    }
    else
    {
        A_Clipboard := ''
        SendInput('^c')
        ClipWait(0.6)
        text := A_Clipboard
    }
    if(text = '')
        return
    g_eb.show_baidu_web(text)
    ; 网页窗口就绪后模拟粘贴，把剪贴板里的选中文本粘进百度输入框
    Sleep(200)
    SendInput('^a')
    Sleep(200)
    SendInput('^v')
}


serpentine_naming(*)
{
    global g_window_hwnd
    old := A_Clipboard
    cd_str := get_result()
    g_eb.hide()
    cd_str := StrLower(cd_str)
    cd_str := RegExReplace(cd_str, 'i)\s+', '_')
    cd_str := RegExReplace(cd_str, "[^A-Za-z0-9_]", "")
    A_Clipboard := cd_str

    if(g_window_hwnd)
    {
        try
        {
            WinActivate(g_window_hwnd)
            WinWaitActive(g_window_hwnd,, 1)
        }
    }
    SendInput('{RShift Down}{Insert}{RShift Up}')
    Sleep(200)
    A_Clipboard := old
}

copy(*)
{
    A_Clipboard := get_result()
}

paste(*)
{
    g_eb.text := A_Clipboard
    g_eb.draw()
}

sound_play(*)
{
    data := get_result()
    if(data = '')
        return
    ;去掉换行，TTS 对换行不友好
    data := StrReplace(data, "`r", " ")
    data := StrReplace(data, "`n", " ")
    ;百度 fanyi 的 TTS：长短句都支持
    ;（原 api.oick.cn 已失效；有道 dictvoice 超过约 17 字会 HTTP 500，这就是长句不能发音的原因）
    lan := RegExMatch(data, "\p{Han}") ? 'zh' : 'en'
    url := 'https://fanyi.baidu.com/gettts?lan=' lan '&spd=5&source=web&text=' EncodeDecodeURI(data)
    logger.info(url)
    ;按文本长度给足播放时间，避免长句被默认 5 秒超时截断
    PlayMedia(url, Max(8000, StrLen(data) * 250))
}

send_command(p*)
{
    global g_window_hwnd
    try
    {
        data := g_eb.text
        old := A_Clipboard
        g_eb.hide()
        if(p[1] == 'Primitive')
            A_Clipboard := data
        else
            A_Clipboard := get_result()
        if(g_window_hwnd)
        {
            try
            {
                WinActivate(g_window_hwnd)
                WinWaitActive(g_window_hwnd,, 1)
            }
        }
        SendInput('{RShift Down}{Insert}{RShift Up}')
        sleep(200)
        A_Clipboard := old
    }
    catch as e
    {
        logger.err(e.Message)
    }
}

tab_send(*)
{
    global g_current_api
    global g_all_api
    ;找到当前index
    current_index := 1
    for k,v in g_all_api
    {
        if(v = g_current_api)
        {
            current_index := k
            break
        }
    }
    current_index++
    if(current_index > g_all_api.Length)
        current_index := 1
    g_current_api := g_all_api[current_index]
    logger.info('=========' g_current_api)
    btt('[' g_current_api ']',g_cursor_x, g_cursor_y - Round(45 * GetScale(WinExist('A'))),,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
    g_eb.draw('tab')
}

fanyi(*)
{
    global g_cursor_x
    global g_cursor_y
    global g_window_hwnd
    if(!(g_window_hwnd := GetCaretPosEx(&x, &y, &w, &h)))
    {
        g_window_hwnd := WinExist("A")
        MouseGetPos(&x, &y)
    }
    g_cursor_x := x
    g_cursor_y := y
    g_eb.show(x, y)
    btt('[' g_current_api ']',g_cursor_x, g_cursor_y - Round(45 * GetScale(WinExist('A'))),,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
    g_eb.draw()
}

;通过 zmq 把文本发给 thread.ah2 后台线程翻译
cd(text, x := 0, y := 0)
{
    try
    {
        send2cd_param := Map()
        send2cd_param['x'] := x
        send2cd_param['y'] := y
        send2cd_param['text'] := text
        send2cd_param['is_ime_char'] := g_is_ime_char
        send2cd_param['api'] := g_current_api
        str := JSON.stringify(send2cd_param)
        g_sender2plug.pub(str)
    }
    catch as e
    {
        logger.err(e.Message)
        return
    }
}

;取当前译文：API 语言由 thread.ah2 放进剪贴板，deepl 用网页回调结果
get_result()
{
    global g_current_api
    if(g_current_api = 'deepl')
        return g_eb.fanyi_result
    return A_Clipboard
}

ON_MESSAGE_WM_CHAR(a*)
{
    logger.info(a*)
    logger.info(num2utf16(a[1]))
    if(a[2] != 1)
        g_eb.set_imm(a[1])
}
ON_MESSAGE_WM_IME_CHAR(a*)
{
    global g_is_ime_char
    g_is_ime_char := true
    logger.info(a*)
    logger.info(num2utf16(a[1]))
    g_eb.set_imm(a[1])
}

class Edit_box
{
    __New(x, y, w, h) 
    {
        this.x := 0
        this.y := 0
        this.w := w
        this.h := h
        this.ui := Direct2DRender(x, y, w, h,,, false)
        this.text := ''
        this.fanyi_result := ''
        this.show_status := false
        ; 网页实例；baidu 和 deepl 启动预加载
        this.bd := ''
        this.yd := ''
        this.sg := ''
        this.dp := ''

        ; 预加载百度网页，保证 F7 秒开（启动会多等十几秒）
        if(this.has_key('baidu'))
        {
            this.bd := bd := Baidu_web_cd()
            bd.set_out_change_call_back(this.on_change.bind(this))
            bd.set_input_box('')
        }

        ; 预加载 deepl 网页（启动会再多等十几秒）
        if(this.has_key('deepl'))
        {
            this.dp := dp := Deepl_web_cd()
            dp.set_out_change_call_back(this.on_change.bind(this))
            dp.set_input_box('我来自Deepl')
        }
    }
    ; 兜底：若 deepl 未创建则按需创建（正常启动已预加载）
    ensure_deepl()
    {
        if(!this.dp)
        {
            btt('deepl 网页加载中。。。',0, 0,,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
            dp := Deepl_web_cd()
            dp.set_out_change_call_back(this.on_change.bind(this))
            dp.set_input_box(this.text)
            this.dp := dp
        }
    }
    ; 用百度网页(WebView2)打开并翻译指定文本
    show_baidu_web(text)
    {
        if(!this.bd)
        {
            btt('baidu 网页加载中。。。',0, 0,,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
            bd := Baidu_web_cd()
            bd.set_out_change_call_back(this.on_change.bind(this))
            this.bd := bd
        }
        this.bd.show(,, 2000, 550)
        try WinActivate('ahk_id ' this.bd.ui.Hwnd)
        ; 聚焦并全选网页里的输入框，内容稍后由 Ctrl+V 粘入
        this.bd.set_input_box(text)
    }
    has_key(key)
    {
        global g_all_api
        for k,v in g_all_api
        {
            if(v = key)
                return true
        }
        return false
    }
    debug()
    {
        ; F7 固定只打开百度网页，不看当前 API
        try
        {
            if(!this.bd)
            {
                btt('baidu 网页加载中。。。',0, 0,,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
                bd := Baidu_web_cd()
                bd.set_out_change_call_back(this.on_change.bind(this))
                bd.set_input_box(this.text)
                this.bd := bd
            }
            this.bd.show(,, 2000, 550)
        }
        catch as e
        {
            logger.err(e.Message)
            btt('打开网页失败: ' e.Message,0, 0,,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
        }
    }
    on_change(cd ,text)
    {
        logger.info(cd ,text)
        logger.info()
        if(this.show_status && cd = g_current_api)
        {
            this.fanyi_result := text
            this.ui.gui.GetPos(&x, &y, &w, &h)
            btt(cd ':' text,x, y - Round(45 * GetScale(this.ui.Hwnd)),,OwnzztooltipStyle1,{Transparent:180,DistanceBetweenMouseXAndToolTip:-100,DistanceBetweenMouseYAndToolTip:-20})
        }
    }
    show(x := 0, y := 0)
    {
        this.ui.gui.show('x' x ' y' y)
        this.show_status := true
    }
    hide()
    {
        global g_is_ime_char
        this.clear()
        this.ui.gui.hide()
        g_is_ime_char := false
        this.show_status := false
        OwnzztooltipEnd()
        cd('') ; 清掉后台线程的结果 ToolTip
    }
    move(x, y, w := 0, h := 0)
    {
        this.ui.SetPosition(x, y, w, h)
    }
    draw(flag := 0)
    {
        global g_current_api
        ui := this.ui
        ui.gui.GetPos(&x, &y, &w, &h)
        logger.info(x, y, w, h)
        ;按窗口所在显示器的 DPI 缩放，和 API 版保持一致
        scale := GetScale(ui.hwnd)
        font_size := Round(20 * scale)
        pad := Round(14 * scale)
        radius := Round(8 * scale)
        thickness := Max(1, Round(scale))
        ;计算文字的大小
        wh := this.ui.GetTextWidthHeight(this.text, font_size)
        logger.info(wh)
        box_w := wh.width + pad * 2
        box_h := wh.height + pad * 2
        this.move(x, y, box_w, box_h)
        if(ui.BeginDraw())
        {
            ui.FillRoundedRectangle(0, 0, box_w, box_h, radius, radius, 0xcc1E1E1E)
            ui.DrawRoundedRectangle(0, 0, box_w, box_h, radius, radius, 0xffff0000, thickness)
            ui.DrawText(this.text, pad, pad, font_size, 0xFFC9E47E)
            logger.info(this.text)
            ui.EndDraw()
        }
        ;切换 API：把当前文本发给新 API（与 API 版一致）
        if(flag = 'tab')
        {
            if(g_current_api = 'deepl')
            {
                this.ensure_deepl()
                this.dp.set_input_box(this.text)
            }
            else
                cd(this.text, x, y)
            return
        }
        ;末尾空格：立即触发一次
        if(SubStr(this.text, -1) == A_Space)
        {
            if(g_current_api = 'deepl')
            {
                this.ensure_deepl()
                this.dp.set_input_box(this.text)
            }
            else
                cd(this.text, x, y)
            return
        }
        switch(g_current_api)
        {
            case 'baidu':
            {
                if(g_config['baidu']['is_real_time_translate'] = 1)
                    cd(this.text, x, y)
            }
            case 'google':
            {
                if(g_config['google']['is_real_time_translate'] = 1)
                    cd(this.text, x, y)
            }
            case 'sougou':
            {
                if(g_config['sougou']['is_real_time_translate'] = 1)
                    cd(this.text, x, y)
            }
            case 'youdao':
            {
                cd(this.text, x, y)
            }
            case 'deepl':
            {
                this.ensure_deepl()
                this.dp.set_input_box(this.text)
            }
        }
    }
    clear()
    {
        this.text := ''
    }
    push(char)
    {
        if(char == '`b')
            this.text := SubStr(this.text, 1, -1)
        else
            this.text .= char
    }
    set_imm(char)
    {
        himc := ImmGetContext(this.ui.Hwnd)
        imm_scale := GetScale(this.ui.Hwnd)
        composition_form := COMPOSITIONFORM()
        composition_form.ptCurrentPos.x := Round(14 * imm_scale)
        composition_form.ptCurrentPos.y := Round(14 * imm_scale)
        composition_form.rcArea.left :=  0
        composition_form.rcArea.top :=  0
        composition_form.rcArea.right :=  Round(100 * imm_scale)
        composition_form.rcArea.bottom := Round(100 * imm_scale)
        composition_form.dwStyle := 0x0020 ;CFS_FORCE_POSITION
        rtn := ImmSetCompositionWindow(himc, composition_form)

        candidate_form := CANDIDATEFORM()
        candidate_form.dwStyle := 0x0040 ;CFS_CANDIDATEPOS 
        candidate_form.ptCurrentPos.x := Round(14 * imm_scale)
        candidate_form.ptCurrentPos.y := Round(30 * imm_scale)

        rtn := ImmSetCandidateWindow(himc, candidate_form)
        ImmReleaseContext(this.ui.Hwnd, himc)
        logger.info(num2utf16(char))
        this.push(num2utf16(char))
        this.draw()
    }
}

class RECT extends ctypes.struct
{
	static fields := [['int', 'left'], ['int', 'top'], ['int', 'right'], ['int', 'bottom']]
}

class POINT extends ctypes.struct
{
    static  fields := [['int', 'x'], ['int', 'y']]
}

class COMPOSITIONFORM extends ctypes.struct
{
    static  fields := [['uint', 'dwStyle'], ['POINT', 'ptCurrentPos'], ['RECT', 'rcArea']]
}

class CANDIDATEFORM extends ctypes.struct
{
    static  fields := [['uint', 'dwIndex'], ['uint', 'dwStyle'], ['POINT', 'ptCurrentPos'], ['RECT', 'rcArea']]
}

ImmGetContext(hwnd)
{
    return DllCall('imm32\ImmGetContext', 'int', hwnd, 'int')
}
ImmSetCompositionWindow(HIMC, lpCompForm) ;COMPOSITIONFORM
{
    return DllCall('imm32\ImmSetCompositionWindow', 'int', HIMC, 'ptr', lpCompForm, 'int')
}
ImmSetCandidateWindow(HIMC, lpCandidate) ;CANDIDATEFORM
{
    return DllCall('imm32\ImmSetCandidateWindow', 'int', HIMC, 'ptr', lpCandidate, 'int')
}
ImmReleaseContext(hwnd, HIMC)
{
    return DllCall('imm32\ImmReleaseContext', 'int', hwnd, 'int', HIMC, 'int')
}
ImmSetOpenStatus(HIMC, status) ; HIMC, bool 
{
    return DllCall('imm32\ImmSetOpenStatus', 'int', HIMC, 'int', status, 'int')
}
ImmGetOpenStatus(HIMC)
{
    return DllCall('imm32\ImmGetOpenStatus', 'int', HIMC, 'int')
}
ImmAssociateContext(hwnd, HIMC)
{
    return DllCall('imm32\ImmAssociateContext', 'int', hwnd, 'int', HIMC, "int")
}

num2utf16(code)
{
    bf := Buffer(2, 0)
    NumPut('short', code, bf)
    return StrGet(bf, 1, 'UTF-16')
}

;获取指定窗口所在显示器的缩放系数（96 DPI = 1.0），再乘以 setting.json 的 ui_scale
GetScale(hwnd := 0)
{
    global g_ui_scale
    dpi := 96
    try
    {
        if(hwnd)
            dpi := DllCall('user32\GetDpiForWindow', 'ptr', hwnd, 'uint')
        if(!dpi)
            dpi := A_ScreenDPI
    }
    catch
        dpi := A_ScreenDPI
    user_scale := (IsSet(g_ui_scale) ? g_ui_scale : 1)
    return Max(0.5, dpi / 96) * user_scale
}

GetCaretPosEx(&x?, &y?, &w?, &h?) 
{
    x := h := w := h := 0
    static iUIAutomation := 0, hOleacc := 0, IID_IAccessible, guiThreadInfo, _ := init()
    if !iUIAutomation || ComCall(8, iUIAutomation, "ptr*", eleFocus := ComValue(13, 0), "int") || !eleFocus.Ptr
        goto useAccLocation
    if !ComCall(16, eleFocus, "int", 10002, "ptr*", valuePattern := ComValue(13, 0), "int") && valuePattern.Ptr
        if !ComCall(5, valuePattern, "int*", &isReadOnly := 0) && isReadOnly
            return 0
    useAccLocation:
    ; use IAccessible::accLocation
    hwndFocus := DllCall("GetGUIThreadInfo", "uint", DllCall("GetWindowThreadProcessId", "ptr", WinExist("A"), "ptr", 0, "uint"), "ptr", guiThreadInfo) && NumGet(guiThreadInfo, A_PtrSize == 8 ? 16 : 12, "ptr") || WinExist()
    if hOleacc && !DllCall("Oleacc\AccessibleObjectFromWindow", "ptr", hwndFocus, "uint", 0xFFFFFFF8, "ptr", IID_IAccessible, "ptr*", accCaret := ComValue(13, 0), "int") && accCaret.Ptr {
        NumPut("ushort", 3, varChild := Buffer(24, 0))
        if !ComCall(22, accCaret, "int*", &x := 0, "int*", &y := 0, "int*", &w := 0, "int*", &h := 0, "ptr", varChild, "int")
            return hwndFocus
    }
    if iUIAutomation && eleFocus {
        ; use IUIAutomationTextPattern2::GetCaretRange
        if ComCall(16, eleFocus, "int", 10024, "ptr*", textPattern2 := ComValue(13, 0), "int") || !textPattern2.Ptr
            goto useGetSelection
        if ComCall(10, textPattern2, "int*", &isActive := 0, "ptr*", caretTextRange := ComValue(13, 0), "int") || !caretTextRange.Ptr || !isActive
            goto useGetSelection
        if !ComCall(10, caretTextRange, "ptr*", &rects := 0, "int") && rects && (rects := ComValue(0x2005, rects, 1)).MaxIndex() >= 3 {
            x := rects[0], y := rects[1], w := rects[2], h := rects[3]
            return hwndFocus
        }
        useGetSelection:
        ; use IUIAutomationTextPattern::GetSelection
        if textPattern2.Ptr
            textPattern := textPattern2
        else if ComCall(16, eleFocus, "int", 10014, "ptr*", textPattern := ComValue(13, 0), "int") || !textPattern.Ptr
            goto useGUITHREADINFO
        if ComCall(5, textPattern, "ptr*", selectionRangeArray := ComValue(13, 0), "int") || !selectionRangeArray.Ptr
            goto useGUITHREADINFO
        if ComCall(3, selectionRangeArray, "int*", &length := 0, "int") || length <= 0
            goto useGUITHREADINFO
        if ComCall(4, selectionRangeArray, "int", 0, "ptr*", selectionRange := ComValue(13, 0), "int") || !selectionRange.Ptr
            goto useGUITHREADINFO
        if ComCall(10, selectionRange, "ptr*", &rects := 0, "int") || !rects
            goto useGUITHREADINFO
        rects := ComValue(0x2005, rects, 1)
        if rects.MaxIndex() < 3 {
            if ComCall(6, selectionRange, "int", 0, "int") || ComCall(10, selectionRange, "ptr*", &rects := 0, "int") || !rects
                goto useGUITHREADINFO
            rects := ComValue(0x2005, rects, 1)
            if rects.MaxIndex() < 3
                goto useGUITHREADINFO
        }
        x := rects[0], y := rects[1], w := rects[2], h := rects[3]
        return hwndFocus
    }
    useGUITHREADINFO:
    if hwndCaret := NumGet(guiThreadInfo, A_PtrSize == 8 ? 48 : 28, "ptr") {
        if DllCall("GetWindowRect", "ptr", hwndCaret, "ptr", clientRect := Buffer(16)) {
            w := NumGet(guiThreadInfo, 64, "int") - NumGet(guiThreadInfo, 56, "int")
            h := NumGet(guiThreadInfo, 68, "int") - NumGet(guiThreadInfo, 60, "int")
            DllCall("ClientToScreen", "ptr", hwndCaret, "ptr", guiThreadInfo.Ptr + 56)
            x := NumGet(guiThreadInfo, 56, "int")
            y := NumGet(guiThreadInfo, 60, "int")
            return hwndCaret
        }
    }
    return 0
    static init() {
        try
            iUIAutomation := ComObject("{E22AD333-B25F-460C-83D0-0581107395C9}", "{30CBE57D-D9D0-452A-AB13-7AC5AC4825EE}")
        hOleacc := DllCall("LoadLibraryW", "str", "Oleacc.dll", "ptr")
        NumPut("int64", 0x11CF3C3D618736E0, "int64", 0x719B3800AA000C81, IID_IAccessible := Buffer(16))
        guiThreadInfo := Buffer(A_PtrSize == 8 ? 72 : 48), NumPut("uint", guiThreadInfo.Size, guiThreadInfo)
    }
}

;by tebayaki
;PlayMedia("https://dict.youdao.com/dictvoice?audio=apple")

PlayMedia(uri, time_out := 5000) 
{
    DllCall("Combase\RoActivateInstance", "ptr", CreateHString("Windows.Media.Playback.MediaPlayer"), "ptr*", iMediaPlayer := ComValue(13, 0), "HRESULT")
    iUri := CreateUri(uri)
    ComCall(47, iMediaPlayer, "ptr", iUri) ; SetUriSource
    ComCall(45, iMediaPlayer) ; Play
    index := 1
    loop {
        ComCall(12, iMediaPlayer, "uint*", &state := 0) ; CurrentState
        if(index != 1)
            Sleep(20)
        index++
    } until (state == 3 || index > (time_out / 20))

    index := 1
    loop {
        ComCall(12, iMediaPlayer, "uint*", &state := 0) ; CurrentState
        if(index != 1)
            Sleep(20)
        index++
        Sleep(20)
    } until (state == 4 || index > (time_out / 20))
}

CreateUri(str) 
{
    DllCall("ole32\IIDFromString", "str", "{44A9796F-723E-4FDF-A218-033E75B0C084}", "ptr", iid := Buffer(16), "HRESULT")
    DllCall("Combase\RoGetActivationFactory", "ptr", CreateHString("Windows.Foundation.Uri"), "ptr", iid, "ptr*", factory := ComValue(13, 0), "HRESULT")
    ComCall(6, factory, "ptr", CreateHString(str), "ptr*", uri := ComValue(13, 0))
    return uri
}

CreateHString(str) 
{
    DllCall("Combase\WindowsCreateString", "wstr", str, "uint", StrLen(str), "ptr*", &hString := 0, "HRESULT")
    return { Ptr: hString, __Delete: (_) => DllCall("Combase\WindowsDeleteString", "ptr", _, "HRESULT") }
}

class Zmq_send2plug
{
    __New()
    {
        zmq_version(&a := 0, &b := 0, &c := 0)
        logger.info("zmq版本: ", a, b, c)
        this.ctx := ctx := g_zmq_ctx
        this.socket := socket := zmq_socket(ctx, ZMQ_PUB)
        rtn := zmq_bind(socket, "inproc://main")
    }
    __Delete()
    {
        zmq_close(this.socket)
        zmq_ctx_shutdown(this.ctx)
    }
    pub(data := unset)
    {
        if(IsSet(data) == 1 || InStr(data, '@stop') || InStr(data, '@exit'))
        {
            zmq_send_string(this.socket, data,,ZMQ_DONTWAIT)
        }
    }
}

loadconfig(&config, json_path)
{
    outputvar := FileRead(json_path)
    config := JSON.parse(outputvar)
}
;保存配置函数
saveconfig(config, json_path)
{
    str := JSON.stringify(config, 4)
    FileDelete(json_path)
    FileAppend(str, json_path, 'UTF-8')
}

EncodeDecodeURI(str, encode := true, component := true) {
    ; Adapted from teadrinker: https://www.autohotkey.com/boards/viewtopic.php?p=372134#p372134
    static Doc, JS
    if !IsSet(Doc) {
        Doc := ComObject("htmlfile")
        Doc.write('<meta http-equiv="X-UA-Compatible" content="IE=9">')
        JS := Doc.parentWindow
        ( Doc.documentMode < 9 && JS.execScript() )
    }
    Return JS.%( (encode ? "en" : "de") . "codeURI" . (component ? "Component" : "") )%(str)
}
