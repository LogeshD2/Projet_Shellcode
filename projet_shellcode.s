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

msg_found_pt_note db "pt_note trouvé", 10, 0
len_msg_found_pt_note equ $-msg_found_pt_note

msg_count db "Nombre de PT_NOTE trouvés: ", 0
len_msg_count equ $-msg_count

newline db 10    
buffer_size equ 20

section .bss
fd resq 1
statbuf resb 144
buffer resb 256
elf_header resb 64
programm_header resb 56
pt_note_count resb 1
number_buffer resb buffer_size    

section .text
global _start

_start:
	mov byte [pt_note_count], 0

	; Ouverture fichier
	mov rax, 2
	lea rdi, [fichier]
	mov rsi, 2
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
    
	; Message que c'est un fichier ELF
	mov rax, 1
	mov rdi, 1
	lea rsi, [msg_is_elf]
	mov rdx, len_msg_is_elf
	syscall

	; Fermeture fichier pour ne pas avoir les informations décalé
	mov rdi, [fd]
	mov rax, 3
	syscall
	mov qword [fd], -1
	
	; Réouverture
	lea rdi, [fichier]
	mov rsi, 2
	xor rdx, rdx
	mov rax, 2
	syscall
	mov [fd], rax

	; Lecture 64 bit du fichier elf
   	mov rax, 0
	mov rdi, [fd]
	lea rsi, [elf_header]
	mov rdx, 64
	syscall

	
	; Lire les Program Headers
	movzx rcx, word [elf_header + 56]
	mov rbx, 0
	

programm_header_loop:
	; Condition pour quitter la boucle
	cmp rbx, rcx
	jge exit_loop
	
	push rcx
	push rbx

	; Détermine l'index de chaque Header
	mov rax, rbx
	mov rdx, 56
	mul rdx
	add rax, 64

	; Déplace le curseur du fichier à l'offset calculé pour lire l'en-tête de Program Headers
	mov rdi, [fd]
	mov rsi, rax
	xor rdx, rdx
	mov rax, 8
	syscall	

	; Lire le programme Header
	mov rax, 0
	mov rdi, [fd]
	lea rsi, [programm_header]
	mov rdx, 56
	syscall

	; Comparaison du p_type (égal à 4 pour le PT_NOTE)
	mov eax, dword [programm_header]
	cmp eax, 4
	jne not_pt_note
	
	; Changement du PT_NOTE en PT_LOAD	
	mov dword [programm_header], 1

	; Recalcule le positionnement avec l'index
	mov rax, rbx
	mov rdx, 56
	mul rdx
	add rax, 64

	; Recalcule le positionnement (l_seek)
	push rax
	mov rax, 8
	mov rdi, [fd]
	pop rsi
	xor rdx, rdx
	syscall
	
	; Écriture les nouvelles valeurs de l'en-tête de programme dans le fichier ELF
	mov rax, 1
	mov rdi, [fd]
	lea rsi, [programm_header]
	mov rdx, 56
	syscall

	; Incrémente le compteur de nombre de pt_note
	inc byte [pt_note_count]
	call pt_note_found	
	jmp exit_loop

; Si le segment n'est pas de type PT_NOTE, passe au prochain en-tête de programme	
not_pt_note:
	pop rbx
	pop rcx
	inc rbx
	jmp programm_header_loop

; Quitte la boucle
exit_loop:
	mov rax, 3
   	mov rdi, [fd]
    	syscall    
    	jmp exit


; Message qui affiche que ce n'est pas un fichier ELF	
not_elf:
	mov rax, 1
	mov rdi, 2
	lea rsi, [msg_not_elf]
	mov rdx, len_msg_not_elf
	syscall    
	jmp exit    

; Message qui affiche que c'est un dossier
is_folder:
	mov rax, 1
	mov rdi, 1
	lea rsi, [msg_is_folder]
	mov rdx, len_msg_is_folder
	syscall
	jmp exit

; Message qui affiche que le fichier/dossier ne s'ouvre pas
error_open_file:
	mov rax, 1
	mov rdi, 1
	lea rsi, [msg_error_open_file]
	mov rdx, len_msg_error_open_file
	syscall
	jmp exit

; Message qui affiche qu'il n'as pas trouvé de PT_NOTE
pt_note_found:
        mov rax, 1
        mov rdi, 1
        lea rsi, [msg_found_pt_note]
        mov rdx, len_msg_found_pt_note
        syscall
	ret


convert_number:
    ; Convertit la valeur de pt_note_count en une chaîne de caractères ASCII
    push rbx
    mov rbx, number_buffer
    add rbx, buffer_size - 1
    mov byte [rbx], 0      
    dec rbx
    mov byte [rbx], 10     
    dec rbx
    
    mov rcx, 10            
    movzx rax, byte [pt_note_count]  
    
.convert_loop:
    ; Boucle de conversion : extrait chaque chiffre en ASCII
    xor rdx, rdx        
    div rcx               
    add dl, '0'             
    mov [rbx], dl          
    dec rbx                 
    test rax, rax           
    jnz .convert_loop
    
    inc rbx                
    mov rax, rbx          
    pop rbx
    mov rbx, rax           
    ret


exit:		
    ; Ferme le fichier, affiche le compteur PT_NOTE et termine le programme
    mov rdi, [fd]
    mov rax, 3
    syscall
    
    ; Affiche le message indiquant le nombre de PT_NOTE trouvés
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_count]
    mov rdx, len_msg_count
    syscall

    call convert_number     
    
    ; Calcule la longueur de la chaîne ASCII générée
    mov rdx, number_buffer
    add rdx, buffer_size
    sub rdx, rbx           
    
    ; Affiche la chaîne ASCII générée (le nombre)
    mov rax, 1
    mov rdi, 1
    mov rsi, rbx           
    syscall
    
    ; Quitte le programme proprement
    mov rax, 60
    xor rdi, rdi
    syscall
