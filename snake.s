; MEMORY LAYOUT
; 1-33: Snake queue
; 34: food location
; 35: score
; 36: high score
; 37: ticks

; Storing the head & tail pointer in R5 & R6

ORG 0
BAL start_game ; go straight to starting the game

ORG 1 ; Snake queue
DATA 26 ; snake tail in 26
DATA 27 ; we want the snake head to start in cell 27

ORG 34
food_location DATA 0
score DATA 0
waited_steps DATA 0
tickrate DATA 2500
direction DATA 2
state DATA 1

ORG 40
; create a reserved branch so that we can always get back to the main loop
branch_main BAL main
branch_gfp BAL gen_food_pos
branch_cis BAL check_inside_snake
ORG 43 ; code begins

; gen_food_pos, generates new food position & stores it
; returns to address at R1
gen_food_pos ST R1, genfp_adr
  LD R1, frc_adr
  LD R1, [R1]
  CMP R1, R0
  BGE gfp_ts
  SUB R1, R0, R1
  gfp_ts ST R2, genfp_rtemp ; temp store R2
  ADD R2, R1, R0, asr ; gonna do frc % 64 by dividing by 64 then getting rem
  ADD R2, R2, R0, asr
  ADD R2, R2, R0, asr
  ADD R2, R2, R0, asr
  ADD R2, R2, R0, asr
  ADD R2, R2, R0, asr
  BAL genfp_mul
  genfp_adr DATA 0
  frc_adr DATA 0xFFA4
  genfp_rtemp DATA 0 ; somewhere to store R2
  genfp_fp_adr DATA 34 ; address of food_location
  genfp_mul ADD R2, R2, R2 ; multiply back up now
  ADD R2, R2, R2
  ADD R2, R2, R2
  ADD R2, R2, R2
  ADD R2, R2, R2
  ADD R2, R2, R2
  SUB R1, R1, R2
  LD R2, genfp_fp_adr
  ST R1, [R2]
  LD R2, genfp_rtemp
  LD R7, genfp_adr

; check_inside_snake checks if a cell is inside the snake
; give cell as R1, ret adr as R2, R1 will either be 0 or 1

cis_queue_end DATA 33
check_inside_snake ST R2, cis_adr
  ST R3, cis_r3
  ST R4, cis_r4
  MOV R2, R6
  LD R3, cis_queue_end

  cis_comp LD R4, [R2]
  CMP R4, R1
  BEQ cis_eq
  CMP R2, R5
  BEQ cis_neq
  BAL cis_add
  cis_adr DATA 0
  cis_r3 DATA 0
  cis_r4 DATA 0
  cis_add ADD R2, R2, #1
  CMP R2, R3
  BLS cis_comp
  MOV R2, #1 ; back to start of queue
  BAL cis_comp
  cis_eq MOV R1, #1
  BAL cis_dne
  cis_neq MOV R1, #0
  cis_dne LD R3, cis_r3
  LD R4, cis_r4
  LD R7, cis_adr

