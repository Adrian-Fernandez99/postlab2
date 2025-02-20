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

// Configuración de la pila
.include "M328PDEF.inc"		// Include definitions specific to ATMega328P
.cseg
.org 0x0000
.def COUNTER = R18			// Se define contador

TABLA7SEG: .DB	 0x60, 0xDA, 0xF2, 0x66, 0xB6, 0xBE, 0xE0, 0xFE, 0xF6, 0xEE, 0x3E, 0x4D, 0x76, 0x9E, 0x8E, 0xFC
//					0,    1,    2,    3,    4,    5,    6,    7,    8,    9,    A,    B,    C,    D,    E,    F


// Configurar el MCU
	LDI R16, LOW(RAMEND)
	OUT SPL, R16
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16

SETUP:
// Configurar pines de entrada y salida (DDRx, PORTx, PINx)
// PORTD como entrada con pull-up habilitado
	LDI		R16, 0x00
	OUT		DDRB, R16		// Setear puerto B como entrada
	LDI		R16, 0xFF
	OUT		PORTB, R16		// Habilitar pull-ups en puerto B

// PORTB como salida inicialmente encendido
	LDI		R16, 0xFF
	OUT		DDRD, R16		// Setear puerto D como salida
// PORTC como salida inicialmente encendido
	LDI		R16, 0xFF
	OUT		DDRC, R16		// Setear puerto C como salida

// Configurar Prescaler "Principal"
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16		// Habilitar cambio de PRESCALER
	LDI		R16, 0x04
	STS		CLKPR, R16		// Configurar Prescaler a 16 F_cpu = 1MHz

// Inicializar timer0
	CALL	INIT_TMR0

// Deshabilitar serial (esto apaga los demas LEDs del Arduino)
	LDI		R16, 0x00
	STS		UCSR0B, R16

// Realizar variables

	LDI		R16, 0xFF		// Registro para el clock
	LDI		R17, 0xFF		// Registro de contador (clock)
//	LDI		R18, --			Se aparto el para el contador
	LDI		R19, 0x00		

// Main loop
MAIN_LOOP:
	IN		R16, TIFR0		// Leer registro de interrupción de TIMER0
	SBRS	R16, TOV0		// Salta si el bit 0 est "set" (TOV0 bit)
	RJMP	MAIN_LOOP		// Reiniciar loop
	SBI		TIFR0, TOV0		// Limpiar bandera de "overflow"
	LDI		R16, 158
	OUT		TCNT0, R16		// Volver a cargar valor inicial en TCNT0
	INC		COUNTER
	CPI		COUNTER, 10		// Se necesitan hacer 10 overflows para 1s
	BRNE	MAIN_LOOP
	CLR		COUNTER			// Se reinicia el conteo de overflows
	CALL	SUMA			// Se llama al incremento del contador
	OUT		PORTC, R17		// Sale la señal
	RJMP	MAIN_LOOP		// Regresa al main loop

// NON-Interrupt subroutines
INIT_TMR0:
	LDI		R16, (1 << CS00) | (1 << CS02)
	OUT		TCCR0B, R16		// Setear prescaler del TIMER 0 a 8
	LDI		R16, 158
	OUT		TCNT0, R16		// Cargar valor inicial en TCNT0
	RET

SUMA:						// Función para el incremento del primer contador
	INC		R17				// Se incrementa el valor
	SBRC	R17, 4			// Se observa si tiene más de 4 bits
	LDI		R17, 0x00		// En ese caso es overflow y debe regresar a 0
	RET

DECREMENTO1:
	LDI		R17, 0x1E		// Valor que esperamos para decrementar el contador 1		
	CP		R16, R17		// Comparamos con la entrada
	BRNE	INCREMENTO1		// Si no es el valor que esperamos pasamos a otra función
	CALL	DELAY			// Realizamos antirebote
	IN		R16, PINB		// Leemos otra vez
	CP		R17, R16		// Comparamos
	BRNE	MAIN_LOOP		// Si fue una lectura falsa se regresa al contador
	CALL	BOTON_SUELTO	// Se espera a que se libere el boton
	CALL	RESTA1			// Se realiza el decremento
	RET						// Se regresa al incio

INCREMENTO1:				// La logica es muy parecida
	LDI		R17, 0x1D		// Nuevamente valor que se espera para incrementar
	CP		R16, R17		// Se compara si no es el valro se va a otra función
	BRNE	CONTADOR		// Si es el valor se realiza el mismo sistema de antirebote
	CALL	DELAY
	IN		R16, PINB
	CP		R17, R16
	BRNE	MIAN_LOOP
	CALL	BOTON_SUELTO2	// Siempre se verifica que se suelte el botón
	CALL	SUMA1			// Se realiza el incremento
	RET						// Se regresa al incio
	
SUMA1:						// Función para el incremento del primer contador
	INC		R19				// Se incrementa el valor
	ADIW	Z, 1			// Se incrementa el valor en el puntero de la tabla
	SBRC	R19, 4			// Se observa si tiene más de 4 bits
	CALL	OVER			// En caso de overflow y debe regresar el puntero a 0
	SBRC	R19, 4			// Se observa si tiene más de 4 bits
	LDI		R19, 0x00		// En caso de overflow y debe regresar a 0
	LPM		R22, Z			// Subir valor del puntero a registro
	RET

RESTA1:						// Función para el decremento del primer contador
	DEC		R19				// Se decrementa el valor
	SBIW	Z, 1			// Se decrementa el valor en el puntero de la tabla
	SBRC	R19, 4			// Se observa si tiene más de 4 bits
	CALL	UNDER			// En caso de overflow y debe regresar el puntero a 0
	SBRC	R19, 4			// Se observa si tiene más de 4 bits
	LDI		R19, 0x0F		// En ese caso es underflow y debe regresar a F
	LPM		R22, Z			// Subir valor del puntero a registro
	RET

BOTON_SUELTO:				// Función para esperar a que se suelte el boton
	CALL	DELAY			// Se espera un momento
	IN		R16, PINB		// Se lee otra vez
	SBIS	PINB, 0			// Hasta que el boton deje de estar apachado (bit = 1) se salta
	RJMP	BOTON_SUELTO	// De lo contrario se vuelve a empezar
	RET
		
BOTON_SUELTO2:				// Función para esperar a que se suelte el boton
	CALL	DELAY			// Misma logica, distinto bit verificado
	IN		R16, PINB
	SBIS	PINB, 1
	RJMP	BOTON_SUELTO2
	RET

OVER:
	LDI	ZL, LOW(TABLA7SEG << 1)
	LDI	ZH, HIGH(TABLA7SEG << 1)
	RET

UNDER:
	LDI	ZL, LOW((TABLA7SEG + 15) << 0)
	LDI	ZH, HIGH((TABLA7SEG + 15) << 0)
	RET

// Interrupt routines