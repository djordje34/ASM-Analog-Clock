title primerPrekida

assume cs:program,ds:podaci,es:podaci,ss:stek
	extrn PostaviNovuPrekidnuRutinu:near,VratiStaruPrekidnuRutinu:near
	extrn videoModeInit:near, kolor:near
		extrn linija:near, DebelaLinija:near  
		extrn boja
		extrn  standardVGA:near, mojVGAmod:near, cuvajMod:near, vratiMod:near
		extrn normalStil:near, orstil:near, xorstil:near, tacka:near
		extrn put:near
		extrn brisiEkran:near
		extrn debljina:near,popunjenost:near
;====================================
; Primer koriscenja modula za postavljanje prekidne rutine
; Prekidna rutina se postavlja stavljanjem u DS:DX adrese prekidne rutine i pozivanjem PostaviNovuPrekidnuRutinu
; Na kraju programa se poziva VratiStaruPrekidnuRutinu kako bi se vratila stara prekidna rutina

    


podaci segment para public 'data'
X1 dw 320
Y1 dw 240
X2 dw 320
Y2 dw 90
x11 dw 320
y11 dw 240
x22 dw 320
y22 dw 90
x111 dw 320
y111 dw 240
x222 dw 320
y222 dw 25
xmax dw 470
ymax dw 390
xmin dw 170
ymin dw 90															
xmid dw 320
ymid dw 240
minutidod db 0
OldInterruptAddress dw 0h, 0h
boja_p_d dw 0												;za trenutni mod boje->promenljive koje imaju d na kraju naziva su trenutne boje
boja_p_l dw 0FFh											;koje imaju l su za drugu temu boja
boja_h_d dw 4													;prva tema-> crvene kazaljke za sate, zelene za minute, plave za sekunde
boja_m_d dw 2													;druga tema za kazaljke-> monochrome, tamno sive kazaljke za sate, minute i sekunde
boja_s_d dw 1
boja_h_l dw 8h													;teme za pozadinu->standard->crna boja pozadine
boja_m_l dw 8h													;druga tema->bela boja pozadine
boja_s_l dw 8h	
boja_p_t dw 0
boja_h_t dw 4
boja_m_t dw 0Ah
boja_s_t dw 9
checker1 dw 0		
tip	dw	0															;tip okvira sata-> mogucnosti-> dvanaestougao,osmougao,kvadrat,bez okvira
current_sec dw 0	
new_sec dw 1														;promenljive za funkciju koju nisam implementirao, delay
delay db 1
seconds  db 61
;-------------
podaci ends

;============================

program segment para public 'code'						
	org 100h
glavno proc far
	mov ax,seg podaci
	mov ds,ax
	mov es,ax
	mov ax,seg stek
	mov ss,ax

		mov ah,0fh
        int 10h ;get video mode
        push ax
		mov al,12h
        mov ah,0
        int 10h ;set video mode VGA
		call videoModeInit
	
	mov dx, offset PrekidnaRutina		;poziv
	mov ax, seg program
	push ds
	mov ds, ax
	; ds:dx adresa prekidne rutine
	call PostaviNovuPrekidnuRutinu
	pop ds

	; cekaj da se pritisne ESC 
