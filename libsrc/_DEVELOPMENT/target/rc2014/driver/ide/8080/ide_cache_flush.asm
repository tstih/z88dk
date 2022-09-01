
SECTION code_driver

PUBLIC ide_cache_flush

EXTERN __IO_IDE_COMMAND

EXTERN __IDE_CMD_CACHE_FLUSH

EXTERN ide_wait_ready

EXTERN ide_write_byte

;------------------------------------------------------------------------------
; Routines that talk with the IDE drive, these should be called by
; the main program.
; tell the drive to flush its write cache
; Uses AF, DE
; return carry on success

.ide_cache_flush
    call ide_wait_ready

    ld de,__IO_IDE_COMMAND<<8|__IDE_CMD_CACHE_FLUSH
    call ide_write_byte
    jp ide_wait_ready           ;carry set on return = operation ok

