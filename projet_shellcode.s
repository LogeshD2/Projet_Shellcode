section .data
fichier db "dossier", 0

msg_error_open_file db "Erreur lors de l'ouverture du fichier", 10, 0
len_msg_error_open_file equ $-msg_error_open_file

msg_not_elf db "Ce n'est pas un fichier elf", 10, 0
len_msg_not_elf equ $-msg_not_elf

msg_is_elf db "C'est un fichier elf", 10, 0
len_msg_is_elf equ $-msg_is_elf

msg_is_folder db "C'est un dossier", 10, 0
len_msg_is_folder equ $-msg_is_folder

section .bss
fd resq 1
statbuf resb 144
buffer resb 256

section .text
global _start

_start:
	; Ouverture fichier
	mov rax, 2
	lea rdi, [fichier]
	mov rsi, 0
	xor rdx, rdx
	syscall
	mov [fd], rax

	; Vérifie erreur ouverture
	cmp rax, 0
	js error_open_file
	

	; Vérifie si c'est un dossier
        mov rax, 4
        lea rdi, [fichier]
        lea rsi, [statbuf]
	syscall


	; Vérifie le champ st_mode
	mov eax, dword [statbuf + 24]
	and eax, 0xF000
	cmp eax, 0x4000
	je is_folder	

	
	; Lecture fichier
	mov rax, 0
	mov rdi, [fd]
	lea rsi, [buffer]
	mov rdx, 4
	syscall
	mov r8, rax

	; Ecriture fichier
	mov rax, 1
	mov rdi, 1
	lea rsi, [buffer]
	mov rdx, r8	
	syscall
	
	; Verifie si 4 octets
	cmp r8, 4
	jne not_elf

	; Comparer signature elf
	; Premier octet
	mov al, byte [buffer]
	cmp al, 0x7F
	jne not_elf

	; Deuxième octet	
	mov al, byte [buffer + 1]
	cmp al, 0x45
	jne not_elf

	; Troisième octet
	mov al, byte [buffer + 2]
	cmp al, 0x4C
	jne not_elf

	; Quatrième octet
	mov al, byte [buffer + 3]	
	cmp al, 0x46
	jne not_elf
	
	jmp is_elf

	; Fermture fichier
	mov rax, 3
	mov rdi, [fd]
	syscall	

	; Quitter programme
	xor rdi, rdi
	jmp exit

exit:
	mov rax, 60
	syscall

not_elf: 
	mov rax, 1
	mov rdi, 2
	lea rsi, [msg_not_elf]
	mov rdx, len_msg_not_elf
	syscall	
	jmp exit

is_elf:
	mov rax, 1
	mov rdi, 1
	lea rsi, [msg_is_elf]
	mov rdx, len_msg_is_elf
	syscall
	jmp exit

is_folder:
	mov rax, 1
	mov rdi, 1
	lea rsi, [msg_is_folder]
	mov rdx, len_msg_is_folder
	syscall
	jmp exit

error_open_file:
	mov rax, 1
	mov rdi, 1
	lea rsi, [msg_error_open_file]
	mov rdx, len_msg_error_open_file
	syscall
	jmp exit