GetKey:												;provera dugmeta
	mov ah, 00h    ;BIOS.GetKey				;ESC->gasi se program
    int 16h													;SPACE->menja se boja kazaljki  RGB ili Monochrome
	cmp al,32			;space						;BACKSPACE->menja se boja pozadine 
	je switchcolors									;ENTER->Menja se okvir sata, moguci oblici: Dvanaestougao,osmougao,kvadrat,bez okvira
	cmp al,13		;enter
	je switchborder
	cmp al,08
	je switchbg
	 cmp al, 27     ;Is it ESCAPE
	jne GetKey 
	cmp al,27
	je kraj11
	switchcolors:										;menjaju se karakteristicne boje za kazaljke sa bojama iz drugog moda
	mov bx,boja_h_t								
	mov cx,boja_m_t
	mov dx,boja_s_t

		xchg bx,boja_h_l
		xchg cx,boja_m_l
		xchg dx,boja_s_l
		mov boja_h_t,bx
		mov boja_m_t,cx
		mov boja_s_t,dx
		jmp GetKey
		switchbg:											
			push ax
			mov ax,boja_p_t
			xchg ax,boja_p_l
				mov boja_p_t,ax
				pop ax
				jmp GetKey
		switchborder:
			mov ax,tip
			cmp ax,3									;ako su iscrtane sve moguce vrste okvira, vrati na mod bez okvira
			je restartborder
			inc ax
			mov tip,ax
			jmp krajb
			restartborder:
			mov tip,0
			jmp krajb
			krajb:
			jmp GetKey
		kraj11:
	call VratiStaruPrekidnuRutinu
		
	mov ah,4ch	
	int 21h
glavno endp

PrekidnaRutina proc far
pocetak:
	push ds
	mov ax,seg podaci
    mov ds,ax             ;initialize DS
	push ax
call clsc													;improvizovana funkcija za brisanje ekrana
	mov ax,boja_h_t 
