; ============================================================
;  Auto Copy / 鼠标增强  （AutoHotkey v1，用 AutoHotkey1.exe 运行）
; ============================================================
;  双击鼠标右键             ：复制
;  单击鼠标中键（<0.3秒）   ：粘贴
;  长按鼠标中键（>0.3秒）   ：剪切
;  长按鼠标右键（>1秒）     ：删除
;  单击鼠标右键             ：右键
;  Ctrl + 鼠标右键          ：全选
;  Ctrl+1                   ：暂停脚本
;  Ctrl+2                   ：退出脚本
; ============================================================

#SingleInstance Force
#NoEnv
#MaxHotkeysPerInterval 200
SendMode Input
SetBatchLines, -1

; ---------------- Ctrl + 右键：全选 ----------------
^RButton::
    SendInput, ^a
return

; ---------------- 中键：短按粘贴 / 长按剪切 ----------------
MButton::
    KeyWait, MButton, T0.3
    if (ErrorLevel = 1)       ; 超时 = 长按
        SendInput, ^x         ; 剪切
    else
        SendInput, ^v         ; 粘贴
return

; ---------------- 右键：单击=右键 / 长按=删除 / 双击=复制 ----------------
RButton:
    if (RB_presses > 0)
    {
        RB_presses += 1
        return
    }
    RB_presses := 1
    SetTimer, LabelRB, -400
return

LabelRB:
    if (RB_presses = 1)
    {
        KeyWait, RButton, T1.0
        if (ErrorLevel = 1)
            SendInput, {Del}       ; 长按删除
        else
            SendInput, {RButton}   ; 单击右键
    }
    else if (RB_presses >= 2)
    {
        SendInput, ^c              ; 双击复制
        SoundBeep, 1800, 150
    }
    RB_presses := 0
return

; ---------------- 暂停 / 退出 ----------------
^1::Pause
^2::ExitApp
