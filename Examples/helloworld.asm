# Simple smiley
# Displays a smiley sprite in the upper left corner of the screen

bg_tile_map = 0x9800
bg_tile_data = 0x9000
alphabet_start_addr = 0x9000 + (0x41 * 16)

lcdc = 0xff40
lcdc_operation_bit = (1 << 7)
lcdc_gbwin_on_bit = (1 << 0)
ly = 0xff44
palette = 0xff47

[org(0x4000)] message: db "HELLO WORLD"
[org(0x4041)]
letter_a: db 0x00, 0x18, 0x24, 0x24, 0x3c, 0x24, 0x24, 0x24
letter_b: db 0x00, 0x38, 0x24, 0x24, 0x24, 0x38, 0x24, 0x38
letter_c: db 0x00, 0x18, 0x24, 0x20, 0x20, 0x20, 0x24, 0x18
letter_d: db 0x00, 0x38, 0x24, 0x24, 0x24, 0x24, 0x24, 0x38
letter_e: db 0x00, 0x3c, 0x20, 0x20, 0x20, 0x38, 0x20, 0x3c
letter_f: db 0x00, 0x3c, 0x20, 0x20, 0x20, 0x38, 0x20, 0x20
letter_g: db 0x00, 0x18, 0x24, 0x20, 0x20, 0x2c, 0x24, 0x1c
letter_h: db 0x00, 0x24, 0x24, 0x24, 0x24, 0x3c, 0x24, 0x24
letter_i: db 0x00, 0x1c, 0x08, 0x08, 0x08, 0x08, 0x08, 0x1c
letter_j: db 0x00, 0x0e, 0x04, 0x04, 0x04, 0x04, 0x24, 0x18
letter_k: db 0x00, 0x24, 0x24, 0x28, 0x30, 0x30, 0x28, 0x24
letter_l: db 0x00, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x3c
letter_m: db 0x00, 0x22, 0x36, 0x2a, 0x22, 0x22, 0x22, 0x22
letter_n: db 0x00, 0x22, 0x32, 0x32, 0x2a, 0x26, 0x26, 0x22
letter_o: db 0x00, 0x18, 0x24, 0x24, 0x24, 0x24, 0x24, 0x18
letter_p: db 0x00, 0x38, 0x24, 0x24, 0x38, 0x30, 0x30, 0x30
letter_q: db 0x00, 0x38, 0x24, 0x24, 0x24, 0x24, 0x2c, 0x1e
letter_r: db 0x00, 0x38, 0x24, 0x24, 0x38, 0x24, 0x24, 0x24
letter_s: db 0x00, 0x18, 0x24, 0x20, 0x18, 0x04, 0x24, 0x18
letter_t: db 0x00, 0x3e, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08
letter_u: db 0x00, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x18
letter_v: db 0x00, 0x22, 0x22, 0x22, 0x22, 0x22, 0x14, 0x08
letter_w: db 0x00, 0x52, 0x52, 0x52, 0x52, 0x52, 0x52, 0x2c
letter_x: db 0x00, 0x22, 0x22, 0x14, 0x08, 0x14, 0x22, 0x22
letter_y: db 0x00, 0x22, 0x22, 0x14, 0x08, 0x08, 0x08, 0x08
letter_z: db 0x00, 0x3c, 0x04, 0x04, 0x18, 0x20, 0x20, 0x3c

[org(0x100)] start: nop; jp main
[org(0x134)] game_title: db "HELLO WORLD"

[org(0x150)] main:
  ld sp, 0xfffe
  di
  
  call stopLCD
  
  ld hl, alphabet_start_addr
  ld de, 25 * (8 * 8)
  ld bc, 0x4041
  call copy_bytes_twice

  ld hl, bg_tile_map
  ld bc, 0x4000
  ld d, 11
  call copy_bytes
  
  # Set bg palette data
  ld a, 0xe4
  ld (palette), a
  
  call startLCD
  
  end: jp end

# Wait until it's safe to update the screen and then disable LCD operation
stopLCD:
  ld a, (ly)
  cp 145
  jp nc, stopLCD
  ld a, (lcdc_gbwin_on_bit)
  ld (lcdc), a
  ret

startLCD:
  ld a, (lcdc_gbwin_on_bit | lcdc_operation_bit)
  ld (lcdc), a
  ret

# d: number of bytes
# bc: start address
# hl: destination address
copy_bytes:
  ld a, (bc)
  ld (hl+), a
  inc bc
  
  dec d
  jp nz, copy_bytes
  ret

# de: number of bytes
# bc: start address
# hl: destination address
copy_bytes_twice:
  ld a, (bc)
  inc bc
  ld (hl+), a
  ld (hl+), a
  
  dec e
  jp nz, copy_bytes_twice
  dec d
  jp nz, copy_bytes_twice
  ret

[org(0x7fff)] pad: db 0x00
