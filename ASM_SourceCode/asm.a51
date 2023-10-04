;---------------------------------------------------------------------------------------------
	;Variables
		; R0 mode
		; R1 phase
		; R2 10ms_counter
		; R3 second
		; R4 red_time
		; R5 green_time
		; R7 tmp
		normal_red_time 	equ 10
		normal_green_time 	equ 20
		peak_red_time 		equ 20
		peak_green_time 	equ 40
		yellow_time 		equ 3
		red_led_1 			equ 0b0h
		red_led_2 			equ 0b1h
		yellow_led_1 		equ 0b4h
		yellow_led_2 		equ 0b5h
		green_led_1 		equ 0b6h
		green_led_2 		equ 0b7h
		stop_led_1 			equ 80h
		stop_led_2 			equ 81h
		walk_led_1 			equ 82h
		walk_led_2 			equ 83h
		;org 	500h
		;first_red:	db 10
		;first_green:	db 20
		;second_red:	db 10
		;second_green:	db 20
;---------------------------------------------------------------------------------------------
	; Reset and Interrupt vectors
		; Reset Vector
	org 0000h
		ljmp Reset_ISR
		; External Interrupt 0 Vector
	org	0003h
		ljmp INT0_ISR
		; Timer0 Interrupt Vector
	org	000bh
		ljmp Timer0_ISR
		; External Interrupt 1 Vector
	org	0013h
		ljmp INT1_ISR
;---------------------------------------------------------------------------------------------
	; Code
	org	0030h
		; Main
	Start:	
		mov 	IE, #87h						; Enable external interrupt 0, Timer 0 interrupt and external interrupt 1
		mov 	TMOD, #11h						; Enable mode 1 Timer 0 and mode 1 Timer 1
		mov 	TCON, #05h						; Enable falling-edge trigger for external interrupt 0 and external interrupt 1
		mov 	TH0, #0d8h						; Init
		mov 	TL0, #0ffh						; Timer 0
		setb 	TR0								; Enable Timer 0
		cjne 	r0, #1, Loop		
		lcall 	Phase_Init			 
	Loop:	
		cjne 	r0, #1, Loop
		lcall 	Mode_1
		jmp 	Loop
;---------------------------Mode 1---------------------------
	Mode_1:													
		lcall Phase_Update									
		lcall Phase_Call
	ret
;------------------------------------------------------------
;--------------------Mode 1 Phase Update--------------------- 
	Phase_Update:								; Check and update phase-to-phase
	phase_1_update:
		cjne r1, #1, phase_2_update
		cjne r3, #yellow_time, Phase_Update_exit
		mov r7, #1
		lcall walk_off
		lcall stop_on
		mov r7, #2
		lcall green_off
		lcall yellow_on
		;lcall Phase_Clear
		mov r1, #2
		;lcall Phase_Init
		ljmp exit
	phase_2_update:
		cjne r1, #2, phase_3_update
		cjne r3, #0, Phase_Update_exit
		mov a, r5
		mov r3, a
		mov r7, #1
		lcall red_off
		lcall green_on
		mov r7, #2
		lcall yellow_off
		lcall red_on
		lcall stop_off
		lcall walk_on
		;lcall Phase_Clear
		mov r1, #3
		;lcall Phase_Init
		ljmp exit
	phase_3_update:
		cjne r1, #3, phase_4_update
		cjne r3, #yellow_time, Phase_Update_exit
		mov r7, #1
		lcall green_off
		lcall yellow_on
		mov r7, #2
		lcall walk_off
		lcall stop_on
		;lcall Phase_Clear
		mov r1, #4
		;lcall Phase_Init
		ljmp exit
	phase_4_update:
		cjne r3, #0, Phase_Update_exit
		mov a, r4
		mov r3, a
		mov r7, #1
		lcall yellow_off
		lcall red_on
		lcall stop_off
		lcall walk_on
		mov r7, #2
		lcall red_off
		lcall green_on
		;lcall Phase_Clear
		mov r1, #1
		;lcall Phase_Init
	Phase_Update_exit:
	ret
