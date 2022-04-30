
  mount_save_argc := userzp
  debug_mainargs_ptr  := userzp+1 ; 2 bytes
  mount_ptr1 := userzp+3
  mount_ptr2 := userzp+5
  mount_ptr3 := userzp+7
  save_id_current_mountpoint := userzp +9

.macro addoffset struct_offset,ptr
  lda     #struct_offset
  clc  
  adc     ptr
  bcc     *+3
  inc     ptr+1

  sta     ptr  
.endmacro


.macro copy_ptr_offset ptr1, ptr2 
  lda     ptr1
  sta     ptr2
  
  lda     ptr1+1
  sta     ptr2+1
.endmacro




  XGETARGV = $2E
.proc _mount
 ; mount -t vfat /dev/hda1 /mnt/win95

 XMAINARGS = $2C

  BRK_KERNEL XMAINARGS

  ;cpx     #05
  ;bne     @out 
  
  stx     mount_save_argc
  cpx     #$01
  beq     @displays_mounts_point

  sta     debug_mainargs_ptr
  sty     debug_mainargs_ptr+1

  ldx     #$01 ; get arg 2 ; Get the third param
  lda     debug_mainargs_ptr
  ldy     debug_mainargs_ptr+1
  BRK_KERNEL XGETARGV
  sta     mount_ptr1
  sty     mount_ptr1+1

  ; Check if -t
  ldy     #$00
  lda     (mount_ptr1),y
  cmp     #'-'
  bne     @out
  iny
  lda     (mount_ptr1),y
  cmp     #'t'
  bne     @out
  iny 
  lda     (mount_ptr1),y  ;  is it EOS ?
  bne     @out
  ; -t reached, check now type

  ldx     #$02 ; get arg 2 ; Get the third param
  lda     debug_mainargs_ptr
  ldy     debug_mainargs_ptr+1
  BRK_KERNEL XGETARGV
  sta     mount_ptr1
  sty     mount_ptr1+1



  ldx     #$00
@L1:
  lda     busy_mount_point,x
  beq     @found 
  inx  
  cpx     #MAX_MOUNTPOINT
  bne     @L1 
  ; Here MAX mount point
  lda     #$01
  rts

@out:
  print str_missing_args
  BRK_KERNEL XCRLF
  rts

@not_known: 
  print str_type_not_known
  rts

@displays_mounts_point:

  jmp     display_all


@found:
  ; Checking if .dsk
  tax  ; X contains the free MOUNTPOINT ID
  sta     save_id_current_mountpoint
  lda     tab_mountpoint_low,x
  sta     mount_ptr2
  lda     tab_mountpoint_high,x
  sta     mount_ptr2,x


  ldy     #$00
  lda     (mount_ptr1),y
  cmp     #'d'
  bne     @not_known
  iny
  lda     (mount_ptr1),y
  cmp     #'s'
  bne     @not_known
  iny
  lda     (mount_ptr1),y
  cmp     #'k'
  bne     @not_known
  iny 
  lda     (mount_ptr1),y  ;  is it EOS ?
  bne     @not_known

  lda     #DSK_FS
  ldy     #mount_struct::driver
  sta     (mount_ptr2),y

  ; copy source
  ldx     #$03 ; get arg 2 ; Get the third param
  lda     debug_mainargs_ptr
  ldy     debug_mainargs_ptr+1
  BRK_KERNEL XGETARGV
  sta     mount_ptr1
  sty     mount_ptr1+1


  copy_ptr_offset mount_ptr2, mount_ptr3
  addoffset mount_struct::source,mount_ptr3

  jsr     copy_ptr1_to_ptr3


; Copy target

  ; copy source
  ldx     #$04 ; get arg 2 ; Get the third param
  lda     debug_mainargs_ptr
  ldy     debug_mainargs_ptr+1
  BRK_KERNEL XGETARGV
  sta     mount_ptr1
  sty     mount_ptr1+1


  copy_ptr_offset mount_ptr2, mount_ptr3


  addoffset mount_struct::mountpoint,mount_ptr3



  jsr     copy_ptr1_to_ptr3
  ; now store
  lda    #$01
  ldx    save_id_current_mountpoint
  sta    busy_mount_point,x

  lda    #$00
  rts 

display_string:

  ldy     #$00
@L200:  
  lda     (mount_ptr3),y
  beq     @end_display
  BRK_KERNEL XWR0
  ;sta     (mount_ptr3),y
  iny
  cpy     #MAX_PATH_SOURCE
  bne     @L200
  ; Path is longer than require
@end_display:
  rts


display_all:
  ldx     #$00

@next_mountpoint:
  lda     busy_mount_point,x
  beq     @next

  lda     tab_mountpoint_low,x
  sta     mount_ptr2

  lda     tab_mountpoint_high,x
  sta     mount_ptr2,x

  copy_ptr_offset mount_ptr2, mount_ptr3


  addoffset mount_struct::source,mount_ptr3



  jsr     display_string

  print   str_on

  copy_ptr_offset mount_ptr2, mount_ptr3

  addoffset mount_struct::mountpoint,mount_ptr3

  jsr     display_string

  print   str_type
  
  jsr     displays_type

  ; get driver

  BRK_KERNEL XCRLF

@next: 
  inx 
  cpx    #MAX_MOUNTPOINT
  bne    @next_mountpoint

  rts

displays_type:

  copy_ptr_offset mount_ptr2, mount_ptr3

  addoffset mount_struct::driver,mount_ptr3



  ldy     #$00
  
  lda     (mount_ptr3),y 
  tax
  lda     tab_type_low,x
  sta     mount_ptr3
  lda     tab_type_high,x
  sta     mount_ptr3+1

  ldy     #$00
@L900:  
  lda     (mount_ptr3),y
  beq     @out
  BRK_KERNEL XWR0
  iny
  bne     @L900
@out:  
  rts


str_missing_args:
    .asciiz "Missing arg"
str_type_not_known:    
    .asciiz "Type not known"
str_on:
     .asciiz " on "

str_type:
     .asciiz " type "

.endproc

.proc copy_ptr1_to_ptr3

  ldy     #$00
@L2:  
  lda     (mount_ptr1),y
  beq     @end_copy_source
  sta     (mount_ptr3),y
  iny
  cpy     #MAX_PATH_SOURCE
  bne     @L2
  ; Path is longer than require
  lda     #$02
  rts
@end_copy_source:
  sta     (mount_ptr3),y

  rts  
.endproc




