;; SETUP ==========================
org 7C00h

jmp setup_game

;; CONSTANTS-----------------------
VIDMEM      equ 0B800h
SCREENW     equ 80
SCREENH     equ 25
WINCOND     equ 10
BGCOLOR     equ 1020h
APPLECOLOR  equ 4020h
SNAKECOLOR  equ 2020h
TIMER       equ 046Ch
SNAKEXARRAY equ 1000h
SNAKEYARRAY equ 2000h
UP          equ 0
DOWN        equ 1
LEFT        equ 2
RIGHT       equ 3

;; VARIABLES-----------------------
playerX:     dw 40
playerY:     dw 12
appleX:      dw 16
appleY:      dw 8
direction:   db 4
snakeLength: dw 1



;; LOGIC ==========================
setup_game:
    ;; Set up video mode - VGA mode 03h ( 80x25 text mode, 16 colors)
    mov ax, 0003h
    int 10h

    ;; set up video memory
    mov ax, VIDMEM
    mov es, ax  ; ES:DI video memory ()

    ;; first snake segment
    mov ax, [playerX]
    mov word [SNAKEXARRAY], ax
    mov ax, [playerY]
    mov word [SNAKEYARRAY], ax 

;;game loop
game_loop:
    ;; clear 
    mov ax, BGCOLOR
    xor di, di
    mov cx, SCREENW*SCREENH
    rep stosw 

    xor bx, bx
    mov cx, [snakeLength]
    mov ax, SNAKECOLOR
    .snake_loop:
        imul di, [SNAKEYARRAY+bx], SCREENW*2 ; Y POS of snake segment
        imul dx, [SNAKEXARRAY+bx], 2         ; X POS of snake segment
        add di,dx  
        stosw
        inc bx
        inc bx
    loop .snake_loop 

    ;; Draw Apple
    imul di, [appleY], SCREENW*2
    imul dx, [appleX], 2
    add di, dx
    mov ax, APPLECOLOR
    stosw

    ;; move snake in current direction
    mov al, [direction]
    cmp al, UP
    je move_up
    cmp al, DOWN
    je move_down
    cmp al, LEFT
    je move_left
    cmp al, RIGHT
    je move_right

    jmp update_snake

    move_up:
        dec word[playerY]  ; move up 1 row in screen
        jmp update_snake
    move_down:
        inc word[playerY]  ; move down 1 row in screen
        jmp update_snake
    move_left:
        dec word[playerX]  ; move left 1 row in screen
        jmp update_snake
    move_right:
        inc word[playerX]  ; move right 1 row in screen
    ;; update snake position from player x/y changes
    update_snake:
        ;; update all snake segments
        imul bx, [snakeLength], 2
        .snake_loop:
            mov ax, [SNAKEXARRAY-2+bx]
            mov word [SNAKEXARRAY+bx], ax 
            mov ax, [SNAKEYARRAY-2+bx]
            mov word [SNAKEYARRAY+bx], ax 

            dec bx       ;get previous array elem
            dec bx       ; stop at first elem "head"
        jnz .snake_loop

    ;;store updated values to head of snake in arrays
    mov ax, [playerY]
    mov word [SNAKEYARRAY], ax
    mov ax, [playerX]
    mov word [SNAKEXARRAY], ax

    ;; Loose conditions
    ;; 1) Hit border of screen
    cmp word [playerY], -1      ; top of screen
    je game_lost
    cmp word [playerY], SCREENH ; bottom of screen
    je game_lost
    cmp word [playerX], -1      ; left of screen
    je game_lost
    cmp word [playerX], SCREENW ; right of screen
    je game_lost

    ;; 2) Hit part of snake
    cmp word [snakeLength], 1   ; only starting segment
    je get_player_input

    mov bx, 2                   ; array indexes, start at 2nd array element
    mov cx, [snakeLength]       ; loop counter
    check_hit_snake_loop:
        mov ax, [playerX]
        cmp ax, [SNAKEXARRAY+bx]
        jne .increment

        mov ax, [playerY]
        cmp ax, [SNAKEYARRAY+BX]
        je game_lost

        .increment:
            inc bx
            inc bx
    loop check_hit_snake_loop
 

    get_player_input:
        mov bl, [direction]      ; save current direction

        mov ah, 1                
        int 16h                  ; get keyboard status
        jz check_apple           ; if no key was pressed

        xor ah, ah
        int 16h                  ; ah = scan code, al = ascii char entered

        cmp al, 'w'
        je w_pressed
        cmp al, 's'
        je s_pressed
        cmp al, 'a'
        je a_pressed
        cmp al, 'd'
        je d_pressed

        jmp check_apple

        w_pressed:
            mov bl, UP
            jmp check_apple
        s_pressed:
            mov bl, DOWN
            jmp check_apple
        a_pressed:
            mov bl, LEFT
            jmp check_apple
        d_pressed:            ; me, with the e 
            mov bl, RIGHT
            
    ;; did player hit apple
    check_apple:
        mov byte [direction], bl

        mov ax, [playerX]
        cmp ax, [appleX]
        jne delay_loop

        mov ax, [playerY]
        cmp ax, [appleY]
        jne delay_loop

        ; if apple hit, increase snake length
        inc word [snakeLength]
        cmp word [snakeLength], WINCOND
        je game_won
    ;; if not game won, generate new apple
    next_apple:
        ;; RANDOM X POSITION
        xor ah, ah
        int 1Ah            ; Timer ticks since midnight in CX:DX
        mov ax, dx         ; lower half of time ticks
        xor dx, dx         ; clear out upper half of dividend
        mov cx, SCREENW
        div cx
        mov word [appleX], dx

     ;; RANDOM Y POSITION
        xor ah, ah
        int 1Ah            ; Timer ticks since midnight in CX:DX
        mov ax, dx         ; lower half of time ticks
        xor dx, dx         ; clear out upper half of dividend
        mov cx, SCREENH
        div cx
        mov word [appleY], dx

    ;; check if apple spawned inside of snake
    xor bx, bx              ; array index
    mov cx, [snakeLength]   ; loop counter
    .check_loop:
        mov ax, [appleX]
        cmp ax, [SNAKEXARRAY+bx]
        jne .increment

        mov ax, [appleY]
        cmp ax, [SNAKEYARRAY+bx]
        je next_apple

        .increment:
            inc bx
            inc bx
    loop .check_loop

    ;; delay loop to stop blinking
    delay_loop:
        mov bx, [TIMER]
        inc bx
        inc bx
        .delay:
            cmp [TIMER], bx
            jl .delay



jmp game_loop
;; End conditions
game_won:
    mov dword [ES:0000], 1F491F57h ; WI
    mov dword [ES:0004], 1F211F4Eh ; N!
    jmp reset
game_lost:
    mov dword [ES:0000], 1F4F1F4Ch ; LO
    mov dword [ES:0004], 1F451F53h ; SE

reset:
    xor ah, ah
    int 16h
    
    jmp 0FFFFh:0000h  ; reset vector, "warm reboot"
;;  int 19h           ; restarts qemu

;; BOOTSECTOR PADDING -------------
times 510 - ($-$$) db 0

dw 0AA55h