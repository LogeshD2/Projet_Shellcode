section .data

fichier db "ls_copy", 0
    
msg_error_open_file db "Erreur lors de l'ouverture du fichier", 10, 0
len_msg_error_open_file equ $-msg_error_open_file

msg_not_elf db "Ce n'est pas un fichier elf", 10, 0
len_msg_not_elf equ $-msg_not_elf

msg_is_elf db "C'est un fichier elf", 10, 0
len_msg_is_elf equ $-msg_is_elf

msg_is_folder db "C'est un dossier", 10, 0
len_msg_is_folder equ $-msg_is_folder

; Messages d'entête ELF
msg_type db "Type de fichier:", 0
msg_machine db "Machine cible: ", 0
msg_version db "Version: ", 0
msg_entry db "Point d'entrée:", 0
msg_phoff db "Offset de la table des programmes: ", 0
msg_shoff db "Offset de la table des sections: ", 0
msg_flags db "Flags: ", 0
msg_ehsize db "Taille de l'en-tête ELF:", 0
msg_phentsize db "Taille d'une entrée du programme:", 0
msg_phnum db "Nombre d'entrées du programme: ", 0
msg_shentsize db "Taille d'une entrée de section:", 0
msg_shnum db "Nombre d'entrées de section: ", 0
msg_shstrndx db "Index de la table des chaînes de section:", 0

; Messages Program Header
msg_ph db "Program Header ", 0
msg_ph_type db "  p_type:", 0
msg_ph_flags db "  p_flags:", 0
msg_ph_offset db "  p_offset:", 0
msg_ph_vaddr db "  p_vaddr: ", 0
msg_ph_paddr db "  p_paddr: ", 0
msg_ph_filesz db "  p_filesz:", 0
msg_ph_memsz db "  p_memsz: ", 0
msg_ph_align db "  p_align:", 0

; Tableau des descripteurs de champs avec leurs messages et offsets
msg_offsets:
	dq msg_ph_type,    0
	dq msg_ph_flags,   4
	dq msg_ph_offset,  8
	dq msg_ph_vaddr,   16
	dq msg_ph_paddr,   24
	dq msg_ph_filesz,  32
	dq msg_ph_memsz,   40
	dq msg_ph_align,   48
NUM_FIELDS equ 8

space db " ", 0
newline db 10, 0

section .bss

fd resq 1
elf_header resb 64
phdr resb 56
hex_string resb 17
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
	
	; Appelle pour afficher que c'est un fichier elf
	call is_elf
	
	; Ferme le fichier
	mov rax, 3
	mov rdi, [fd]
	syscall	
    	mov qword [fd], -1
    	
    	; Ouvre le fichier
    	mov rax, 2
	lea rdi, [fichier]
	mov rsi, 0
	xor rdx, rdx
	syscall
	mov [fd], rax
    	
	; Lire l'en-tête ELF
	mov rax, 0
	mov rdi, [fd]
	mov rsi, elf_header
	mov rdx, 64
	syscall

	; Afficher l'en-tête ELF
	call print_elf_header

	; Lire et afficher les Program Headers
	movzx rcx, word [elf_header + 56]
	mov rbx, 0

print_ph_loop:
	
	; Condition pour quitter la boucle
	cmp rbx, rcx
	jge exit

	push rcx
	push rbx

	; Calculer l'offset du Program Header
	mov rax, rbx
	mov rdx, 56
	mul rdx
	add rax, qword [elf_header + 32]

	; Positionner le curseur
	mov rdi, [fd]
	mov rsi, rax
	mov rdx, 0
	mov rax, 8
	syscall

	; Lire le Program Header
	mov rax, 0
	mov rdi, [fd]
	mov rsi, phdr
	mov rdx, 56
	syscall

	; Afficher le Program Header
	call print_program_header

	pop rbx
	pop rcx

	inc rbx
	jmp print_ph_loop

print_elf_header:
	push rbp
	mov rbp, rsp

	; Affiche "Type de fichier"
	mov rdi, msg_type
	call print_string
	movzx rax, word [elf_header + 16]
	call print_hex_padded
	call print_newline

	; Affiche "Machine cible"
	mov rdi, msg_machine
	call print_string
	movzx rax, word [elf_header + 18]
	call print_hex_padded
	call print_newline

	; Affiche "Version"
	mov rdi, msg_version
	call print_string
	mov eax, dword [elf_header + 20]
	call print_hex_padded
	call print_newline

	; Affiche "Point d'entrée"
	mov rdi, msg_entry
	call print_string
	mov rax, qword [elf_header + 24]
	call print_hex_padded
	call print_newline

	; Affiche "Offset de la table des programmes"
	mov rdi, msg_phoff
	call print_string
	mov rax, qword [elf_header + 32]
	call print_hex_padded
	call print_newline

	; Affiche "Offset de la table des sections"
	mov rdi, msg_shoff
	call print_string
	mov rax, qword [elf_header + 40]
	call print_hex_padded
	call print_newline

	; Affiche "Flags"
	mov rdi, msg_flags
	call print_string
	mov eax, dword [elf_header + 48]
	call print_hex_padded
	call print_newline

	; Affiche "Taille de l'en-tête ELF"
	mov rdi, msg_ehsize
	call print_string
	movzx rax, word [elf_header + 52]
	call print_hex_padded
	call print_newline

	; Affiche "Taille d'une entrée du programme"
	mov rdi, msg_phentsize
	call print_string
	movzx rax, word [elf_header + 54]
	call print_hex_padded
	call print_newline

	; Affiche "Nombre d'entrées du programme"
	mov rdi, msg_phnum
	call print_string
	movzx rax, word [elf_header + 56]
	call print_hex_padded
	call print_newline

	; Affiche "Taille d'une entrée de section"
	mov rdi, msg_shentsize
	call print_string
	movzx rax, word [elf_header + 58]
	call print_hex_padded
	call print_newline

	; Affiche "Nombre d'entrées de section"
	mov rdi, msg_shnum
	call print_string
	movzx rax, word [elf_header + 60]
	call print_hex_padded
	call print_newline

	; Affiche "Index de la table des chaînes de section"
	mov rdi, msg_shstrndx
	call print_string
	movzx rax, word [elf_header + 62]
	call print_hex_padded
	call print_newline

	pop rbp
	ret



