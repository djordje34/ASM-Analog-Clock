;================ GRAFIKA ===================
podaci segment para public 'data'

debljina db 5
boja db 15
popunjenost db 0
izlazbafer db 0
starox dw 0
staroy dw 0
x1 dw ?
x2 dw ?
y1 dw ?
y2 dw ?
xx dw 0
yy dw 0
xmin dw 0
xmax dw 640
ymin dw 0
ymax dw 480
dyy dw ?
dxx dw ?
sacboja db ?
plot dw tacka
bivsireg db ?
video dw 0a000h
SEQUENCER_ADRESS_REGISTER EQU 3C4h
MAP_MASK_REGISTER EQU 02H
GRAPHICS_ADRESS_REGISTER equ 3CEh
BIT_MASK_REGISTER equ 08H
orgx dw 0
orgy dw 0
nacincrt dw 0
bit db 0
saby dw 0
AdrTrougaoniz dw ?
tabelatrougao dw 960 dup(?)
lokacija dw 0
baferseg1 dw ?
baferseg2 dw ?
baferseg3 dw ?
baferseg4 dw ?

podaci ends
;============================================

program segment public 'code'
        assume cs:program,ds:podaci,es:podaci
		
		public videoModeInit, brisiEkran, standardVGA, mojVGAmod, cuvajMod, vratiMod
		public kolor, normalStil, orstil, xorstil, tacka
		public linija, DebelaLinija, put

		public boja,debljina,popunjenost


videoModeInit proc near
        mov dx,GRAPHICS_ADRESS_REGISTER
        mov ax,0305h;write mode 3  read mode 0
        out dx,ax
        mov ax,0f01h;enable set reset= 1111
        out dx,ax
		mov ax,0ff08h;bit maska=255
		out dx,ax
		mov dx,SEQUENCER_ADRESS_REGISTER
        mov al,MAP_MASK_REGISTER
        mov ah,15 ;sva 4 write planea
        out dx,ax
		mov ax,0a000h
		mov video,ax
		mov es,ax
		ret
videoModeInit endp

brisiEkran proc near
		push ax
		push di
		push cx
		mov ah,boja
		push ax
		call standardvga
		;call mojVGAmod
		call normalStil
		xor di,di
		mov es,video
		mov al,0
		mov cx,38400
	
		;mov boja,5
		call kolor
		;rep stosb
brisiEkranPetlja:
		mov ah,es:[di]
		mov es:[di],al
		inc di
		loop brisiEkranPetlja	
		
		call mojVGAmod
		
		pop ax
		mov boja,ah
		call kolor
		pop cx
		pop di
		pop ax
		ret
brisiEkran endp

standardVGA proc near
		push dx
		push ax
		mov dx,GRAPHICS_ADRESS_REGISTER
        mov ax,0005h;write mode 0  read mode 0
        out dx,ax	
		mov ax,0ff08h;bit maska=255
		out dx,ax
		pop ax
		pop dx
		ret
standardVGA endp

mojVGAmod proc near
		push dx
		push ax
		mov dx,GRAPHICS_ADRESS_REGISTER
        mov ax,0305h;write mode 3  read mode 0
        out dx,ax
		mov ax,0ff08h;bit maska=255
		out dx,ax
		pop ax
		pop dx
		ret
mojVGAmod endp
	
cuvajMod proc near 
		mov al,0   ;set/reset polje je boja
        mov dx,GRAPHICS_ADRESS_REGISTER
		out dx,al
		inc dx
		in al,dx
		mov ah,al
		ret
cuvajMod endp

vratiMod proc near
		mov al,0   ;set/reset polje je boja
        mov dx,GRAPHICS_ADRESS_REGISTER
		out dx,ax
		ret
vratiMod endp

kolor proc near
		push dx
		push ax
		mov ah,boja
        mov al,0   ;set/reset polje je boja
        mov dx,GRAPHICS_ADRESS_REGISTER
		out dx,ax
        pop ax
		pop dx
		ret
kolor endp

normalStil proc near
        push dx
        push ax
        mov dx,GRAPHICS_ADRESS_REGISTER
        mov ax,0003h;0003 za normal nacin
        out dx,ax; bez logickih operacija i nema okretanja
        pop ax
        pop dx
        ret
normalStil endp

orstil proc near
        push dx
        push ax
        mov dx,GRAPHICS_ADRESS_REGISTER
        mov ax,1003h; za OR nacin
        out dx,ax; bez logickih operacija i nema okretanja
        pop ax
        pop dx
        ret
orstil endp

xorstil proc near
        push dx
        push ax
        mov dx,GRAPHICS_ADRESS_REGISTER
        mov ax,1803h;1803h za XOR nacin
        out dx,ax; bez logickih operacija i nema okretanja
        pop ax
        pop dx
        ret
xorstil endp

; Spor nacin crtanja tacke preko DOS funkcije
tacka   proc near
        mov al,boja
        push bx
        mov bh,0
        mov ah,0ch;write pixel dot
        int 10h
        pop bx
        ret
tacka   endp		
		
;================ LINIJA ===================
; ULAZNI PARAMETRI:
; (X1=BX, Y1=AX), (X2=CX, Y2=DX)
;
linija proc near
		push si
		push di
		push ax
		push bx
		push cx
		push dx
		
		mov dxx,1; dxx=1
        mov dyy,1; dyy=1
        mov si,dx
        sub si,ax
        jns dalje1
        neg si ;si=yy=|y2-y1|
		