;------------------------------------------------------------
;---------------------Mode 1 phase call----------------------
	Phase_Call:									; Show 2 modules 7-segment LED
	phase_1_call:
		cjne r1, #1, phase_2_call
		mov a, r3
		lcall Show_Led_1 
		mov a, r3
		subb a, #yellow_time
		lcall Show_Led_2
		ljmp exit
	phase_2_call:
		cjne r1, #2, phase_3_call
		mov a, r3
		lcall Show_Led_1
		mov a, r3
		lcall Show_Led_2
		ljmp exit
	phase_3_call:
		cjne r1, #3, phase_4_call
		mov a, r3
		subb a, #yellow_time
		lcall Show_Led_1
		mov a, r3
		lcall Show_Led_2
		ljmp exit
	phase_4_call:
		mov a, r3
		lcall Show_Led_1
		mov a, r3
		lcall Show_Led_2
	ret    
;------------------------------------------------------------
;---------------Show 1st module 7-segment LED---------------- 
	Show_Led_1:									; Show 1st module 7-segment LED
		mov b, #10
		div ab
		mov P1, a
		setb P1.4
		lcall delay_10ms
		mov P1, b
		setb P1.5
		lcall delay_10ms
		clr P1.5
	ret   
;------------------------------------------------------------
;---------------Show 2nd module 7-segment LED---------------- 
	Show_Led_2:									; Show 2nd module 7-segment LED
		mov b, #10
		div ab
		mov P2, a
		setb P2.4
		lcall delay_10ms
		mov P2, b
		setb P2.5
		lcall delay_10ms
		clr P2.5
	ret
;------------------------------------------------------------
;---------------------Mode 1 Phase Init---------------------- 
	Phase_Init:									; Turn on leds current phase use 
	phase_1_init:
		cjne r1, #1, phase_2_init
		mov r7, #1
		lcall red_on
		lcall walk_on
		mov r7, #2
		lcall green_on
		lcall stop_on
		ljmp exit
	phase_2_init:
		cjne r1, #2, phase_3_init
		mov r7, #1
		lcall red_on
		lcall stop_on
		mov r7, #2
		lcall yellow_on
		lcall stop_on
		ljmp exit
	phase_3_init:      
		cjne r1, #3, phase_4_init
		mov r7, #1
		lcall green_on
		lcall stop_on
		mov r7, #2
		lcall red_on
		lcall walk_on
		ljmp exit
	phase_4_init:
		mov r7, #1
		lcall yellow_on
		lcall stop_on
		mov r7, #2
		lcall red_on
		lcall stop_on
	ret
;------------------------------------------------------------
;---------------------Mode 1 Phase Clear---------------------
	Phase_Clear:								; Turn off leds current phase use 
	phase_1_clear:
		mov P1, #0
		mov P2, #0
		cjne r1, #1, phase_2_clear
		mov r7, #1
		lcall red_off
		lcall walk_off
		mov r7, #2
		lcall green_off
		lcall stop_off
		ljmp exit
	phase_2_clear:
		cjne r1, #2, phase_3_clear
		mov r7, #1
		lcall red_off
		lcall stop_off
		mov r7, #2
		lcall yellow_off
		lcall stop_off
		ljmp exit
	phase_3_clear:
		cjne r1, #3, phase_4_clear
		mov r7, #1
		lcall green_off
		lcall stop_off
		mov r7, #2
		lcall red_off
		lcall walk_off
		ljmp exit
	phase_4_clear:
		mov r7, #1								
		lcall yellow_off							
		lcall stop_off							
		mov r7, #2
		lcall red_off							
		lcall stop_off							
	ret
;------------------------------------------------------------
;------------------------Mode 2 Clear------------------------
	Mode_2_Clear:
		mov r7, #1								; Turn
		lcall yellow_off						; off
		mov r7, #2								; 2 
		lcall yellow_off						; yellow leds
	ret
