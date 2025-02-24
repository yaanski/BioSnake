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
appleY:     dw 8
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
    mov ax, [playerX]
    mov [SNAKEXARRAY], ax

    ;; delay loop to stop blinking
    delay_loop:
        mov bx, [TIMER]
        inc bx
        inc bx
        .delay:
            cmp [TIMER], bx
            jl .delay



jmp game_loop

;; BOOTSECTOR PADDING -------------
times 510 - ($-$$) db 0

dw 0AA55h