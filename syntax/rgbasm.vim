" Minimal RGBDS (rgbasm) syntax
if exists("b:current_syntax") | finish | endif
syntax case ignore

syn match rgbComment ";.*$" contains=rgbTodo
syn keyword rgbTodo TODO FIXME XXX contained
syn region rgbString start=+"+ skip=+\\"+ end=+"+
syn match rgbNumber "\<\d\+\>"
syn match rgbNumber "[$]\x\+\>"
syn match rgbNumber "[%&]\@<=[01]\+\>" 
syn match rgbNumber "%[01_]\+\>"
syn match rgbNumber "&[0-7]\+\>"
syn match rgbNumber "`[0-3]\+\>"
syn match rgbLabel "^\s*[A-Za-z_][A-Za-z0-9_#@.]*:\{1,2}"
syn match rgbLabel "^\s*\.[A-Za-z_][A-Za-z0-9_#@]*:\{0,2}"
syn match rgbMacroArg "\\[0-9@#<]"
syn match rgbMacroArg "\\([^)]*)"

syn keyword rgbInstr adc add and bit call ccf cp cpl daa dec di ei halt inc jp jr ld ldh ldi ldd nop or pop push res ret reti rl rla rlc rlca rr rra rrc rrca rst sbc scf set sla sra srl stop sub swap xor
syn keyword rgbReg a b c d e h l af bc de hl sp pc hli hld nz z nc
syn keyword rgbDirective section endsection pushs pops load endl union nextu endu include incbin
syn keyword rgbDirective db dw dl ds db ds align assert static_assert fail warn println print printf
syn keyword rgbDirective if elif else endc rept for endr break macro endm shift purge def redef equ equs set rb rw rsset rsreset export opt pusho popo pushc popc charmap newcharmap setcharmap fragment rom0 romx vram sram wram0 wramx oam hram bank
syn keyword rgbFunc high low bitwidth tzcount strlen strcat strsub strin strupr strlwr strrpl strfmt strcmp charlen charsub revchar bank sizeof startof div mul fmod pow log round ceil floor sin cos tan asin acos atan atan2 isconst def

hi def link rgbComment Comment
hi def link rgbTodo Todo
hi def link rgbString String
hi def link rgbNumber Number
hi def link rgbLabel Function
hi def link rgbMacroArg Special
hi def link rgbInstr Statement
hi def link rgbReg Identifier
hi def link rgbDirective PreProc
hi def link rgbFunc Function

let b:current_syntax = "rgbasm"
