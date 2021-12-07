title prekid

assume cs:program,ds:podaci,es:podaci

	public PostaviNovuPrekidnuRutinu,VratiStaruPrekidnuRutinu

;====================================
; Prekid (Interrupt) 1Ch se poziva iz prekidne rutine (Interrupt routine)  INT 8, 
; a koji se opet poziva od strane tajmera svakih 18,2 puta u sekundi 
; Programski kod sluzi za postavljanje sopstvene prekidne rutinu za ulaz 1Ch
; Our program will have a main procedure that sets up the interrupt routine and when a key is pressed, 
; it will deactivate the interrupt routine and terminate

podaci segment para public 'data'


OldInterruptAddress dw 0h, 0h

podaci ends

program segment para public 'code'

PostaviNovuPrekidnuRutinu proc near	
	; DS:DX = adresa gde je smestena adresa nove prekidne rutine u formatu CS:Offset - ukupno 4 bajta
		
	mov ah, 35h	; AH = 35h -> poziva se funkcija dohvatanja adrese prekidne rutine		
	mov al, 1Ch ; Broj ulaza iz tabele prekidnih rutina - Interrupt vector
	int 21h	    
	; po povratku iz funkcije OS-a 
	; ES:BX sadrži adresu prekidne rutine
	
	;čuvanje stare adrese prekidne rutine
	push ds
	
	mov ax,seg podaci
	mov ds,ax
	mov OldInterruptAddress, bx
	mov bx, es
	mov OldInterruptAddress+2, bx
	
	pop ds

	mov ah, 25h	; Set interrupt vector into vector table		
	mov al, 1Ch ; Interrupt number
	; DS:DX = adresa prekidne rutine koja ce se postaviti za prekid 1Ch - interrupt vector
	int 21h	
	
	ret
	
PostaviNovuPrekidnuRutinu endp

VratiStaruPrekidnuRutinu proc near
	; vraca se stara prekidna rutina koja je zapamcena na adresi OldInterruptAddress
	push ds
	
	mov ax,seg podaci
	mov ds,ax
	mov dx, OldInterruptAddress
	mov ax, OldInterruptAddress+2
	mov ds, ax
	
	mov ah, 25h	; Set interrupt vector into vector table		
	mov al, 1Ch ; Interrupt number
	; DS:DX = adresa stare prekidne rutine - interrupt vector
	int 21h	
	
	pop ds
	ret
	
VratiStaruPrekidnuRutinu endp	
 

program ends

end