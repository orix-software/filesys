
.define DSK_FTDOS_FS 0
.define DSK_SEDORIC_FS 1
.define DSK_FS 2

FILESYS_BANK := $20C

XVALUES_ROUTINE := $2D

WHO_AM_IAM := 1

.define MAX_MOUNTPOINT 4

.include   "../dependencies/orix-sdk/macros/SDK.mac"

.define MAX_PATH_SOURCE 100
.define MAX_PATH_TARGET 100

.struct mount_struct
mountpoint       .res MAX_PATH_TARGET
driver           .res 1
source           .res MAX_PATH_SOURCE
.endstruct

.macro  BRK_KERNEL   value
        .byte $00,value
.endmacro


.struct filedef
        d_name .res 16
        d_size  .res 4
        d_type  .res 1
        day_mdate .res 1
        mon_mdate .res 1
        year_mdate .res 1
.endstruct
;struct dirent {
;    char          d_name[16];
;    unsigned      d_ino;
 ;   unsigned      d_blocks;
    ;unsigned long d_size;
    ;unsigned char d_type;
    ;struct {
        ;unsigned day  :5;
        ;unsigned mon  :4;
        ;unsigned year :7;
    ;}             d_cdate;
    ;struct {
        ;unsigned char min;
        ;unsigned char hour;
    ;}             d_ctime;
    ;unsigned char d_access;
    ;unsigned      d_auxtype;
    ;struct {
        ;unsigned day  :5;
        ;unsigned mon  :4;
        ;unsigned year :7;
    ;}             d_mdate;
    ;struct {
        ;unsigned char min;
        ;unsigned char hour;
    ;}             d_mtime;
;};



.include   "telestrat.inc"
.include   "fcntl.inc"
;.include   "build.inc"

userzp := $80 ; FIXME

.org $c000

.code
        jmp filesys_start
        jmp in_open_stream
       
;        jp DOSNode_CheckDrive
 ;       jp DOSNode_GetStatus
  ;      jp DOSNode_GetName
   ;     jp DOSNode_GetDesc
    ;    jp DOSNode_GetFreeSpace
     ;   jp DOSNode_InOpenStream
      ;  jp DOSNode_InReadStream
;        jp DOSNode_InCloseStream
 ;       jp DOSNode_InSeekStream
  ;      jp DOSNode_OutOpenStream
   ;     jp DOSNode_OutWriteStream
    ;    jp DOSNode_OutCloseStream
     ;   jp DOSNode_OutSeekStream
;         jp DOSNode_Examine
       ; jp DOSNode_ExamineNext
       ; jp DOSNode_Rename
;        jp DOSNode_Delete
 ;       jp DOSNode_CreateDir
  ;      jp DOSNode_SetProtection
   ;     jp DOSNode_Format
    ;    jp DOSNode_Void
     ;   jp DOSNode_Void
      ;  jp DOSNode_Void
       ; jp DOSNode_Void
;        jp DOSNode_Void
 ;       jp DOSNode_Void
  ;      jp DOSNode_OpenNVRAM
   ;     jp DOSNode_CloseNVRAM
    ;    jp DOSNode_ReadNVRAM
     ;   jp DOSNode_WriteNVRAM
      ;  jp DOSNode_SeekNVRAM
; vectors

.proc in_open_stream

   lda    #'A'       
   sta    $bb80
   rts
.endproc

.include "commands/mount.asm"

filesys_start:
    ; Get who am i


    print  str_who_am_i

    ldx    #WHO_AM_IAM
    BRK_KERNEL XVALUES_ROUTINE
    ; Register to kernel
    sta     FILESYS_BANK

    ;lda     bank_decimal_current_bank
    ldy     #$00
    ldx     #$20 ;
    stx     DEFAFF
    ldx     #$00
    BRK_KERNEL XDECIM


    jmp init
str_who_am_i:
  .asciiz "Who am i : "

.proc init
    lda     #$00
        sta     mount_point_available_id

 	lda     #<version
	ldy     #>version
	BRK_TELEMON XWSTR0

	lda     #<systemd_starting
	ldy     #>systemd_starting
	BRK_TELEMON XWSTR0
