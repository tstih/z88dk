; uchar __FASTCALL__ *zx_saddrcright(void *pixeladdr)
; aralbrec 06.2007

XLIB zx_saddrcright

.zx_saddrcright

; enter: hl = valid screen address
; exit : carry = moved off screen
;        hl = new screen address one character right with line wrap
; uses : af, hl

   inc l
   ret nz
   
   ld a,8
   add a,h
   ld h,a
   cp $58
   ccf
   
   ret
