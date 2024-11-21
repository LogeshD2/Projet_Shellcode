section .data
fichier db "test.txt", 0

section .bss
fd resq 1
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
	
	; Lecture fichier
	mov rax, 0
	mov rdi, [fd]
	lea rsi, [buffer]
	mov rdx, 256
	syscall
	mov r8, rax

	; Ecriture fichier
	mov rax, 1
	mov rdi, 1
	lea rsi, [buffer]
	mov rdx, r8	
	syscall
	
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

