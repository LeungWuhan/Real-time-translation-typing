;双击鼠标右键：复制

;单击鼠标中键：粘贴（小于0.3秒）

;长按鼠标中键：剪切（大于0.3秒）

;长按鼠标右键：删除（大于1秒）

;ctrl+鼠标右键：全选

;ctrl+1：暂停脚本

;ctrl+2：退出脚本 
^Rbutton::

send ^a

return


mbutton::

KeyWait, MButton, T0.5 ; T后数字为多少秒内松开鼠标中键

If ErrorLevel = 1  ;如果超时

   {
    sendinput, ^{a}     ;发送《粘贴》
    sendinput, ^{v}     ;发送《粘贴》

}

Else

{

sendinput, ^{v}     ;发送《粘贴》
}

return


RButton::

if (RB_presses > 0) {

    RB_presses += 1

        return

        }

        RB_presses := 1 ;设置计数器，记录按键次数

        SetTimer, LabelRB, -400 ;设置时钟，在 0.4秒内等待更多的按键

        return

        

        LabelRB:

        if (RB_presses = 1) {  ; 单击右键：≤0.x秒《右键功能》，＞0.x秒《删除》

        KeyWait, Rbutton, T1.0 ; T后数字为多少秒内松开鼠标r键

If ErrorLevel = 1  ;如果超时

{

sendinput, {del}

}

Else

{

sendinput,{Rbutton}

}

                     } else if (RB_presses >= 2) {  ;双击右键，发送《复制》

               Sendinput,^{c}

               SoundBeep, 1800, 150

                                }RB_presses = 0  ;每次响应时钟后把计数器清0复位

               return


^1::pause

^2::exitapp

 