;------------------------------------------------------------
;-------------------------Delay 10ms-------------------------
	delay_10ms:
		mov TH1, #0d8h							; Init
		mov TL1, #0f0h							; Timer 1
		setb TR1								; Enable Timer 1
		jnb TR1, $								; while ...
		clr TR1									; Disable Timer 1
		clr TF1									; Clear flag
	ret
;------------------------------------------------------------
;------------Interrupt Service Routine for Reset-------------
	Reset_ISR:
		mov r0, #1								; Mode = 1
		mov r1, #1								; Phase = 1
		mov r2, #0								; 10ms_counter = 0
		mov r3, #normal_red_time				; Set second
		mov r4, #normal_red_time				; Set red_time
		mov r5, #normal_green_time				; Set green_time
		ljmp Start
	reti
;------------------------------------------------------------
;-----Interrupt Service Routine for External Interrupt 0-----
	INT0_ISR:
		mov r2, #0								; Reset 10ms_counter
		cjne r0, #1, mode_2_turn
	mode_1_turn:
		lcall Phase_Clear						; Turn off leds
		mov r0, #2								; Turn to mode 2
		ljmp exiti
	mode_2_turn:
		mov r0, #1								; Turn to mode 1
		mov r1, #1								; Reset to phase 1
		mov a, r4								; Set
		mov r3, a								; second = red_time
		lcall Mode_2_Clear						; Turn off 2 yellow leds
		lcall Phase_Init						; Turn on leds phase 1 use
	reti	
;------------------------------------------------------------
;-----Interrupt Service Routine for External Interrupt 1-----
	INT1_ISR:
		cjne r4, #normal_red_time, turn_to_normal
	turn_to_peak:
		mov r4, #peak_red_time
		mov r5, #peak_green_time
		ljmp exiti
	turn_to_normal:      
		mov r4, #normal_red_time
		mov r5, #normal_green_time
	reti
;------------------------------------------------------------
;------Interrupt Service Routine for Timer 0 Interrupt-------
	Timer0_ISR:
		clr TR0									; Disable Timer 0
		inc r2									; Inc 10ms_counter		
		cjne r0, #1, if_mode_2					; Jump if mode != 1
	if_mode_1:
		cjne r2, #50, inc_second				; Jump if 10ms_counter != 50 (0.5s)
		mov a, #yellow_time						
		add a, #3								
		mov b, r3								
		clr CY									; Clear CY
		cjne a, b, check_greater_smaller_1		; Jump if second != yellow_time + 3
		jmp oke
	check_greater_smaller_1:
		jb CY, not_oke							; Jump if second > yellow_time + 3
	oke:
		mov a, #yellow_time						
		mov b, r3
		clr CY									; Clear CY
		cjne a, b, check_greater_smaller_2		; Jump if second != yellow_time
		jmp oke_tiep	
	check_greater_smaller_2:
		jnb CY, not_oke							; Jump if second < yellow_time + 3
	oke_tiep:
		cjne r1, #1, if_phase_3					; Jump if phase != 1
	if_phase_1:
		mov r7, #1
		lcall walk_on
		ljmp set_timer0
	if_phase_3:
		cjne r1, #3, not_oke					; Jump if phase != 3
		mov r7, #2
		lcall walk_on
	not_oke:    
		ljmp set_timer0
	inc_second:
		cjne r2, #100, set_timer0				; Jump if 10ms_counter
		mov r2, #0								; Reset 10ms_counter
		dec r3									; Dec second
		mov a, #yellow_time
		add a, #3
		mov b, r3
		clr CY									; Clear CY
		cjne a, b, check_greater_smaller_3		; Jump if second != yellow_time + 3
		jmp oke_2
	check_greater_smaller_3:
		jb CY, not_oke_2						; Jump if second > yellow_time + 3
	oke_2:
		mov a, #yellow_time
		mov b, r3
		clr CY
		cjne a, b, check_greater_smaller_4		; Jump if second != yellow_time
		jmp oke_tiep_2
	check_greater_smaller_4:
		jnb CY, not_oke_2						; Jump if second < yellow_time
	oke_tiep_2:
		cjne r1, #1, if_phase_3_2				; Jump if phase != 1
	if_phase_1_2:
		mov r7, #1
		lcall walk_off
		ljmp set_timer0
	if_phase_3_2:
		cjne r1, #3, not_oke_2					; Jump if phase != 3
		mov r7, #2
		lcall walk_off
	not_oke_2:
		ljmp set_timer0
	if_mode_2:
		cjne r2, #50, set_timer0
		mov r2, #0								; Reset 10ms_counter
		mov r7, #1								; Toggle
		lcall yellow_toggle						; 2
		mov r7, #2								; yellow
		lcall yellow_toggle						; led
	set_timer0:
		mov TH0, #0d8h							; Reset
		mov TL0, #0ffh							; Timer 0
		setb TR0								; Enable Timer 0
	reti
