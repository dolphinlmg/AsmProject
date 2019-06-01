;------------------------------------------------;
;
; Inha University 
; Computer Science & Engennering
; 12181647 Lee Minkyu 
;
; 2019.05.28
;
;------------------------------------------------;

include irvine32.inc

position struct
	x byte 0
	y byte 0
position ends

.data
	BufferInfo CONSOLE_SCREEN_BUFFER_INFO <>
	wallBlock byte "в╠", 00h				; map block
	filledBlock BYTE "бс",00h			; tetris block
	noBlock byte "  ", 00h				; blank
	tmpWallSize byte 0					; use when draw map
	mapSize position <14, 25>			; width, height of map
	nextBlockPos position <22*2,10>		; position to draw next block
	infoPos position <20*2, 1>			; position to write info
	scorePos position <20*2, 6>			; position to write score
	blockPos position <>
	arrPos position <>					; use when save in arr-map
	tmpBlockPos position <>				; temporary position to draw next block
	tmpBlockIndex byte ?				; temporary index of next block
	eraseBlock byte 0					; printBlock erase that block when eraseBlock is 1
	eraseBlockInMap byte 0				; drawInMap erase when this var is 1
	setBlockAsWall byte 0				; set block as wall in map when set 1
	scoreStr byte "Score: ", 00h
	infoStr1 byte "Use ASD to move", 00h
	infoStr2 byte "Use Space bar to rotate", 00h
	infoStr3 byte "Press Any Key to Start", 00h
	infoStr4 byte "Next Block:", 00h
	currentBlockIndex byte ?				; index of current block: 0 ~ 23
	nextBlockIndex byte -1					; index of next block 
	downFlag byte ?							; go down every downFlag * 100ms 
	landFlag byte 0							; if block stop landFlag set to 1
	startFlag byte 0						; start game when startFlag is 1
	score byte ?
	curLine byte ?							; line to check

	blocks  byte 1,0,0,0, 1,1,1,0, 0,0,0,0, 0,0,0,0			; 0th
			byte 1,1,0,0, 1,0,0,0, 1,0,0,0, 0,0,0,0			
			byte 1,1,1,0, 0,0,1,0, 0,0,0,0, 0,0,0,0			
			byte 0,1,0,0, 0,1,0,0, 1,1,0,0, 0,0,0,0			
			byte 1,1,0,0, 1,1,0,0, 0,0,0,0, 0,0,0,0			; 1st
			byte 1,1,0,0, 1,1,0,0, 0,0,0,0, 0,0,0,0
			byte 1,1,0,0, 1,1,0,0, 0,0,0,0, 0,0,0,0
			byte 1,1,0,0, 1,1,0,0, 0,0,0,0, 0,0,0,0			
			byte 1,1,1,1, 0,0,0,0, 0,0,0,0, 0,0,0,0			; 2nd
			byte 1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0
			byte 1,1,1,1, 0,0,0,0, 0,0,0,0, 0,0,0,0
			byte 1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0			
			byte 0,0,1,0, 1,1,1,0, 0,0,0,0, 0,0,0,0			; 3rd
			byte 1,0,0,0, 1,0,0,0, 1,1,0,0, 0,0,0,0	
			byte 1,1,1,0, 1,0,0,0, 0,0,0,0, 0,0,0,0	
			byte 1,1,0,0, 0,1,0,0, 0,1,0,0, 0,0,0,0			
			byte 1,1,0,0, 0,1,1,0, 0,0,0,0, 0,0,0,0			; 4th
			byte 0,1,0,0, 1,1,0,0, 1,0,0,0, 0,0,0,0
			byte 1,1,0,0, 0,1,1,0, 0,0,0,0, 0,0,0,0
			byte 0,1,0,0, 1,1,0,0, 1,0,0,0, 0,0,0,0
			byte 0,1,1,0, 1,1,0,0, 0,0,0,0, 0,0,0,0			; 5th
			byte 1,0,0,0, 1,1,0,0, 0,1,0,0, 0,0,0,0
			byte 0,1,1,0, 1,1,0,0, 0,0,0,0, 0,0,0,0
			byte 1,0,0,0, 1,1,0,0, 0,1,0,0, 0,0,0,0
			byte 0,1,0,0, 1,1,1,0, 0,0,0,0, 0,0,0,0			; 6th
			byte 1,0,0,0, 1,1,0,0, 1,0,0,0, 0,0,0,0
			byte 1,1,1,0, 0,1,0,0, 0,0,0,0, 0,0,0,0
			byte 0,1,0,0, 1,1,0,0, 0,1,0,0, 0,0,0,0
			
	map byte 14 dup(25 dup(0))								; map info 2: current block, 1: wall, 0: none