dalje1: mov di,cx
        sub di,bx
        jns dalje2
        neg di  ;di=xx=|x2-x1|
dalje2: cmp si,di ;sta se uvek povecava: x ili y
        jl vecex
        cmp dx,ax
        jle ok1
        xchg dx,ax ;zamena y1<->y2
        xchg cx,bx ;zamena x1<->x2
ok1:    cmp cx,bx
        jle po_ypre
        mov dxx,-1 ;x1 je vece od x2
po_ypre:mov y2,ax
		xor bx,bx        
po_y:   call put
        inc dx ;y=y+1
        add bx,di ; f=f+xx
        test bh,80h
		jnz dalje5	;skok ako je  f<0
		mov ax,bx
        sub ax,si
        jge dalje4 ; f-yy je >0 ako je skok i to je blize nuli nego samo pozitivno f
        neg ax
		cmp bx,ax
        jl dalje5
dalje4: add cx,dxx ; x=x+dxx
        sub bx,si ;f=f-yy
dalje5: cmp dx,y2
        jg Linkraj
        cmp dx,ymax
        jle Po_y
        jmp Linkraj
;------ po x --------
vecex:  cmp cx,bx
        jle ok2
        xchg cx,bx  ;zamena x1<->x2
        xchg dx,ax ;zamena y1<->y2
ok2:    cmp dx,ax
        jle po_xpre
        mov dyy,-1;y1 je vece od y2
po_xpre:mov x2,bx
		xor bx,bx           
po_x:   call put
        inc cx
        add bx,si
        test bh,80h
        jnz dalje7 
		mov ax,bx
		sub ax,di
        jns dalje6
        neg ax
		cmp bx,ax
        jl dalje7
dalje6: add dx,dyy ;y=y+dyy
        sub bx,di  ;f=f-xx	
dalje7: cmp cx,x2
        jg Linkraj
        cmp cx,xmax
        jle Po_x

Linkraj:pop dx
		pop cx
		pop bx
		pop ax
		pop di
		pop si
		ret
linija endp

;===========================================
; ULAZNI PARAMETRI:
; (X1=BX, Y1=AX), (X2=CX, Y2=DX)
; adresa debljina = debljina linije
DebelaLinija proc near
	push si
	push di	
	mov di,cx
	sub di,bx
	jge DebDalje1
	neg di
DebDalje1:mov si,dx
	sub si,ax
	jge DebDalje2
	neg si
DebDalje2:
	cmp di,si
	jl DebljepoX
DebljePoy:
	xchg si,ax
	xor ax,ax
	mov al,debljina
	xchg si,ax
	mov di,si
	shr si,1
	push dx
	push ax
	sub dx,si
	sub ax,si
	mov si,di
DebljePoyPetlja:call linija
	inc dx
	inc ax
	dec si
	jne DebljePoyPetlja 	
	pop ax
	pop dx
	jmp DebelaLinKraj
DebljePox:
	xchg si,ax
	xor ax,ax
	mov al,debljina
	xchg si,ax
	mov di,si
	shr si,1
	push cx
	push bx
	sub cx,si
	sub bx,si
	mov si,di
DebljePoxPetlja:call linija
	inc cx
	inc bx
	dec si
	jne DebljePoxPetlja 	
	pop bx
	pop cx
DebelaLinKraj:
	pop di
	pop si
	ret
DebelaLinija endp
;------ K R A J  L I N I J E -------
; CRTANJE TACKE DIREKTNO U VIDEO MEMORIJI
; X = CX, Y = DX
put proc near
		cmp cx,xmin
        jl krjp
        cmp cx,xmax
        jg krjp
        cmp dx,ymin
        jl krjp
        cmp dx,ymax
        jg krjp
        push ax
        push bx
        push cx
        push dx
        call izracunaj
        mov bx,ax
    ;    cmp izlazbafer,0
    ;    je putekran
    ;    call putbafer
    ;    jmp krajputpre
putekran:mov dx,GRAPHICS_ADRESS_REGISTER;
        mov al,8;BIT MASK REGISTER
        mov ah,ch
        out dx,ax
        mov es,video
        mov ah,es:[bx]
        mov es:[bx],ch ;upis tacke
        mov ah,255 ;da se bit maska vrati na 255
        out dx,ax
krajputpre:pop dx
        pop cx
        pop bx
        pop ax
krjp:   ret
put endp
;KRAJ CRTANJA TACKE U VIDEO MEMORIJI
putbafer proc near
		push ax
		push es
		mov al,boja
        mov es,baferseg1
	;	call baferugasupal
		mov es,baferseg2
	;	call baferugasupal
		mov es,baferseg3
	;	call baferugasupal
		mov es,baferseg4
	;	call baferugasupal
		pop es
		pop ax
		ret
putbafer endp
baferugasupal proc near
        shr al,1
		jnc baferugas1
        or es:[bx],ch
        jmp baferdalje1
baferugas1:not ch
        and es:[bx],ch
        not ch
baferdalje1:
		ret
baferugasupal endp	
;----------------------
;izracunava adresu i bit u video memoriji
;ulaz cx=x dx=y izlaz ax=offset ch=bit
izracunaj proc near
		push dx
		mov ax,80
        mul dx
        mov dx,cx
        shr dx,1
        shr dx,1
        shr dx,1
        add ax,dx
        and cl,7
        mov ch,80h
        shr ch,cl
		pop dx
		ret
izracunaj endp

program ends

end