start_game
  ; set up these pointers
  MOV R5, #2
  MOV R6, #1
  MOV R4, #2
  ; reset Memory
  LD R1, sg_gs_adr
  MOV R2, #1
  ST R2, [R1]
  LD R1, sg_dir_adr
  MOV R2, #2
  ST R2, [R1]
  LD R1, sg_score_adr
  ST R0, [R1]
  ; generate food position
  ADD R1, R7, #1
  BAL gen_food_pos
  BAL main

  sg_gs_adr DATA 39
  sg_score_adr DATA 35
  sg_dir_adr DATA 38
  m_tickrate_adr DATA 37
  waited_steps_adr DATA 36 ; how many have we waited
  m_dir_adr DATA 38

  main
    ; retrieve current dir
    LD R4, m_dir_adr
    LD R4, [R4]

    LD R2, waited_steps_adr
    LD R2, [R2]
    LD R3, m_tickrate_adr
    LD R3, [R3]
    CMP R2, R3
    BEQ waited ; if enough time has passed skip this next bit
    ADD R2, R2, #1
    LD R1, waited_steps_adr
    ST R2, [R1]
    BAL control_loop ; check controls
    ; set waited_steps back to 0
    waited MOV R2, #0
    LD R1, waited_steps_adr
    ST R2, [R1]
    BAL update ; and update our positions

    ; get our current direction and store in R4
    control_loop
      LD R2, btn_u
      LD R1, btn_addr
      LD R1, [R1]
      BAL ccmpu
      btn_u DATA 0x0004
      btn_r DATA 0x0040
      btn_d DATA 0x0100
      btn_l DATA 0x0010
      btn_addr DATA 0xFF94
      dir DATA 2
      ccmpu CMP R1, R2
      BNE ccmpr
      MOV R4, #1
      ccmpr LD R2, btn_r
      CMP R1, R2
      BNE ccmpd
      MOV R4, #2
      ccmpd LD R2, btn_d
      CMP R1, R2
      BNE ccmpl
      MOV R4, #3
      ccmpl LD R2, btn_l
      CMP R1, R2
      BNE ccmph
      MOV R4, #4
      ccmph LD R2, btn_h
      CMP R1, R2
      BNE done_controls
      MOV R4, #5
      BAL done_controls
      c_dir_adr DATA 38
      btn_h DATA 0x0800
      done_controls LD R1, c_dir_adr
      ST R4, [R1]
      BAL main

    ;TODO: make it so you can't switch directions
    u_gs_adr DATA 39
    ; By now we have our direction in R4, head in R5 and tail in R6
    update
    ; check if we need to reset game
    MOV R1, #5
    CMP R1, R4
    BEQ start_game
    LD R1, u_gs_adr
    LD R1, [R1]
    CMP R1, R0
    BEQ update_done ; if game isn't running skip logic

    LD R3, [R5]
    ; head position in R3

    ; calculate the X & Y co-ordinates from the cell number
    ; divide by 8 for the Y
    ADD R2, R3, R0, asr
    ADD R2, R2, R0, asr
    ADD R2, R2, R0, asr

    ADD R1, R2, R2
    ADD R1, R1, R1
    ADD R1, R1, R1

    SUB R1, R3, R1
    ; X in R1, Y in R2

    ; let's update these X & Y co-ords now
    cmpst CMP R4, #1
    BNE cmpr
    SUBS R2, R2, #1
    BAL cmpdne
    cmpr CMP R4, #2
    BNE cmpd
    ADDS R1, R1, #1
    BAL cmpdne
    cmpd CMP R4, #3
    BNE cmpl
    ADDS R2, R2, #1
    BAL cmpdne
    cmpl SUBS R1, R1, #1

    ; edge detection
    cmpdne CMP R1, R0
    BGE check_x_max
    MOV R1, #7
    check_x_max MOV R3, #7
    CMP R1, R3
    BLS check_y_min
    MOV R1, #0
    check_y_min CMP R2, R0
    BGE check_y_max
    MOV R2, #7
    check_y_max CMP R2, R3
    BLS edgedne
    MOV R2, #0

    ; updating done, let's figure out the cell number by Y*8+X
    edgedne ADD R3, R2, R2
    ADD R3, R3, R3
    ADD R3, R3, R3
    ADD R3, R3, R1

    ; check if new cell is inside snake, if so we lose
    MOV R1, R3
    ADD R2, R7, #1
    LD R7, u_cis_adr
    CMP R1, R0
    BEQ push_h
    BAL game_lose

    ; new head cell in R3 now
    ; need to push to queue, pop off the oldest tail
    u_cis_adr DATA 42
    u_fp_adr DATA 34
    queue_end DATA 33 ;
    queue_start DATA 1
    push_h LD R1, queue_end
    ADD R5, R5, #1
    CMP R5, R1
    BLS update_h
    ; if gt than queue_end we need to circle the queue
    LD R5, queue_start
    update_h ST R3, [R5] ; store our new head
    ; check if the next cell is food, if it is, skip the pop
    LD R4, u_fp_adr
    LD R4, [R4]
    CMP R3, R4
    BEQ increase_score
    ; now need to pop the tail
    LD R1, queue_end
    ADD R6, R6, #1
    CMP R6, R1
    BLS update_done
    LD R6, queue_start

    update_done BAL clear_screen

gl_gs_adr DATA 39
gl_main_adr DATA 40
game_lose LD R1, gl_gs_adr
  ST R0, [R1]
  ADD R1, R7, #1
  BAL do_vibrate
  ADD R1, R7, #1
  BAL do_vibrate
  ADD R1, R7, #1
  BAL do_vibrate
  ADD R1, R7, #1
  BAL do_vibrate
  LD R7, gl_main_adr

gfp_adr DATA 41
score_adr DATA 35
hs_adr DATA 36
is_vib_length DATA 1000
is_vib_adr DATA 0xFF96
increase_score ADD R1, R7, #1
  LD R7, gfp_adr
  ADD R1, R7, #1
  BAL do_beep
  ;increase score
  LD R1, score_adr
  LD R2, [R1]
  ADD R2, R2, #1
  ST R2, [R1]
  LD R1, hs_adr
  LD R3, [R1]
  CMP R2, R3
  BLS clear_screen
  ST R2, [R1]
  BAL clear_screen