;------------------------------------------------------------
;-------------------------Red Led On-------------------------
	red_on:
		cjne r7, #1, red_2_on
	red_1_on:      
		clr red_led_1
		ljmp exit
	red_2_on:
		clr red_led_2
	ret
;------------------------------------------------------------
;-------------------------Red Led Off------------------------
	red_off:
		cjne r7, #1, red_2_off
	red_1_off:
		setb red_led_1
		ljmp exit
	red_2_off:
		setb red_led_2
	ret
;------------------------------------------------------------
;------------------------Yellow Led On-----------------------
	yellow_on:
		cjne r7, #1, yellow_2_on
	yellow_1_on:      
		clr yellow_led_1
		ljmp exit
	yellow_2_on:
		clr yellow_led_2
	ret
;------------------------------------------------------------
;------------------------Yellow Led Off----------------------
	yellow_off:
		cjne r7, #1, yellow_2_off
	yellow_1_off:
		setb yellow_led_1
		ljmp exit
	yellow_2_off:
		setb yellow_led_2
	ret
;------------------------------------------------------------
;-----------------------Yellow Led Toggle--------------------
	yellow_toggle:
		cjne r7, #1, yellow_2_toggle
	yellow_1_toggle:
		cpl yellow_led_1
		ljmp exit
	yellow_2_toggle:
		cpl yellow_led_2
	ret
;------------------------------------------------------------
;-------------------------Green Led On-----------------------
	green_on:
		cjne r7, #1, green_2_on
	green_1_on:      
		clr green_led_1
		ljmp exit
	green_2_on:
		clr green_led_2
	ret
;------------------------------------------------------------
;-------------------------Green Led Off----------------------
	green_off:
		cjne r7, #1, green_2_off
	green_1_off:
		setb green_led_1
		ljmp exit
	green_2_off:
		setb green_led_2
	ret
;------------------------------------------------------------
;--------------------------Stop Led On-----------------------
	stop_on:
		cjne r7, #1, stop_2_on
	stop_1_on:      
		clr stop_led_1
		ljmp exit
	stop_2_on:
		clr stop_led_2
	ret
;------------------------------------------------------------
;--------------------------Stop Led Off----------------------
	stop_off:
		cjne r7, #1, stop_2_off
	stop_1_off:
		setb stop_led_1
		ljmp exit
	stop_2_off:
		setb stop_led_2
	ret

;------------------------------------------------------------
;--------------------------Walk Led On-----------------------
	walk_on:
		cjne r7, #1, walk_2_on
	walk_1_on:      
		clr walk_led_1
		ljmp exit
	walk_2_on:
		clr walk_led_2
	ret

;------------------------------------------------------------
;--------------------------Walk Led Off----------------------
	walk_off:
		cjne r7, #1, walk_2_off
	walk_1_off:
		setb walk_led_1
		ljmp exit
	walk_2_off:
		setb walk_led_2
	ret

;------------------------------------------------------------
;-------------------------Walk Led Toggle--------------------
	walk_toggle:
		cjne r7, #1, walk_2_toggle
	walk_1_toggle:
		cpl walk_led_1
		ljmp exit
	walk_2_toggle:
		cpl walk_led_2
	ret
;------------------------------------------------------------
	exit: ret
	exiti: reti
;---------------------------------------------------------------------------------------------
	END