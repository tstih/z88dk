#!/usr/bin/env perl

BEGIN { use lib 't2'; require 'testlib.pl'; }

# test continuation lines
z80asm_ok("-b -l", "", "", <<'END', bytes(0x3e, 1));
ld a,\
1
END
check_txt_file("$test.lis", <<'END');
1     0000              ld a,\
2     0000  3E 01       1
3     0002              
4     0002              
END

# backslash at end of line inside a comment
z80asm_ok("", "", "", <<'END', bytes(0, 1, 2));
zero: equ 0 ;\
one   equ 1 ;\
.two  equ 2
defb zero,one,two
END

# test split lines
z80asm_ok("-b -l", "", "", <<'END', bytes(0x3e, 1, 0xc9));
ld a,1\ret
END
check_txt_file("$test.lis", <<'END');
1     0000  3E 01 C9    ld a,1\ret
2     0003              
3     0003              
END

# backslash inside a comment
z80asm_ok("", "", "", <<'END', bytes(0, 1, 2));
zero: equ 0 ;\ret
one   equ 1 ;\ret
.two  equ 2
defb zero,one,two
END

# test ## concatenation
z80asm_ok("", "", "", <<'END', bytes(0));
zero equ 0
     defb ze \
	      ## \
		  ro
END

# continuation line without next line
z80asm_ok("", "", "", <<'END', bytes(0,1,2));
     defb 0 \ defb 1 \ defb 2 \
END

# IF label
z80asm_ok("", "", "", <<'END', bytes(0xc3, 0, 0));
if: if 1
jp if
endif
END

# quoted strings
z80asm_ok("", "", "", <<'END', bytes(7, 8, 27, 12, 10, 13, 9, 11, 0x5c, 0x27, 0x22));
defb '\a','\b','\e','\f','\n','\r','\t','\v','\\','\'','\"'
END

z80asm_ok("", "", "", <<'END', bytes(0, 1, 7, 8, 15, 16, 255));
defb '\0','\1','\7','\10','\17','\20','\377'
END

z80asm_ok("", "", "", <<'END', bytes(0, 1, 7, 8, 15, 16, 255));
defb '\x0','\x1','\x7','\x8','\xf','\x10','\xff'
END

z80asm_ok("", "", "", <<'END', bytes(7, 8, 27, 12, 10, 13, 9, 11, 0x5c, 0x27, 0x22));
defb "\a\b\e\f\n\r\t\v\\\'\""
END

z80asm_ok("", "", "", <<'END', bytes(0, 1, 7, 8, 15, 16, 255));
defb "\0\1\7\10\17\20\377"
END

z80asm_ok("", "", "", <<'END', bytes(0, 1, 7, 8, 15, 16, 255));
defb "\x0\x1\x7\x8\xf\x10\xff"
END

z80asm_nok("", "", <<'END_ASM', <<END_ERR);
defb 'a
END_ASM
Error at file '$test.asm' line 1: unclosed quoted string
END_ERR

z80asm_nok("", "", <<'END_ASM', <<END_ERR);
ld a, "a"
END_ASM
Error at file '$test.asm' line 1: syntax error
END_ERR

z80asm_nok("", "", <<'END_ASM', <<END_ERR);
defb ''
END_ASM
Error at file '$test.asm' line 1: invalid single quoted character
END_ERR

z80asm_nok("", "", <<'END_ASM', <<END_ERR);
defb 'ab'
END_ASM
Error at file '$test.asm' line 1: invalid single quoted character
END_ERR

z80asm_nok("", "", <<'END_ASM', <<END_ERR);
defb "a
END_ASM
Error at file '$test.asm' line 1: unclosed quoted string
END_ERR

# invalid single quoted character was overflowing to next line
z80asm_nok("", "", <<'END_ASM', <<END_ERR);
ld a,'he'
ld a,"a"
END_ASM
Error at file '$test.asm' line 1: invalid single quoted character
Error at file '$test.asm' line 2: syntax error
END_ERR

unlink_testfiles;
done_testing;