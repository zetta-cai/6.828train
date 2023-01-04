/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps
#define TH(n) \
TRAPHANDLER_NOEC(handler##n, n)

#define THE(n) \
TRAPHANDLER(handler##n, n)

.text
#include <kern/trapentry.inc>
/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */


/*
 * Lab 3: Your code here for _alltraps
 *	1.push values to make the stack look like a struct Trapframe 
 *  考虑使用pushal指令，他会很好的和结构体 Trapframe 的布局配合好。
 *	2.load into %ds and %es  GD_KD
 *	3.pushl %esp to pass a pointer to the Trapframe as an argument to trap()
 *	4.call trap (can ever return?)trap
 */
.globl _alltraps
_alltraps:
	push %ds;
	push %es;
	pushal;

	movw 	$(GD_KD), %ax
	movw %ax, %ds
    movw %ax, %es

	pushl %esp
	call trap
trap_spin:
    jmp trap_spin
