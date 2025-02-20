/*

postlab2.asm

Created: 2/19/2025 1:12:50 PM
Author : Adrián Fernández

Descripción:
	Se realiza un contador por medio de un timer
	Este contador tiene que incrementar cada segundo
	Por otro lado debe de haber un contador conectado a un display
	Siempre que este segundo contador sea igual al del timer se reinicia el timer
	Cuando haya un reinicio cambiar de estado una led externa
*/

.include "M328PDEF.inc"		// Include definitions specific to ATMega328P
.cseg
.org 0x0000
.def COUNTER = R20			// Se define contador

// Configuración de la pila
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16

// Configuración del MCU
// Configurar Prescaler "Principal"
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16		// Habilitar cambio de PRESCALER
	LDI		R16, 0x04
	STS		CLKPR, R16		// Configurar Prescaler a 16 F_cpu = 1MHz

// Inicializar timer0
	CALL	INIT_TMR0
// PORTB como salida inicialmente encendido
	LDI		R16, 0xFF
	OUT		DDRD, R16		// Setear puerto D como salida

// Deshabilitar serial (esto apaga los demas LEDs del Arduino)
	LDI		R16, 0x00
	STS		UCSR0B, R16

// Main loop
MAIN_LOOP:
	IN		R16, TIFR0		// Leer registro de interrupción de TIMER0
	SBRS	R16, TOV0		// Salta si el bit 0 est "set" (TOV0 bit)
	RJMP	MAIN_LOOP		// Reiniciar loop
	SBI		TIFR0, TOV0		// Limpiar bandera de "overflow"
	LDI		R16, 158
	OUT		TCNT0, R16		// Volver a cargar valor inicial en TCNT0
	INC		COUNTER
	CPI		COUNTER, 10	// Se necesitan hacer 125 overflows para 100ms
	BRNE	MAIN_LOOP
	CLR		COUNTER			// Se reinicia el conteo de overflows
	CALL	SUMA			// Se llama al incremento del contador
	OUT		PORTD, R19		// Sale la señal
	RJMP	MAIN_LOOP		// Regresa al main loop

// NON-Interrupt subroutines
INIT_TMR0:
	LDI		R16, (1 << CS00) | (1 << CS02)
	OUT		TCCR0B, R16		// Setear prescaler del TIMER 0 a 8
	LDI		R16, 158
	OUT		TCNT0, R16		// Cargar valor inicial en TCNT0
	RET

SUMA:						// Función para el incremento del primer contador
	INC		R19				// Se incrementa el valor
	SBRC	R19, 4			// Se observa si tiene más de 4 bits
	LDI		R19, 0x00		// En ese caso es overflow y debe regresar a 0
	RET

// Interrupt routines