.code
	main proc
		call printWall				; print wall
		call printDashBoard	
		call createNextBlock		; create first block
		call initMap
		call printScore
	init:
		call readKey
		jnz Start
		jmp init
	Start:							; create next block ~ go down ~ stop
		mov landFlag, 0
		mov eax, 10
		call delay
		call setCurrentBlockFromNext
		call createNextBlock		; create next block / print to dashboard
		call displayCurrentBlock	; print current block (init)
		call drawInMap				; save current block to map
		L1:								
			mov downFlag, 0
			call isLanded
			cmp landFlag, 0
			jne Stop
			mov eax, 10
			call delay
			call goDown
		D1:
			call readkey
			jz D2							
			call blockControl
		D2:
			cmp downFlag, 4						; go down every 400ms
			je L1
			add downFlag, 1
			mov eax, 100
			call delay
			jmp D1
		Stop:
			mov setBlockAsWall, 1
			call drawInMap
			call isGetScore
			call isFinished
			cmp eax, 1
			je fin
		jmp Start
	fin:
		call waitmsg
		
		exit
	main endp

	;-------------------------------------------------;
	;
	; isLanded: when block can't go down, set landFlag 1
	; uses landFlag
	;
	;-------------------------------------------------;
	isLanded proc
		mov eax, 3
		call canMove
		.if eax != 0
			mov landFlag, 1
		.endif
		ret
	isLanded endp

	;-------------------------------------------------;
	;
	; printMapByData: print in stdout by map 
	; uses score, scorePos
	;
	;-------------------------------------------------;
	printMapByData proc uses eax ebx ecx edx
		mov ecx, 0
		.while ecx < 24
			mov ebx, 1
			.while ebx < 13			; ebx = x, ecx = y
				mov al, bl
				mov ah, cl
				call getOffsetXY
					mov dl, bl
					mov dh, cl
					shl dl, 1
					call gotoxy
				.if map[eax] == 1
					mov edx, offset filledBlock	
				.else
					mov edx, offset noBlock
				.endif
				call writestring
				inc ebx
			.endw
			inc ecx
		.endw
		ret
	printMapByData endp

	;-------------------------------------------------;
	;
	; printScore: print score 
	; uses score, scorePos
	;
	;-------------------------------------------------;
	printScore proc uses eax edx
		mov dl, scorePos.x
		add dl, 7
		mov dh, scorePos.y
		call gotoxy
		movzx eax, score
		call writedec
		ret
	printScore endp


	;-------------------------------------------------;
	;
	; eraseLine: erase line
	; uses map, curLine
	; please set curLine before call me
	;
	;-------------------------------------------------;
	eraseLine proc uses eax ebx ecx edx
		movzx ecx, curLine
		dec ecx
		.while ecx >= 0			; ecx = y, ebx = x
			mov ebx, 1
			.while ebx < 13
				mov al, bl
				mov ah, cl
				call getOffsetXY
				movzx edx, map[eax]
				mov map[eax+14], dl
				inc ebx
			.endw
			cmp ecx, 0
			je exit1
			dec ecx
		.endw
		exit1:
		call printMapByData
		ret
	eraseLine endp

	;-------------------------------------------------;
	;
	; isGetScore: if there is cleared line, add score, erase line
	; uses map, curLine
	;
	;
	;-------------------------------------------------;
	isGetScore proc	uses ecx
		mov ecx, 23
		.while ecx >= 0
			mov curLine, cl
			call isLineCleared
			.if eax == 1
				call eraseLine
				add score, 10
				call printScore
				inc ecx				; if curLine is cleared, erase curLine and re-confirm curLine
			.endif
			cmp ecx, 0
			je exit1
			dec ecx
		.endw
		exit1:
		ret
	isGetScore endp

	;-------------------------------------------------;
	;
	; isLineCleared: if curLine is cleared, return 1 by eax
	; uses map, curLine
	; please set curLine before call me
	;
	;-------------------------------------------------;
	isLineCleared proc uses ecx esi
		mov al, 1
		mov ah, curLine
		call getOffsetXY
		mov esi, eax
		mov ecx, 0
		.while ecx < 13
			.if map[esi] == 0
				mov eax, 0
				ret
			.endif
			inc esi
			inc ecx
		.endw
		mov eax, 1
		ret
	isLineCleared endp


	;-------------------------------------------------;
	;
	; isFinished: if game is finished, return 1 by eax
	; uses map
	;
	;-------------------------------------------------;
	isFinished proc
		mov eax, 1
		.while eax < 13
			.if map[eax] == 1
				mov eax, 1
				jmp exit1
			.endif
			inc eax
		.endw
		mov eax, 0
	exit1:
		ret
	isFinished endp

	;-------------------------------------------------;
	;
	; setCurrentBlockFromNext: set currentBlock from next block
	; uses currentBlockIndex, nextBlockIndex
	; uses eax, ebx, ecx
	; 
	;
	;-------------------------------------------------;
	setCurrentBlockFromNext proc uses eax
		movzx eax, nextBlockIndex
		mov currentBlockIndex, al
		ret
	setCurrentBlockFromNext endp

	;-------------------------------------------------;
	;
	; getOffsetXY: returns offset of xy in map
	; uses eax, ebx, ecx
	; please give me x, y in al, ah
	; I'll give you offset by eax
	;
	;-------------------------------------------------;
	getOffsetXY proc uses ebx ecx
		movzx ebx, al			; x
		movzx ecx, ah			; y
		mov eax, 14
		mul ecx
		add eax, ebx
		ret
	getOffsetXY endp

	;-------------------------------------------------;
	;
	; canMove : return 0 by eax when can move
	; uses currentBlockIndex, blockPos, map, blocks
	; uses eax
	; please give me where to move by eax
	; 
	; 1: E, 2: W, 3: S, 0: rotate
	;
	;-------------------------------------------------;
	canMove proc uses ebx ecx esi
		; nextPosition in map is not 1
		; 2 is ok
		cmp eax, 0
		je L0
		cmp eax, 1
		je L1
		cmp eax,2
		je L2
		cmp eax, 3
		je L3
		jmp exit1
		
	L0:
		movzx ebx, currentBlockIndex
		and ebx, 3						; ebx = cri % 4
		movzx eax, currentBlockIndex
		sub eax, ebx					; tmp == eax = cri - cri % 4
		movzx ebx, currentBlockIndex
		add ebx, 1
		and ebx, 3
		add eax, ebx					; tmp == eax += (cri + 1) % 4
		mov tmpBlockIndex, al
		mov al, blockPos.x
		shr al, 1
		mov ah, blockPos.y
		mov tmpBlockPos.x, al
		mov tmpBlockPos.y, ah
		jmp T1
	L1:
		movzx eax, currentBlockIndex
		mov tmpBlockIndex, al
		mov al, blockPos.x
		mov ah, blockPos.y
		shr al, 1
		inc al
		mov tmpBlockPos.x, al
		mov tmpBlockPos.y, ah
		jmp T1
	L2:
		movzx eax, currentBlockIndex
		mov tmpBlockIndex, al
		mov al, blockPos.x
		mov ah, blockPos.y
		shr al, 1
		dec al
		mov tmpBlockPos.x, al
		mov tmpBlockPos.y, ah
		jmp T1
	L3:
		movzx eax, currentBlockIndex
		mov tmpBlockIndex, al
		mov al, blockPos.x
		mov ah, blockPos.y
		shr al, 1
		inc ah
		mov tmpBlockPos.x, al
		mov tmpBlockPos.y, ah
		jmp T1

	T1:
		movzx esi, tmpBlockIndex
		shl esi, 4
		mov ecx, 0
		.while ecx < 4
			mov ebx, 0
			.while ebx < 4			; bl = x, cl = y
				mov al, bl
				mov ah, cl
				add al, tmpBlockPos.x
				add ah, tmpBlockPos.y
				call getOffsetXY
				.if blocks[esi] == 1 && map[eax] == 1
					mov eax, 1
					jmp exit1
				.endif
				inc ebx
				inc esi
			.endw
			inc ecx
		.endw
		mov eax, 0
		jmp exit1
		
		exit1:
		ret
	canMove endp


	;-------------------------------------------------;
	;
	; drawInMap		: draw current block in map arr
	; uses currentBlockIndex, blocks, blockPos, map, arrPos
	; uses eax, ebx, ecx
	;
	;-------------------------------------------------;
	drawInMap proc uses esi eax ebx ecx
		movzx esi, currentBlockIndex
		shl esi, 4
		movzx eax, blockPos.x
		shr eax, 1
		mov arrPos.x, al
		movzx eax, blockPos.y
		mov arrPos.y, al
		mov ecx, 0
		.while ecx < 4
			mov ebx, 0
			.while ebx < 4			; bl = x, cl = y
				mov al, arrPos.x
				mov ah, arrPos.y
				add al, bl
				add ah, cl
				call getOffsetXY
				.if blocks[esi] == 1 && eraseBlockInMap == 0 && setBlockAsWall == 0
					mov map[eax], 2
				.elseif blocks[esi] == 1 && eraseBlockInMap == 0 && setBlockAsWall == 1
					mov map[eax], 1
				.elseif blocks[esi] == 1 && eraseBlockInMap == 1
					mov map[eax], 0
				.endif
				inc ebx
				inc esi
			.endw
			inc ecx
		.endw
		mov eraseBlockInMap, 0
		mov setBlockAsWall, 0
		ret
	drawInMap endp

	;-------------------------------------------------;
	;
	; goDown
	; uses currentBlockIndex, blockPos, eraseBlock
	; uses eax, ebx, ecx
	;
	;-------------------------------------------------;
	goDown proc uses eax ecx
		; if block can move
		; erase before block
		; blockPos.y += 1
		; draw new block

		mov eax, 3
		call canMove
		.if eax != 0
			jmp exit1
		.endif		

		mov eraseBlock, 1
		movzx eax, currentBlockIndex
		call printTetris

		mov eraseBlockInMap, 1
		call drawInMap

		movzx eax, blockPos.y
		inc eax
		mov blockPos.y, al
		movzx eax, currentBlockIndex
		call printTetris
		call drawInMap
	exit1:
		ret
	goDown endp

	;-------------------------------------------------;
	;
	; blockControl
	; uses currentBlockIndex, eraseBlock, blockPos
	; uses eax, ebx, ecx
	; please call readkey before call me
	;
	;-------------------------------------------------;
	blockControl proc uses eax ecx
		cmp al, 'd'
		je right
		cmp al, 'a'
		je left
		cmp al, 's'
		je down
		cmp al, 20h	; space bar
		je spaceBar
		jmp exit1

		right:
			mov eax, 1
			call canMove
			.if eax != 0
				jmp exit1
			.endif
			mov eraseBlock, 1
			movzx eax, currentBlockIndex
			call printTetris
			mov eraseBlockInMap, 1
			call drawInMap
			movzx eax, blockPos.x
			add eax, 2
			mov blockPos.x, al
			movzx eax, currentBlockIndex
			call printTetris
			call drawInMap
		jmp exit1

		left:
			mov eax, 2
			call canMove
			.if eax != 0
				jmp exit1
			.endif
			mov eraseBlock, 1
			movzx eax, currentBlockIndex
			call printTetris
			mov eraseBlockInMap, 1
			call drawInMap
			movzx eax, blockPos.x
			sub eax, 2
			mov blockPos.x, al
			movzx eax, currentBlockIndex
			call printTetris
			call drawInMap
		jmp exit1

		down:
			mov eax, 3
			call canMove
			.if eax != 0
				jmp exit1
			.endif
			mov eraseBlock, 1
			movzx eax, currentBlockIndex
			call printTetris
			mov eraseBlockInMap, 1
			call drawInMap
			movzx eax, blockPos.y
			inc eax
			mov blockPos.y, al
			movzx eax, currentBlockIndex
			call printTetris
			call drawInMap
		jmp exit1

		spaceBar:
			mov eax, 0
			call canMove
			.if eax != 0
				jmp exit1
			.endif
			call rotateBlock
		jmp exit1

		exit1:
		ret
	blockControl endp

	;-------------------------------------------------;
	;
	; rotateBlock
	; uses currentBlockIndex, blocks
	; uses eax, ebx, ecx
	; usage: call rotateBlock
	; 
	;-------------------------------------------------;
	rotateBlock proc uses eax ebx ecx
		; tmp = cri - cri % 4
		; tmp += (cri + 1) % 4
		; erase tetris
		; cir = tmp
		; printTetris
		; a % b == a & (b - 1)
		movzx ebx, currentBlockIndex
		and ebx, 3						; ebx = cri % 4
		movzx eax, currentBlockIndex
		sub eax, ebx					; tmp == eax = cri - cri % 4
		movzx ebx, currentBlockIndex
		add ebx, 1
		and ebx, 3
		add eax, ebx					; tmp == eax += (cri + 1) % 4
		mov ebx, eax					; ebx = tmp == eax
		mov eraseBlock, 1
		movzx eax, currentBlockIndex
		call printTetris
		mov eraseBlockInMap, 1
		call drawInMap
		mov currentBlockIndex, bl
		movzx eax, currentBlockIndex
		call printTetris
		call drawInMap
		ret
	rotateBlock endp

	;-------------------------------------------------;
	;
	; initMap
	; uses map, mapSize
	; uses eax, ecx
	;
	;-------------------------------------------------;
	initMap proc uses eax ebx ecx
		mov eax, 0
		.while al < 25		; al == y
			mov ebx, 0
			.while bl < 14		; bl == x
				.if bl == 0 || bl == 13 || al ==24
					push eax			; map[bl][al]
					mul mapSize.x		; al * 14
					add eax, ebx
					mov map[eax], 1
					pop eax
				.endif
				inc bl
			.endw
			inc al
		.endw
		ret
	initMap endp

	;-------------------------------------------------;
	;
	; displayCurrentBlock
	; uses currentBlockIndex, mapSize, blockPos
	; uses eax
	; print when nextblock is init
	;
	;-------------------------------------------------;
	displayCurrentBlock proc uses eax ecx
		movzx eax, mapSize.x
		shr eax, 1
		add eax, 3
		mov blockPos.x, al
		mov blockPos.y, 0
		movzx eax, currentBlockIndex
		call printTetris
		ret
	displayCurrentBlock endp

	;-------------------------------------------------;
	;
	; createCurrentBlock
	; uses currentBlockIndex
	; uses eax
	;
	;-------------------------------------------------;
	createCurrentBlock proc uses eax ecx
		mov eax, 8
		call delay
		call randomize
		mov eax, 28
		call randomRange
		mov currentBlockIndex, al
		ret
	createCurrentBlock endp

	;-------------------------------------------------;
	;
	; createNextBlock
	; uses nextBlockPos, blockPos, nextBlockIndex, eraseBlock
	; uses eax
	;
	;-------------------------------------------------;
	createNextBlock proc uses eax ecx
		; before start we should erase block
		.if nextBlockIndex != -1
			mov al, nextBlockPos.x
			mov blockPos.x, al
			mov al, nextBlockPos.y
			mov blockPos.y, al
			mov eraseBlock, 1
			movzx eax, nextBlockIndex
			call printTetris
		.endif
		call randomize
		mov eax, 28
		call randomRange
		mov nextBlockIndex, al
		mov al, nextBlockPos.x
		mov blockPos.x, al
		mov al, nextBlockPos.y
		mov blockPos.y, al
		movzx eax, nextBlockIndex
		call printTetris
		ret
	createNextBlock endp

	;-------------------------------------------------;
	;
	; getCursorPos
	; uses BufferInfo
	; returns X, Y in al, ah
	;
	;-------------------------------------------------;
	getCursorPos proc uses ecx
		invoke GetStdHandle, STD_OUTPUT_HANDLE
		invoke GetConsoleScreenBufferInfo, eax, ADDR BufferInfo
		mov eax, 0
		mov al, byte ptr BufferInfo.dwCursorPosition.X 
		mov ah, byte ptr BufferInfo.dwCursorPosition.Y 
		ret
	getCursorPos endp

	;-------------------------------------------------;
	;
	; printTetris
	; uses filledBlock, blocks, noBlock, eraseBlock
	; uses edx
	; please give pos in blockPos
	;			  numbers of block by eax
	;
	; usage:
	; mov eax, currentBlockIndex
	; call printBlock
	;
	;-------------------------------------------------;
	printTetris proc uses edx ecx
		mov dl, blockPos.x
		mov dh, blockPos.y
		call gotoxy
		mov ecx, 4
		mov esi, eax		; change later
		shl esi, 4			; esi *= 16
	L1:
		push ecx
		mov ecx, 4
		L2:
			.if blocks[esi] == 1
				.if eraseBlock == 1
					mov edx, offset noBlock
				.else
					mov edx, offset filledBlock
				.endif
				call writestring
			.else
				call getCursorPos
				add al, 2
				mov dx, ax
				call gotoxy
			.endif
			inc esi
			dec ecx
			jne L2
			pop ecx
		mov eax, 4
		sub eax, ecx
		inc eax
		mov dl, blockPos.x
		mov dh, blockPos.y
		add dh, al
		call gotoxy
		dec ecx
		jne L1
		mov eraseBlock, 0
		ret
	printTetris endp

	;-------------------------------------------------;
	;
	; printDashBoard
	; uses wallBlock, nextBlock Pos, infoPos
	; uses eax edx
	;
	;-------------------------------------------------;
	printDashBoard proc uses eax ecx edx
		mov dl, infoPos.x
		mov dh, infoPos.y
		call gotoxy
		mov edx, offset infoStr1
		call writestring

		mov dl, infoPos.x
		mov dh, infoPos.y
		add dh, 1
		call gotoxy
		mov edx, offset infoStr2
		call writeString

		mov eax, black + (lightgray * 16)
		call setTextColor
		mov dl, infoPos.x
		mov dh, infoPos.y
		add dh, 3
		call gotoxy
		mov edx, offset infoStr3
		call writeString
		mov eax, lightgray + (black * 16)
		call setTextColor

		mov dl, scorePos.x
		mov dh, scorePos.y
		call gotoxy
		mov edx, offset scoreStr
		call writestring
		
		mov dl, scorePos.x
		mov dh, scorePos.y
		add dh, 2
		call gotoxy
		mov edx, offset infoStr4
		call writestring

		ret
	printDashBoard endp

	;-------------------------------------------------;
	;
	; printBlock 
	; uses wallBlock
	; uses edx
	; please give pos in dh, dl
	;
	;-------------------------------------------------;
	printBlock proc uses ecx
		call gotoxy
		push edx
		mov edx, offset wallBlock
		call writestring
		pop edx
		ret
	printBlock endp

	;-------------------------------------------------;
	;
	; printWall 
	; uses mapSize.y, mapSize.x
	; uses edx, eax, ecx
	;
	;-------------------------------------------------;
	printWall proc uses eax ecx edx
		movzx ecx, mapSize.y
	L1:							; left
		mov dh, tmpWallSize
		mov dl, 0
		call printBlock
		add tmpWallSize, 1
		loop L1
		mov tmpWallSize, 0

		movzx ecx, mapSize.y
	L2:								; right
		mov dl, mapSize.x
		mov eax, 2
		sub dl, 1
		mul dl
		mov dl, al
		mov dh, tmpWallSize
		call printBlock
		add tmpWallSize, 1
		loop L2
		mov tmpWallSize, 0

		movzx ecx, mapSize.x
	L3:									; bottom
		mov dh, mapSize.y
		sub dh, 1
		mov dl, tmpWallSize
		call printBlock
		add tmpWallSize, 2
		loop L3
		mov tmpWallSize, 0
		ret
	printWall endp
end main