; Debug	
    ldx     #$00
    lda     tab_mountpoint_low,x
    sta     mount_ptr2
    lda     tab_mountpoint_high,x
    sta     mount_ptr2,x

    

    copy_ptr_offset mount_ptr2, mount_ptr3
    addoffset mount_struct::source,mount_ptr3

    lda     #<str_source
    sta     mount_ptr1
    
    lda     #>str_source
    sta     mount_ptr1+1

    jsr     copy_ptr1_to_ptr3

    copy_ptr_offset mount_ptr2, mount_ptr3
    addoffset mount_struct::mountpoint,mount_ptr3

    lda     #<str_mountpoint
    sta     mount_ptr1
    
    lda     #>str_mountpoint
    sta     mount_ptr1+1

    jsr     copy_ptr1_to_ptr3


    lda     #DSK_FS
    ldy     #mount_struct::driver
    sta     (mount_ptr2),y

    lda    #$01
    ldx    #$00
    sta    busy_mount_point,x

    jsr    _mount


    rts
.endproc

str_source:
 .asciiz "/home/sedoric/hide.dsk"

 str_mountpoint:
 .asciiz "/mnt/hide"

str_driver:
.asciiz "dsk"



fs_drivers:
        .asciiz "seddsk"
        .asciiz "ftdsk"


.proc copyfrom
        rts
.endproc

.proc copyto
        rts
.endproc

.proc readdir
        rts
.endproc

.proc mkdir
        rts
.endproc

mount_point_available_id:
        .res 1

tab_mountpoint_low: 
        .byte  <mountpoint1
        .byte  <mountpoint2
        .byte  <mountpoint3
        .byte  <mountpoint4

tab_mountpoint_high: 
        .byte  >mountpoint1
        .byte  >mountpoint2
        .byte  >mountpoint3
        .byte  >mountpoint4

busy_mount_point:
     .byte 0,0,0,0 

tab_type_low: 
    .byte  <DSK_FTDOS_FS_str
    .byte  <DSK_SEDORIC_FS_str
    .byte  <DSK_FS_str

tab_type_high: 
    .byte  >DSK_FTDOS_FS_str
    .byte  >DSK_SEDORIC_FS_str
    .byte  >DSK_FS_str    

DSK_FTDOS_FS_str:
   .asciiz "ftd"
DSK_SEDORIC_FS_str:
   .asciiz "sed"
DSK_FS_str:
   .asciiz "dsk"   



mountpoint1:
  .tag mount_struct
mountpoint2:
  .tag mount_struct  
mountpoint3:
  .tag mount_struct  
mountpoint4:
  .tag mount_struct    

;systemd_cnf:
    ;.tag systemd_struct


path_cnf:
    .asciiz "/etc/fstab"	


systemd_starting:
   .byte " ..........",$82,"[OK]",$0D,$0A,0

rom_signature:
	.byte   "Filesys " ; Space must be present
version:    
    .asciiz "v2021.3"


command1_str:
        .asciiz "fsinit"
        .asciiz "m" ; mount
        .asciiz "mls" ; mount mls

commands_address:
        .addr  filesys_start
        .addr  _mount

commands_version:
        .ASCIIZ "0.0.1"


	
; ----------------------------------------------------------------------------
; Copyrights address

        .res $FFF0-*
        .org $FFF0
; $fff0
; $00 : empty ROM
; $01 : command ROM
; $02 : TMPFS
; $03 : Drivers
; $04 : filesystem drivers
type_of_rom:
    .byt $04
; $fff1
parse_vector:
        .byt $00,$00
; fff3
adress_commands:
        .addr commands_address   
; fff5        
list_commands:
        .addr command1_str
; $fff7
number_of_commands:
        .byt 2
signature_address:
        .word   rom_signature

; ----------------------------------------------------------------------------
; Version + ROM Type
ROMDEF: 
        .addr filesys_start

; ----------------------------------------------------------------------------
; RESET
rom_reset:
        .addr filesys_start
; ----------------------------------------------------------------------------
; IRQ Vector
empty_rom_irq_vector:
        .addr   IRQVECTOR ; from telestrat.inc (cc65)