print_program_header:
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14

	; Afficher l'en-tête
	mov rdi, msg_ph
	call print_string
	mov rax, rbx
	call print_dec
	call print_newline

	; Initialiser le compteur et le pointeur
	xor r12, r12                    
	mov r13, msg_offsets          
	mov r14, NUM_FIELDS            

.loop:
	; Comparer le compteur avec le nombre total de champs
	cmp r12, r14
	jge .done

	; Afficher le message
	mov rdi, [r13]
	call print_string

	; Calculer l'adresse de la valeur dans phdr
	mov rax, phdr
	add rax, [r13 + 8]             
	mov rax, [rax]                 
	call print_hex_padded
	call print_newline

	; Passer au champ suivant
	add r13, 16                    
	inc r12
	jmp .loop

.done:
	; Restaurer les registres sauvegardés et retourner
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

print_string:
	push rax
	push rcx
	push rdx
	
	; Calculer la longueur de la chaîne
	mov rcx, -1
	mov rsi, rdi
.count:
	inc rcx
	cmp byte [rsi + rcx], 0
	jne .count

	; Afficher la chaîne
	mov rax, 1
	mov rdx, rcx
	mov rdi, 1
	syscall

	; Restaurer l'état initial
	pop rdx
	pop rcx
	pop rax
	ret

print_hex_padded:
	push rbx
	push rcx
	push rdx
	push rdi

	; Préparer la conversion 
	mov rdi, hex_string
	mov rcx, 16
    
.convert_loop:
	
	; Convertir les 4 bits de poids fort
	rol rax, 4
	mov dl, al
	and dl, 0x0F
	add dl, '0'
	cmp dl, '9'
	jle .store
	add dl, 7
.store:
	mov [rdi], dl
	inc rdi
	dec rcx
	jnz .convert_loop

	; Afficher le tampon
	mov rax, 1
	mov rdi, 1
	mov rsi, hex_string
	mov rdx, 16
	syscall

	; Restaurer l'état initial 
	pop rdi
	pop rdx
	pop rcx
	pop rbx
	ret

print_dec:
	push rax
	push rbx
	push rcx
	push rdx

	; Préparer la division
	mov rcx, 0
	mov rbx, 10
.divide_loop:

	; Extraire les chiffres
	xor rdx, rdx
	div rbx
	push rdx
	inc rcx
	test rax, rax
	jnz .divide_loop
    
.print_loop:

	; Afficher les chiffres
	pop rax
	add al, '0'
	mov [hex_string], al
	push rcx

	; Appel système pour écrire un caractère
	mov rax, 1
	mov rdi, 1
	mov rsi, hex_string
	mov rdx, 1
	syscall

	pop rcx
	loop .print_loop

	; Restaurer l'état initial
	pop rdx
	pop rcx
	pop rbx
	pop rax
	ret

print_newline:
	push rax
	push rdi
	push rsi
	push rdx

	; Préparer l'appel système pour '\n'
	mov rax, 1
	mov rdi, 1
	mov rsi, newline
	mov rdx, 1
	syscall

	; Restaurer l'état initial
	pop rdx
	pop rsi
	pop rdi
	pop rax
	ret

exit:

	; Fermture fichier
	mov rax, 3
	mov rdi, [fd]
	syscall	
	mov rax, 60
	xor rdi, rdi
	syscall
    
not_elf: 
	; Affiche que ce n'est pas un fichier elf
	mov rax, 1
	mov rdi, 2
	lea rsi, [msg_not_elf]
	mov rdx, len_msg_not_elf
	syscall	
	jmp exit

is_elf:
	; Affiche que c'est un fichier elf
	mov rax, 1
	mov rdi, 1
	lea rsi, [msg_is_elf]
	mov rdx, len_msg_is_elf
	syscall
	ret

is_folder:
	; Affiche que c'est un dossier
	mov rax, 1
	mov rdi, 1
	lea rsi, [msg_is_folder]
	mov rdx, len_msg_is_folder
	syscall
	jmp exit

error_open_file:
	; Affiche une erreur d'ouverture du fichier
	mov rax, 1
	mov rdi, 1
	lea rsi, [msg_error_open_file]
	mov rdx, len_msg_error_open_file
	syscall
	jmp exit