mov boja,ax
		call kolor
		pop ax
		 mov ah,2Ch            ;gettime
		int 21h               ;CH = hr, CL = min, DH = sec
		mov si, offset minutidod											;minutidod predstavlja koliko je minuti trenutno, tj. promenljivu koja odredjuje offset kazaljke za sate, koliko ce da se pomeri u odnosu na standardni polozaj
		mov [si],cl
		mov bl,ch		;deo za sate
		cmp bl,0Ch
		jle cont		
		sub bl,0Ch																	;ako vece od 12, oduzimamo 12, npr. kazaljke za 1 i 13 pokazuju na istu tacku
		cont:
		cmp bl,3
		jle trojka
		cmp bl,6 
		jle sestica1
		cmp bl,9
		jle devetka1
		cmp bl,0Ch
		jle dvanaest1
		trojka:
			cmp bl,1h
			je jedan
			cmp bl,2h
			je dvaa
			cmp bl,3h
			je trii
			jedan:
			mov cx,18Dh
			mov dx,73h
			jmp korekcija1																;racunanje offseta kazaljke za sate
			dvaa:
			mov cx,1BDh
			mov dx,0A5h
			jmp korekcija2
			trii:
			mov cx,1D6h
			mov dx,0F0h
			jmp korekcija3
			sestica1:
			jmp sestica
			devetka1:
			jmp devetka2
			dvanaest1:jmp dvanaest2
			korekcija1:
			mov al,minutidod
			mov ah,00h
						mov bl,5h
			mul bl
			mov bl,6
			push dx
			div bl
			pop dx
			and ax,00FFh
			add dx,ax
			add cx,ax
			jmp minuti
					korekcija2:
			mov al,minutidod
			mov ah,00h
			mov bl,19h
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			
			add cx,ax
				mov al,minutidod
				mov ah,00h
				mov bl,4Bh
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			
			add dx,ax
			jmp minuti
			korekcija3:
			mov al,minutidod
			mov ah,00h
				mov bl,19h
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			sub cx,ax
			mov al,minutidod
			mov ah,00h
			mov bl,4bh
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh

			add dx,ax
			jmp minuti
		sestica:
		cmp bl,4h
			je cetiri
			cmp bl,5h
			je pet
			cmp bl,6h
			je sest
			cetiri:
			mov cx,1BDh
			mov dx,13Bh
			jmp korekcija4
			pet:
			mov cx,18bh
			mov dx,16dh
			jmp korekcija5
			sest:
			mov cx,140h
			mov dx,186h
			jmp korekcija6
			korekcija4:
			mov al,minutidod
			mov ah,00h
			mov bl,32h
			mul bl
			mov bl,3ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			
			sub cx,ax
			add dx,ax
			jmp minuti
			devetka2:jmp devetka															;dodatne jmp 'stanice', jer jmp ne moze da skoci na prvobitnu 'stanicu' zbog opsega
			dvanaest2:jmp dvanaest3
					korekcija5:
			mov al,minutidod
			mov ah,00h
			mov bl,19h
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			
			add dx,ax
				mov al,minutidod
				mov ah,00h
				mov bl,4Bh
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			
			sub cx,ax
			jmp minuti
			korekcija6:
			mov al,minutidod
			mov ah,00h
			mov bl,4bh
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			sub cx,ax
			mov al,minutidod
			mov ah,00h
			mov bl,19h
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			sub dx,ax
			jmp minuti
		devetka:
		cmp bl,07h
			je sedam
			cmp bl,08h
			je osam
			cmp bl,9h
			je devet
			sedam:
			mov cx,0F5h
			mov dx,16Dh
			jmp korekcija7
			osam:
			mov cx,0C3h
			mov dx,13Bh
			jmp korekcija8
			devet:
			mov cx,0AAh
			mov dx,0F0h
			jmp korekcija9
			korekcija7:
			mov al,minutidod
			mov ah,00h
			mov bl,32h
			mul bl
			mov bl,3ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			sub cx,ax
			sub dx,ax
			jmp minuti
					korekcija8:
			mov al,minutidod
			mov ah,00h
			mov bl,4bh
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			
			sub dx,ax
				mov al,minutidod
				mov ah,00h
				mov bl,19h
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			sub cx,ax
			jmp minuti
			dvanaest3:jmp dvanaest
			korekcija9:
			mov al,minutidod
			mov  ah,00h
			mov bl,19h
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			add cx,ax
			mov al,minutidod
			mov ah,00h
			mov bl,4bh
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			sub dx,ax
			jmp minuti
		dvanaest:
			cmp bl,0Ah
			je deset
			cmp bl,0Bh
			je jedanaest
			cmp bl,Ch
			je nula
			deset:
			mov cx,0C3h
			mov dx,0A5h
			jmp korekcija10
			jedanaest:
			mov cx,0F5h
			mov dx,73h
			jmp korekcija11
			nula:
			mov cx,140h
			mov dx,05Ah
			jmp korekcija12
			korekcija10:
			mov al,minutidod
				mov ah,00h
			mov bl,32h
			mul bl
			mov bl,3ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			add cx,ax
			sub dx,ax
			jmp minuti
					korekcija11:
			mov al,minutidod
			mov ah,00h
			mov bl,19h
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			sub dx,ax
				mov al,minutidod
				mov ah,00h
			mov bl,4bh
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			add cx,ax
			jmp minuti
			korekcija12:
			mov al,minutidod
			mov ah,00h
			mov bl,4bh
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh
			add cx,ax
			mov al,minutidod
			and ax,00FFh
			mov bl,19h
			mul bl
			mov bl,3Ch
			push dx
			div bl
			pop dx
			and ax,00FFh

			add dx,ax
			jmp minuti
										;deo za minute
		minuti:														
		mov bx,x11
		mov ax,y11
		call DebelaLinija
			 mov ah,2Ch            ;gettime
		int 21h 
		mov checker1,0								;checker varijabla, sluzi za odredjuvanje da li ce funkcija getMS racunati trenutni polozaj sekundare ili kazaljke za minute, uz pomoc checkera znamo koju kazaljku kako treba obojiti
		call getMS											;prvo se postavlja za racun pozicije kazaljke za minute
					mov ah,2ch
					int 21h
					mov cl,dh										;CL->minuti			DH->sekunde			neophodno zameniti da bi getMS racunala polozaj sekundare
					mov checker1,1						;ovde postavljamo da racuna polozaj sekundare
					call  getMS
		;sekunde2:
			;	mov bx,x11
		;mov ax,y11
		;	push ax
		;mov ax,boja_m_t 
	;	mov boja,ax
		;		call kolor
	;	pop ax
	;	call linija
		mov ax,235													;iscrtavanje staticnih poligona i linija				oznaka za sate, minute, sekunde....
		mov bx,315
		mov cx,325
		mov dx,235
		call kolor
		call DebelaLinija
		mov cx,315
		mov dx,245
		call kolor
		call DebelaLinija
		xchg ax,dx
		xchg bx,cx
		mov cx,325
		mov dx,245
		call kolor
		call DebelaLinija
			xchg ax,dx
		xchg bx,cx
		mov cx,325
		mov dx,235
		call kolor
		call DebelaLinija
		mov ax,240
		mov bx,318
		mov cx,322
		mov dx,240
		push ax
		mov ax,boja_m_t
		mov boja,ax
		pop ax
		call kolor
		call DebelaLinija
		mov ax,boja_s_t
		mov boja,ax
		mov bx,320
		mov ax,90
		mov cx,320
		mov dx,75
		call kolor
		call linija
		mov bx,395
		mov ax,115
		mov cx,400
		mov dx,105
		call kolor
		call linija
		mov bx,445
		mov ax,165
		mov cx,450
		mov dx,162
		call kolor
		call linija
			mov bx,470
		mov ax,240
		mov cx,485
		mov dx,240
		call kolor
		call linija
		mov bx,445
		mov ax,315
		mov cx,450
		mov dx,318
		call kolor
		call linija
		mov bx,395
		mov ax,365
		mov cx,400
		mov dx,375
		call kolor
		call linija
		
			mov bx,320
		mov ax,390
		mov cx,320
		mov dx,405
		call kolor
		call linija
		mov bx,245
		mov ax,365
		mov cx,240
		mov dx,375
		call kolor
		call linija
		mov bx,195
		mov ax,315
		mov cx,190
		mov dx,318
		call kolor
		call linija
			mov bx,170
		mov ax,240
		mov cx,155
		mov dx,240
		call kolor
		call linija
		mov bx,195
		mov ax,165
		mov cx,190
		mov dx,162
		call kolor 
		call linija
		mov bx,245
		mov ax,115
		mov cx,240
		mov dx,105
		call kolor
		call linija
		mov ax,tip
		cmp ax,0
		je notip
		cmp ax,1
		je okttip
		cmp ax,2
		je twtip
		cmp ax,3
		je ktip2
		notip:
		jmp krajPR
		okttip:													;okviri
			mov bx,320
			mov ax,70
			mov cx,440
			mov dx,120
			call kolor
			call DebelaLinija
			xchg bx,cx
			xchg ax,dx
			mov cx,490
			mov dx,240
			call kolor
			call DebelaLinija
			xchg bx,cx
			xchg ax,dx
			mov cx,440
			mov dx,360
			call kolor
			call DebelaLinija
			xchg bx,cx
			xchg ax,dx
			mov cx,320
			mov dx,410
			call kolor
			call DebelaLinija
			xchg bx,cx
			xchg ax,dx
			mov cx,200
			mov dx,360
			call kolor
			call DebelaLinija
			xchg bx,cx
			xchg ax,dx
			mov cx,150
			mov dx,240
			call kolor
			call DebelaLinija
			xchg bx,cx
			xchg ax,dx
			mov cx,200
			mov dx,120
			call kolor
			call DebelaLinija
			jmp nesto2
			ktip2:jmp ktip
			twtip:jmp twtip1
			nesto2:
			xchg bx,cx
			xchg ax,dx
			mov cx,320
			mov dx,70
			call kolor
			call DebelaLinija
			jmp krajPR
			ktip:jmp ktip1
			twtip1:
				mov ax,70
				mov bx,320
				mov cx,400
				mov dx,100
				call kolor
				call DebelaLinija
					xchg bx,cx
					xchg ax,dx
					mov cx,455
					mov dx,157
					call kolor
					call DebelaLinija
					xchg bx,cx
					xchg ax,dx
					mov cx,490
					mov dx,240
					call kolor
					call DebelaLinija
					xchg bx,cx
					xchg ax,dx
					mov cx,455
					mov dx,323
					call kolor
					call DebelaLinija
					xchg bx,cx
					xchg ax,dx
					mov cx,405
					mov dx,380
					call kolor
					call DebelaLinija
					xchg bx,cx
					xchg ax,dx
					mov cx,320
					mov dx,410
					call kolor
					call DebelaLinija
					xchg bx,cx
					xchg ax,dx
					mov cx,235
					mov dx,380
					call kolor
					call DebelaLinija
					xchg bx,cx
					xchg ax,dx
					mov cx,185
					mov dx,323
					call kolor
					call DebelaLinija
					xchg bx,cx
					xchg ax,dx
					mov cx,150
					mov dx,240
					call kolor
					call DebelaLinija
					xchg bx,cx
					xchg ax,dx
					mov cx,185
					mov dx,157
					call kolor
					call DebelaLinija
					xchg bx,cx
					xchg ax,dx
					mov cx,235
					mov dx,100
					call kolor
					call DebelaLinija
					xchg bx,cx
					xchg ax,dx
					mov cx,320
					mov dx,70
					call kolor
					call DebelaLinija
					
				jmp krajPR
			ktip1:
			mov bx,490
			mov ax,70
			mov cx,490
			mov dx,410
			call kolor
			call DebelaLinija
			xchg bx,cx
					xchg ax,dx
					mov cx,150
					mov dx,410
					call kolor
					call DebelaLinija
					xchg bx,cx
					xchg ax,dx
					mov cx,150
					mov dx,70
					call kolor
					call DebelaLinija
					xchg bx,cx
					xchg ax,dx
					mov cx,490
					mov dx,70
					call kolor
					call DebelaLinija
			jmp krajPR