rgb_e DEFW 0xFF3F
clear_screen LD R1, rgb_s
  MOV R2, #0
  LD R3, rgb_e
  clear_loop ST R2, [R1]
  ADD R1, R1, #1
  CMP R1, R3
  BLS clear_loop
  BAL draw_snake


; routine to draw the snake
rgb_s DEFW 0xFF00 ; start address of screen
color_head DEFW 0b00011100;
draw_snake LD R1, [R5] ; load the cell number of the head
  LD R2, rgb_s
  LD R3, color_head
  ADD R2, R2, R1
  ST R3, [R2]
  LD R2, rgb_s
  LD R1, [R6]
  ADD R2, R2, R1
  ST R3, [R2]
  BAL draw_body
  ;draw body now

  d_queue_end DATA 33 ;
  d_queue_start DATA 1

  draw_body MOV R1, R6 ; copy tail+1 to R1
    body_loop ADD R1, R1, #1
    LD R2, d_queue_end
    CMP R1, R2
    BLS check_head
    LD R1, d_queue_start
    check_head CMP R1, R5
    BEQ draw_food
    BAL do_body_draw
    rgb_sb DEFW 0xFF00
    color_body DEFW 0b00011100;
    do_body_draw LD R2, [R1]
    LD R3, rgb_sb
    LD R4, color_body
    ADD R3, R3, R2
    ST R4, [R3]
    BAL body_loop

  color_food DEFW 0b11100000;
  d_fp_adr DEFW 34


  draw_food LD R3, rgb_sb
    LD R1, d_fp_adr
    LD R1, [R1]
    LD R4, color_food
    ST R4, [R3, R1]
    BAL update_screen

vib_length DATA 100000
vib_adr DATA 0xFF96
vib_tick_adr DATA 37
vib_radr DATA 0
do_vibrate ST R1, vib_radr
  LD R1, vib_adr
  MOV R2, #1
  LD R3, vib_length
  ST R2, [R1] ; turn vibrator on
  vib_loop CMP R3, R0
  BEQ vib_done
  SUB R3, R3, #1
  BAL vib_loop
  vib_done ST R0, [R1] ; turn off
  ; make sure the next update is instant cos we've just delayed for ages
  LD R1, vib_tick_adr
  LD R2, [R1]
  SUB R1, R1, #1
  ST R2, [R1]
  LD R7, vib_radr

beep_data DATA 0b1000000101000000

beep_adr DATA 0xFF92
beep_radr DATA 0
do_beep ST R1, beep_radr
  LD R1, beep_adr
  LD R2, beep_data
  ST R2, [R1]
  LD R7, beep_radr

screen_adr DATA 0xFF40
us_gs_adr DATA 39
us_bmain_adr DEFW 40

update_screen LD R1, screen_adr
  LD R2, us_gs_adr
  LD R2, [R2]
  CMP R2, R0
  BEQ update_screen_over
  BAL update_screen_run

  su_dne LD R7, us_bmain_adr

score_str_adr DATA 0x1000

score_ten DATA 10
us_score_adr DATA 35
update_screen_run
  LD R1, score_str_adr
  MOV R2, #0
  ADD R3, R7, #1
  BAL print_str
  MOV R1, #0 ; R1 is digit 1 of score
  LD R2, us_score_adr
  LD R2, [R2] ; R2 is digit 2 of score
  LD R4, score_ten
  us_s_loop SUB R2, R2, R4 ; sub 10
  CMP R2, R0 ; is below 0?
  BLT us_too_far
  ADD R1, R1, #1
  BAL us_s_loop
  ascii_start DATA 48
  score_pos DATA 0xFF47
  us_too_far ADD R2, R2, R4
  LD R3, ascii_start
  ADD R1, R1, R3
  ADD R2, R2, R3
  LD R3, score_pos
  ST R1, [R3]
  ADD R3, R3, #1
  ST R2, [R3]
  BAL su_dne

go_str_adr DATA 0x1040
update_screen_over
  LD R1, go_str_adr
  MOV R2, #0
  ADD R3, R7, #1
  BAL print_str
  BAL su_dne

; function to print a string
; R1 = string adr, R2 = screen pos, R3 = ret adr
pstr_radr DATA 0
screen_start DATA 0xFF40
print_str ST R3, pstr_radr
  LD R4, screen_start
  ADD R2, R2, R4
  print_loop LD R3, [R1]
  CMP R3, R0
  BEQ pstr_dne
  ST R3, [R2]
  ADD R1, R1, #1
  ADD R2, R2, #1
  BAL print_loop
  pstr_dne LD R7, pstr_radr


; somewhere to store strings
ORG 0x1000
score_str DATA 'Score:                                    \0'
ORG 0x1040
go_str DATA 'GAME OVER!          Press # to try again\0'
; init screen
ORG 0xFF40
DATA '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0'