;exit
krajPR:
	 
	pop ds
	iret	; povratak iz prekidne rutine mora sa instrukcijom IRET
PrekidnaRutina	endp

	clsc PROC NEAR
			;mov ax,0012h
			;mov ah,00h
			;int 10h    ; izvrsi konfiguraciju
			;call videoModeInit
			mov ah,0bh
			mov bx,boja_p_t
			mov boja,bx
			call brisiEkran
			;int 10h
			ret
	clsc ENDP

getMS PROC NEAR
cmp cl,05h													;proverava trenutnu vrednost registra cl i skace na potrebni deo funkcije
			jle pet1
		cmp cl, 0Ah
			jle deset1
		cmp cl, 0Fh
			jle petnaest
		cmp cl,14h
			jle dvad11
			cmp cl,19h
				jle dvapet11
			cmp cl,1Eh
				jle	trid11
			cmp cl,23h
				jle tripet11
			cmp cl,28h
				jle cetd11
			cmp cl,2Dh
				jle cetpet11
			cmp cl,32h
				jle petd11
			cmp cl,37h
				jle petpet11
			cmp cl,3Ch
				jle sestd11
				pet1:
					mov al,cl
					mov bl,cl
					mov ah,00h
					mov bh,0Fh
					mul bh
					mov cx,320
					mov dx,90
					add cx,ax
					mov al,bl
					mov bh,05h
					mul bh
					add dx,ax
					jmp sekunde
				deset1:
				sub cl,5h
					mov al,cl
					mov bl,cl
					mov ah,00h
					mov bh,0Ah
					mul bh
					mov cx,395
					mov dx,115
					add cx,ax
					add dx,ax
					jmp sekunde
					dvad11:jmp dvad1
					dvapet11:jmp dvapet1
					trid11:jmp trid1
					tripet11:jmp tripet1
					cetd11:jmp cetd1
					cetpet11:jmp cetpet1
					petd11:jmp petd1
					petpet11:jmp petpet1
					sestd11:jmp sestd1
		petnaest:
						sub cl,0Ah
				mov al,cl
					mov bl,cl
					mov ah,00h
					mov bh,05h
					mul bh
					mov cx,445
					mov dx,165
					add cx,ax
					mov al,bl
					mov bh,0Fh
					mul bh
					add dx,ax
				jmp sekunde
				trid1:jmp trid
				tripet1:jmp tripet
				dvad1:jmp dvad
				dvapet1:jmp dvapet
		dvad:
		sub cl,0Fh
			mov al,cl
					mov bl,cl
					mov ah,00h
					mov bh,05h
					mul bh
					mov cx,470
					mov dx,240
					sub cx,ax
					mov al,bl
					mov bh,0Fh
					mul bh
					add dx,ax
					jmp sekunde
					cetd1:jmp cetd
					cetpet1:jmp cetpet
					petd1:jmp petd
					petpet1:jmp petpet
					sestd1:jmp sestd
		dvapet:
						sub cl,14h
					mov al,cl
					mov bl,cl
					mov ah,00h
					mov bh,0Ah
					mul bh
					mov dx,315
					mov cx,445
					sub cx,ax
					add dx,ax
					jmp sekunde
		trid:
		sub cl,19h
				mov al,cl
					mov bl,cl
					mov ah,00h
					mov bh,0Fh
					mul bh
					mov cx,395
					mov dx,365
					sub cx,ax
					mov al,bl
					mov bh,05h
					mul bh
					add dx,ax
					jmp sekunde
					sekunde:jmp sekunde1
		tripet:
		sub cl,1Eh
					mov al,cl
					mov bl,cl
					mov ah,00h
					mov bh,0Fh
					mul bh
					mov cx,320
					mov dx,390
					sub cx,ax
					mov al,bl
					mov bh,05h
					mul bh
					sub dx,ax
					jmp sekunde
		cetd:
		sub cl,23h
					mov al,cl
					mov bl,cl
					mov ah,00h
					mov bh,0Ah
					mul bh
					mov cx,245
					mov dx,365
					sub cx,ax
					sub dx,ax
				jmp sekunde
		cetpet:
		sub cl,28h
					mov al,cl
					mov bl,cl
					mov ah,00h
					mov bh,05h
					mul bh
					mov cx,195
					mov dx,315
					sub cx,ax
					mov al,bl
					mov bh,0Fh
					mul bh
					sub dx,ax
					jmp sekunde
		petd:
		sub cl,2Dh
					mov al,cl
					mov bl,cl
					mov ah,00h
					mov bh,05h
					mul bh
					mov cx,170
					mov dx,240
					add cx,ax
					mov al,bl
					mov bh,0Fh
					mul bh
					sub dx,ax
					jmp sekunde
		petpet:
		sub cl,32h
					mov al,cl
					mov bl,cl
					mov ah,00h
					mov bh,0Ah
					mul bh
					mov cx,195
					mov dx,165
					add cx,ax
					sub dx,ax
					jmp sekunde
		sestd:
		sub cl,37h
					mov al,cl
					mov bl,cl
					mov ah,00h
					mov bh,0Fh
					mul bh
					mov cx,245
					mov dx,115
					add cx,ax
					mov al,bl
					mov bh,05h
					mul bh
					sub dx,ax
					jmp sekunde
					
		sekunde1:										;crtanje linija za sekunde/minute
				mov bx,x11
		mov ax,y11
			push ax
			mov ax,checker1
			cmp ax,0h
			je minutes
			mov ax,boja_s_t
			mov boja,ax
			jmp nastavi
		minutes:mov ax,boja_m_t 
		mov boja,ax
		nastavi:		call kolor
		pop ax
		call linija

		ret 
getMS ENDP
delaying proc near										;neimplementirana funkcija, napravljena iz razloga da bi usporili refresh rate tj. brisanje ekrana
del:
	mov ah,2ch
	int 21h
	cmp dh,seconds
	je del
	mov seconds,dh
	mov ah,delay
	dec ah
	mov delay,ah
	jnz del
	
	ret
	delaying endp

program ends

stek segment para stack 'stack'
svasta	dw 200 dup (?)
stek ends

end glavno