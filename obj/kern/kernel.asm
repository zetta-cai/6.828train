
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 e0 18 00       	mov    $0x18e000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 b0 11 f0       	mov    $0xf011b000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 1b 01 00 00       	call   f0100167 <__x86.get_pc_thunk.bx>
f010004c:	81 c3 d4 cf 08 00    	add    $0x8cfd4,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c0 e0 03 19 f0    	mov    $0xf01903e0,%eax
f0100058:	c7 c2 e0 f4 18 f0    	mov    $0xf018f4e0,%edx
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 86 4e 00 00       	call   f0104eef <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 4e 05 00 00       	call   f01005bc <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 20 83 f7 ff    	lea    -0x87ce0(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 32 3b 00 00       	call   f0103bb4 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 a6 13 00 00       	call   f010142d <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100087:	e8 5f 34 00 00       	call   f01034eb <env_init>
	trap_init();
f010008c:	e8 d6 3b 00 00       	call   f0103c67 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100091:	83 c4 08             	add    $0x8,%esp
f0100094:	6a 00                	push   $0x0
f0100096:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f010009c:	e8 27 36 00 00       	call   f01036c8 <env_create>
	// ENV_CREATE(user_hello, ENV_TYPE_USER);
	ENV_CREATE(user_softint, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a1:	83 c4 04             	add    $0x4,%esp
f01000a4:	c7 c0 2c f7 18 f0    	mov    $0xf018f72c,%eax
f01000aa:	ff 30                	pushl  (%eax)
f01000ac:	e8 07 3a 00 00       	call   f0103ab8 <env_run>

f01000b1 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000b1:	55                   	push   %ebp
f01000b2:	89 e5                	mov    %esp,%ebp
f01000b4:	57                   	push   %edi
f01000b5:	56                   	push   %esi
f01000b6:	53                   	push   %ebx
f01000b7:	83 ec 0c             	sub    $0xc,%esp
f01000ba:	e8 a8 00 00 00       	call   f0100167 <__x86.get_pc_thunk.bx>
f01000bf:	81 c3 61 cf 08 00    	add    $0x8cf61,%ebx
f01000c5:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000c8:	c7 c0 e4 03 19 f0    	mov    $0xf01903e4,%eax
f01000ce:	83 38 00             	cmpl   $0x0,(%eax)
f01000d1:	74 0f                	je     f01000e2 <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 f3 07 00 00       	call   f01008d0 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x22>
	panicstr = fmt;
f01000e2:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000e4:	fa                   	cli    
f01000e5:	fc                   	cld    
	va_start(ap, fmt);
f01000e6:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000e9:	83 ec 04             	sub    $0x4,%esp
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	8d 83 3b 83 f7 ff    	lea    -0x87cc5(%ebx),%eax
f01000f8:	50                   	push   %eax
f01000f9:	e8 b6 3a 00 00       	call   f0103bb4 <cprintf>
	vcprintf(fmt, ap);
f01000fe:	83 c4 08             	add    $0x8,%esp
f0100101:	56                   	push   %esi
f0100102:	57                   	push   %edi
f0100103:	e8 75 3a 00 00       	call   f0103b7d <vcprintf>
	cprintf("\n");
f0100108:	8d 83 ff 92 f7 ff    	lea    -0x86d01(%ebx),%eax
f010010e:	89 04 24             	mov    %eax,(%esp)
f0100111:	e8 9e 3a 00 00       	call   f0103bb4 <cprintf>
f0100116:	83 c4 10             	add    $0x10,%esp
f0100119:	eb b8                	jmp    f01000d3 <_panic+0x22>

f010011b <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010011b:	55                   	push   %ebp
f010011c:	89 e5                	mov    %esp,%ebp
f010011e:	56                   	push   %esi
f010011f:	53                   	push   %ebx
f0100120:	e8 42 00 00 00       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100125:	81 c3 fb ce 08 00    	add    $0x8cefb,%ebx
	va_list ap;

	va_start(ap, fmt);
f010012b:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f010012e:	83 ec 04             	sub    $0x4,%esp
f0100131:	ff 75 0c             	pushl  0xc(%ebp)
f0100134:	ff 75 08             	pushl  0x8(%ebp)
f0100137:	8d 83 53 83 f7 ff    	lea    -0x87cad(%ebx),%eax
f010013d:	50                   	push   %eax
f010013e:	e8 71 3a 00 00       	call   f0103bb4 <cprintf>
	vcprintf(fmt, ap);
f0100143:	83 c4 08             	add    $0x8,%esp
f0100146:	56                   	push   %esi
f0100147:	ff 75 10             	pushl  0x10(%ebp)
f010014a:	e8 2e 3a 00 00       	call   f0103b7d <vcprintf>
	cprintf("\n");
f010014f:	8d 83 ff 92 f7 ff    	lea    -0x86d01(%ebx),%eax
f0100155:	89 04 24             	mov    %eax,(%esp)
f0100158:	e8 57 3a 00 00       	call   f0103bb4 <cprintf>
	va_end(ap);
}
f010015d:	83 c4 10             	add    $0x10,%esp
f0100160:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100163:	5b                   	pop    %ebx
f0100164:	5e                   	pop    %esi
f0100165:	5d                   	pop    %ebp
f0100166:	c3                   	ret    

f0100167 <__x86.get_pc_thunk.bx>:
f0100167:	8b 1c 24             	mov    (%esp),%ebx
f010016a:	c3                   	ret    

f010016b <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010016b:	55                   	push   %ebp
f010016c:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010016e:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100173:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100174:	a8 01                	test   $0x1,%al
f0100176:	74 0b                	je     f0100183 <serial_proc_data+0x18>
f0100178:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010017d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010017e:	0f b6 c0             	movzbl %al,%eax
}
f0100181:	5d                   	pop    %ebp
f0100182:	c3                   	ret    
		return -1;
f0100183:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100188:	eb f7                	jmp    f0100181 <serial_proc_data+0x16>

f010018a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010018a:	55                   	push   %ebp
f010018b:	89 e5                	mov    %esp,%ebp
f010018d:	56                   	push   %esi
f010018e:	53                   	push   %ebx
f010018f:	e8 d3 ff ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100194:	81 c3 8c ce 08 00    	add    $0x8ce8c,%ebx
f010019a:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f010019c:	ff d6                	call   *%esi
f010019e:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001a1:	74 2e                	je     f01001d1 <cons_intr+0x47>
		if (c == 0)
f01001a3:	85 c0                	test   %eax,%eax
f01001a5:	74 f5                	je     f010019c <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a7:	8b 8b e4 26 00 00    	mov    0x26e4(%ebx),%ecx
f01001ad:	8d 51 01             	lea    0x1(%ecx),%edx
f01001b0:	89 93 e4 26 00 00    	mov    %edx,0x26e4(%ebx)
f01001b6:	88 84 0b e0 24 00 00 	mov    %al,0x24e0(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001bd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c3:	75 d7                	jne    f010019c <cons_intr+0x12>
			cons.wpos = 0;
f01001c5:	c7 83 e4 26 00 00 00 	movl   $0x0,0x26e4(%ebx)
f01001cc:	00 00 00 
f01001cf:	eb cb                	jmp    f010019c <cons_intr+0x12>
	}
}
f01001d1:	5b                   	pop    %ebx
f01001d2:	5e                   	pop    %esi
f01001d3:	5d                   	pop    %ebp
f01001d4:	c3                   	ret    

f01001d5 <kbd_proc_data>:
{
f01001d5:	55                   	push   %ebp
f01001d6:	89 e5                	mov    %esp,%ebp
f01001d8:	56                   	push   %esi
f01001d9:	53                   	push   %ebx
f01001da:	e8 88 ff ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01001df:	81 c3 41 ce 08 00    	add    $0x8ce41,%ebx
f01001e5:	ba 64 00 00 00       	mov    $0x64,%edx
f01001ea:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001eb:	a8 01                	test   $0x1,%al
f01001ed:	0f 84 06 01 00 00    	je     f01002f9 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f01001f3:	a8 20                	test   $0x20,%al
f01001f5:	0f 85 05 01 00 00    	jne    f0100300 <kbd_proc_data+0x12b>
f01001fb:	ba 60 00 00 00       	mov    $0x60,%edx
f0100200:	ec                   	in     (%dx),%al
f0100201:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100203:	3c e0                	cmp    $0xe0,%al
f0100205:	0f 84 93 00 00 00    	je     f010029e <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f010020b:	84 c0                	test   %al,%al
f010020d:	0f 88 a0 00 00 00    	js     f01002b3 <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f0100213:	8b 8b c0 24 00 00    	mov    0x24c0(%ebx),%ecx
f0100219:	f6 c1 40             	test   $0x40,%cl
f010021c:	74 0e                	je     f010022c <kbd_proc_data+0x57>
		data |= 0x80;
f010021e:	83 c8 80             	or     $0xffffff80,%eax
f0100221:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100223:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100226:	89 8b c0 24 00 00    	mov    %ecx,0x24c0(%ebx)
	shift |= shiftcode[data];
f010022c:	0f b6 d2             	movzbl %dl,%edx
f010022f:	0f b6 84 13 a0 84 f7 	movzbl -0x87b60(%ebx,%edx,1),%eax
f0100236:	ff 
f0100237:	0b 83 c0 24 00 00    	or     0x24c0(%ebx),%eax
	shift ^= togglecode[data];
f010023d:	0f b6 8c 13 a0 83 f7 	movzbl -0x87c60(%ebx,%edx,1),%ecx
f0100244:	ff 
f0100245:	31 c8                	xor    %ecx,%eax
f0100247:	89 83 c0 24 00 00    	mov    %eax,0x24c0(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f010024d:	89 c1                	mov    %eax,%ecx
f010024f:	83 e1 03             	and    $0x3,%ecx
f0100252:	8b 8c 8b 00 20 00 00 	mov    0x2000(%ebx,%ecx,4),%ecx
f0100259:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010025d:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100260:	a8 08                	test   $0x8,%al
f0100262:	74 0d                	je     f0100271 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f0100264:	89 f2                	mov    %esi,%edx
f0100266:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100269:	83 f9 19             	cmp    $0x19,%ecx
f010026c:	77 7a                	ja     f01002e8 <kbd_proc_data+0x113>
			c += 'A' - 'a';
f010026e:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100271:	f7 d0                	not    %eax
f0100273:	a8 06                	test   $0x6,%al
f0100275:	75 33                	jne    f01002aa <kbd_proc_data+0xd5>
f0100277:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f010027d:	75 2b                	jne    f01002aa <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f010027f:	83 ec 0c             	sub    $0xc,%esp
f0100282:	8d 83 6d 83 f7 ff    	lea    -0x87c93(%ebx),%eax
f0100288:	50                   	push   %eax
f0100289:	e8 26 39 00 00       	call   f0103bb4 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010028e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100293:	ba 92 00 00 00       	mov    $0x92,%edx
f0100298:	ee                   	out    %al,(%dx)
f0100299:	83 c4 10             	add    $0x10,%esp
f010029c:	eb 0c                	jmp    f01002aa <kbd_proc_data+0xd5>
		shift |= E0ESC;
f010029e:	83 8b c0 24 00 00 40 	orl    $0x40,0x24c0(%ebx)
		return 0;
f01002a5:	be 00 00 00 00       	mov    $0x0,%esi
}
f01002aa:	89 f0                	mov    %esi,%eax
f01002ac:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01002af:	5b                   	pop    %ebx
f01002b0:	5e                   	pop    %esi
f01002b1:	5d                   	pop    %ebp
f01002b2:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f01002b3:	8b 8b c0 24 00 00    	mov    0x24c0(%ebx),%ecx
f01002b9:	89 ce                	mov    %ecx,%esi
f01002bb:	83 e6 40             	and    $0x40,%esi
f01002be:	83 e0 7f             	and    $0x7f,%eax
f01002c1:	85 f6                	test   %esi,%esi
f01002c3:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002c6:	0f b6 d2             	movzbl %dl,%edx
f01002c9:	0f b6 84 13 a0 84 f7 	movzbl -0x87b60(%ebx,%edx,1),%eax
f01002d0:	ff 
f01002d1:	83 c8 40             	or     $0x40,%eax
f01002d4:	0f b6 c0             	movzbl %al,%eax
f01002d7:	f7 d0                	not    %eax
f01002d9:	21 c8                	and    %ecx,%eax
f01002db:	89 83 c0 24 00 00    	mov    %eax,0x24c0(%ebx)
		return 0;
f01002e1:	be 00 00 00 00       	mov    $0x0,%esi
f01002e6:	eb c2                	jmp    f01002aa <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f01002e8:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002eb:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002ee:	83 fa 1a             	cmp    $0x1a,%edx
f01002f1:	0f 42 f1             	cmovb  %ecx,%esi
f01002f4:	e9 78 ff ff ff       	jmp    f0100271 <kbd_proc_data+0x9c>
		return -1;
f01002f9:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002fe:	eb aa                	jmp    f01002aa <kbd_proc_data+0xd5>
		return -1;
f0100300:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100305:	eb a3                	jmp    f01002aa <kbd_proc_data+0xd5>

f0100307 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100307:	55                   	push   %ebp
f0100308:	89 e5                	mov    %esp,%ebp
f010030a:	57                   	push   %edi
f010030b:	56                   	push   %esi
f010030c:	53                   	push   %ebx
f010030d:	83 ec 1c             	sub    $0x1c,%esp
f0100310:	e8 52 fe ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100315:	81 c3 0b cd 08 00    	add    $0x8cd0b,%ebx
f010031b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f010031e:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100323:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100328:	b9 84 00 00 00       	mov    $0x84,%ecx
f010032d:	eb 09                	jmp    f0100338 <cons_putc+0x31>
f010032f:	89 ca                	mov    %ecx,%edx
f0100331:	ec                   	in     (%dx),%al
f0100332:	ec                   	in     (%dx),%al
f0100333:	ec                   	in     (%dx),%al
f0100334:	ec                   	in     (%dx),%al
	     i++)
f0100335:	83 c6 01             	add    $0x1,%esi
f0100338:	89 fa                	mov    %edi,%edx
f010033a:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010033b:	a8 20                	test   $0x20,%al
f010033d:	75 08                	jne    f0100347 <cons_putc+0x40>
f010033f:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100345:	7e e8                	jle    f010032f <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f0100347:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010034a:	89 f8                	mov    %edi,%eax
f010034c:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100354:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100355:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010035a:	bf 79 03 00 00       	mov    $0x379,%edi
f010035f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100364:	eb 09                	jmp    f010036f <cons_putc+0x68>
f0100366:	89 ca                	mov    %ecx,%edx
f0100368:	ec                   	in     (%dx),%al
f0100369:	ec                   	in     (%dx),%al
f010036a:	ec                   	in     (%dx),%al
f010036b:	ec                   	in     (%dx),%al
f010036c:	83 c6 01             	add    $0x1,%esi
f010036f:	89 fa                	mov    %edi,%edx
f0100371:	ec                   	in     (%dx),%al
f0100372:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100378:	7f 04                	jg     f010037e <cons_putc+0x77>
f010037a:	84 c0                	test   %al,%al
f010037c:	79 e8                	jns    f0100366 <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010037e:	ba 78 03 00 00       	mov    $0x378,%edx
f0100383:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0100387:	ee                   	out    %al,(%dx)
f0100388:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010038d:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100392:	ee                   	out    %al,(%dx)
f0100393:	b8 08 00 00 00       	mov    $0x8,%eax
f0100398:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100399:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010039c:	89 fa                	mov    %edi,%edx
f010039e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01003a4:	89 f8                	mov    %edi,%eax
f01003a6:	80 cc 07             	or     $0x7,%ah
f01003a9:	85 d2                	test   %edx,%edx
f01003ab:	0f 45 c7             	cmovne %edi,%eax
f01003ae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f01003b1:	0f b6 c0             	movzbl %al,%eax
f01003b4:	83 f8 09             	cmp    $0x9,%eax
f01003b7:	0f 84 b9 00 00 00    	je     f0100476 <cons_putc+0x16f>
f01003bd:	83 f8 09             	cmp    $0x9,%eax
f01003c0:	7e 74                	jle    f0100436 <cons_putc+0x12f>
f01003c2:	83 f8 0a             	cmp    $0xa,%eax
f01003c5:	0f 84 9e 00 00 00    	je     f0100469 <cons_putc+0x162>
f01003cb:	83 f8 0d             	cmp    $0xd,%eax
f01003ce:	0f 85 d9 00 00 00    	jne    f01004ad <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f01003d4:	0f b7 83 e8 26 00 00 	movzwl 0x26e8(%ebx),%eax
f01003db:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e1:	c1 e8 16             	shr    $0x16,%eax
f01003e4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003e7:	c1 e0 04             	shl    $0x4,%eax
f01003ea:	66 89 83 e8 26 00 00 	mov    %ax,0x26e8(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003f1:	66 81 bb e8 26 00 00 	cmpw   $0x7cf,0x26e8(%ebx)
f01003f8:	cf 07 
f01003fa:	0f 87 d4 00 00 00    	ja     f01004d4 <cons_putc+0x1cd>
	outb(addr_6845, 14);
f0100400:	8b 8b f0 26 00 00    	mov    0x26f0(%ebx),%ecx
f0100406:	b8 0e 00 00 00       	mov    $0xe,%eax
f010040b:	89 ca                	mov    %ecx,%edx
f010040d:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010040e:	0f b7 9b e8 26 00 00 	movzwl 0x26e8(%ebx),%ebx
f0100415:	8d 71 01             	lea    0x1(%ecx),%esi
f0100418:	89 d8                	mov    %ebx,%eax
f010041a:	66 c1 e8 08          	shr    $0x8,%ax
f010041e:	89 f2                	mov    %esi,%edx
f0100420:	ee                   	out    %al,(%dx)
f0100421:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100426:	89 ca                	mov    %ecx,%edx
f0100428:	ee                   	out    %al,(%dx)
f0100429:	89 d8                	mov    %ebx,%eax
f010042b:	89 f2                	mov    %esi,%edx
f010042d:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010042e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100431:	5b                   	pop    %ebx
f0100432:	5e                   	pop    %esi
f0100433:	5f                   	pop    %edi
f0100434:	5d                   	pop    %ebp
f0100435:	c3                   	ret    
	switch (c & 0xff) {
f0100436:	83 f8 08             	cmp    $0x8,%eax
f0100439:	75 72                	jne    f01004ad <cons_putc+0x1a6>
		if (crt_pos > 0) {
f010043b:	0f b7 83 e8 26 00 00 	movzwl 0x26e8(%ebx),%eax
f0100442:	66 85 c0             	test   %ax,%ax
f0100445:	74 b9                	je     f0100400 <cons_putc+0xf9>
			crt_pos--;
f0100447:	83 e8 01             	sub    $0x1,%eax
f010044a:	66 89 83 e8 26 00 00 	mov    %ax,0x26e8(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100451:	0f b7 c0             	movzwl %ax,%eax
f0100454:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100458:	b2 00                	mov    $0x0,%dl
f010045a:	83 ca 20             	or     $0x20,%edx
f010045d:	8b 8b ec 26 00 00    	mov    0x26ec(%ebx),%ecx
f0100463:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f0100467:	eb 88                	jmp    f01003f1 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100469:	66 83 83 e8 26 00 00 	addw   $0x50,0x26e8(%ebx)
f0100470:	50 
f0100471:	e9 5e ff ff ff       	jmp    f01003d4 <cons_putc+0xcd>
		cons_putc(' ');
f0100476:	b8 20 00 00 00       	mov    $0x20,%eax
f010047b:	e8 87 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f0100480:	b8 20 00 00 00       	mov    $0x20,%eax
f0100485:	e8 7d fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f010048a:	b8 20 00 00 00       	mov    $0x20,%eax
f010048f:	e8 73 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f0100494:	b8 20 00 00 00       	mov    $0x20,%eax
f0100499:	e8 69 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f010049e:	b8 20 00 00 00       	mov    $0x20,%eax
f01004a3:	e8 5f fe ff ff       	call   f0100307 <cons_putc>
f01004a8:	e9 44 ff ff ff       	jmp    f01003f1 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f01004ad:	0f b7 83 e8 26 00 00 	movzwl 0x26e8(%ebx),%eax
f01004b4:	8d 50 01             	lea    0x1(%eax),%edx
f01004b7:	66 89 93 e8 26 00 00 	mov    %dx,0x26e8(%ebx)
f01004be:	0f b7 c0             	movzwl %ax,%eax
f01004c1:	8b 93 ec 26 00 00    	mov    0x26ec(%ebx),%edx
f01004c7:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004cb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004cf:	e9 1d ff ff ff       	jmp    f01003f1 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004d4:	8b 83 ec 26 00 00    	mov    0x26ec(%ebx),%eax
f01004da:	83 ec 04             	sub    $0x4,%esp
f01004dd:	68 00 0f 00 00       	push   $0xf00
f01004e2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004e8:	52                   	push   %edx
f01004e9:	50                   	push   %eax
f01004ea:	e8 4d 4a 00 00       	call   f0104f3c <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004ef:	8b 93 ec 26 00 00    	mov    0x26ec(%ebx),%edx
f01004f5:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004fb:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100501:	83 c4 10             	add    $0x10,%esp
f0100504:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100509:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010050c:	39 d0                	cmp    %edx,%eax
f010050e:	75 f4                	jne    f0100504 <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100510:	66 83 ab e8 26 00 00 	subw   $0x50,0x26e8(%ebx)
f0100517:	50 
f0100518:	e9 e3 fe ff ff       	jmp    f0100400 <cons_putc+0xf9>

f010051d <serial_intr>:
{
f010051d:	e8 e7 01 00 00       	call   f0100709 <__x86.get_pc_thunk.ax>
f0100522:	05 fe ca 08 00       	add    $0x8cafe,%eax
	if (serial_exists)
f0100527:	80 b8 f4 26 00 00 00 	cmpb   $0x0,0x26f4(%eax)
f010052e:	75 02                	jne    f0100532 <serial_intr+0x15>
f0100530:	f3 c3                	repz ret 
{
f0100532:	55                   	push   %ebp
f0100533:	89 e5                	mov    %esp,%ebp
f0100535:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100538:	8d 80 4b 31 f7 ff    	lea    -0x8ceb5(%eax),%eax
f010053e:	e8 47 fc ff ff       	call   f010018a <cons_intr>
}
f0100543:	c9                   	leave  
f0100544:	c3                   	ret    

f0100545 <kbd_intr>:
{
f0100545:	55                   	push   %ebp
f0100546:	89 e5                	mov    %esp,%ebp
f0100548:	83 ec 08             	sub    $0x8,%esp
f010054b:	e8 b9 01 00 00       	call   f0100709 <__x86.get_pc_thunk.ax>
f0100550:	05 d0 ca 08 00       	add    $0x8cad0,%eax
	cons_intr(kbd_proc_data);
f0100555:	8d 80 b5 31 f7 ff    	lea    -0x8ce4b(%eax),%eax
f010055b:	e8 2a fc ff ff       	call   f010018a <cons_intr>
}
f0100560:	c9                   	leave  
f0100561:	c3                   	ret    

f0100562 <cons_getc>:
{
f0100562:	55                   	push   %ebp
f0100563:	89 e5                	mov    %esp,%ebp
f0100565:	53                   	push   %ebx
f0100566:	83 ec 04             	sub    $0x4,%esp
f0100569:	e8 f9 fb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010056e:	81 c3 b2 ca 08 00    	add    $0x8cab2,%ebx
	serial_intr();
f0100574:	e8 a4 ff ff ff       	call   f010051d <serial_intr>
	kbd_intr();
f0100579:	e8 c7 ff ff ff       	call   f0100545 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f010057e:	8b 93 e0 26 00 00    	mov    0x26e0(%ebx),%edx
	return 0;
f0100584:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100589:	3b 93 e4 26 00 00    	cmp    0x26e4(%ebx),%edx
f010058f:	74 19                	je     f01005aa <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100591:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100594:	89 8b e0 26 00 00    	mov    %ecx,0x26e0(%ebx)
f010059a:	0f b6 84 13 e0 24 00 	movzbl 0x24e0(%ebx,%edx,1),%eax
f01005a1:	00 
		if (cons.rpos == CONSBUFSIZE)
f01005a2:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01005a8:	74 06                	je     f01005b0 <cons_getc+0x4e>
}
f01005aa:	83 c4 04             	add    $0x4,%esp
f01005ad:	5b                   	pop    %ebx
f01005ae:	5d                   	pop    %ebp
f01005af:	c3                   	ret    
			cons.rpos = 0;
f01005b0:	c7 83 e0 26 00 00 00 	movl   $0x0,0x26e0(%ebx)
f01005b7:	00 00 00 
f01005ba:	eb ee                	jmp    f01005aa <cons_getc+0x48>

f01005bc <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005bc:	55                   	push   %ebp
f01005bd:	89 e5                	mov    %esp,%ebp
f01005bf:	57                   	push   %edi
f01005c0:	56                   	push   %esi
f01005c1:	53                   	push   %ebx
f01005c2:	83 ec 1c             	sub    $0x1c,%esp
f01005c5:	e8 9d fb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01005ca:	81 c3 56 ca 08 00    	add    $0x8ca56,%ebx
	was = *cp;
f01005d0:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005d7:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005de:	5a a5 
	if (*cp != 0xA55A) {
f01005e0:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005e7:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005eb:	0f 84 bc 00 00 00    	je     f01006ad <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f01005f1:	c7 83 f0 26 00 00 b4 	movl   $0x3b4,0x26f0(%ebx)
f01005f8:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005fb:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100602:	8b bb f0 26 00 00    	mov    0x26f0(%ebx),%edi
f0100608:	b8 0e 00 00 00       	mov    $0xe,%eax
f010060d:	89 fa                	mov    %edi,%edx
f010060f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100610:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100613:	89 ca                	mov    %ecx,%edx
f0100615:	ec                   	in     (%dx),%al
f0100616:	0f b6 f0             	movzbl %al,%esi
f0100619:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010061c:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100621:	89 fa                	mov    %edi,%edx
f0100623:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100624:	89 ca                	mov    %ecx,%edx
f0100626:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100627:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010062a:	89 bb ec 26 00 00    	mov    %edi,0x26ec(%ebx)
	pos |= inb(addr_6845 + 1);
f0100630:	0f b6 c0             	movzbl %al,%eax
f0100633:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f0100635:	66 89 b3 e8 26 00 00 	mov    %si,0x26e8(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010063c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100641:	89 c8                	mov    %ecx,%eax
f0100643:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100648:	ee                   	out    %al,(%dx)
f0100649:	bf fb 03 00 00       	mov    $0x3fb,%edi
f010064e:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100653:	89 fa                	mov    %edi,%edx
f0100655:	ee                   	out    %al,(%dx)
f0100656:	b8 0c 00 00 00       	mov    $0xc,%eax
f010065b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100660:	ee                   	out    %al,(%dx)
f0100661:	be f9 03 00 00       	mov    $0x3f9,%esi
f0100666:	89 c8                	mov    %ecx,%eax
f0100668:	89 f2                	mov    %esi,%edx
f010066a:	ee                   	out    %al,(%dx)
f010066b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100670:	89 fa                	mov    %edi,%edx
f0100672:	ee                   	out    %al,(%dx)
f0100673:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100678:	89 c8                	mov    %ecx,%eax
f010067a:	ee                   	out    %al,(%dx)
f010067b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100680:	89 f2                	mov    %esi,%edx
f0100682:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100683:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100688:	ec                   	in     (%dx),%al
f0100689:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010068b:	3c ff                	cmp    $0xff,%al
f010068d:	0f 95 83 f4 26 00 00 	setne  0x26f4(%ebx)
f0100694:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100699:	ec                   	in     (%dx),%al
f010069a:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010069f:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006a0:	80 f9 ff             	cmp    $0xff,%cl
f01006a3:	74 25                	je     f01006ca <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f01006a5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006a8:	5b                   	pop    %ebx
f01006a9:	5e                   	pop    %esi
f01006aa:	5f                   	pop    %edi
f01006ab:	5d                   	pop    %ebp
f01006ac:	c3                   	ret    
		*cp = was;
f01006ad:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006b4:	c7 83 f0 26 00 00 d4 	movl   $0x3d4,0x26f0(%ebx)
f01006bb:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006be:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006c5:	e9 38 ff ff ff       	jmp    f0100602 <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006ca:	83 ec 0c             	sub    $0xc,%esp
f01006cd:	8d 83 79 83 f7 ff    	lea    -0x87c87(%ebx),%eax
f01006d3:	50                   	push   %eax
f01006d4:	e8 db 34 00 00       	call   f0103bb4 <cprintf>
f01006d9:	83 c4 10             	add    $0x10,%esp
}
f01006dc:	eb c7                	jmp    f01006a5 <cons_init+0xe9>

f01006de <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006de:	55                   	push   %ebp
f01006df:	89 e5                	mov    %esp,%ebp
f01006e1:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01006e7:	e8 1b fc ff ff       	call   f0100307 <cons_putc>
}
f01006ec:	c9                   	leave  
f01006ed:	c3                   	ret    

f01006ee <getchar>:

int
getchar(void)
{
f01006ee:	55                   	push   %ebp
f01006ef:	89 e5                	mov    %esp,%ebp
f01006f1:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006f4:	e8 69 fe ff ff       	call   f0100562 <cons_getc>
f01006f9:	85 c0                	test   %eax,%eax
f01006fb:	74 f7                	je     f01006f4 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006fd:	c9                   	leave  
f01006fe:	c3                   	ret    

f01006ff <iscons>:

int
iscons(int fdnum)
{
f01006ff:	55                   	push   %ebp
f0100700:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100702:	b8 01 00 00 00       	mov    $0x1,%eax
f0100707:	5d                   	pop    %ebp
f0100708:	c3                   	ret    

f0100709 <__x86.get_pc_thunk.ax>:
f0100709:	8b 04 24             	mov    (%esp),%eax
f010070c:	c3                   	ret    

f010070d <mon_help>:
};

/***** Implementations of basic kernel monitor commands *****/

int mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010070d:	55                   	push   %ebp
f010070e:	89 e5                	mov    %esp,%ebp
f0100710:	56                   	push   %esi
f0100711:	53                   	push   %ebx
f0100712:	e8 50 fa ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100717:	81 c3 09 c9 08 00    	add    $0x8c909,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010071d:	83 ec 04             	sub    $0x4,%esp
f0100720:	8d 83 a0 85 f7 ff    	lea    -0x87a60(%ebx),%eax
f0100726:	50                   	push   %eax
f0100727:	8d 83 be 85 f7 ff    	lea    -0x87a42(%ebx),%eax
f010072d:	50                   	push   %eax
f010072e:	8d b3 c3 85 f7 ff    	lea    -0x87a3d(%ebx),%esi
f0100734:	56                   	push   %esi
f0100735:	e8 7a 34 00 00       	call   f0103bb4 <cprintf>
f010073a:	83 c4 0c             	add    $0xc,%esp
f010073d:	8d 83 4c 86 f7 ff    	lea    -0x879b4(%ebx),%eax
f0100743:	50                   	push   %eax
f0100744:	8d 83 cc 85 f7 ff    	lea    -0x87a34(%ebx),%eax
f010074a:	50                   	push   %eax
f010074b:	56                   	push   %esi
f010074c:	e8 63 34 00 00       	call   f0103bb4 <cprintf>
	return 0;
}
f0100751:	b8 00 00 00 00       	mov    $0x0,%eax
f0100756:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100759:	5b                   	pop    %ebx
f010075a:	5e                   	pop    %esi
f010075b:	5d                   	pop    %ebp
f010075c:	c3                   	ret    

f010075d <mon_kerninfo>:

int mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010075d:	55                   	push   %ebp
f010075e:	89 e5                	mov    %esp,%ebp
f0100760:	57                   	push   %edi
f0100761:	56                   	push   %esi
f0100762:	53                   	push   %ebx
f0100763:	83 ec 18             	sub    $0x18,%esp
f0100766:	e8 fc f9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010076b:	81 c3 b5 c8 08 00    	add    $0x8c8b5,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100771:	8d 83 d5 85 f7 ff    	lea    -0x87a2b(%ebx),%eax
f0100777:	50                   	push   %eax
f0100778:	e8 37 34 00 00       	call   f0103bb4 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010077d:	83 c4 08             	add    $0x8,%esp
f0100780:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f0100786:	8d 83 74 86 f7 ff    	lea    -0x8798c(%ebx),%eax
f010078c:	50                   	push   %eax
f010078d:	e8 22 34 00 00       	call   f0103bb4 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100792:	83 c4 0c             	add    $0xc,%esp
f0100795:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f010079b:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007a1:	50                   	push   %eax
f01007a2:	57                   	push   %edi
f01007a3:	8d 83 9c 86 f7 ff    	lea    -0x87964(%ebx),%eax
f01007a9:	50                   	push   %eax
f01007aa:	e8 05 34 00 00       	call   f0103bb4 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007af:	83 c4 0c             	add    $0xc,%esp
f01007b2:	c7 c0 29 53 10 f0    	mov    $0xf0105329,%eax
f01007b8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007be:	52                   	push   %edx
f01007bf:	50                   	push   %eax
f01007c0:	8d 83 c0 86 f7 ff    	lea    -0x87940(%ebx),%eax
f01007c6:	50                   	push   %eax
f01007c7:	e8 e8 33 00 00       	call   f0103bb4 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cc:	83 c4 0c             	add    $0xc,%esp
f01007cf:	c7 c0 e0 f4 18 f0    	mov    $0xf018f4e0,%eax
f01007d5:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007db:	52                   	push   %edx
f01007dc:	50                   	push   %eax
f01007dd:	8d 83 e4 86 f7 ff    	lea    -0x8791c(%ebx),%eax
f01007e3:	50                   	push   %eax
f01007e4:	e8 cb 33 00 00       	call   f0103bb4 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e9:	83 c4 0c             	add    $0xc,%esp
f01007ec:	c7 c6 e0 03 19 f0    	mov    $0xf01903e0,%esi
f01007f2:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007f8:	50                   	push   %eax
f01007f9:	56                   	push   %esi
f01007fa:	8d 83 08 87 f7 ff    	lea    -0x878f8(%ebx),%eax
f0100800:	50                   	push   %eax
f0100801:	e8 ae 33 00 00       	call   f0103bb4 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100806:	83 c4 08             	add    $0x8,%esp
			ROUNDUP(end - entry, 1024) / 1024);
f0100809:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010080f:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100811:	c1 fe 0a             	sar    $0xa,%esi
f0100814:	56                   	push   %esi
f0100815:	8d 83 2c 87 f7 ff    	lea    -0x878d4(%ebx),%eax
f010081b:	50                   	push   %eax
f010081c:	e8 93 33 00 00       	call   f0103bb4 <cprintf>
	return 0;
}
f0100821:	b8 00 00 00 00       	mov    $0x0,%eax
f0100826:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100829:	5b                   	pop    %ebx
f010082a:	5e                   	pop    %esi
f010082b:	5f                   	pop    %edi
f010082c:	5d                   	pop    %ebp
f010082d:	c3                   	ret    

f010082e <mon_backtrace>:

int mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010082e:	55                   	push   %ebp
f010082f:	89 e5                	mov    %esp,%ebp
f0100831:	57                   	push   %edi
f0100832:	56                   	push   %esi
f0100833:	53                   	push   %ebx
f0100834:	83 ec 48             	sub    $0x48,%esp
f0100837:	e8 2b f9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010083c:	81 c3 e4 c7 08 00    	add    $0x8c7e4,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100842:	89 ee                	mov    %ebp,%esi
	// 利用 ebp 的初始值0判断是否停止
	// 利用数组指针运算来获取 eip 以及 args
	uint32_t ebp, eip, *ptr_ebp;
	struct Eipdebuginfo info;
	ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f0100844:	8d 83 ee 85 f7 ff    	lea    -0x87a12(%ebx),%eax
f010084a:	50                   	push   %eax
f010084b:	e8 64 33 00 00       	call   f0103bb4 <cprintf>
	while (ebp != 0)
f0100850:	83 c4 10             	add    $0x10,%esp
	{
		ptr_ebp = (uint32_t *)ebp;
		eip = ptr_ebp[1];

		cprintf("ebp %x  eip %x  args %08x %08x %08x %08x %08x\n",
f0100853:	8d 83 58 87 f7 ff    	lea    -0x878a8(%ebx),%eax
f0100859:	89 45 c0             	mov    %eax,-0x40(%ebp)
				ebp, eip, ptr_ebp[2], ptr_ebp[3], ptr_ebp[4], ptr_ebp[5], ptr_ebp[6]);

		int ret = debuginfo_eip(eip, &info);
f010085c:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010085f:	89 45 bc             	mov    %eax,-0x44(%ebp)
	while (ebp != 0)
f0100862:	eb 05                	jmp    f0100869 <mon_backtrace+0x3b>
		if (ret == 0)
		{
			cprintf("%s:%d: %.*s+%d\n",
					info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
		}
		ebp = ptr_ebp[0];
f0100864:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100867:	8b 30                	mov    (%eax),%esi
	while (ebp != 0)
f0100869:	85 f6                	test   %esi,%esi
f010086b:	74 56                	je     f01008c3 <mon_backtrace+0x95>
		ptr_ebp = (uint32_t *)ebp;
f010086d:	89 75 c4             	mov    %esi,-0x3c(%ebp)
		eip = ptr_ebp[1];
f0100870:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("ebp %x  eip %x  args %08x %08x %08x %08x %08x\n",
f0100873:	ff 76 18             	pushl  0x18(%esi)
f0100876:	ff 76 14             	pushl  0x14(%esi)
f0100879:	ff 76 10             	pushl  0x10(%esi)
f010087c:	ff 76 0c             	pushl  0xc(%esi)
f010087f:	ff 76 08             	pushl  0x8(%esi)
f0100882:	57                   	push   %edi
f0100883:	56                   	push   %esi
f0100884:	ff 75 c0             	pushl  -0x40(%ebp)
f0100887:	e8 28 33 00 00       	call   f0103bb4 <cprintf>
		int ret = debuginfo_eip(eip, &info);
f010088c:	83 c4 18             	add    $0x18,%esp
f010088f:	ff 75 bc             	pushl  -0x44(%ebp)
f0100892:	57                   	push   %edi
f0100893:	e8 4d 3b 00 00       	call   f01043e5 <debuginfo_eip>
		if (ret == 0)
f0100898:	83 c4 10             	add    $0x10,%esp
f010089b:	85 c0                	test   %eax,%eax
f010089d:	75 c5                	jne    f0100864 <mon_backtrace+0x36>
			cprintf("%s:%d: %.*s+%d\n",
f010089f:	83 ec 08             	sub    $0x8,%esp
f01008a2:	2b 7d e0             	sub    -0x20(%ebp),%edi
f01008a5:	57                   	push   %edi
f01008a6:	ff 75 d8             	pushl  -0x28(%ebp)
f01008a9:	ff 75 dc             	pushl  -0x24(%ebp)
f01008ac:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008af:	ff 75 d0             	pushl  -0x30(%ebp)
f01008b2:	8d 83 00 86 f7 ff    	lea    -0x87a00(%ebx),%eax
f01008b8:	50                   	push   %eax
f01008b9:	e8 f6 32 00 00       	call   f0103bb4 <cprintf>
f01008be:	83 c4 20             	add    $0x20,%esp
f01008c1:	eb a1                	jmp    f0100864 <mon_backtrace+0x36>
	}
	return 0;
}
f01008c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01008c8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008cb:	5b                   	pop    %ebx
f01008cc:	5e                   	pop    %esi
f01008cd:	5f                   	pop    %edi
f01008ce:	5d                   	pop    %ebp
f01008cf:	c3                   	ret    

f01008d0 <monitor>:
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void monitor(struct Trapframe *tf)
{
f01008d0:	55                   	push   %ebp
f01008d1:	89 e5                	mov    %esp,%ebp
f01008d3:	57                   	push   %edi
f01008d4:	56                   	push   %esi
f01008d5:	53                   	push   %ebx
f01008d6:	83 ec 68             	sub    $0x68,%esp
f01008d9:	e8 89 f8 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01008de:	81 c3 42 c7 08 00    	add    $0x8c742,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008e4:	8d 83 88 87 f7 ff    	lea    -0x87878(%ebx),%eax
f01008ea:	50                   	push   %eax
f01008eb:	e8 c4 32 00 00       	call   f0103bb4 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008f0:	8d 83 ac 87 f7 ff    	lea    -0x87854(%ebx),%eax
f01008f6:	89 04 24             	mov    %eax,(%esp)
f01008f9:	e8 b6 32 00 00       	call   f0103bb4 <cprintf>

	if (tf != NULL)
f01008fe:	83 c4 10             	add    $0x10,%esp
f0100901:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100905:	74 0e                	je     f0100915 <monitor+0x45>
		print_trapframe(tf);
f0100907:	83 ec 0c             	sub    $0xc,%esp
f010090a:	ff 75 08             	pushl  0x8(%ebp)
f010090d:	e8 b4 34 00 00       	call   f0103dc6 <print_trapframe>
f0100912:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100915:	8d bb 14 86 f7 ff    	lea    -0x879ec(%ebx),%edi
f010091b:	eb 4a                	jmp    f0100967 <monitor+0x97>
f010091d:	83 ec 08             	sub    $0x8,%esp
f0100920:	0f be c0             	movsbl %al,%eax
f0100923:	50                   	push   %eax
f0100924:	57                   	push   %edi
f0100925:	e8 88 45 00 00       	call   f0104eb2 <strchr>
f010092a:	83 c4 10             	add    $0x10,%esp
f010092d:	85 c0                	test   %eax,%eax
f010092f:	74 08                	je     f0100939 <monitor+0x69>
			*buf++ = 0;
f0100931:	c6 06 00             	movb   $0x0,(%esi)
f0100934:	8d 76 01             	lea    0x1(%esi),%esi
f0100937:	eb 79                	jmp    f01009b2 <monitor+0xe2>
		if (*buf == 0)
f0100939:	80 3e 00             	cmpb   $0x0,(%esi)
f010093c:	74 7f                	je     f01009bd <monitor+0xed>
		if (argc == MAXARGS - 1)
f010093e:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f0100942:	74 0f                	je     f0100953 <monitor+0x83>
		argv[argc++] = buf;
f0100944:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100947:	8d 48 01             	lea    0x1(%eax),%ecx
f010094a:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f010094d:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f0100951:	eb 44                	jmp    f0100997 <monitor+0xc7>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100953:	83 ec 08             	sub    $0x8,%esp
f0100956:	6a 10                	push   $0x10
f0100958:	8d 83 19 86 f7 ff    	lea    -0x879e7(%ebx),%eax
f010095e:	50                   	push   %eax
f010095f:	e8 50 32 00 00       	call   f0103bb4 <cprintf>
f0100964:	83 c4 10             	add    $0x10,%esp

	while (1)
	{
		buf = readline("K> ");
f0100967:	8d 83 10 86 f7 ff    	lea    -0x879f0(%ebx),%eax
f010096d:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100970:	83 ec 0c             	sub    $0xc,%esp
f0100973:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100976:	e8 ff 42 00 00       	call   f0104c7a <readline>
f010097b:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f010097d:	83 c4 10             	add    $0x10,%esp
f0100980:	85 c0                	test   %eax,%eax
f0100982:	74 ec                	je     f0100970 <monitor+0xa0>
	argv[argc] = 0;
f0100984:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f010098b:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100992:	eb 1e                	jmp    f01009b2 <monitor+0xe2>
			buf++;
f0100994:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100997:	0f b6 06             	movzbl (%esi),%eax
f010099a:	84 c0                	test   %al,%al
f010099c:	74 14                	je     f01009b2 <monitor+0xe2>
f010099e:	83 ec 08             	sub    $0x8,%esp
f01009a1:	0f be c0             	movsbl %al,%eax
f01009a4:	50                   	push   %eax
f01009a5:	57                   	push   %edi
f01009a6:	e8 07 45 00 00       	call   f0104eb2 <strchr>
f01009ab:	83 c4 10             	add    $0x10,%esp
f01009ae:	85 c0                	test   %eax,%eax
f01009b0:	74 e2                	je     f0100994 <monitor+0xc4>
		while (*buf && strchr(WHITESPACE, *buf))
f01009b2:	0f b6 06             	movzbl (%esi),%eax
f01009b5:	84 c0                	test   %al,%al
f01009b7:	0f 85 60 ff ff ff    	jne    f010091d <monitor+0x4d>
	argv[argc] = 0;
f01009bd:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009c0:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f01009c7:	00 
	if (argc == 0)
f01009c8:	85 c0                	test   %eax,%eax
f01009ca:	74 9b                	je     f0100967 <monitor+0x97>
		if (strcmp(argv[0], commands[i].name) == 0)
f01009cc:	83 ec 08             	sub    $0x8,%esp
f01009cf:	8d 83 be 85 f7 ff    	lea    -0x87a42(%ebx),%eax
f01009d5:	50                   	push   %eax
f01009d6:	ff 75 a8             	pushl  -0x58(%ebp)
f01009d9:	e8 76 44 00 00       	call   f0104e54 <strcmp>
f01009de:	83 c4 10             	add    $0x10,%esp
f01009e1:	85 c0                	test   %eax,%eax
f01009e3:	74 38                	je     f0100a1d <monitor+0x14d>
f01009e5:	83 ec 08             	sub    $0x8,%esp
f01009e8:	8d 83 cc 85 f7 ff    	lea    -0x87a34(%ebx),%eax
f01009ee:	50                   	push   %eax
f01009ef:	ff 75 a8             	pushl  -0x58(%ebp)
f01009f2:	e8 5d 44 00 00       	call   f0104e54 <strcmp>
f01009f7:	83 c4 10             	add    $0x10,%esp
f01009fa:	85 c0                	test   %eax,%eax
f01009fc:	74 1a                	je     f0100a18 <monitor+0x148>
	cprintf("Unknown command '%s'\n", argv[0]);
f01009fe:	83 ec 08             	sub    $0x8,%esp
f0100a01:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a04:	8d 83 36 86 f7 ff    	lea    -0x879ca(%ebx),%eax
f0100a0a:	50                   	push   %eax
f0100a0b:	e8 a4 31 00 00       	call   f0103bb4 <cprintf>
f0100a10:	83 c4 10             	add    $0x10,%esp
f0100a13:	e9 4f ff ff ff       	jmp    f0100967 <monitor+0x97>
	for (i = 0; i < ARRAY_SIZE(commands); i++)
f0100a18:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f0100a1d:	83 ec 04             	sub    $0x4,%esp
f0100a20:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a23:	ff 75 08             	pushl  0x8(%ebp)
f0100a26:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a29:	52                   	push   %edx
f0100a2a:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100a2d:	ff 94 83 18 20 00 00 	call   *0x2018(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100a34:	83 c4 10             	add    $0x10,%esp
f0100a37:	85 c0                	test   %eax,%eax
f0100a39:	0f 89 28 ff ff ff    	jns    f0100967 <monitor+0x97>
				break;
	}
}
f0100a3f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a42:	5b                   	pop    %ebx
f0100a43:	5e                   	pop    %esi
f0100a44:	5f                   	pop    %edi
f0100a45:	5d                   	pop    %ebp
f0100a46:	c3                   	ret    

f0100a47 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a47:	55                   	push   %ebp
f0100a48:	89 e5                	mov    %esp,%ebp
f0100a4a:	57                   	push   %edi
f0100a4b:	56                   	push   %esi
f0100a4c:	53                   	push   %ebx
f0100a4d:	83 ec 18             	sub    $0x18,%esp
f0100a50:	e8 12 f7 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100a55:	81 c3 cb c5 08 00    	add    $0x8c5cb,%ebx
f0100a5b:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a5d:	50                   	push   %eax
f0100a5e:	e8 ca 30 00 00       	call   f0103b2d <mc146818_read>
f0100a63:	89 c6                	mov    %eax,%esi
f0100a65:	83 c7 01             	add    $0x1,%edi
f0100a68:	89 3c 24             	mov    %edi,(%esp)
f0100a6b:	e8 bd 30 00 00       	call   f0103b2d <mc146818_read>
f0100a70:	c1 e0 08             	shl    $0x8,%eax
f0100a73:	09 f0                	or     %esi,%eax
}
f0100a75:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a78:	5b                   	pop    %ebx
f0100a79:	5e                   	pop    %esi
f0100a7a:	5f                   	pop    %edi
f0100a7b:	5d                   	pop    %ebp
f0100a7c:	c3                   	ret    

f0100a7d <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a7d:	55                   	push   %ebp
f0100a7e:	89 e5                	mov    %esp,%ebp
f0100a80:	53                   	push   %ebx
f0100a81:	83 ec 04             	sub    $0x4,%esp
f0100a84:	e8 de f6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100a89:	81 c3 97 c5 08 00    	add    $0x8c597,%ebx
f0100a8f:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree)
f0100a91:	83 bb f8 26 00 00 00 	cmpl   $0x0,0x26f8(%ebx)
f0100a98:	74 2b                	je     f0100ac5 <boot_alloc+0x48>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// Your code here.
	if (n == 0)
f0100a9a:	85 d2                	test   %edx,%edx
f0100a9c:	74 3f                	je     f0100add <boot_alloc+0x60>
	{
		return nextfree;
	}

	// note before update
	result = nextfree;
f0100a9e:	8b 83 f8 26 00 00    	mov    0x26f8(%ebx),%eax
	nextfree = ROUNDUP(n, PGSIZE) + nextfree;
f0100aa4:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100aaa:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ab0:	01 c2                	add    %eax,%edx
f0100ab2:	89 93 f8 26 00 00    	mov    %edx,0x26f8(%ebx)

	// out of memory panic
	if (nextfree > (char *)0xf0400000)
f0100ab8:	81 fa 00 00 40 f0    	cmp    $0xf0400000,%edx
f0100abe:	77 25                	ja     f0100ae5 <boot_alloc+0x68>
		nextfree = result; // reset static data
		return NULL;
	}

	return result;
}
f0100ac0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ac3:	c9                   	leave  
f0100ac4:	c3                   	ret    
		nextfree = ROUNDUP((char *)end, PGSIZE);
f0100ac5:	c7 c0 e0 03 19 f0    	mov    $0xf01903e0,%eax
f0100acb:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100ad0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ad5:	89 83 f8 26 00 00    	mov    %eax,0x26f8(%ebx)
f0100adb:	eb bd                	jmp    f0100a9a <boot_alloc+0x1d>
		return nextfree;
f0100add:	8b 83 f8 26 00 00    	mov    0x26f8(%ebx),%eax
f0100ae3:	eb db                	jmp    f0100ac0 <boot_alloc+0x43>
		panic("boot_alloc: out of memory, nothing changed, returning NULL...\n");
f0100ae5:	83 ec 04             	sub    $0x4,%esp
f0100ae8:	8d 83 d4 87 f7 ff    	lea    -0x8782c(%ebx),%eax
f0100aee:	50                   	push   %eax
f0100aef:	6a 75                	push   $0x75
f0100af1:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0100af7:	50                   	push   %eax
f0100af8:	e8 b4 f5 ff ff       	call   f01000b1 <_panic>

f0100afd <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100afd:	55                   	push   %ebp
f0100afe:	89 e5                	mov    %esp,%ebp
f0100b00:	56                   	push   %esi
f0100b01:	53                   	push   %ebx
f0100b02:	e8 2b 28 00 00       	call   f0103332 <__x86.get_pc_thunk.cx>
f0100b07:	81 c1 19 c5 08 00    	add    $0x8c519,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b0d:	89 d3                	mov    %edx,%ebx
f0100b0f:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100b12:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100b15:	a8 01                	test   $0x1,%al
f0100b17:	74 5a                	je     f0100b73 <check_va2pa+0x76>
		return ~0;
	p = (pte_t *)KADDR(PTE_ADDR(*pgdir));
f0100b19:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b1e:	89 c6                	mov    %eax,%esi
f0100b20:	c1 ee 0c             	shr    $0xc,%esi
f0100b23:	c7 c3 e8 03 19 f0    	mov    $0xf01903e8,%ebx
f0100b29:	3b 33                	cmp    (%ebx),%esi
f0100b2b:	73 2b                	jae    f0100b58 <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100b2d:	c1 ea 0c             	shr    $0xc,%edx
f0100b30:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b36:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b3d:	89 c2                	mov    %eax,%edx
f0100b3f:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b42:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b47:	85 d2                	test   %edx,%edx
f0100b49:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b4e:	0f 44 c2             	cmove  %edx,%eax
}
f0100b51:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100b54:	5b                   	pop    %ebx
f0100b55:	5e                   	pop    %esi
f0100b56:	5d                   	pop    %ebp
f0100b57:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b58:	50                   	push   %eax
f0100b59:	8d 81 14 88 f7 ff    	lea    -0x877ec(%ecx),%eax
f0100b5f:	50                   	push   %eax
f0100b60:	68 63 03 00 00       	push   $0x363
f0100b65:	8d 81 a5 90 f7 ff    	lea    -0x86f5b(%ecx),%eax
f0100b6b:	50                   	push   %eax
f0100b6c:	89 cb                	mov    %ecx,%ebx
f0100b6e:	e8 3e f5 ff ff       	call   f01000b1 <_panic>
		return ~0;
f0100b73:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b78:	eb d7                	jmp    f0100b51 <check_va2pa+0x54>

f0100b7a <check_page_free_list>:
{
f0100b7a:	55                   	push   %ebp
f0100b7b:	89 e5                	mov    %esp,%ebp
f0100b7d:	57                   	push   %edi
f0100b7e:	56                   	push   %esi
f0100b7f:	53                   	push   %ebx
f0100b80:	83 ec 3c             	sub    $0x3c,%esp
f0100b83:	e8 ae 27 00 00       	call   f0103336 <__x86.get_pc_thunk.di>
f0100b88:	81 c7 98 c4 08 00    	add    $0x8c498,%edi
f0100b8e:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b91:	84 c0                	test   %al,%al
f0100b93:	0f 85 dd 02 00 00    	jne    f0100e76 <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100b99:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100b9c:	83 b8 00 27 00 00 00 	cmpl   $0x0,0x2700(%eax)
f0100ba3:	74 0c                	je     f0100bb1 <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ba5:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100bac:	e9 2f 03 00 00       	jmp    f0100ee0 <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100bb1:	83 ec 04             	sub    $0x4,%esp
f0100bb4:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bb7:	8d 83 38 88 f7 ff    	lea    -0x877c8(%ebx),%eax
f0100bbd:	50                   	push   %eax
f0100bbe:	68 98 02 00 00       	push   $0x298
f0100bc3:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0100bc9:	50                   	push   %eax
f0100bca:	e8 e2 f4 ff ff       	call   f01000b1 <_panic>
f0100bcf:	50                   	push   %eax
f0100bd0:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bd3:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f0100bd9:	50                   	push   %eax
f0100bda:	6a 56                	push   $0x56
f0100bdc:	8d 83 b1 90 f7 ff    	lea    -0x86f4f(%ebx),%eax
f0100be2:	50                   	push   %eax
f0100be3:	e8 c9 f4 ff ff       	call   f01000b1 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100be8:	8b 36                	mov    (%esi),%esi
f0100bea:	85 f6                	test   %esi,%esi
f0100bec:	74 40                	je     f0100c2e <check_page_free_list+0xb4>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bee:	89 f0                	mov    %esi,%eax
f0100bf0:	2b 07                	sub    (%edi),%eax
f0100bf2:	c1 f8 03             	sar    $0x3,%eax
f0100bf5:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100bf8:	89 c2                	mov    %eax,%edx
f0100bfa:	c1 ea 16             	shr    $0x16,%edx
f0100bfd:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c00:	73 e6                	jae    f0100be8 <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100c02:	89 c2                	mov    %eax,%edx
f0100c04:	c1 ea 0c             	shr    $0xc,%edx
f0100c07:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100c0a:	3b 11                	cmp    (%ecx),%edx
f0100c0c:	73 c1                	jae    f0100bcf <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100c0e:	83 ec 04             	sub    $0x4,%esp
f0100c11:	68 80 00 00 00       	push   $0x80
f0100c16:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c1b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c20:	50                   	push   %eax
f0100c21:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c24:	e8 c6 42 00 00       	call   f0104eef <memset>
f0100c29:	83 c4 10             	add    $0x10,%esp
f0100c2c:	eb ba                	jmp    f0100be8 <check_page_free_list+0x6e>
	first_free_page = (char *)boot_alloc(0);
f0100c2e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c33:	e8 45 fe ff ff       	call   f0100a7d <boot_alloc>
f0100c38:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c3b:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100c3e:	8b 97 00 27 00 00    	mov    0x2700(%edi),%edx
		assert(pp >= pages);
f0100c44:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f0100c4a:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100c4c:	c7 c0 e8 03 19 f0    	mov    $0xf01903e8,%eax
f0100c52:	8b 00                	mov    (%eax),%eax
f0100c54:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100c57:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100c5a:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c5d:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c62:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c65:	e9 08 01 00 00       	jmp    f0100d72 <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0100c6a:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c6d:	8d 83 bf 90 f7 ff    	lea    -0x86f41(%ebx),%eax
f0100c73:	50                   	push   %eax
f0100c74:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0100c7a:	50                   	push   %eax
f0100c7b:	68 b5 02 00 00       	push   $0x2b5
f0100c80:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0100c86:	50                   	push   %eax
f0100c87:	e8 25 f4 ff ff       	call   f01000b1 <_panic>
		assert(pp < pages + npages);
f0100c8c:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c8f:	8d 83 e0 90 f7 ff    	lea    -0x86f20(%ebx),%eax
f0100c95:	50                   	push   %eax
f0100c96:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0100c9c:	50                   	push   %eax
f0100c9d:	68 b6 02 00 00       	push   $0x2b6
f0100ca2:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0100ca8:	50                   	push   %eax
f0100ca9:	e8 03 f4 ff ff       	call   f01000b1 <_panic>
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100cae:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cb1:	8d 83 5c 88 f7 ff    	lea    -0x877a4(%ebx),%eax
f0100cb7:	50                   	push   %eax
f0100cb8:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0100cbe:	50                   	push   %eax
f0100cbf:	68 b7 02 00 00       	push   $0x2b7
f0100cc4:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0100cca:	50                   	push   %eax
f0100ccb:	e8 e1 f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != 0);
f0100cd0:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cd3:	8d 83 f4 90 f7 ff    	lea    -0x86f0c(%ebx),%eax
f0100cd9:	50                   	push   %eax
f0100cda:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0100ce0:	50                   	push   %eax
f0100ce1:	68 ba 02 00 00       	push   $0x2ba
f0100ce6:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0100cec:	50                   	push   %eax
f0100ced:	e8 bf f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cf2:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cf5:	8d 83 05 91 f7 ff    	lea    -0x86efb(%ebx),%eax
f0100cfb:	50                   	push   %eax
f0100cfc:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0100d02:	50                   	push   %eax
f0100d03:	68 bb 02 00 00       	push   $0x2bb
f0100d08:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0100d0e:	50                   	push   %eax
f0100d0f:	e8 9d f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d14:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d17:	8d 83 8c 88 f7 ff    	lea    -0x87774(%ebx),%eax
f0100d1d:	50                   	push   %eax
f0100d1e:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0100d24:	50                   	push   %eax
f0100d25:	68 bc 02 00 00       	push   $0x2bc
f0100d2a:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0100d30:	50                   	push   %eax
f0100d31:	e8 7b f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d36:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d39:	8d 83 1e 91 f7 ff    	lea    -0x86ee2(%ebx),%eax
f0100d3f:	50                   	push   %eax
f0100d40:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0100d46:	50                   	push   %eax
f0100d47:	68 bd 02 00 00       	push   $0x2bd
f0100d4c:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0100d52:	50                   	push   %eax
f0100d53:	e8 59 f3 ff ff       	call   f01000b1 <_panic>
	if (PGNUM(pa) >= npages)
f0100d58:	89 c6                	mov    %eax,%esi
f0100d5a:	c1 ee 0c             	shr    $0xc,%esi
f0100d5d:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0100d60:	76 70                	jbe    f0100dd2 <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0100d62:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *)page2kva(pp) >= first_free_page);
f0100d67:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d6a:	77 7f                	ja     f0100deb <check_page_free_list+0x271>
			++nfree_extmem;
f0100d6c:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d70:	8b 12                	mov    (%edx),%edx
f0100d72:	85 d2                	test   %edx,%edx
f0100d74:	0f 84 93 00 00 00    	je     f0100e0d <check_page_free_list+0x293>
		assert(pp >= pages);
f0100d7a:	39 d1                	cmp    %edx,%ecx
f0100d7c:	0f 87 e8 fe ff ff    	ja     f0100c6a <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0100d82:	39 d3                	cmp    %edx,%ebx
f0100d84:	0f 86 02 ff ff ff    	jbe    f0100c8c <check_page_free_list+0x112>
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100d8a:	89 d0                	mov    %edx,%eax
f0100d8c:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100d8f:	a8 07                	test   $0x7,%al
f0100d91:	0f 85 17 ff ff ff    	jne    f0100cae <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0100d97:	c1 f8 03             	sar    $0x3,%eax
f0100d9a:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100d9d:	85 c0                	test   %eax,%eax
f0100d9f:	0f 84 2b ff ff ff    	je     f0100cd0 <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0100da5:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100daa:	0f 84 42 ff ff ff    	je     f0100cf2 <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100db0:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100db5:	0f 84 59 ff ff ff    	je     f0100d14 <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100dbb:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100dc0:	0f 84 70 ff ff ff    	je     f0100d36 <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *)page2kva(pp) >= first_free_page);
f0100dc6:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100dcb:	77 8b                	ja     f0100d58 <check_page_free_list+0x1de>
			++nfree_basemem;
f0100dcd:	83 c7 01             	add    $0x1,%edi
f0100dd0:	eb 9e                	jmp    f0100d70 <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dd2:	50                   	push   %eax
f0100dd3:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100dd6:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f0100ddc:	50                   	push   %eax
f0100ddd:	6a 56                	push   $0x56
f0100ddf:	8d 83 b1 90 f7 ff    	lea    -0x86f4f(%ebx),%eax
f0100de5:	50                   	push   %eax
f0100de6:	e8 c6 f2 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *)page2kva(pp) >= first_free_page);
f0100deb:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100dee:	8d 83 b0 88 f7 ff    	lea    -0x87750(%ebx),%eax
f0100df4:	50                   	push   %eax
f0100df5:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0100dfb:	50                   	push   %eax
f0100dfc:	68 be 02 00 00       	push   $0x2be
f0100e01:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0100e07:	50                   	push   %eax
f0100e08:	e8 a4 f2 ff ff       	call   f01000b1 <_panic>
f0100e0d:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f0100e10:	85 ff                	test   %edi,%edi
f0100e12:	7e 1e                	jle    f0100e32 <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f0100e14:	85 f6                	test   %esi,%esi
f0100e16:	7e 3c                	jle    f0100e54 <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f0100e18:	83 ec 0c             	sub    $0xc,%esp
f0100e1b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e1e:	8d 83 f4 88 f7 ff    	lea    -0x8770c(%ebx),%eax
f0100e24:	50                   	push   %eax
f0100e25:	e8 8a 2d 00 00       	call   f0103bb4 <cprintf>
}
f0100e2a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e2d:	5b                   	pop    %ebx
f0100e2e:	5e                   	pop    %esi
f0100e2f:	5f                   	pop    %edi
f0100e30:	5d                   	pop    %ebp
f0100e31:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e32:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e35:	8d 83 38 91 f7 ff    	lea    -0x86ec8(%ebx),%eax
f0100e3b:	50                   	push   %eax
f0100e3c:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0100e42:	50                   	push   %eax
f0100e43:	68 c6 02 00 00       	push   $0x2c6
f0100e48:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0100e4e:	50                   	push   %eax
f0100e4f:	e8 5d f2 ff ff       	call   f01000b1 <_panic>
	assert(nfree_extmem > 0);
f0100e54:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e57:	8d 83 4a 91 f7 ff    	lea    -0x86eb6(%ebx),%eax
f0100e5d:	50                   	push   %eax
f0100e5e:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0100e64:	50                   	push   %eax
f0100e65:	68 c7 02 00 00       	push   $0x2c7
f0100e6a:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0100e70:	50                   	push   %eax
f0100e71:	e8 3b f2 ff ff       	call   f01000b1 <_panic>
	if (!page_free_list)
f0100e76:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100e79:	8b 80 00 27 00 00    	mov    0x2700(%eax),%eax
f0100e7f:	85 c0                	test   %eax,%eax
f0100e81:	0f 84 2a fd ff ff    	je     f0100bb1 <check_page_free_list+0x37>
		struct PageInfo **tp[2] = {&pp1, &pp2};
f0100e87:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e8a:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e8d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e90:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100e93:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100e96:	c7 c3 f0 03 19 f0    	mov    $0xf01903f0,%ebx
f0100e9c:	89 c2                	mov    %eax,%edx
f0100e9e:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ea0:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ea6:	0f 95 c2             	setne  %dl
f0100ea9:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100eac:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100eb0:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100eb2:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link)
f0100eb6:	8b 00                	mov    (%eax),%eax
f0100eb8:	85 c0                	test   %eax,%eax
f0100eba:	75 e0                	jne    f0100e9c <check_page_free_list+0x322>
		*tp[1] = 0;
f0100ebc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ebf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ec5:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ec8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ecb:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ecd:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ed0:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100ed3:	89 87 00 27 00 00    	mov    %eax,0x2700(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ed9:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ee0:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100ee3:	8b b0 00 27 00 00    	mov    0x2700(%eax),%esi
f0100ee9:	c7 c7 f0 03 19 f0    	mov    $0xf01903f0,%edi
	if (PGNUM(pa) >= npages)
f0100eef:	c7 c0 e8 03 19 f0    	mov    $0xf01903e8,%eax
f0100ef5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100ef8:	e9 ed fc ff ff       	jmp    f0100bea <check_page_free_list+0x70>

f0100efd <page_init>:
{
f0100efd:	55                   	push   %ebp
f0100efe:	89 e5                	mov    %esp,%ebp
f0100f00:	57                   	push   %edi
f0100f01:	56                   	push   %esi
f0100f02:	53                   	push   %ebx
f0100f03:	83 ec 1c             	sub    $0x1c,%esp
f0100f06:	e8 2b 24 00 00       	call   f0103336 <__x86.get_pc_thunk.di>
f0100f0b:	81 c7 15 c1 08 00    	add    $0x8c115,%edi
f0100f11:	89 7d e4             	mov    %edi,-0x1c(%ebp)
	pages[0].pp_ref = 1;
f0100f14:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f0100f1a:	8b 00                	mov    (%eax),%eax
f0100f1c:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	for (i = 1; i < npages_basemem; i++)
f0100f22:	8b 87 04 27 00 00    	mov    0x2704(%edi),%eax
f0100f28:	8b b7 00 27 00 00    	mov    0x2700(%edi),%esi
f0100f2e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f33:	ba 01 00 00 00       	mov    $0x1,%edx
		pages[i].pp_ref = 0;
f0100f38:	c7 c7 f0 03 19 f0    	mov    $0xf01903f0,%edi
	for (i = 1; i < npages_basemem; i++)
f0100f3e:	eb 1f                	jmp    f0100f5f <page_init+0x62>
		pages[i].pp_ref = 0;
f0100f40:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f0100f47:	89 cb                	mov    %ecx,%ebx
f0100f49:	03 1f                	add    (%edi),%ebx
f0100f4b:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f0100f51:	89 33                	mov    %esi,(%ebx)
	for (i = 1; i < npages_basemem; i++)
f0100f53:	83 c2 01             	add    $0x1,%edx
		page_free_list = &pages[i];
f0100f56:	89 ce                	mov    %ecx,%esi
f0100f58:	03 37                	add    (%edi),%esi
f0100f5a:	b9 01 00 00 00       	mov    $0x1,%ecx
	for (i = 1; i < npages_basemem; i++)
f0100f5f:	39 d0                	cmp    %edx,%eax
f0100f61:	77 dd                	ja     f0100f40 <page_init+0x43>
f0100f63:	84 c9                	test   %cl,%cl
f0100f65:	75 0d                	jne    f0100f74 <page_init+0x77>
		pages[i].pp_ref = 1;
f0100f67:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f6a:	c7 c2 f0 03 19 f0    	mov    $0xf01903f0,%edx
f0100f70:	8b 12                	mov    (%edx),%edx
f0100f72:	eb 15                	jmp    f0100f89 <page_init+0x8c>
f0100f74:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f77:	89 b7 00 27 00 00    	mov    %esi,0x2700(%edi)
f0100f7d:	eb e8                	jmp    f0100f67 <page_init+0x6a>
f0100f7f:	66 c7 44 c2 04 01 00 	movw   $0x1,0x4(%edx,%eax,8)
	for (i = npages_basemem; i < EXTPHYSMEM / PGSIZE; i++)
f0100f86:	83 c0 01             	add    $0x1,%eax
f0100f89:	3d ff 00 00 00       	cmp    $0xff,%eax
f0100f8e:	76 ef                	jbe    f0100f7f <page_init+0x82>
	physaddr_t first_free_addr = PADDR(boot_alloc(0));
f0100f90:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f95:	e8 e3 fa ff ff       	call   f0100a7d <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f0100f9a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f9f:	76 1a                	jbe    f0100fbb <page_init+0xbe>
	return (physaddr_t)kva - KERNBASE;
f0100fa1:	05 00 00 00 10       	add    $0x10000000,%eax
	size_t first_free_page = first_free_addr / PGSIZE;
f0100fa6:	c1 e8 0c             	shr    $0xc,%eax
		pages[i].pp_ref = 1;
f0100fa9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fac:	c7 c2 f0 03 19 f0    	mov    $0xf01903f0,%edx
f0100fb2:	8b 0a                	mov    (%edx),%ecx
	for (i = EXTPHYSMEM / PGSIZE; i < first_free_page; i++)
f0100fb4:	ba 00 01 00 00       	mov    $0x100,%edx
f0100fb9:	eb 26                	jmp    f0100fe1 <page_init+0xe4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100fbb:	50                   	push   %eax
f0100fbc:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100fbf:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f0100fc5:	50                   	push   %eax
f0100fc6:	68 33 01 00 00       	push   $0x133
f0100fcb:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0100fd1:	50                   	push   %eax
f0100fd2:	e8 da f0 ff ff       	call   f01000b1 <_panic>
		pages[i].pp_ref = 1;
f0100fd7:	66 c7 44 d1 04 01 00 	movw   $0x1,0x4(%ecx,%edx,8)
	for (i = EXTPHYSMEM / PGSIZE; i < first_free_page; i++)
f0100fde:	83 c2 01             	add    $0x1,%edx
f0100fe1:	39 c2                	cmp    %eax,%edx
f0100fe3:	72 f2                	jb     f0100fd7 <page_init+0xda>
f0100fe5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100fe8:	8b 9e 00 27 00 00    	mov    0x2700(%esi),%ebx
f0100fee:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100ff5:	b9 00 00 00 00       	mov    $0x0,%ecx
	for (i = first_free_page; i < npages; i++)
f0100ffa:	c7 c7 e8 03 19 f0    	mov    $0xf01903e8,%edi
		pages[i].pp_ref = 0;
f0101000:	c7 c6 f0 03 19 f0    	mov    $0xf01903f0,%esi
f0101006:	eb 1b                	jmp    f0101023 <page_init+0x126>
f0101008:	89 d1                	mov    %edx,%ecx
f010100a:	03 0e                	add    (%esi),%ecx
f010100c:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0101012:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0101014:	89 d3                	mov    %edx,%ebx
f0101016:	03 1e                	add    (%esi),%ebx
	for (i = first_free_page; i < npages; i++)
f0101018:	83 c0 01             	add    $0x1,%eax
f010101b:	83 c2 08             	add    $0x8,%edx
f010101e:	b9 01 00 00 00       	mov    $0x1,%ecx
f0101023:	39 07                	cmp    %eax,(%edi)
f0101025:	77 e1                	ja     f0101008 <page_init+0x10b>
f0101027:	84 c9                	test   %cl,%cl
f0101029:	75 08                	jne    f0101033 <page_init+0x136>
}
f010102b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010102e:	5b                   	pop    %ebx
f010102f:	5e                   	pop    %esi
f0101030:	5f                   	pop    %edi
f0101031:	5d                   	pop    %ebp
f0101032:	c3                   	ret    
f0101033:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101036:	89 98 00 27 00 00    	mov    %ebx,0x2700(%eax)
f010103c:	eb ed                	jmp    f010102b <page_init+0x12e>

f010103e <page_alloc>:
{
f010103e:	55                   	push   %ebp
f010103f:	89 e5                	mov    %esp,%ebp
f0101041:	56                   	push   %esi
f0101042:	53                   	push   %ebx
f0101043:	e8 1f f1 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0101048:	81 c3 d8 bf 08 00    	add    $0x8bfd8,%ebx
	if (!page_free_list)
f010104e:	8b b3 00 27 00 00    	mov    0x2700(%ebx),%esi
f0101054:	85 f6                	test   %esi,%esi
f0101056:	74 14                	je     f010106c <page_alloc+0x2e>
	page_free_list = page_free_list->pp_link; // update free list pointer
f0101058:	8b 06                	mov    (%esi),%eax
f010105a:	89 83 00 27 00 00    	mov    %eax,0x2700(%ebx)
	pp->pp_link = NULL;						  // set to NULL according to notes
f0101060:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if (alloc_flags & ALLOC_ZERO)
f0101066:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010106a:	75 09                	jne    f0101075 <page_alloc+0x37>
}
f010106c:	89 f0                	mov    %esi,%eax
f010106e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101071:	5b                   	pop    %ebx
f0101072:	5e                   	pop    %esi
f0101073:	5d                   	pop    %ebp
f0101074:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f0101075:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f010107b:	89 f2                	mov    %esi,%edx
f010107d:	2b 10                	sub    (%eax),%edx
f010107f:	89 d0                	mov    %edx,%eax
f0101081:	c1 f8 03             	sar    $0x3,%eax
f0101084:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101087:	89 c1                	mov    %eax,%ecx
f0101089:	c1 e9 0c             	shr    $0xc,%ecx
f010108c:	c7 c2 e8 03 19 f0    	mov    $0xf01903e8,%edx
f0101092:	3b 0a                	cmp    (%edx),%ecx
f0101094:	73 1a                	jae    f01010b0 <page_alloc+0x72>
		memset(va, '\0', PGSIZE);
f0101096:	83 ec 04             	sub    $0x4,%esp
f0101099:	68 00 10 00 00       	push   $0x1000
f010109e:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f01010a0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01010a5:	50                   	push   %eax
f01010a6:	e8 44 3e 00 00       	call   f0104eef <memset>
f01010ab:	83 c4 10             	add    $0x10,%esp
f01010ae:	eb bc                	jmp    f010106c <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010b0:	50                   	push   %eax
f01010b1:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f01010b7:	50                   	push   %eax
f01010b8:	6a 56                	push   $0x56
f01010ba:	8d 83 b1 90 f7 ff    	lea    -0x86f4f(%ebx),%eax
f01010c0:	50                   	push   %eax
f01010c1:	e8 eb ef ff ff       	call   f01000b1 <_panic>

f01010c6 <page_free>:
{
f01010c6:	55                   	push   %ebp
f01010c7:	89 e5                	mov    %esp,%ebp
f01010c9:	53                   	push   %ebx
f01010ca:	83 ec 04             	sub    $0x4,%esp
f01010cd:	e8 95 f0 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01010d2:	81 c3 4e bf 08 00    	add    $0x8bf4e,%ebx
f01010d8:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_link || pp->pp_ref)
f01010db:	83 38 00             	cmpl   $0x0,(%eax)
f01010de:	75 1a                	jne    f01010fa <page_free+0x34>
f01010e0:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01010e5:	75 13                	jne    f01010fa <page_free+0x34>
	pp->pp_link = page_free_list;
f01010e7:	8b 8b 00 27 00 00    	mov    0x2700(%ebx),%ecx
f01010ed:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f01010ef:	89 83 00 27 00 00    	mov    %eax,0x2700(%ebx)
}
f01010f5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010f8:	c9                   	leave  
f01010f9:	c3                   	ret    
		panic("pp->pp_ref is nonzero or pp->pp_link is not NULL\n");
f01010fa:	83 ec 04             	sub    $0x4,%esp
f01010fd:	8d 83 3c 89 f7 ff    	lea    -0x876c4(%ebx),%eax
f0101103:	50                   	push   %eax
f0101104:	68 71 01 00 00       	push   $0x171
f0101109:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010110f:	50                   	push   %eax
f0101110:	e8 9c ef ff ff       	call   f01000b1 <_panic>

f0101115 <page_decref>:
{
f0101115:	55                   	push   %ebp
f0101116:	89 e5                	mov    %esp,%ebp
f0101118:	83 ec 08             	sub    $0x8,%esp
f010111b:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f010111e:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101122:	83 e8 01             	sub    $0x1,%eax
f0101125:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101129:	66 85 c0             	test   %ax,%ax
f010112c:	74 02                	je     f0101130 <page_decref+0x1b>
}
f010112e:	c9                   	leave  
f010112f:	c3                   	ret    
		page_free(pp);
f0101130:	83 ec 0c             	sub    $0xc,%esp
f0101133:	52                   	push   %edx
f0101134:	e8 8d ff ff ff       	call   f01010c6 <page_free>
f0101139:	83 c4 10             	add    $0x10,%esp
}
f010113c:	eb f0                	jmp    f010112e <page_decref+0x19>

f010113e <pgdir_walk>:
{
f010113e:	55                   	push   %ebp
f010113f:	89 e5                	mov    %esp,%ebp
f0101141:	57                   	push   %edi
f0101142:	56                   	push   %esi
f0101143:	53                   	push   %ebx
f0101144:	83 ec 1c             	sub    $0x1c,%esp
f0101147:	e8 1b f0 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010114c:	81 c3 d4 be 08 00    	add    $0x8bed4,%ebx
f0101152:	8b 75 0c             	mov    0xc(%ebp),%esi
	uint32_t ptx = PTX(va); // 页表项索引
f0101155:	89 f0                	mov    %esi,%eax
f0101157:	c1 e8 0c             	shr    $0xc,%eax
f010115a:	25 ff 03 00 00       	and    $0x3ff,%eax
f010115f:	89 c7                	mov    %eax,%edi
	uint32_t pdx = PDX(va); // 页目录项索引
f0101161:	c1 ee 16             	shr    $0x16,%esi
	pde = &pgdir[pdx]; // 获取页目录项
f0101164:	c1 e6 02             	shl    $0x2,%esi
f0101167:	03 75 08             	add    0x8(%ebp),%esi
	if (*pde & PTE_P)
f010116a:	8b 16                	mov    (%esi),%edx
f010116c:	f6 c2 01             	test   $0x1,%dl
f010116f:	74 3f                	je     f01011b0 <pgdir_walk+0x72>
		pte = (KADDR(PTE_ADDR(*pde)));
f0101171:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101177:	89 d0                	mov    %edx,%eax
f0101179:	c1 e8 0c             	shr    $0xc,%eax
f010117c:	c7 c1 e8 03 19 f0    	mov    $0xf01903e8,%ecx
f0101182:	39 01                	cmp    %eax,(%ecx)
f0101184:	76 11                	jbe    f0101197 <pgdir_walk+0x59>
	return (void *)(pa + KERNBASE);
f0101186:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
	return &pte[ptx];
f010118c:	8d 04 ba             	lea    (%edx,%edi,4),%eax
}
f010118f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101192:	5b                   	pop    %ebx
f0101193:	5e                   	pop    %esi
f0101194:	5f                   	pop    %edi
f0101195:	5d                   	pop    %ebp
f0101196:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101197:	52                   	push   %edx
f0101198:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f010119e:	50                   	push   %eax
f010119f:	68 a8 01 00 00       	push   $0x1a8
f01011a4:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01011aa:	50                   	push   %eax
f01011ab:	e8 01 ef ff ff       	call   f01000b1 <_panic>
		if (!create)
f01011b0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01011b4:	0f 84 8e 00 00 00    	je     f0101248 <pgdir_walk+0x10a>
		if (!(pp = page_alloc(ALLOC_ZERO)))
f01011ba:	83 ec 0c             	sub    $0xc,%esp
f01011bd:	6a 01                	push   $0x1
f01011bf:	e8 7a fe ff ff       	call   f010103e <page_alloc>
f01011c4:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01011c7:	83 c4 10             	add    $0x10,%esp
f01011ca:	85 c0                	test   %eax,%eax
f01011cc:	0f 84 80 00 00 00    	je     f0101252 <pgdir_walk+0x114>
	return (pp - pages) << PGSHIFT;
f01011d2:	c7 c2 f0 03 19 f0    	mov    $0xf01903f0,%edx
f01011d8:	89 c1                	mov    %eax,%ecx
f01011da:	2b 0a                	sub    (%edx),%ecx
f01011dc:	c1 f9 03             	sar    $0x3,%ecx
f01011df:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f01011e2:	89 ca                	mov    %ecx,%edx
f01011e4:	c1 ea 0c             	shr    $0xc,%edx
f01011e7:	89 d0                	mov    %edx,%eax
f01011e9:	c7 c2 e8 03 19 f0    	mov    $0xf01903e8,%edx
f01011ef:	3b 02                	cmp    (%edx),%eax
f01011f1:	73 26                	jae    f0101219 <pgdir_walk+0xdb>
	return (void *)(pa + KERNBASE);
f01011f3:	8d 91 00 00 00 f0    	lea    -0x10000000(%ecx),%edx
f01011f9:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01011fc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		pp->pp_ref++;
f01011ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101202:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	if ((uint32_t)kva < KERNBASE)
f0101207:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010120d:	76 20                	jbe    f010122f <pgdir_walk+0xf1>
		*pde = PADDR(pte) | (PTE_P | PTE_W | PTE_U); // 设置页目录项
f010120f:	83 c9 07             	or     $0x7,%ecx
f0101212:	89 0e                	mov    %ecx,(%esi)
f0101214:	e9 73 ff ff ff       	jmp    f010118c <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101219:	51                   	push   %ecx
f010121a:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f0101220:	50                   	push   %eax
f0101221:	6a 56                	push   $0x56
f0101223:	8d 83 b1 90 f7 ff    	lea    -0x86f4f(%ebx),%eax
f0101229:	50                   	push   %eax
f010122a:	e8 82 ee ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010122f:	52                   	push   %edx
f0101230:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f0101236:	50                   	push   %eax
f0101237:	68 b6 01 00 00       	push   $0x1b6
f010123c:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0101242:	50                   	push   %eax
f0101243:	e8 69 ee ff ff       	call   f01000b1 <_panic>
			return NULL;
f0101248:	b8 00 00 00 00       	mov    $0x0,%eax
f010124d:	e9 3d ff ff ff       	jmp    f010118f <pgdir_walk+0x51>
			return NULL;
f0101252:	b8 00 00 00 00       	mov    $0x0,%eax
f0101257:	e9 33 ff ff ff       	jmp    f010118f <pgdir_walk+0x51>

f010125c <boot_map_region>:
{
f010125c:	55                   	push   %ebp
f010125d:	89 e5                	mov    %esp,%ebp
f010125f:	57                   	push   %edi
f0101260:	56                   	push   %esi
f0101261:	53                   	push   %ebx
f0101262:	83 ec 1c             	sub    $0x1c,%esp
f0101265:	e8 cc 20 00 00       	call   f0103336 <__x86.get_pc_thunk.di>
f010126a:	81 c7 b6 bd 08 00    	add    $0x8bdb6,%edi
f0101270:	89 7d d8             	mov    %edi,-0x28(%ebp)
f0101273:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101276:	8b 45 08             	mov    0x8(%ebp),%eax
	size_t pgs = PAGE_ALIGN(size) >> PGSHIFT; // 计算总共有多少页
f0101279:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f010127f:	c1 e9 0c             	shr    $0xc,%ecx
f0101282:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for (int i = 0; i < pgs; i++, pa += PGSIZE, va += PGSIZE) // 更新pa和va，进行下一轮循环
f0101285:	89 c3                	mov    %eax,%ebx
f0101287:	be 00 00 00 00       	mov    $0x0,%esi
		pte_t *pte = pgdir_walk(pgdir, (void *)va, 1); // 获取va对应的PTE的地址 create if not exists
f010128c:	89 d7                	mov    %edx,%edi
f010128e:	29 c7                	sub    %eax,%edi
		*pte = pa | PTE_P | perm; // 修改va对应的PTE的值
f0101290:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101293:	83 c8 01             	or     $0x1,%eax
f0101296:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for (int i = 0; i < pgs; i++, pa += PGSIZE, va += PGSIZE) // 更新pa和va，进行下一轮循环
f0101299:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f010129c:	74 48                	je     f01012e6 <boot_map_region+0x8a>
		pte_t *pte = pgdir_walk(pgdir, (void *)va, 1); // 获取va对应的PTE的地址 create if not exists
f010129e:	83 ec 04             	sub    $0x4,%esp
f01012a1:	6a 01                	push   $0x1
f01012a3:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f01012a6:	50                   	push   %eax
f01012a7:	ff 75 e0             	pushl  -0x20(%ebp)
f01012aa:	e8 8f fe ff ff       	call   f010113e <pgdir_walk>
		if (pte == NULL)
f01012af:	83 c4 10             	add    $0x10,%esp
f01012b2:	85 c0                	test   %eax,%eax
f01012b4:	74 12                	je     f01012c8 <boot_map_region+0x6c>
		*pte = pa | PTE_P | perm; // 修改va对应的PTE的值
f01012b6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01012b9:	09 da                	or     %ebx,%edx
f01012bb:	89 10                	mov    %edx,(%eax)
	for (int i = 0; i < pgs; i++, pa += PGSIZE, va += PGSIZE) // 更新pa和va，进行下一轮循环
f01012bd:	83 c6 01             	add    $0x1,%esi
f01012c0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01012c6:	eb d1                	jmp    f0101299 <boot_map_region+0x3d>
			panic("boot_map_region(): out of memory\n");
f01012c8:	83 ec 04             	sub    $0x4,%esp
f01012cb:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01012ce:	8d 83 70 89 f7 ff    	lea    -0x87690(%ebx),%eax
f01012d4:	50                   	push   %eax
f01012d5:	68 d1 01 00 00       	push   $0x1d1
f01012da:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01012e0:	50                   	push   %eax
f01012e1:	e8 cb ed ff ff       	call   f01000b1 <_panic>
}
f01012e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012e9:	5b                   	pop    %ebx
f01012ea:	5e                   	pop    %esi
f01012eb:	5f                   	pop    %edi
f01012ec:	5d                   	pop    %ebp
f01012ed:	c3                   	ret    

f01012ee <page_lookup>:
{
f01012ee:	55                   	push   %ebp
f01012ef:	89 e5                	mov    %esp,%ebp
f01012f1:	56                   	push   %esi
f01012f2:	53                   	push   %ebx
f01012f3:	e8 6f ee ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01012f8:	81 c3 28 bd 08 00    	add    $0x8bd28,%ebx
f01012fe:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0101301:	83 ec 04             	sub    $0x4,%esp
f0101304:	6a 00                	push   $0x0
f0101306:	ff 75 0c             	pushl  0xc(%ebp)
f0101309:	ff 75 08             	pushl  0x8(%ebp)
f010130c:	e8 2d fe ff ff       	call   f010113e <pgdir_walk>
	if (pte == NULL) // no page mapped at va
f0101311:	83 c4 10             	add    $0x10,%esp
f0101314:	85 c0                	test   %eax,%eax
f0101316:	74 44                	je     f010135c <page_lookup+0x6e>
	if (!(*pte & PTE_P)) // 考虑页表项是否存在
f0101318:	f6 00 01             	testb  $0x1,(%eax)
f010131b:	74 46                	je     f0101363 <page_lookup+0x75>
	if (pte_store)
f010131d:	85 f6                	test   %esi,%esi
f010131f:	74 02                	je     f0101323 <page_lookup+0x35>
		*pte_store = pte;
f0101321:	89 06                	mov    %eax,(%esi)
f0101323:	8b 00                	mov    (%eax),%eax
f0101325:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101328:	c7 c2 e8 03 19 f0    	mov    $0xf01903e8,%edx
f010132e:	39 02                	cmp    %eax,(%edx)
f0101330:	76 12                	jbe    f0101344 <page_lookup+0x56>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0101332:	c7 c2 f0 03 19 f0    	mov    $0xf01903f0,%edx
f0101338:	8b 12                	mov    (%edx),%edx
f010133a:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f010133d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101340:	5b                   	pop    %ebx
f0101341:	5e                   	pop    %esi
f0101342:	5d                   	pop    %ebp
f0101343:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0101344:	83 ec 04             	sub    $0x4,%esp
f0101347:	8d 83 94 89 f7 ff    	lea    -0x8766c(%ebx),%eax
f010134d:	50                   	push   %eax
f010134e:	6a 4f                	push   $0x4f
f0101350:	8d 83 b1 90 f7 ff    	lea    -0x86f4f(%ebx),%eax
f0101356:	50                   	push   %eax
f0101357:	e8 55 ed ff ff       	call   f01000b1 <_panic>
		return NULL;
f010135c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101361:	eb da                	jmp    f010133d <page_lookup+0x4f>
		return NULL;
f0101363:	b8 00 00 00 00       	mov    $0x0,%eax
f0101368:	eb d3                	jmp    f010133d <page_lookup+0x4f>

f010136a <page_remove>:
{
f010136a:	55                   	push   %ebp
f010136b:	89 e5                	mov    %esp,%ebp
f010136d:	53                   	push   %ebx
f010136e:	83 ec 18             	sub    $0x18,%esp
f0101371:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *pageInfo = page_lookup(pgdir, va, &pte); // PageInfo
f0101374:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101377:	50                   	push   %eax
f0101378:	53                   	push   %ebx
f0101379:	ff 75 08             	pushl  0x8(%ebp)
f010137c:	e8 6d ff ff ff       	call   f01012ee <page_lookup>
	if (pageInfo == NULL)
f0101381:	83 c4 10             	add    $0x10,%esp
f0101384:	85 c0                	test   %eax,%eax
f0101386:	75 05                	jne    f010138d <page_remove+0x23>
}
f0101388:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010138b:	c9                   	leave  
f010138c:	c3                   	ret    
	page_decref(pageInfo); // 减少引用，如果为0，free
f010138d:	83 ec 0c             	sub    $0xc,%esp
f0101390:	50                   	push   %eax
f0101391:	e8 7f fd ff ff       	call   f0101115 <page_decref>
	*pte = 0;			   // set pte not present
f0101396:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101399:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010139f:	0f 01 3b             	invlpg (%ebx)
f01013a2:	83 c4 10             	add    $0x10,%esp
f01013a5:	eb e1                	jmp    f0101388 <page_remove+0x1e>

f01013a7 <page_insert>:
{
f01013a7:	55                   	push   %ebp
f01013a8:	89 e5                	mov    %esp,%ebp
f01013aa:	57                   	push   %edi
f01013ab:	56                   	push   %esi
f01013ac:	53                   	push   %ebx
f01013ad:	83 ec 10             	sub    $0x10,%esp
f01013b0:	e8 81 1f 00 00       	call   f0103336 <__x86.get_pc_thunk.di>
f01013b5:	81 c7 6b bc 08 00    	add    $0x8bc6b,%edi
f01013bb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f01013be:	6a 01                	push   $0x1
f01013c0:	ff 75 10             	pushl  0x10(%ebp)
f01013c3:	53                   	push   %ebx
f01013c4:	e8 75 fd ff ff       	call   f010113e <pgdir_walk>
	if (!pte)
f01013c9:	83 c4 10             	add    $0x10,%esp
f01013cc:	85 c0                	test   %eax,%eax
f01013ce:	74 56                	je     f0101426 <page_insert+0x7f>
f01013d0:	89 c6                	mov    %eax,%esi
	pp->pp_ref++;
f01013d2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013d5:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	if ((*pte) & PTE_P) // If this virtual address is already mapped. 先删掉
f01013da:	f6 06 01             	testb  $0x1,(%esi)
f01013dd:	75 36                	jne    f0101415 <page_insert+0x6e>
	return (pp - pages) << PGSHIFT;
f01013df:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f01013e5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013e8:	2b 08                	sub    (%eax),%ecx
f01013ea:	89 c8                	mov    %ecx,%eax
f01013ec:	c1 f8 03             	sar    $0x3,%eax
f01013ef:	c1 e0 0c             	shl    $0xc,%eax
	*pte = (page2pa(pp) | perm | PTE_P);
f01013f2:	8b 55 14             	mov    0x14(%ebp),%edx
f01013f5:	83 ca 01             	or     $0x1,%edx
f01013f8:	09 d0                	or     %edx,%eax
f01013fa:	89 06                	mov    %eax,(%esi)
	pgdir[PDX(va)] |= perm; // Remember this step!
f01013fc:	8b 45 10             	mov    0x10(%ebp),%eax
f01013ff:	c1 e8 16             	shr    $0x16,%eax
f0101402:	8b 7d 14             	mov    0x14(%ebp),%edi
f0101405:	09 3c 83             	or     %edi,(%ebx,%eax,4)
	return 0;
f0101408:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010140d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101410:	5b                   	pop    %ebx
f0101411:	5e                   	pop    %esi
f0101412:	5f                   	pop    %edi
f0101413:	5d                   	pop    %ebp
f0101414:	c3                   	ret    
		page_remove(pgdir, va);
f0101415:	83 ec 08             	sub    $0x8,%esp
f0101418:	ff 75 10             	pushl  0x10(%ebp)
f010141b:	53                   	push   %ebx
f010141c:	e8 49 ff ff ff       	call   f010136a <page_remove>
f0101421:	83 c4 10             	add    $0x10,%esp
f0101424:	eb b9                	jmp    f01013df <page_insert+0x38>
		return -E_NO_MEM; // 错误是负数
f0101426:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010142b:	eb e0                	jmp    f010140d <page_insert+0x66>

f010142d <mem_init>:
{
f010142d:	55                   	push   %ebp
f010142e:	89 e5                	mov    %esp,%ebp
f0101430:	57                   	push   %edi
f0101431:	56                   	push   %esi
f0101432:	53                   	push   %ebx
f0101433:	83 ec 3c             	sub    $0x3c,%esp
f0101436:	e8 ce f2 ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f010143b:	05 e5 bb 08 00       	add    $0x8bbe5,%eax
f0101440:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f0101443:	b8 15 00 00 00       	mov    $0x15,%eax
f0101448:	e8 fa f5 ff ff       	call   f0100a47 <nvram_read>
f010144d:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010144f:	b8 17 00 00 00       	mov    $0x17,%eax
f0101454:	e8 ee f5 ff ff       	call   f0100a47 <nvram_read>
f0101459:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010145b:	b8 34 00 00 00       	mov    $0x34,%eax
f0101460:	e8 e2 f5 ff ff       	call   f0100a47 <nvram_read>
f0101465:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0101468:	85 c0                	test   %eax,%eax
f010146a:	0f 85 f3 00 00 00    	jne    f0101563 <mem_init+0x136>
		totalmem = 1 * 1024 + extmem;
f0101470:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101476:	85 f6                	test   %esi,%esi
f0101478:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f010147b:	89 c1                	mov    %eax,%ecx
f010147d:	c1 e9 02             	shr    $0x2,%ecx
f0101480:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101483:	c7 c2 e8 03 19 f0    	mov    $0xf01903e8,%edx
f0101489:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f010148b:	89 da                	mov    %ebx,%edx
f010148d:	c1 ea 02             	shr    $0x2,%edx
f0101490:	89 97 04 27 00 00    	mov    %edx,0x2704(%edi)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101496:	89 c2                	mov    %eax,%edx
f0101498:	29 da                	sub    %ebx,%edx
f010149a:	52                   	push   %edx
f010149b:	53                   	push   %ebx
f010149c:	50                   	push   %eax
f010149d:	8d 87 b4 89 f7 ff    	lea    -0x8764c(%edi),%eax
f01014a3:	50                   	push   %eax
f01014a4:	89 fb                	mov    %edi,%ebx
f01014a6:	e8 09 27 00 00       	call   f0103bb4 <cprintf>
	kern_pgdir = (pde_t *)boot_alloc(PGSIZE);
f01014ab:	b8 00 10 00 00       	mov    $0x1000,%eax
f01014b0:	e8 c8 f5 ff ff       	call   f0100a7d <boot_alloc>
f01014b5:	c7 c6 ec 03 19 f0    	mov    $0xf01903ec,%esi
f01014bb:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f01014bd:	83 c4 0c             	add    $0xc,%esp
f01014c0:	68 00 10 00 00       	push   $0x1000
f01014c5:	6a 00                	push   $0x0
f01014c7:	50                   	push   %eax
f01014c8:	e8 22 3a 00 00       	call   f0104eef <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01014cd:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f01014cf:	83 c4 10             	add    $0x10,%esp
f01014d2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01014d7:	0f 86 90 00 00 00    	jbe    f010156d <mem_init+0x140>
	return (physaddr_t)kva - KERNBASE;
f01014dd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01014e3:	83 ca 05             	or     $0x5,%edx
f01014e6:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f01014ec:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01014ef:	c7 c3 e8 03 19 f0    	mov    $0xf01903e8,%ebx
f01014f5:	8b 03                	mov    (%ebx),%eax
f01014f7:	c1 e0 03             	shl    $0x3,%eax
f01014fa:	e8 7e f5 ff ff       	call   f0100a7d <boot_alloc>
f01014ff:	c7 c6 f0 03 19 f0    	mov    $0xf01903f0,%esi
f0101505:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101507:	83 ec 04             	sub    $0x4,%esp
f010150a:	8b 13                	mov    (%ebx),%edx
f010150c:	c1 e2 03             	shl    $0x3,%edx
f010150f:	52                   	push   %edx
f0101510:	6a 00                	push   $0x0
f0101512:	50                   	push   %eax
f0101513:	89 fb                	mov    %edi,%ebx
f0101515:	e8 d5 39 00 00       	call   f0104eef <memset>
	envs = (struct Env *)boot_alloc(NENV * sizeof(struct Env));
f010151a:	b8 00 80 01 00       	mov    $0x18000,%eax
f010151f:	e8 59 f5 ff ff       	call   f0100a7d <boot_alloc>
f0101524:	c7 c2 2c f7 18 f0    	mov    $0xf018f72c,%edx
f010152a:	89 02                	mov    %eax,(%edx)
	memset(envs, 0, NENV * sizeof(struct Env));
f010152c:	83 c4 0c             	add    $0xc,%esp
f010152f:	68 00 80 01 00       	push   $0x18000
f0101534:	6a 00                	push   $0x0
f0101536:	50                   	push   %eax
f0101537:	e8 b3 39 00 00       	call   f0104eef <memset>
	page_init();
f010153c:	e8 bc f9 ff ff       	call   f0100efd <page_init>
	check_page_free_list(1);
f0101541:	b8 01 00 00 00       	mov    $0x1,%eax
f0101546:	e8 2f f6 ff ff       	call   f0100b7a <check_page_free_list>
	if (!pages)
f010154b:	83 c4 10             	add    $0x10,%esp
f010154e:	83 3e 00             	cmpl   $0x0,(%esi)
f0101551:	74 36                	je     f0101589 <mem_init+0x15c>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101553:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101556:	8b 80 00 27 00 00    	mov    0x2700(%eax),%eax
f010155c:	be 00 00 00 00       	mov    $0x0,%esi
f0101561:	eb 49                	jmp    f01015ac <mem_init+0x17f>
		totalmem = 16 * 1024 + ext16mem;
f0101563:	05 00 40 00 00       	add    $0x4000,%eax
f0101568:	e9 0e ff ff ff       	jmp    f010147b <mem_init+0x4e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010156d:	50                   	push   %eax
f010156e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101571:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f0101577:	50                   	push   %eax
f0101578:	68 9d 00 00 00       	push   $0x9d
f010157d:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0101583:	50                   	push   %eax
f0101584:	e8 28 eb ff ff       	call   f01000b1 <_panic>
		panic("'pages' is a null pointer!");
f0101589:	83 ec 04             	sub    $0x4,%esp
f010158c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010158f:	8d 83 5b 91 f7 ff    	lea    -0x86ea5(%ebx),%eax
f0101595:	50                   	push   %eax
f0101596:	68 da 02 00 00       	push   $0x2da
f010159b:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01015a1:	50                   	push   %eax
f01015a2:	e8 0a eb ff ff       	call   f01000b1 <_panic>
		++nfree;
f01015a7:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01015aa:	8b 00                	mov    (%eax),%eax
f01015ac:	85 c0                	test   %eax,%eax
f01015ae:	75 f7                	jne    f01015a7 <mem_init+0x17a>
	assert((pp0 = page_alloc(0)));
f01015b0:	83 ec 0c             	sub    $0xc,%esp
f01015b3:	6a 00                	push   $0x0
f01015b5:	e8 84 fa ff ff       	call   f010103e <page_alloc>
f01015ba:	89 c3                	mov    %eax,%ebx
f01015bc:	83 c4 10             	add    $0x10,%esp
f01015bf:	85 c0                	test   %eax,%eax
f01015c1:	0f 84 3b 02 00 00    	je     f0101802 <mem_init+0x3d5>
	assert((pp1 = page_alloc(0)));
f01015c7:	83 ec 0c             	sub    $0xc,%esp
f01015ca:	6a 00                	push   $0x0
f01015cc:	e8 6d fa ff ff       	call   f010103e <page_alloc>
f01015d1:	89 c7                	mov    %eax,%edi
f01015d3:	83 c4 10             	add    $0x10,%esp
f01015d6:	85 c0                	test   %eax,%eax
f01015d8:	0f 84 46 02 00 00    	je     f0101824 <mem_init+0x3f7>
	assert((pp2 = page_alloc(0)));
f01015de:	83 ec 0c             	sub    $0xc,%esp
f01015e1:	6a 00                	push   $0x0
f01015e3:	e8 56 fa ff ff       	call   f010103e <page_alloc>
f01015e8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01015eb:	83 c4 10             	add    $0x10,%esp
f01015ee:	85 c0                	test   %eax,%eax
f01015f0:	0f 84 50 02 00 00    	je     f0101846 <mem_init+0x419>
	assert(pp1 && pp1 != pp0);
f01015f6:	39 fb                	cmp    %edi,%ebx
f01015f8:	0f 84 6a 02 00 00    	je     f0101868 <mem_init+0x43b>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015fe:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101601:	39 c7                	cmp    %eax,%edi
f0101603:	0f 84 81 02 00 00    	je     f010188a <mem_init+0x45d>
f0101609:	39 c3                	cmp    %eax,%ebx
f010160b:	0f 84 79 02 00 00    	je     f010188a <mem_init+0x45d>
	return (pp - pages) << PGSHIFT;
f0101611:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101614:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f010161a:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages * PGSIZE);
f010161c:	c7 c0 e8 03 19 f0    	mov    $0xf01903e8,%eax
f0101622:	8b 10                	mov    (%eax),%edx
f0101624:	c1 e2 0c             	shl    $0xc,%edx
f0101627:	89 d8                	mov    %ebx,%eax
f0101629:	29 c8                	sub    %ecx,%eax
f010162b:	c1 f8 03             	sar    $0x3,%eax
f010162e:	c1 e0 0c             	shl    $0xc,%eax
f0101631:	39 d0                	cmp    %edx,%eax
f0101633:	0f 83 73 02 00 00    	jae    f01018ac <mem_init+0x47f>
f0101639:	89 f8                	mov    %edi,%eax
f010163b:	29 c8                	sub    %ecx,%eax
f010163d:	c1 f8 03             	sar    $0x3,%eax
f0101640:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages * PGSIZE);
f0101643:	39 c2                	cmp    %eax,%edx
f0101645:	0f 86 83 02 00 00    	jbe    f01018ce <mem_init+0x4a1>
f010164b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010164e:	29 c8                	sub    %ecx,%eax
f0101650:	c1 f8 03             	sar    $0x3,%eax
f0101653:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages * PGSIZE);
f0101656:	39 c2                	cmp    %eax,%edx
f0101658:	0f 86 92 02 00 00    	jbe    f01018f0 <mem_init+0x4c3>
	fl = page_free_list;
f010165e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101661:	8b 88 00 27 00 00    	mov    0x2700(%eax),%ecx
f0101667:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f010166a:	c7 80 00 27 00 00 00 	movl   $0x0,0x2700(%eax)
f0101671:	00 00 00 
	assert(!page_alloc(0));
f0101674:	83 ec 0c             	sub    $0xc,%esp
f0101677:	6a 00                	push   $0x0
f0101679:	e8 c0 f9 ff ff       	call   f010103e <page_alloc>
f010167e:	83 c4 10             	add    $0x10,%esp
f0101681:	85 c0                	test   %eax,%eax
f0101683:	0f 85 89 02 00 00    	jne    f0101912 <mem_init+0x4e5>
	page_free(pp0);
f0101689:	83 ec 0c             	sub    $0xc,%esp
f010168c:	53                   	push   %ebx
f010168d:	e8 34 fa ff ff       	call   f01010c6 <page_free>
	page_free(pp1);
f0101692:	89 3c 24             	mov    %edi,(%esp)
f0101695:	e8 2c fa ff ff       	call   f01010c6 <page_free>
	page_free(pp2);
f010169a:	83 c4 04             	add    $0x4,%esp
f010169d:	ff 75 d0             	pushl  -0x30(%ebp)
f01016a0:	e8 21 fa ff ff       	call   f01010c6 <page_free>
	assert((pp0 = page_alloc(0)));
f01016a5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016ac:	e8 8d f9 ff ff       	call   f010103e <page_alloc>
f01016b1:	89 c7                	mov    %eax,%edi
f01016b3:	83 c4 10             	add    $0x10,%esp
f01016b6:	85 c0                	test   %eax,%eax
f01016b8:	0f 84 76 02 00 00    	je     f0101934 <mem_init+0x507>
	assert((pp1 = page_alloc(0)));
f01016be:	83 ec 0c             	sub    $0xc,%esp
f01016c1:	6a 00                	push   $0x0
f01016c3:	e8 76 f9 ff ff       	call   f010103e <page_alloc>
f01016c8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01016cb:	83 c4 10             	add    $0x10,%esp
f01016ce:	85 c0                	test   %eax,%eax
f01016d0:	0f 84 80 02 00 00    	je     f0101956 <mem_init+0x529>
	assert((pp2 = page_alloc(0)));
f01016d6:	83 ec 0c             	sub    $0xc,%esp
f01016d9:	6a 00                	push   $0x0
f01016db:	e8 5e f9 ff ff       	call   f010103e <page_alloc>
f01016e0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01016e3:	83 c4 10             	add    $0x10,%esp
f01016e6:	85 c0                	test   %eax,%eax
f01016e8:	0f 84 8a 02 00 00    	je     f0101978 <mem_init+0x54b>
	assert(pp1 && pp1 != pp0);
f01016ee:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f01016f1:	0f 84 a3 02 00 00    	je     f010199a <mem_init+0x56d>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016f7:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01016fa:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01016fd:	0f 84 b9 02 00 00    	je     f01019bc <mem_init+0x58f>
f0101703:	39 c7                	cmp    %eax,%edi
f0101705:	0f 84 b1 02 00 00    	je     f01019bc <mem_init+0x58f>
	assert(!page_alloc(0));
f010170b:	83 ec 0c             	sub    $0xc,%esp
f010170e:	6a 00                	push   $0x0
f0101710:	e8 29 f9 ff ff       	call   f010103e <page_alloc>
f0101715:	83 c4 10             	add    $0x10,%esp
f0101718:	85 c0                	test   %eax,%eax
f010171a:	0f 85 be 02 00 00    	jne    f01019de <mem_init+0x5b1>
f0101720:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101723:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f0101729:	89 f9                	mov    %edi,%ecx
f010172b:	2b 08                	sub    (%eax),%ecx
f010172d:	89 c8                	mov    %ecx,%eax
f010172f:	c1 f8 03             	sar    $0x3,%eax
f0101732:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101735:	89 c1                	mov    %eax,%ecx
f0101737:	c1 e9 0c             	shr    $0xc,%ecx
f010173a:	c7 c2 e8 03 19 f0    	mov    $0xf01903e8,%edx
f0101740:	3b 0a                	cmp    (%edx),%ecx
f0101742:	0f 83 b8 02 00 00    	jae    f0101a00 <mem_init+0x5d3>
	memset(page2kva(pp0), 1, PGSIZE);
f0101748:	83 ec 04             	sub    $0x4,%esp
f010174b:	68 00 10 00 00       	push   $0x1000
f0101750:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101752:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101757:	50                   	push   %eax
f0101758:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010175b:	e8 8f 37 00 00       	call   f0104eef <memset>
	page_free(pp0);
f0101760:	89 3c 24             	mov    %edi,(%esp)
f0101763:	e8 5e f9 ff ff       	call   f01010c6 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101768:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010176f:	e8 ca f8 ff ff       	call   f010103e <page_alloc>
f0101774:	83 c4 10             	add    $0x10,%esp
f0101777:	85 c0                	test   %eax,%eax
f0101779:	0f 84 97 02 00 00    	je     f0101a16 <mem_init+0x5e9>
	assert(pp && pp0 == pp);
f010177f:	39 c7                	cmp    %eax,%edi
f0101781:	0f 85 b1 02 00 00    	jne    f0101a38 <mem_init+0x60b>
	return (pp - pages) << PGSHIFT;
f0101787:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010178a:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f0101790:	89 fa                	mov    %edi,%edx
f0101792:	2b 10                	sub    (%eax),%edx
f0101794:	c1 fa 03             	sar    $0x3,%edx
f0101797:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010179a:	89 d1                	mov    %edx,%ecx
f010179c:	c1 e9 0c             	shr    $0xc,%ecx
f010179f:	c7 c0 e8 03 19 f0    	mov    $0xf01903e8,%eax
f01017a5:	3b 08                	cmp    (%eax),%ecx
f01017a7:	0f 83 ad 02 00 00    	jae    f0101a5a <mem_init+0x62d>
	return (void *)(pa + KERNBASE);
f01017ad:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f01017b3:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01017b9:	80 38 00             	cmpb   $0x0,(%eax)
f01017bc:	0f 85 ae 02 00 00    	jne    f0101a70 <mem_init+0x643>
f01017c2:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01017c5:	39 d0                	cmp    %edx,%eax
f01017c7:	75 f0                	jne    f01017b9 <mem_init+0x38c>
	page_free_list = fl;
f01017c9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017cc:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01017cf:	89 8b 00 27 00 00    	mov    %ecx,0x2700(%ebx)
	page_free(pp0);
f01017d5:	83 ec 0c             	sub    $0xc,%esp
f01017d8:	57                   	push   %edi
f01017d9:	e8 e8 f8 ff ff       	call   f01010c6 <page_free>
	page_free(pp1);
f01017de:	83 c4 04             	add    $0x4,%esp
f01017e1:	ff 75 d0             	pushl  -0x30(%ebp)
f01017e4:	e8 dd f8 ff ff       	call   f01010c6 <page_free>
	page_free(pp2);
f01017e9:	83 c4 04             	add    $0x4,%esp
f01017ec:	ff 75 cc             	pushl  -0x34(%ebp)
f01017ef:	e8 d2 f8 ff ff       	call   f01010c6 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017f4:	8b 83 00 27 00 00    	mov    0x2700(%ebx),%eax
f01017fa:	83 c4 10             	add    $0x10,%esp
f01017fd:	e9 95 02 00 00       	jmp    f0101a97 <mem_init+0x66a>
	assert((pp0 = page_alloc(0)));
f0101802:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101805:	8d 83 76 91 f7 ff    	lea    -0x86e8a(%ebx),%eax
f010180b:	50                   	push   %eax
f010180c:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0101812:	50                   	push   %eax
f0101813:	68 e2 02 00 00       	push   $0x2e2
f0101818:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010181e:	50                   	push   %eax
f010181f:	e8 8d e8 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0101824:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101827:	8d 83 8c 91 f7 ff    	lea    -0x86e74(%ebx),%eax
f010182d:	50                   	push   %eax
f010182e:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0101834:	50                   	push   %eax
f0101835:	68 e3 02 00 00       	push   $0x2e3
f010183a:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0101840:	50                   	push   %eax
f0101841:	e8 6b e8 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f0101846:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101849:	8d 83 a2 91 f7 ff    	lea    -0x86e5e(%ebx),%eax
f010184f:	50                   	push   %eax
f0101850:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0101856:	50                   	push   %eax
f0101857:	68 e4 02 00 00       	push   $0x2e4
f010185c:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0101862:	50                   	push   %eax
f0101863:	e8 49 e8 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f0101868:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010186b:	8d 83 b8 91 f7 ff    	lea    -0x86e48(%ebx),%eax
f0101871:	50                   	push   %eax
f0101872:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0101878:	50                   	push   %eax
f0101879:	68 e7 02 00 00       	push   $0x2e7
f010187e:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0101884:	50                   	push   %eax
f0101885:	e8 27 e8 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010188a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010188d:	8d 83 f0 89 f7 ff    	lea    -0x87610(%ebx),%eax
f0101893:	50                   	push   %eax
f0101894:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010189a:	50                   	push   %eax
f010189b:	68 e8 02 00 00       	push   $0x2e8
f01018a0:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01018a6:	50                   	push   %eax
f01018a7:	e8 05 e8 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp0) < npages * PGSIZE);
f01018ac:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018af:	8d 83 10 8a f7 ff    	lea    -0x875f0(%ebx),%eax
f01018b5:	50                   	push   %eax
f01018b6:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01018bc:	50                   	push   %eax
f01018bd:	68 e9 02 00 00       	push   $0x2e9
f01018c2:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01018c8:	50                   	push   %eax
f01018c9:	e8 e3 e7 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp1) < npages * PGSIZE);
f01018ce:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018d1:	8d 83 30 8a f7 ff    	lea    -0x875d0(%ebx),%eax
f01018d7:	50                   	push   %eax
f01018d8:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01018de:	50                   	push   %eax
f01018df:	68 ea 02 00 00       	push   $0x2ea
f01018e4:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01018ea:	50                   	push   %eax
f01018eb:	e8 c1 e7 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp2) < npages * PGSIZE);
f01018f0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018f3:	8d 83 50 8a f7 ff    	lea    -0x875b0(%ebx),%eax
f01018f9:	50                   	push   %eax
f01018fa:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0101900:	50                   	push   %eax
f0101901:	68 eb 02 00 00       	push   $0x2eb
f0101906:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010190c:	50                   	push   %eax
f010190d:	e8 9f e7 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0101912:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101915:	8d 83 ca 91 f7 ff    	lea    -0x86e36(%ebx),%eax
f010191b:	50                   	push   %eax
f010191c:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0101922:	50                   	push   %eax
f0101923:	68 f2 02 00 00       	push   $0x2f2
f0101928:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010192e:	50                   	push   %eax
f010192f:	e8 7d e7 ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f0101934:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101937:	8d 83 76 91 f7 ff    	lea    -0x86e8a(%ebx),%eax
f010193d:	50                   	push   %eax
f010193e:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0101944:	50                   	push   %eax
f0101945:	68 f9 02 00 00       	push   $0x2f9
f010194a:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0101950:	50                   	push   %eax
f0101951:	e8 5b e7 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0101956:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101959:	8d 83 8c 91 f7 ff    	lea    -0x86e74(%ebx),%eax
f010195f:	50                   	push   %eax
f0101960:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0101966:	50                   	push   %eax
f0101967:	68 fa 02 00 00       	push   $0x2fa
f010196c:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0101972:	50                   	push   %eax
f0101973:	e8 39 e7 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f0101978:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010197b:	8d 83 a2 91 f7 ff    	lea    -0x86e5e(%ebx),%eax
f0101981:	50                   	push   %eax
f0101982:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0101988:	50                   	push   %eax
f0101989:	68 fb 02 00 00       	push   $0x2fb
f010198e:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0101994:	50                   	push   %eax
f0101995:	e8 17 e7 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f010199a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010199d:	8d 83 b8 91 f7 ff    	lea    -0x86e48(%ebx),%eax
f01019a3:	50                   	push   %eax
f01019a4:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01019aa:	50                   	push   %eax
f01019ab:	68 fd 02 00 00       	push   $0x2fd
f01019b0:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01019b6:	50                   	push   %eax
f01019b7:	e8 f5 e6 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019bc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019bf:	8d 83 f0 89 f7 ff    	lea    -0x87610(%ebx),%eax
f01019c5:	50                   	push   %eax
f01019c6:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01019cc:	50                   	push   %eax
f01019cd:	68 fe 02 00 00       	push   $0x2fe
f01019d2:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01019d8:	50                   	push   %eax
f01019d9:	e8 d3 e6 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f01019de:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019e1:	8d 83 ca 91 f7 ff    	lea    -0x86e36(%ebx),%eax
f01019e7:	50                   	push   %eax
f01019e8:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01019ee:	50                   	push   %eax
f01019ef:	68 ff 02 00 00       	push   $0x2ff
f01019f4:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01019fa:	50                   	push   %eax
f01019fb:	e8 b1 e6 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a00:	50                   	push   %eax
f0101a01:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f0101a07:	50                   	push   %eax
f0101a08:	6a 56                	push   $0x56
f0101a0a:	8d 83 b1 90 f7 ff    	lea    -0x86f4f(%ebx),%eax
f0101a10:	50                   	push   %eax
f0101a11:	e8 9b e6 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101a16:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a19:	8d 83 d9 91 f7 ff    	lea    -0x86e27(%ebx),%eax
f0101a1f:	50                   	push   %eax
f0101a20:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0101a26:	50                   	push   %eax
f0101a27:	68 04 03 00 00       	push   $0x304
f0101a2c:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0101a32:	50                   	push   %eax
f0101a33:	e8 79 e6 ff ff       	call   f01000b1 <_panic>
	assert(pp && pp0 == pp);
f0101a38:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a3b:	8d 83 f7 91 f7 ff    	lea    -0x86e09(%ebx),%eax
f0101a41:	50                   	push   %eax
f0101a42:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0101a48:	50                   	push   %eax
f0101a49:	68 05 03 00 00       	push   $0x305
f0101a4e:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0101a54:	50                   	push   %eax
f0101a55:	e8 57 e6 ff ff       	call   f01000b1 <_panic>
f0101a5a:	52                   	push   %edx
f0101a5b:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f0101a61:	50                   	push   %eax
f0101a62:	6a 56                	push   $0x56
f0101a64:	8d 83 b1 90 f7 ff    	lea    -0x86f4f(%ebx),%eax
f0101a6a:	50                   	push   %eax
f0101a6b:	e8 41 e6 ff ff       	call   f01000b1 <_panic>
		assert(c[i] == 0);
f0101a70:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a73:	8d 83 07 92 f7 ff    	lea    -0x86df9(%ebx),%eax
f0101a79:	50                   	push   %eax
f0101a7a:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0101a80:	50                   	push   %eax
f0101a81:	68 08 03 00 00       	push   $0x308
f0101a86:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0101a8c:	50                   	push   %eax
f0101a8d:	e8 1f e6 ff ff       	call   f01000b1 <_panic>
		--nfree;
f0101a92:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101a95:	8b 00                	mov    (%eax),%eax
f0101a97:	85 c0                	test   %eax,%eax
f0101a99:	75 f7                	jne    f0101a92 <mem_init+0x665>
	assert(nfree == 0);
f0101a9b:	85 f6                	test   %esi,%esi
f0101a9d:	0f 85 65 08 00 00    	jne    f0102308 <mem_init+0xedb>
	cprintf("check_page_alloc() succeeded!\n");
f0101aa3:	83 ec 0c             	sub    $0xc,%esp
f0101aa6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101aa9:	8d 83 70 8a f7 ff    	lea    -0x87590(%ebx),%eax
f0101aaf:	50                   	push   %eax
f0101ab0:	e8 ff 20 00 00       	call   f0103bb4 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101ab5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101abc:	e8 7d f5 ff ff       	call   f010103e <page_alloc>
f0101ac1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ac4:	83 c4 10             	add    $0x10,%esp
f0101ac7:	85 c0                	test   %eax,%eax
f0101ac9:	0f 84 5b 08 00 00    	je     f010232a <mem_init+0xefd>
	assert((pp1 = page_alloc(0)));
f0101acf:	83 ec 0c             	sub    $0xc,%esp
f0101ad2:	6a 00                	push   $0x0
f0101ad4:	e8 65 f5 ff ff       	call   f010103e <page_alloc>
f0101ad9:	89 c7                	mov    %eax,%edi
f0101adb:	83 c4 10             	add    $0x10,%esp
f0101ade:	85 c0                	test   %eax,%eax
f0101ae0:	0f 84 66 08 00 00    	je     f010234c <mem_init+0xf1f>
	assert((pp2 = page_alloc(0)));
f0101ae6:	83 ec 0c             	sub    $0xc,%esp
f0101ae9:	6a 00                	push   $0x0
f0101aeb:	e8 4e f5 ff ff       	call   f010103e <page_alloc>
f0101af0:	89 c6                	mov    %eax,%esi
f0101af2:	83 c4 10             	add    $0x10,%esp
f0101af5:	85 c0                	test   %eax,%eax
f0101af7:	0f 84 71 08 00 00    	je     f010236e <mem_init+0xf41>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101afd:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0101b00:	0f 84 8a 08 00 00    	je     f0102390 <mem_init+0xf63>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101b06:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101b09:	0f 84 a3 08 00 00    	je     f01023b2 <mem_init+0xf85>
f0101b0f:	39 c7                	cmp    %eax,%edi
f0101b11:	0f 84 9b 08 00 00    	je     f01023b2 <mem_init+0xf85>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101b17:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b1a:	8b 88 00 27 00 00    	mov    0x2700(%eax),%ecx
f0101b20:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101b23:	c7 80 00 27 00 00 00 	movl   $0x0,0x2700(%eax)
f0101b2a:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b2d:	83 ec 0c             	sub    $0xc,%esp
f0101b30:	6a 00                	push   $0x0
f0101b32:	e8 07 f5 ff ff       	call   f010103e <page_alloc>
f0101b37:	83 c4 10             	add    $0x10,%esp
f0101b3a:	85 c0                	test   %eax,%eax
f0101b3c:	0f 85 92 08 00 00    	jne    f01023d4 <mem_init+0xfa7>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *)0x0, &ptep) == NULL);
f0101b42:	83 ec 04             	sub    $0x4,%esp
f0101b45:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101b48:	50                   	push   %eax
f0101b49:	6a 00                	push   $0x0
f0101b4b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b4e:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101b54:	ff 30                	pushl  (%eax)
f0101b56:	e8 93 f7 ff ff       	call   f01012ee <page_lookup>
f0101b5b:	83 c4 10             	add    $0x10,%esp
f0101b5e:	85 c0                	test   %eax,%eax
f0101b60:	0f 85 90 08 00 00    	jne    f01023f6 <mem_init+0xfc9>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101b66:	6a 02                	push   $0x2
f0101b68:	6a 00                	push   $0x0
f0101b6a:	57                   	push   %edi
f0101b6b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b6e:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101b74:	ff 30                	pushl  (%eax)
f0101b76:	e8 2c f8 ff ff       	call   f01013a7 <page_insert>
f0101b7b:	83 c4 10             	add    $0x10,%esp
f0101b7e:	85 c0                	test   %eax,%eax
f0101b80:	0f 89 92 08 00 00    	jns    f0102418 <mem_init+0xfeb>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101b86:	83 ec 0c             	sub    $0xc,%esp
f0101b89:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b8c:	e8 35 f5 ff ff       	call   f01010c6 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101b91:	6a 02                	push   $0x2
f0101b93:	6a 00                	push   $0x0
f0101b95:	57                   	push   %edi
f0101b96:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b99:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101b9f:	ff 30                	pushl  (%eax)
f0101ba1:	e8 01 f8 ff ff       	call   f01013a7 <page_insert>
f0101ba6:	83 c4 20             	add    $0x20,%esp
f0101ba9:	85 c0                	test   %eax,%eax
f0101bab:	0f 85 89 08 00 00    	jne    f010243a <mem_init+0x100d>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101bb1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101bb4:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101bba:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101bbc:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f0101bc2:	8b 08                	mov    (%eax),%ecx
f0101bc4:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101bc7:	8b 13                	mov    (%ebx),%edx
f0101bc9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101bcf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bd2:	29 c8                	sub    %ecx,%eax
f0101bd4:	c1 f8 03             	sar    $0x3,%eax
f0101bd7:	c1 e0 0c             	shl    $0xc,%eax
f0101bda:	39 c2                	cmp    %eax,%edx
f0101bdc:	0f 85 7a 08 00 00    	jne    f010245c <mem_init+0x102f>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101be2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101be7:	89 d8                	mov    %ebx,%eax
f0101be9:	e8 0f ef ff ff       	call   f0100afd <check_va2pa>
f0101bee:	89 fa                	mov    %edi,%edx
f0101bf0:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101bf3:	c1 fa 03             	sar    $0x3,%edx
f0101bf6:	c1 e2 0c             	shl    $0xc,%edx
f0101bf9:	39 d0                	cmp    %edx,%eax
f0101bfb:	0f 85 7d 08 00 00    	jne    f010247e <mem_init+0x1051>
	assert(pp1->pp_ref == 1);
f0101c01:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101c06:	0f 85 94 08 00 00    	jne    f01024a0 <mem_init+0x1073>
	assert(pp0->pp_ref == 1);
f0101c0c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c0f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c14:	0f 85 a8 08 00 00    	jne    f01024c2 <mem_init+0x1095>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101c1a:	6a 02                	push   $0x2
f0101c1c:	68 00 10 00 00       	push   $0x1000
f0101c21:	56                   	push   %esi
f0101c22:	53                   	push   %ebx
f0101c23:	e8 7f f7 ff ff       	call   f01013a7 <page_insert>
f0101c28:	83 c4 10             	add    $0x10,%esp
f0101c2b:	85 c0                	test   %eax,%eax
f0101c2d:	0f 85 b1 08 00 00    	jne    f01024e4 <mem_init+0x10b7>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c33:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c38:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c3b:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101c41:	8b 00                	mov    (%eax),%eax
f0101c43:	e8 b5 ee ff ff       	call   f0100afd <check_va2pa>
f0101c48:	c7 c2 f0 03 19 f0    	mov    $0xf01903f0,%edx
f0101c4e:	89 f1                	mov    %esi,%ecx
f0101c50:	2b 0a                	sub    (%edx),%ecx
f0101c52:	89 ca                	mov    %ecx,%edx
f0101c54:	c1 fa 03             	sar    $0x3,%edx
f0101c57:	c1 e2 0c             	shl    $0xc,%edx
f0101c5a:	39 d0                	cmp    %edx,%eax
f0101c5c:	0f 85 a4 08 00 00    	jne    f0102506 <mem_init+0x10d9>
	assert(pp2->pp_ref == 1);
f0101c62:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c67:	0f 85 bb 08 00 00    	jne    f0102528 <mem_init+0x10fb>

	// should be no free memory
	assert(!page_alloc(0));
f0101c6d:	83 ec 0c             	sub    $0xc,%esp
f0101c70:	6a 00                	push   $0x0
f0101c72:	e8 c7 f3 ff ff       	call   f010103e <page_alloc>
f0101c77:	83 c4 10             	add    $0x10,%esp
f0101c7a:	85 c0                	test   %eax,%eax
f0101c7c:	0f 85 c8 08 00 00    	jne    f010254a <mem_init+0x111d>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101c82:	6a 02                	push   $0x2
f0101c84:	68 00 10 00 00       	push   $0x1000
f0101c89:	56                   	push   %esi
f0101c8a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c8d:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101c93:	ff 30                	pushl  (%eax)
f0101c95:	e8 0d f7 ff ff       	call   f01013a7 <page_insert>
f0101c9a:	83 c4 10             	add    $0x10,%esp
f0101c9d:	85 c0                	test   %eax,%eax
f0101c9f:	0f 85 c7 08 00 00    	jne    f010256c <mem_init+0x113f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ca5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101caa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101cad:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101cb3:	8b 00                	mov    (%eax),%eax
f0101cb5:	e8 43 ee ff ff       	call   f0100afd <check_va2pa>
f0101cba:	c7 c2 f0 03 19 f0    	mov    $0xf01903f0,%edx
f0101cc0:	89 f1                	mov    %esi,%ecx
f0101cc2:	2b 0a                	sub    (%edx),%ecx
f0101cc4:	89 ca                	mov    %ecx,%edx
f0101cc6:	c1 fa 03             	sar    $0x3,%edx
f0101cc9:	c1 e2 0c             	shl    $0xc,%edx
f0101ccc:	39 d0                	cmp    %edx,%eax
f0101cce:	0f 85 ba 08 00 00    	jne    f010258e <mem_init+0x1161>
	assert(pp2->pp_ref == 1);
f0101cd4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cd9:	0f 85 d1 08 00 00    	jne    f01025b0 <mem_init+0x1183>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101cdf:	83 ec 0c             	sub    $0xc,%esp
f0101ce2:	6a 00                	push   $0x0
f0101ce4:	e8 55 f3 ff ff       	call   f010103e <page_alloc>
f0101ce9:	83 c4 10             	add    $0x10,%esp
f0101cec:	85 c0                	test   %eax,%eax
f0101cee:	0f 85 de 08 00 00    	jne    f01025d2 <mem_init+0x11a5>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101cf4:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101cf7:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101cfd:	8b 10                	mov    (%eax),%edx
f0101cff:	8b 02                	mov    (%edx),%eax
f0101d01:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101d06:	89 c3                	mov    %eax,%ebx
f0101d08:	c1 eb 0c             	shr    $0xc,%ebx
f0101d0b:	c7 c1 e8 03 19 f0    	mov    $0xf01903e8,%ecx
f0101d11:	3b 19                	cmp    (%ecx),%ebx
f0101d13:	0f 83 db 08 00 00    	jae    f01025f4 <mem_init+0x11c7>
	return (void *)(pa + KERNBASE);
f0101d19:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d1e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) == ptep + PTX(PGSIZE));
f0101d21:	83 ec 04             	sub    $0x4,%esp
f0101d24:	6a 00                	push   $0x0
f0101d26:	68 00 10 00 00       	push   $0x1000
f0101d2b:	52                   	push   %edx
f0101d2c:	e8 0d f4 ff ff       	call   f010113e <pgdir_walk>
f0101d31:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d34:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d37:	83 c4 10             	add    $0x10,%esp
f0101d3a:	39 d0                	cmp    %edx,%eax
f0101d3c:	0f 85 ce 08 00 00    	jne    f0102610 <mem_init+0x11e3>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W | PTE_U) == 0);
f0101d42:	6a 06                	push   $0x6
f0101d44:	68 00 10 00 00       	push   $0x1000
f0101d49:	56                   	push   %esi
f0101d4a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d4d:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101d53:	ff 30                	pushl  (%eax)
f0101d55:	e8 4d f6 ff ff       	call   f01013a7 <page_insert>
f0101d5a:	83 c4 10             	add    $0x10,%esp
f0101d5d:	85 c0                	test   %eax,%eax
f0101d5f:	0f 85 cd 08 00 00    	jne    f0102632 <mem_init+0x1205>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d65:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d68:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101d6e:	8b 18                	mov    (%eax),%ebx
f0101d70:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d75:	89 d8                	mov    %ebx,%eax
f0101d77:	e8 81 ed ff ff       	call   f0100afd <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101d7c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101d7f:	c7 c2 f0 03 19 f0    	mov    $0xf01903f0,%edx
f0101d85:	89 f1                	mov    %esi,%ecx
f0101d87:	2b 0a                	sub    (%edx),%ecx
f0101d89:	89 ca                	mov    %ecx,%edx
f0101d8b:	c1 fa 03             	sar    $0x3,%edx
f0101d8e:	c1 e2 0c             	shl    $0xc,%edx
f0101d91:	39 d0                	cmp    %edx,%eax
f0101d93:	0f 85 bb 08 00 00    	jne    f0102654 <mem_init+0x1227>
	assert(pp2->pp_ref == 1);
f0101d99:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d9e:	0f 85 d2 08 00 00    	jne    f0102676 <mem_init+0x1249>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U);
f0101da4:	83 ec 04             	sub    $0x4,%esp
f0101da7:	6a 00                	push   $0x0
f0101da9:	68 00 10 00 00       	push   $0x1000
f0101dae:	53                   	push   %ebx
f0101daf:	e8 8a f3 ff ff       	call   f010113e <pgdir_walk>
f0101db4:	83 c4 10             	add    $0x10,%esp
f0101db7:	f6 00 04             	testb  $0x4,(%eax)
f0101dba:	0f 84 d8 08 00 00    	je     f0102698 <mem_init+0x126b>
	assert(kern_pgdir[0] & PTE_U);
f0101dc0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dc3:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101dc9:	8b 00                	mov    (%eax),%eax
f0101dcb:	f6 00 04             	testb  $0x4,(%eax)
f0101dce:	0f 84 e6 08 00 00    	je     f01026ba <mem_init+0x128d>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101dd4:	6a 02                	push   $0x2
f0101dd6:	68 00 10 00 00       	push   $0x1000
f0101ddb:	56                   	push   %esi
f0101ddc:	50                   	push   %eax
f0101ddd:	e8 c5 f5 ff ff       	call   f01013a7 <page_insert>
f0101de2:	83 c4 10             	add    $0x10,%esp
f0101de5:	85 c0                	test   %eax,%eax
f0101de7:	0f 85 ef 08 00 00    	jne    f01026dc <mem_init+0x12af>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_W);
f0101ded:	83 ec 04             	sub    $0x4,%esp
f0101df0:	6a 00                	push   $0x0
f0101df2:	68 00 10 00 00       	push   $0x1000
f0101df7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dfa:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101e00:	ff 30                	pushl  (%eax)
f0101e02:	e8 37 f3 ff ff       	call   f010113e <pgdir_walk>
f0101e07:	83 c4 10             	add    $0x10,%esp
f0101e0a:	f6 00 02             	testb  $0x2,(%eax)
f0101e0d:	0f 84 eb 08 00 00    	je     f01026fe <mem_init+0x12d1>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0101e13:	83 ec 04             	sub    $0x4,%esp
f0101e16:	6a 00                	push   $0x0
f0101e18:	68 00 10 00 00       	push   $0x1000
f0101e1d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e20:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101e26:	ff 30                	pushl  (%eax)
f0101e28:	e8 11 f3 ff ff       	call   f010113e <pgdir_walk>
f0101e2d:	83 c4 10             	add    $0x10,%esp
f0101e30:	f6 00 04             	testb  $0x4,(%eax)
f0101e33:	0f 85 e7 08 00 00    	jne    f0102720 <mem_init+0x12f3>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void *)PTSIZE, PTE_W) < 0);
f0101e39:	6a 02                	push   $0x2
f0101e3b:	68 00 00 40 00       	push   $0x400000
f0101e40:	ff 75 d0             	pushl  -0x30(%ebp)
f0101e43:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e46:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101e4c:	ff 30                	pushl  (%eax)
f0101e4e:	e8 54 f5 ff ff       	call   f01013a7 <page_insert>
f0101e53:	83 c4 10             	add    $0x10,%esp
f0101e56:	85 c0                	test   %eax,%eax
f0101e58:	0f 89 e4 08 00 00    	jns    f0102742 <mem_init+0x1315>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W) == 0);
f0101e5e:	6a 02                	push   $0x2
f0101e60:	68 00 10 00 00       	push   $0x1000
f0101e65:	57                   	push   %edi
f0101e66:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e69:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101e6f:	ff 30                	pushl  (%eax)
f0101e71:	e8 31 f5 ff ff       	call   f01013a7 <page_insert>
f0101e76:	83 c4 10             	add    $0x10,%esp
f0101e79:	85 c0                	test   %eax,%eax
f0101e7b:	0f 85 e3 08 00 00    	jne    f0102764 <mem_init+0x1337>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0101e81:	83 ec 04             	sub    $0x4,%esp
f0101e84:	6a 00                	push   $0x0
f0101e86:	68 00 10 00 00       	push   $0x1000
f0101e8b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e8e:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101e94:	ff 30                	pushl  (%eax)
f0101e96:	e8 a3 f2 ff ff       	call   f010113e <pgdir_walk>
f0101e9b:	83 c4 10             	add    $0x10,%esp
f0101e9e:	f6 00 04             	testb  $0x4,(%eax)
f0101ea1:	0f 85 df 08 00 00    	jne    f0102786 <mem_init+0x1359>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ea7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eaa:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0101eb0:	8b 18                	mov    (%eax),%ebx
f0101eb2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101eb7:	89 d8                	mov    %ebx,%eax
f0101eb9:	e8 3f ec ff ff       	call   f0100afd <check_va2pa>
f0101ebe:	89 c2                	mov    %eax,%edx
f0101ec0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ec3:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ec6:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f0101ecc:	89 f9                	mov    %edi,%ecx
f0101ece:	2b 08                	sub    (%eax),%ecx
f0101ed0:	89 c8                	mov    %ecx,%eax
f0101ed2:	c1 f8 03             	sar    $0x3,%eax
f0101ed5:	c1 e0 0c             	shl    $0xc,%eax
f0101ed8:	39 c2                	cmp    %eax,%edx
f0101eda:	0f 85 c8 08 00 00    	jne    f01027a8 <mem_init+0x137b>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ee0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ee5:	89 d8                	mov    %ebx,%eax
f0101ee7:	e8 11 ec ff ff       	call   f0100afd <check_va2pa>
f0101eec:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101eef:	0f 85 d5 08 00 00    	jne    f01027ca <mem_init+0x139d>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101ef5:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101efa:	0f 85 ec 08 00 00    	jne    f01027ec <mem_init+0x13bf>
	assert(pp2->pp_ref == 0);
f0101f00:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f05:	0f 85 03 09 00 00    	jne    f010280e <mem_init+0x13e1>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f0b:	83 ec 0c             	sub    $0xc,%esp
f0101f0e:	6a 00                	push   $0x0
f0101f10:	e8 29 f1 ff ff       	call   f010103e <page_alloc>
f0101f15:	83 c4 10             	add    $0x10,%esp
f0101f18:	39 c6                	cmp    %eax,%esi
f0101f1a:	0f 85 10 09 00 00    	jne    f0102830 <mem_init+0x1403>
f0101f20:	85 c0                	test   %eax,%eax
f0101f22:	0f 84 08 09 00 00    	je     f0102830 <mem_init+0x1403>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f28:	83 ec 08             	sub    $0x8,%esp
f0101f2b:	6a 00                	push   $0x0
f0101f2d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f30:	c7 c3 ec 03 19 f0    	mov    $0xf01903ec,%ebx
f0101f36:	ff 33                	pushl  (%ebx)
f0101f38:	e8 2d f4 ff ff       	call   f010136a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f3d:	8b 1b                	mov    (%ebx),%ebx
f0101f3f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f44:	89 d8                	mov    %ebx,%eax
f0101f46:	e8 b2 eb ff ff       	call   f0100afd <check_va2pa>
f0101f4b:	83 c4 10             	add    $0x10,%esp
f0101f4e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f51:	0f 85 fb 08 00 00    	jne    f0102852 <mem_init+0x1425>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f57:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f5c:	89 d8                	mov    %ebx,%eax
f0101f5e:	e8 9a eb ff ff       	call   f0100afd <check_va2pa>
f0101f63:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101f66:	c7 c2 f0 03 19 f0    	mov    $0xf01903f0,%edx
f0101f6c:	89 f9                	mov    %edi,%ecx
f0101f6e:	2b 0a                	sub    (%edx),%ecx
f0101f70:	89 ca                	mov    %ecx,%edx
f0101f72:	c1 fa 03             	sar    $0x3,%edx
f0101f75:	c1 e2 0c             	shl    $0xc,%edx
f0101f78:	39 d0                	cmp    %edx,%eax
f0101f7a:	0f 85 f4 08 00 00    	jne    f0102874 <mem_init+0x1447>
	assert(pp1->pp_ref == 1);
f0101f80:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101f85:	0f 85 0b 09 00 00    	jne    f0102896 <mem_init+0x1469>
	assert(pp2->pp_ref == 0);
f0101f8b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f90:	0f 85 22 09 00 00    	jne    f01028b8 <mem_init+0x148b>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, 0) == 0);
f0101f96:	6a 00                	push   $0x0
f0101f98:	68 00 10 00 00       	push   $0x1000
f0101f9d:	57                   	push   %edi
f0101f9e:	53                   	push   %ebx
f0101f9f:	e8 03 f4 ff ff       	call   f01013a7 <page_insert>
f0101fa4:	83 c4 10             	add    $0x10,%esp
f0101fa7:	85 c0                	test   %eax,%eax
f0101fa9:	0f 85 2b 09 00 00    	jne    f01028da <mem_init+0x14ad>
	assert(pp1->pp_ref);
f0101faf:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101fb4:	0f 84 42 09 00 00    	je     f01028fc <mem_init+0x14cf>
	assert(pp1->pp_link == NULL);
f0101fba:	83 3f 00             	cmpl   $0x0,(%edi)
f0101fbd:	0f 85 5b 09 00 00    	jne    f010291e <mem_init+0x14f1>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void *)PGSIZE);
f0101fc3:	83 ec 08             	sub    $0x8,%esp
f0101fc6:	68 00 10 00 00       	push   $0x1000
f0101fcb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fce:	c7 c3 ec 03 19 f0    	mov    $0xf01903ec,%ebx
f0101fd4:	ff 33                	pushl  (%ebx)
f0101fd6:	e8 8f f3 ff ff       	call   f010136a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101fdb:	8b 1b                	mov    (%ebx),%ebx
f0101fdd:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fe2:	89 d8                	mov    %ebx,%eax
f0101fe4:	e8 14 eb ff ff       	call   f0100afd <check_va2pa>
f0101fe9:	83 c4 10             	add    $0x10,%esp
f0101fec:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fef:	0f 85 4b 09 00 00    	jne    f0102940 <mem_init+0x1513>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101ff5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ffa:	89 d8                	mov    %ebx,%eax
f0101ffc:	e8 fc ea ff ff       	call   f0100afd <check_va2pa>
f0102001:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102004:	0f 85 58 09 00 00    	jne    f0102962 <mem_init+0x1535>
	assert(pp1->pp_ref == 0);
f010200a:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010200f:	0f 85 6f 09 00 00    	jne    f0102984 <mem_init+0x1557>
	assert(pp2->pp_ref == 0);
f0102015:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010201a:	0f 85 86 09 00 00    	jne    f01029a6 <mem_init+0x1579>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102020:	83 ec 0c             	sub    $0xc,%esp
f0102023:	6a 00                	push   $0x0
f0102025:	e8 14 f0 ff ff       	call   f010103e <page_alloc>
f010202a:	83 c4 10             	add    $0x10,%esp
f010202d:	85 c0                	test   %eax,%eax
f010202f:	0f 84 93 09 00 00    	je     f01029c8 <mem_init+0x159b>
f0102035:	39 c7                	cmp    %eax,%edi
f0102037:	0f 85 8b 09 00 00    	jne    f01029c8 <mem_init+0x159b>

	// should be no free memory
	assert(!page_alloc(0));
f010203d:	83 ec 0c             	sub    $0xc,%esp
f0102040:	6a 00                	push   $0x0
f0102042:	e8 f7 ef ff ff       	call   f010103e <page_alloc>
f0102047:	83 c4 10             	add    $0x10,%esp
f010204a:	85 c0                	test   %eax,%eax
f010204c:	0f 85 98 09 00 00    	jne    f01029ea <mem_init+0x15bd>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102052:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102055:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f010205b:	8b 08                	mov    (%eax),%ecx
f010205d:	8b 11                	mov    (%ecx),%edx
f010205f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102065:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f010206b:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f010206e:	2b 18                	sub    (%eax),%ebx
f0102070:	89 d8                	mov    %ebx,%eax
f0102072:	c1 f8 03             	sar    $0x3,%eax
f0102075:	c1 e0 0c             	shl    $0xc,%eax
f0102078:	39 c2                	cmp    %eax,%edx
f010207a:	0f 85 8c 09 00 00    	jne    f0102a0c <mem_init+0x15df>
	kern_pgdir[0] = 0;
f0102080:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102086:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102089:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010208e:	0f 85 9a 09 00 00    	jne    f0102a2e <mem_init+0x1601>
	pp0->pp_ref = 0;
f0102094:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102097:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010209d:	83 ec 0c             	sub    $0xc,%esp
f01020a0:	50                   	push   %eax
f01020a1:	e8 20 f0 ff ff       	call   f01010c6 <page_free>
	va = (void *)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01020a6:	83 c4 0c             	add    $0xc,%esp
f01020a9:	6a 01                	push   $0x1
f01020ab:	68 00 10 40 00       	push   $0x401000
f01020b0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020b3:	c7 c3 ec 03 19 f0    	mov    $0xf01903ec,%ebx
f01020b9:	ff 33                	pushl  (%ebx)
f01020bb:	e8 7e f0 ff ff       	call   f010113e <pgdir_walk>
f01020c0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020c3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01020c6:	8b 1b                	mov    (%ebx),%ebx
f01020c8:	8b 53 04             	mov    0x4(%ebx),%edx
f01020cb:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f01020d1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01020d4:	c7 c1 e8 03 19 f0    	mov    $0xf01903e8,%ecx
f01020da:	8b 09                	mov    (%ecx),%ecx
f01020dc:	89 d0                	mov    %edx,%eax
f01020de:	c1 e8 0c             	shr    $0xc,%eax
f01020e1:	83 c4 10             	add    $0x10,%esp
f01020e4:	39 c8                	cmp    %ecx,%eax
f01020e6:	0f 83 64 09 00 00    	jae    f0102a50 <mem_init+0x1623>
	assert(ptep == ptep1 + PTX(va));
f01020ec:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f01020f2:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f01020f5:	0f 85 71 09 00 00    	jne    f0102a6c <mem_init+0x163f>
	kern_pgdir[PDX(va)] = 0;
f01020fb:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0102102:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102105:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f010210b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010210e:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f0102114:	2b 18                	sub    (%eax),%ebx
f0102116:	89 d8                	mov    %ebx,%eax
f0102118:	c1 f8 03             	sar    $0x3,%eax
f010211b:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010211e:	89 c2                	mov    %eax,%edx
f0102120:	c1 ea 0c             	shr    $0xc,%edx
f0102123:	39 d1                	cmp    %edx,%ecx
f0102125:	0f 86 63 09 00 00    	jbe    f0102a8e <mem_init+0x1661>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010212b:	83 ec 04             	sub    $0x4,%esp
f010212e:	68 00 10 00 00       	push   $0x1000
f0102133:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0102138:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010213d:	50                   	push   %eax
f010213e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102141:	e8 a9 2d 00 00       	call   f0104eef <memset>
	page_free(pp0);
f0102146:	83 c4 04             	add    $0x4,%esp
f0102149:	ff 75 d0             	pushl  -0x30(%ebp)
f010214c:	e8 75 ef ff ff       	call   f01010c6 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102151:	83 c4 0c             	add    $0xc,%esp
f0102154:	6a 01                	push   $0x1
f0102156:	6a 00                	push   $0x0
f0102158:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010215b:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0102161:	ff 30                	pushl  (%eax)
f0102163:	e8 d6 ef ff ff       	call   f010113e <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0102168:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f010216e:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0102171:	2b 10                	sub    (%eax),%edx
f0102173:	c1 fa 03             	sar    $0x3,%edx
f0102176:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102179:	89 d1                	mov    %edx,%ecx
f010217b:	c1 e9 0c             	shr    $0xc,%ecx
f010217e:	83 c4 10             	add    $0x10,%esp
f0102181:	c7 c0 e8 03 19 f0    	mov    $0xf01903e8,%eax
f0102187:	3b 08                	cmp    (%eax),%ecx
f0102189:	0f 83 18 09 00 00    	jae    f0102aa7 <mem_init+0x167a>
	return (void *)(pa + KERNBASE);
f010218f:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *)page2kva(pp0);
f0102195:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102198:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for (i = 0; i < NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010219e:	f6 00 01             	testb  $0x1,(%eax)
f01021a1:	0f 85 19 09 00 00    	jne    f0102ac0 <mem_init+0x1693>
f01021a7:	83 c0 04             	add    $0x4,%eax
	for (i = 0; i < NPTENTRIES; i++)
f01021aa:	39 d0                	cmp    %edx,%eax
f01021ac:	75 f0                	jne    f010219e <mem_init+0xd71>
	kern_pgdir[0] = 0;
f01021ae:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021b1:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f01021b7:	8b 00                	mov    (%eax),%eax
f01021b9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01021bf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01021c2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01021c8:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01021cb:	89 93 00 27 00 00    	mov    %edx,0x2700(%ebx)

	// free the pages we took
	page_free(pp0);
f01021d1:	83 ec 0c             	sub    $0xc,%esp
f01021d4:	50                   	push   %eax
f01021d5:	e8 ec ee ff ff       	call   f01010c6 <page_free>
	page_free(pp1);
f01021da:	89 3c 24             	mov    %edi,(%esp)
f01021dd:	e8 e4 ee ff ff       	call   f01010c6 <page_free>
	page_free(pp2);
f01021e2:	89 34 24             	mov    %esi,(%esp)
f01021e5:	e8 dc ee ff ff       	call   f01010c6 <page_free>

	cprintf("check_page() succeeded!\n");
f01021ea:	8d 83 e8 92 f7 ff    	lea    -0x86d18(%ebx),%eax
f01021f0:	89 04 24             	mov    %eax,(%esp)
f01021f3:	e8 bc 19 00 00       	call   f0103bb4 <cprintf>
	boot_map_region(kern_pgdir, UPAGES, npages * sizeof(struct PageInfo), PADDR(pages), PTE_U);
f01021f8:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f01021fe:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102200:	83 c4 10             	add    $0x10,%esp
f0102203:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102208:	0f 86 d4 08 00 00    	jbe    f0102ae2 <mem_init+0x16b5>
f010220e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102211:	c7 c2 e8 03 19 f0    	mov    $0xf01903e8,%edx
f0102217:	8b 0a                	mov    (%edx),%ecx
f0102219:	c1 e1 03             	shl    $0x3,%ecx
f010221c:	83 ec 08             	sub    $0x8,%esp
f010221f:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102221:	05 00 00 00 10       	add    $0x10000000,%eax
f0102226:	50                   	push   %eax
f0102227:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010222c:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0102232:	8b 00                	mov    (%eax),%eax
f0102234:	e8 23 f0 ff ff       	call   f010125c <boot_map_region>
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f0102239:	c7 c0 2c f7 18 f0    	mov    $0xf018f72c,%eax
f010223f:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102241:	83 c4 10             	add    $0x10,%esp
f0102244:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102249:	0f 86 af 08 00 00    	jbe    f0102afe <mem_init+0x16d1>
f010224f:	83 ec 08             	sub    $0x8,%esp
f0102252:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102254:	05 00 00 00 10       	add    $0x10000000,%eax
f0102259:	50                   	push   %eax
f010225a:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010225f:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102264:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102267:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f010226d:	8b 00                	mov    (%eax),%eax
f010226f:	e8 e8 ef ff ff       	call   f010125c <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102274:	c7 c0 00 30 11 f0    	mov    $0xf0113000,%eax
f010227a:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010227d:	83 c4 10             	add    $0x10,%esp
f0102280:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102285:	0f 86 8f 08 00 00    	jbe    f0102b1a <mem_init+0x16ed>
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f010228b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010228e:	c7 c3 ec 03 19 f0    	mov    $0xf01903ec,%ebx
f0102294:	83 ec 08             	sub    $0x8,%esp
f0102297:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f0102299:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010229c:	05 00 00 00 10       	add    $0x10000000,%eax
f01022a1:	50                   	push   %eax
f01022a2:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01022a7:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01022ac:	8b 03                	mov    (%ebx),%eax
f01022ae:	e8 a9 ef ff ff       	call   f010125c <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f01022b3:	83 c4 08             	add    $0x8,%esp
f01022b6:	6a 02                	push   $0x2
f01022b8:	6a 00                	push   $0x0
f01022ba:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01022bf:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01022c4:	8b 03                	mov    (%ebx),%eax
f01022c6:	e8 91 ef ff ff       	call   f010125c <boot_map_region>
	pgdir = kern_pgdir;
f01022cb:	8b 33                	mov    (%ebx),%esi
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
f01022cd:	c7 c0 e8 03 19 f0    	mov    $0xf01903e8,%eax
f01022d3:	8b 00                	mov    (%eax),%eax
f01022d5:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01022d8:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01022df:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01022e4:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01022e7:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f01022ed:	8b 00                	mov    (%eax),%eax
f01022ef:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01022f2:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01022f5:	8d b8 00 00 00 10    	lea    0x10000000(%eax),%edi
f01022fb:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f01022fe:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102303:	e9 57 08 00 00       	jmp    f0102b5f <mem_init+0x1732>
	assert(nfree == 0);
f0102308:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010230b:	8d 83 11 92 f7 ff    	lea    -0x86def(%ebx),%eax
f0102311:	50                   	push   %eax
f0102312:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102318:	50                   	push   %eax
f0102319:	68 15 03 00 00       	push   $0x315
f010231e:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102324:	50                   	push   %eax
f0102325:	e8 87 dd ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f010232a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010232d:	8d 83 76 91 f7 ff    	lea    -0x86e8a(%ebx),%eax
f0102333:	50                   	push   %eax
f0102334:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010233a:	50                   	push   %eax
f010233b:	68 76 03 00 00       	push   $0x376
f0102340:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102346:	50                   	push   %eax
f0102347:	e8 65 dd ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f010234c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010234f:	8d 83 8c 91 f7 ff    	lea    -0x86e74(%ebx),%eax
f0102355:	50                   	push   %eax
f0102356:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010235c:	50                   	push   %eax
f010235d:	68 77 03 00 00       	push   $0x377
f0102362:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102368:	50                   	push   %eax
f0102369:	e8 43 dd ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f010236e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102371:	8d 83 a2 91 f7 ff    	lea    -0x86e5e(%ebx),%eax
f0102377:	50                   	push   %eax
f0102378:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010237e:	50                   	push   %eax
f010237f:	68 78 03 00 00       	push   $0x378
f0102384:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010238a:	50                   	push   %eax
f010238b:	e8 21 dd ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f0102390:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102393:	8d 83 b8 91 f7 ff    	lea    -0x86e48(%ebx),%eax
f0102399:	50                   	push   %eax
f010239a:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01023a0:	50                   	push   %eax
f01023a1:	68 7b 03 00 00       	push   $0x37b
f01023a6:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01023ac:	50                   	push   %eax
f01023ad:	e8 ff dc ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01023b2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023b5:	8d 83 f0 89 f7 ff    	lea    -0x87610(%ebx),%eax
f01023bb:	50                   	push   %eax
f01023bc:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01023c2:	50                   	push   %eax
f01023c3:	68 7c 03 00 00       	push   $0x37c
f01023c8:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01023ce:	50                   	push   %eax
f01023cf:	e8 dd dc ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f01023d4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023d7:	8d 83 ca 91 f7 ff    	lea    -0x86e36(%ebx),%eax
f01023dd:	50                   	push   %eax
f01023de:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01023e4:	50                   	push   %eax
f01023e5:	68 83 03 00 00       	push   $0x383
f01023ea:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01023f0:	50                   	push   %eax
f01023f1:	e8 bb dc ff ff       	call   f01000b1 <_panic>
	assert(page_lookup(kern_pgdir, (void *)0x0, &ptep) == NULL);
f01023f6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023f9:	8d 83 90 8a f7 ff    	lea    -0x87570(%ebx),%eax
f01023ff:	50                   	push   %eax
f0102400:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102406:	50                   	push   %eax
f0102407:	68 86 03 00 00       	push   $0x386
f010240c:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102412:	50                   	push   %eax
f0102413:	e8 99 dc ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102418:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010241b:	8d 83 c4 8a f7 ff    	lea    -0x8753c(%ebx),%eax
f0102421:	50                   	push   %eax
f0102422:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102428:	50                   	push   %eax
f0102429:	68 89 03 00 00       	push   $0x389
f010242e:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102434:	50                   	push   %eax
f0102435:	e8 77 dc ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010243a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010243d:	8d 83 f4 8a f7 ff    	lea    -0x8750c(%ebx),%eax
f0102443:	50                   	push   %eax
f0102444:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010244a:	50                   	push   %eax
f010244b:	68 8d 03 00 00       	push   $0x38d
f0102450:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102456:	50                   	push   %eax
f0102457:	e8 55 dc ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010245c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010245f:	8d 83 24 8b f7 ff    	lea    -0x874dc(%ebx),%eax
f0102465:	50                   	push   %eax
f0102466:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010246c:	50                   	push   %eax
f010246d:	68 8e 03 00 00       	push   $0x38e
f0102472:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102478:	50                   	push   %eax
f0102479:	e8 33 dc ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010247e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102481:	8d 83 4c 8b f7 ff    	lea    -0x874b4(%ebx),%eax
f0102487:	50                   	push   %eax
f0102488:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010248e:	50                   	push   %eax
f010248f:	68 8f 03 00 00       	push   $0x38f
f0102494:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010249a:	50                   	push   %eax
f010249b:	e8 11 dc ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f01024a0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024a3:	8d 83 1c 92 f7 ff    	lea    -0x86de4(%ebx),%eax
f01024a9:	50                   	push   %eax
f01024aa:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01024b0:	50                   	push   %eax
f01024b1:	68 90 03 00 00       	push   $0x390
f01024b6:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01024bc:	50                   	push   %eax
f01024bd:	e8 ef db ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f01024c2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024c5:	8d 83 2d 92 f7 ff    	lea    -0x86dd3(%ebx),%eax
f01024cb:	50                   	push   %eax
f01024cc:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01024d2:	50                   	push   %eax
f01024d3:	68 91 03 00 00       	push   $0x391
f01024d8:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01024de:	50                   	push   %eax
f01024df:	e8 cd db ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f01024e4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024e7:	8d 83 7c 8b f7 ff    	lea    -0x87484(%ebx),%eax
f01024ed:	50                   	push   %eax
f01024ee:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01024f4:	50                   	push   %eax
f01024f5:	68 94 03 00 00       	push   $0x394
f01024fa:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102500:	50                   	push   %eax
f0102501:	e8 ab db ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102506:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102509:	8d 83 b8 8b f7 ff    	lea    -0x87448(%ebx),%eax
f010250f:	50                   	push   %eax
f0102510:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102516:	50                   	push   %eax
f0102517:	68 95 03 00 00       	push   $0x395
f010251c:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102522:	50                   	push   %eax
f0102523:	e8 89 db ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0102528:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010252b:	8d 83 3e 92 f7 ff    	lea    -0x86dc2(%ebx),%eax
f0102531:	50                   	push   %eax
f0102532:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102538:	50                   	push   %eax
f0102539:	68 96 03 00 00       	push   $0x396
f010253e:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102544:	50                   	push   %eax
f0102545:	e8 67 db ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f010254a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010254d:	8d 83 ca 91 f7 ff    	lea    -0x86e36(%ebx),%eax
f0102553:	50                   	push   %eax
f0102554:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010255a:	50                   	push   %eax
f010255b:	68 99 03 00 00       	push   $0x399
f0102560:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102566:	50                   	push   %eax
f0102567:	e8 45 db ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f010256c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010256f:	8d 83 7c 8b f7 ff    	lea    -0x87484(%ebx),%eax
f0102575:	50                   	push   %eax
f0102576:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010257c:	50                   	push   %eax
f010257d:	68 9c 03 00 00       	push   $0x39c
f0102582:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102588:	50                   	push   %eax
f0102589:	e8 23 db ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010258e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102591:	8d 83 b8 8b f7 ff    	lea    -0x87448(%ebx),%eax
f0102597:	50                   	push   %eax
f0102598:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010259e:	50                   	push   %eax
f010259f:	68 9d 03 00 00       	push   $0x39d
f01025a4:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01025aa:	50                   	push   %eax
f01025ab:	e8 01 db ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f01025b0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025b3:	8d 83 3e 92 f7 ff    	lea    -0x86dc2(%ebx),%eax
f01025b9:	50                   	push   %eax
f01025ba:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01025c0:	50                   	push   %eax
f01025c1:	68 9e 03 00 00       	push   $0x39e
f01025c6:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01025cc:	50                   	push   %eax
f01025cd:	e8 df da ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f01025d2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025d5:	8d 83 ca 91 f7 ff    	lea    -0x86e36(%ebx),%eax
f01025db:	50                   	push   %eax
f01025dc:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01025e2:	50                   	push   %eax
f01025e3:	68 a2 03 00 00       	push   $0x3a2
f01025e8:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01025ee:	50                   	push   %eax
f01025ef:	e8 bd da ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025f4:	50                   	push   %eax
f01025f5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025f8:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f01025fe:	50                   	push   %eax
f01025ff:	68 a5 03 00 00       	push   $0x3a5
f0102604:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010260a:	50                   	push   %eax
f010260b:	e8 a1 da ff ff       	call   f01000b1 <_panic>
	assert(pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) == ptep + PTX(PGSIZE));
f0102610:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102613:	8d 83 e8 8b f7 ff    	lea    -0x87418(%ebx),%eax
f0102619:	50                   	push   %eax
f010261a:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102620:	50                   	push   %eax
f0102621:	68 a6 03 00 00       	push   $0x3a6
f0102626:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010262c:	50                   	push   %eax
f010262d:	e8 7f da ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W | PTE_U) == 0);
f0102632:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102635:	8d 83 28 8c f7 ff    	lea    -0x873d8(%ebx),%eax
f010263b:	50                   	push   %eax
f010263c:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102642:	50                   	push   %eax
f0102643:	68 a9 03 00 00       	push   $0x3a9
f0102648:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010264e:	50                   	push   %eax
f010264f:	e8 5d da ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102654:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102657:	8d 83 b8 8b f7 ff    	lea    -0x87448(%ebx),%eax
f010265d:	50                   	push   %eax
f010265e:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102664:	50                   	push   %eax
f0102665:	68 aa 03 00 00       	push   $0x3aa
f010266a:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102670:	50                   	push   %eax
f0102671:	e8 3b da ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0102676:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102679:	8d 83 3e 92 f7 ff    	lea    -0x86dc2(%ebx),%eax
f010267f:	50                   	push   %eax
f0102680:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102686:	50                   	push   %eax
f0102687:	68 ab 03 00 00       	push   $0x3ab
f010268c:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102692:	50                   	push   %eax
f0102693:	e8 19 da ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U);
f0102698:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010269b:	8d 83 6c 8c f7 ff    	lea    -0x87394(%ebx),%eax
f01026a1:	50                   	push   %eax
f01026a2:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01026a8:	50                   	push   %eax
f01026a9:	68 ac 03 00 00       	push   $0x3ac
f01026ae:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01026b4:	50                   	push   %eax
f01026b5:	e8 f7 d9 ff ff       	call   f01000b1 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01026ba:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026bd:	8d 83 4f 92 f7 ff    	lea    -0x86db1(%ebx),%eax
f01026c3:	50                   	push   %eax
f01026c4:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01026ca:	50                   	push   %eax
f01026cb:	68 ad 03 00 00       	push   $0x3ad
f01026d0:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01026d6:	50                   	push   %eax
f01026d7:	e8 d5 d9 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f01026dc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026df:	8d 83 7c 8b f7 ff    	lea    -0x87484(%ebx),%eax
f01026e5:	50                   	push   %eax
f01026e6:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01026ec:	50                   	push   %eax
f01026ed:	68 b0 03 00 00       	push   $0x3b0
f01026f2:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01026f8:	50                   	push   %eax
f01026f9:	e8 b3 d9 ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_W);
f01026fe:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102701:	8d 83 a0 8c f7 ff    	lea    -0x87360(%ebx),%eax
f0102707:	50                   	push   %eax
f0102708:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010270e:	50                   	push   %eax
f010270f:	68 b1 03 00 00       	push   $0x3b1
f0102714:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010271a:	50                   	push   %eax
f010271b:	e8 91 d9 ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0102720:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102723:	8d 83 d4 8c f7 ff    	lea    -0x8732c(%ebx),%eax
f0102729:	50                   	push   %eax
f010272a:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102730:	50                   	push   %eax
f0102731:	68 b2 03 00 00       	push   $0x3b2
f0102736:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010273c:	50                   	push   %eax
f010273d:	e8 6f d9 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void *)PTSIZE, PTE_W) < 0);
f0102742:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102745:	8d 83 0c 8d f7 ff    	lea    -0x872f4(%ebx),%eax
f010274b:	50                   	push   %eax
f010274c:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102752:	50                   	push   %eax
f0102753:	68 b5 03 00 00       	push   $0x3b5
f0102758:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010275e:	50                   	push   %eax
f010275f:	e8 4d d9 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W) == 0);
f0102764:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102767:	8d 83 44 8d f7 ff    	lea    -0x872bc(%ebx),%eax
f010276d:	50                   	push   %eax
f010276e:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102774:	50                   	push   %eax
f0102775:	68 b8 03 00 00       	push   $0x3b8
f010277a:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102780:	50                   	push   %eax
f0102781:	e8 2b d9 ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0102786:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102789:	8d 83 d4 8c f7 ff    	lea    -0x8732c(%ebx),%eax
f010278f:	50                   	push   %eax
f0102790:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102796:	50                   	push   %eax
f0102797:	68 b9 03 00 00       	push   $0x3b9
f010279c:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01027a2:	50                   	push   %eax
f01027a3:	e8 09 d9 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01027a8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027ab:	8d 83 80 8d f7 ff    	lea    -0x87280(%ebx),%eax
f01027b1:	50                   	push   %eax
f01027b2:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01027b8:	50                   	push   %eax
f01027b9:	68 bc 03 00 00       	push   $0x3bc
f01027be:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01027c4:	50                   	push   %eax
f01027c5:	e8 e7 d8 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01027ca:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027cd:	8d 83 ac 8d f7 ff    	lea    -0x87254(%ebx),%eax
f01027d3:	50                   	push   %eax
f01027d4:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01027da:	50                   	push   %eax
f01027db:	68 bd 03 00 00       	push   $0x3bd
f01027e0:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01027e6:	50                   	push   %eax
f01027e7:	e8 c5 d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 2);
f01027ec:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027ef:	8d 83 65 92 f7 ff    	lea    -0x86d9b(%ebx),%eax
f01027f5:	50                   	push   %eax
f01027f6:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01027fc:	50                   	push   %eax
f01027fd:	68 bf 03 00 00       	push   $0x3bf
f0102802:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102808:	50                   	push   %eax
f0102809:	e8 a3 d8 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f010280e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102811:	8d 83 76 92 f7 ff    	lea    -0x86d8a(%ebx),%eax
f0102817:	50                   	push   %eax
f0102818:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010281e:	50                   	push   %eax
f010281f:	68 c0 03 00 00       	push   $0x3c0
f0102824:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010282a:	50                   	push   %eax
f010282b:	e8 81 d8 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102830:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102833:	8d 83 dc 8d f7 ff    	lea    -0x87224(%ebx),%eax
f0102839:	50                   	push   %eax
f010283a:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102840:	50                   	push   %eax
f0102841:	68 c3 03 00 00       	push   $0x3c3
f0102846:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010284c:	50                   	push   %eax
f010284d:	e8 5f d8 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102852:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102855:	8d 83 00 8e f7 ff    	lea    -0x87200(%ebx),%eax
f010285b:	50                   	push   %eax
f010285c:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102862:	50                   	push   %eax
f0102863:	68 c7 03 00 00       	push   $0x3c7
f0102868:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010286e:	50                   	push   %eax
f010286f:	e8 3d d8 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102874:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102877:	8d 83 ac 8d f7 ff    	lea    -0x87254(%ebx),%eax
f010287d:	50                   	push   %eax
f010287e:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102884:	50                   	push   %eax
f0102885:	68 c8 03 00 00       	push   $0x3c8
f010288a:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102890:	50                   	push   %eax
f0102891:	e8 1b d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f0102896:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102899:	8d 83 1c 92 f7 ff    	lea    -0x86de4(%ebx),%eax
f010289f:	50                   	push   %eax
f01028a0:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01028a6:	50                   	push   %eax
f01028a7:	68 c9 03 00 00       	push   $0x3c9
f01028ac:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01028b2:	50                   	push   %eax
f01028b3:	e8 f9 d7 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f01028b8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028bb:	8d 83 76 92 f7 ff    	lea    -0x86d8a(%ebx),%eax
f01028c1:	50                   	push   %eax
f01028c2:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01028c8:	50                   	push   %eax
f01028c9:	68 ca 03 00 00       	push   $0x3ca
f01028ce:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01028d4:	50                   	push   %eax
f01028d5:	e8 d7 d7 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, 0) == 0);
f01028da:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028dd:	8d 83 24 8e f7 ff    	lea    -0x871dc(%ebx),%eax
f01028e3:	50                   	push   %eax
f01028e4:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01028ea:	50                   	push   %eax
f01028eb:	68 cd 03 00 00       	push   $0x3cd
f01028f0:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01028f6:	50                   	push   %eax
f01028f7:	e8 b5 d7 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref);
f01028fc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028ff:	8d 83 87 92 f7 ff    	lea    -0x86d79(%ebx),%eax
f0102905:	50                   	push   %eax
f0102906:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010290c:	50                   	push   %eax
f010290d:	68 ce 03 00 00       	push   $0x3ce
f0102912:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102918:	50                   	push   %eax
f0102919:	e8 93 d7 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_link == NULL);
f010291e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102921:	8d 83 93 92 f7 ff    	lea    -0x86d6d(%ebx),%eax
f0102927:	50                   	push   %eax
f0102928:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010292e:	50                   	push   %eax
f010292f:	68 cf 03 00 00       	push   $0x3cf
f0102934:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010293a:	50                   	push   %eax
f010293b:	e8 71 d7 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102940:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102943:	8d 83 00 8e f7 ff    	lea    -0x87200(%ebx),%eax
f0102949:	50                   	push   %eax
f010294a:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102950:	50                   	push   %eax
f0102951:	68 d3 03 00 00       	push   $0x3d3
f0102956:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010295c:	50                   	push   %eax
f010295d:	e8 4f d7 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102962:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102965:	8d 83 5c 8e f7 ff    	lea    -0x871a4(%ebx),%eax
f010296b:	50                   	push   %eax
f010296c:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102972:	50                   	push   %eax
f0102973:	68 d4 03 00 00       	push   $0x3d4
f0102978:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010297e:	50                   	push   %eax
f010297f:	e8 2d d7 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f0102984:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102987:	8d 83 a8 92 f7 ff    	lea    -0x86d58(%ebx),%eax
f010298d:	50                   	push   %eax
f010298e:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102994:	50                   	push   %eax
f0102995:	68 d5 03 00 00       	push   $0x3d5
f010299a:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01029a0:	50                   	push   %eax
f01029a1:	e8 0b d7 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f01029a6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029a9:	8d 83 76 92 f7 ff    	lea    -0x86d8a(%ebx),%eax
f01029af:	50                   	push   %eax
f01029b0:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01029b6:	50                   	push   %eax
f01029b7:	68 d6 03 00 00       	push   $0x3d6
f01029bc:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01029c2:	50                   	push   %eax
f01029c3:	e8 e9 d6 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01029c8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029cb:	8d 83 84 8e f7 ff    	lea    -0x8717c(%ebx),%eax
f01029d1:	50                   	push   %eax
f01029d2:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01029d8:	50                   	push   %eax
f01029d9:	68 d9 03 00 00       	push   $0x3d9
f01029de:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01029e4:	50                   	push   %eax
f01029e5:	e8 c7 d6 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f01029ea:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029ed:	8d 83 ca 91 f7 ff    	lea    -0x86e36(%ebx),%eax
f01029f3:	50                   	push   %eax
f01029f4:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01029fa:	50                   	push   %eax
f01029fb:	68 dc 03 00 00       	push   $0x3dc
f0102a00:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102a06:	50                   	push   %eax
f0102a07:	e8 a5 d6 ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102a0c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a0f:	8d 83 24 8b f7 ff    	lea    -0x874dc(%ebx),%eax
f0102a15:	50                   	push   %eax
f0102a16:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102a1c:	50                   	push   %eax
f0102a1d:	68 df 03 00 00       	push   $0x3df
f0102a22:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102a28:	50                   	push   %eax
f0102a29:	e8 83 d6 ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f0102a2e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a31:	8d 83 2d 92 f7 ff    	lea    -0x86dd3(%ebx),%eax
f0102a37:	50                   	push   %eax
f0102a38:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102a3e:	50                   	push   %eax
f0102a3f:	68 e1 03 00 00       	push   $0x3e1
f0102a44:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102a4a:	50                   	push   %eax
f0102a4b:	e8 61 d6 ff ff       	call   f01000b1 <_panic>
f0102a50:	52                   	push   %edx
f0102a51:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a54:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f0102a5a:	50                   	push   %eax
f0102a5b:	68 e8 03 00 00       	push   $0x3e8
f0102a60:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102a66:	50                   	push   %eax
f0102a67:	e8 45 d6 ff ff       	call   f01000b1 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102a6c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a6f:	8d 83 b9 92 f7 ff    	lea    -0x86d47(%ebx),%eax
f0102a75:	50                   	push   %eax
f0102a76:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102a7c:	50                   	push   %eax
f0102a7d:	68 e9 03 00 00       	push   $0x3e9
f0102a82:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102a88:	50                   	push   %eax
f0102a89:	e8 23 d6 ff ff       	call   f01000b1 <_panic>
f0102a8e:	50                   	push   %eax
f0102a8f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a92:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f0102a98:	50                   	push   %eax
f0102a99:	6a 56                	push   $0x56
f0102a9b:	8d 83 b1 90 f7 ff    	lea    -0x86f4f(%ebx),%eax
f0102aa1:	50                   	push   %eax
f0102aa2:	e8 0a d6 ff ff       	call   f01000b1 <_panic>
f0102aa7:	52                   	push   %edx
f0102aa8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102aab:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f0102ab1:	50                   	push   %eax
f0102ab2:	6a 56                	push   $0x56
f0102ab4:	8d 83 b1 90 f7 ff    	lea    -0x86f4f(%ebx),%eax
f0102aba:	50                   	push   %eax
f0102abb:	e8 f1 d5 ff ff       	call   f01000b1 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102ac0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ac3:	8d 83 d1 92 f7 ff    	lea    -0x86d2f(%ebx),%eax
f0102ac9:	50                   	push   %eax
f0102aca:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102ad0:	50                   	push   %eax
f0102ad1:	68 f3 03 00 00       	push   $0x3f3
f0102ad6:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102adc:	50                   	push   %eax
f0102add:	e8 cf d5 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ae2:	50                   	push   %eax
f0102ae3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ae6:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f0102aec:	50                   	push   %eax
f0102aed:	68 c3 00 00 00       	push   $0xc3
f0102af2:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102af8:	50                   	push   %eax
f0102af9:	e8 b3 d5 ff ff       	call   f01000b1 <_panic>
f0102afe:	50                   	push   %eax
f0102aff:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b02:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f0102b08:	50                   	push   %eax
f0102b09:	68 cc 00 00 00       	push   $0xcc
f0102b0e:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102b14:	50                   	push   %eax
f0102b15:	e8 97 d5 ff ff       	call   f01000b1 <_panic>
f0102b1a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b1d:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f0102b23:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f0102b29:	50                   	push   %eax
f0102b2a:	68 d8 00 00 00       	push   $0xd8
f0102b2f:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102b35:	50                   	push   %eax
f0102b36:	e8 76 d5 ff ff       	call   f01000b1 <_panic>
f0102b3b:	ff 75 c0             	pushl  -0x40(%ebp)
f0102b3e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b41:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f0102b47:	50                   	push   %eax
f0102b48:	68 2d 03 00 00       	push   $0x32d
f0102b4d:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102b53:	50                   	push   %eax
f0102b54:	e8 58 d5 ff ff       	call   f01000b1 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f0102b59:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102b5f:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102b62:	76 3f                	jbe    f0102ba3 <mem_init+0x1776>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102b64:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102b6a:	89 f0                	mov    %esi,%eax
f0102b6c:	e8 8c df ff ff       	call   f0100afd <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102b71:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102b78:	76 c1                	jbe    f0102b3b <mem_init+0x170e>
f0102b7a:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0102b7d:	39 d0                	cmp    %edx,%eax
f0102b7f:	74 d8                	je     f0102b59 <mem_init+0x172c>
f0102b81:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b84:	8d 83 a8 8e f7 ff    	lea    -0x87158(%ebx),%eax
f0102b8a:	50                   	push   %eax
f0102b8b:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102b91:	50                   	push   %eax
f0102b92:	68 2d 03 00 00       	push   $0x32d
f0102b97:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102b9d:	50                   	push   %eax
f0102b9e:	e8 0e d5 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102ba3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ba6:	c7 c0 2c f7 18 f0    	mov    $0xf018f72c,%eax
f0102bac:	8b 00                	mov    (%eax),%eax
f0102bae:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102bb1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102bb4:	bf 00 00 c0 ee       	mov    $0xeec00000,%edi
f0102bb9:	8d 98 00 00 40 21    	lea    0x21400000(%eax),%ebx
f0102bbf:	89 fa                	mov    %edi,%edx
f0102bc1:	89 f0                	mov    %esi,%eax
f0102bc3:	e8 35 df ff ff       	call   f0100afd <check_va2pa>
f0102bc8:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102bcf:	76 3d                	jbe    f0102c0e <mem_init+0x17e1>
f0102bd1:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0102bd4:	39 d0                	cmp    %edx,%eax
f0102bd6:	75 54                	jne    f0102c2c <mem_init+0x17ff>
f0102bd8:	81 c7 00 10 00 00    	add    $0x1000,%edi
	for (i = 0; i < n; i += PGSIZE)
f0102bde:	81 ff 00 80 c1 ee    	cmp    $0xeec18000,%edi
f0102be4:	75 d9                	jne    f0102bbf <mem_init+0x1792>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102be6:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102be9:	c1 e7 0c             	shl    $0xc,%edi
f0102bec:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102bf1:	39 fb                	cmp    %edi,%ebx
f0102bf3:	73 7b                	jae    f0102c70 <mem_init+0x1843>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102bf5:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102bfb:	89 f0                	mov    %esi,%eax
f0102bfd:	e8 fb de ff ff       	call   f0100afd <check_va2pa>
f0102c02:	39 c3                	cmp    %eax,%ebx
f0102c04:	75 48                	jne    f0102c4e <mem_init+0x1821>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102c06:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102c0c:	eb e3                	jmp    f0102bf1 <mem_init+0x17c4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c0e:	ff 75 cc             	pushl  -0x34(%ebp)
f0102c11:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c14:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f0102c1a:	50                   	push   %eax
f0102c1b:	68 32 03 00 00       	push   $0x332
f0102c20:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102c26:	50                   	push   %eax
f0102c27:	e8 85 d4 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102c2c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c2f:	8d 83 dc 8e f7 ff    	lea    -0x87124(%ebx),%eax
f0102c35:	50                   	push   %eax
f0102c36:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102c3c:	50                   	push   %eax
f0102c3d:	68 32 03 00 00       	push   $0x332
f0102c42:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102c48:	50                   	push   %eax
f0102c49:	e8 63 d4 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102c4e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c51:	8d 83 10 8f f7 ff    	lea    -0x870f0(%ebx),%eax
f0102c57:	50                   	push   %eax
f0102c58:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102c5e:	50                   	push   %eax
f0102c5f:	68 36 03 00 00       	push   $0x336
f0102c64:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102c6a:	50                   	push   %eax
f0102c6b:	e8 41 d4 ff ff       	call   f01000b1 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102c70:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102c75:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102c78:	81 c7 00 80 00 20    	add    $0x20008000,%edi
f0102c7e:	89 da                	mov    %ebx,%edx
f0102c80:	89 f0                	mov    %esi,%eax
f0102c82:	e8 76 de ff ff       	call   f0100afd <check_va2pa>
f0102c87:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102c8a:	39 c2                	cmp    %eax,%edx
f0102c8c:	75 26                	jne    f0102cb4 <mem_init+0x1887>
f0102c8e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102c94:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102c9a:	75 e2                	jne    f0102c7e <mem_init+0x1851>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102c9c:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102ca1:	89 f0                	mov    %esi,%eax
f0102ca3:	e8 55 de ff ff       	call   f0100afd <check_va2pa>
f0102ca8:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102cab:	75 29                	jne    f0102cd6 <mem_init+0x18a9>
	for (i = 0; i < NPDENTRIES; i++)
f0102cad:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cb2:	eb 6d                	jmp    f0102d21 <mem_init+0x18f4>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102cb4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cb7:	8d 83 38 8f f7 ff    	lea    -0x870c8(%ebx),%eax
f0102cbd:	50                   	push   %eax
f0102cbe:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102cc4:	50                   	push   %eax
f0102cc5:	68 3a 03 00 00       	push   $0x33a
f0102cca:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102cd0:	50                   	push   %eax
f0102cd1:	e8 db d3 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102cd6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cd9:	8d 83 80 8f f7 ff    	lea    -0x87080(%ebx),%eax
f0102cdf:	50                   	push   %eax
f0102ce0:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102ce6:	50                   	push   %eax
f0102ce7:	68 3b 03 00 00       	push   $0x33b
f0102cec:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102cf2:	50                   	push   %eax
f0102cf3:	e8 b9 d3 ff ff       	call   f01000b1 <_panic>
			assert(pgdir[i] & PTE_P);
f0102cf8:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102cfc:	74 52                	je     f0102d50 <mem_init+0x1923>
	for (i = 0; i < NPDENTRIES; i++)
f0102cfe:	83 c0 01             	add    $0x1,%eax
f0102d01:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102d06:	0f 87 bb 00 00 00    	ja     f0102dc7 <mem_init+0x199a>
		switch (i)
f0102d0c:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102d11:	72 0e                	jb     f0102d21 <mem_init+0x18f4>
f0102d13:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102d18:	76 de                	jbe    f0102cf8 <mem_init+0x18cb>
f0102d1a:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102d1f:	74 d7                	je     f0102cf8 <mem_init+0x18cb>
			if (i >= PDX(KERNBASE))
f0102d21:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102d26:	77 4a                	ja     f0102d72 <mem_init+0x1945>
				assert(pgdir[i] == 0);
f0102d28:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102d2c:	74 d0                	je     f0102cfe <mem_init+0x18d1>
f0102d2e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d31:	8d 83 23 93 f7 ff    	lea    -0x86cdd(%ebx),%eax
f0102d37:	50                   	push   %eax
f0102d38:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102d3e:	50                   	push   %eax
f0102d3f:	68 4f 03 00 00       	push   $0x34f
f0102d44:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102d4a:	50                   	push   %eax
f0102d4b:	e8 61 d3 ff ff       	call   f01000b1 <_panic>
			assert(pgdir[i] & PTE_P);
f0102d50:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d53:	8d 83 01 93 f7 ff    	lea    -0x86cff(%ebx),%eax
f0102d59:	50                   	push   %eax
f0102d5a:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102d60:	50                   	push   %eax
f0102d61:	68 46 03 00 00       	push   $0x346
f0102d66:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102d6c:	50                   	push   %eax
f0102d6d:	e8 3f d3 ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f0102d72:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102d75:	f6 c2 01             	test   $0x1,%dl
f0102d78:	74 2b                	je     f0102da5 <mem_init+0x1978>
				assert(pgdir[i] & PTE_W);
f0102d7a:	f6 c2 02             	test   $0x2,%dl
f0102d7d:	0f 85 7b ff ff ff    	jne    f0102cfe <mem_init+0x18d1>
f0102d83:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d86:	8d 83 12 93 f7 ff    	lea    -0x86cee(%ebx),%eax
f0102d8c:	50                   	push   %eax
f0102d8d:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102d93:	50                   	push   %eax
f0102d94:	68 4c 03 00 00       	push   $0x34c
f0102d99:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102d9f:	50                   	push   %eax
f0102da0:	e8 0c d3 ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f0102da5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102da8:	8d 83 01 93 f7 ff    	lea    -0x86cff(%ebx),%eax
f0102dae:	50                   	push   %eax
f0102daf:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0102db5:	50                   	push   %eax
f0102db6:	68 4b 03 00 00       	push   $0x34b
f0102dbb:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0102dc1:	50                   	push   %eax
f0102dc2:	e8 ea d2 ff ff       	call   f01000b1 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102dc7:	83 ec 0c             	sub    $0xc,%esp
f0102dca:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102dcd:	8d 86 b0 8f f7 ff    	lea    -0x87050(%esi),%eax
f0102dd3:	50                   	push   %eax
f0102dd4:	89 f3                	mov    %esi,%ebx
f0102dd6:	e8 d9 0d 00 00       	call   f0103bb4 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102ddb:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0102de1:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102de3:	83 c4 10             	add    $0x10,%esp
f0102de6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102deb:	0f 86 44 02 00 00    	jbe    f0103035 <mem_init+0x1c08>
	return (physaddr_t)kva - KERNBASE;
f0102df1:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102df6:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102df9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102dfe:	e8 77 dd ff ff       	call   f0100b7a <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102e03:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS | CR0_EM);
f0102e06:	83 e0 f3             	and    $0xfffffff3,%eax
f0102e09:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102e0e:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102e11:	83 ec 0c             	sub    $0xc,%esp
f0102e14:	6a 00                	push   $0x0
f0102e16:	e8 23 e2 ff ff       	call   f010103e <page_alloc>
f0102e1b:	89 c6                	mov    %eax,%esi
f0102e1d:	83 c4 10             	add    $0x10,%esp
f0102e20:	85 c0                	test   %eax,%eax
f0102e22:	0f 84 29 02 00 00    	je     f0103051 <mem_init+0x1c24>
	assert((pp1 = page_alloc(0)));
f0102e28:	83 ec 0c             	sub    $0xc,%esp
f0102e2b:	6a 00                	push   $0x0
f0102e2d:	e8 0c e2 ff ff       	call   f010103e <page_alloc>
f0102e32:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102e35:	83 c4 10             	add    $0x10,%esp
f0102e38:	85 c0                	test   %eax,%eax
f0102e3a:	0f 84 33 02 00 00    	je     f0103073 <mem_init+0x1c46>
	assert((pp2 = page_alloc(0)));
f0102e40:	83 ec 0c             	sub    $0xc,%esp
f0102e43:	6a 00                	push   $0x0
f0102e45:	e8 f4 e1 ff ff       	call   f010103e <page_alloc>
f0102e4a:	89 c7                	mov    %eax,%edi
f0102e4c:	83 c4 10             	add    $0x10,%esp
f0102e4f:	85 c0                	test   %eax,%eax
f0102e51:	0f 84 3e 02 00 00    	je     f0103095 <mem_init+0x1c68>
	page_free(pp0);
f0102e57:	83 ec 0c             	sub    $0xc,%esp
f0102e5a:	56                   	push   %esi
f0102e5b:	e8 66 e2 ff ff       	call   f01010c6 <page_free>
	return (pp - pages) << PGSHIFT;
f0102e60:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e63:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f0102e69:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102e6c:	2b 08                	sub    (%eax),%ecx
f0102e6e:	89 c8                	mov    %ecx,%eax
f0102e70:	c1 f8 03             	sar    $0x3,%eax
f0102e73:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102e76:	89 c1                	mov    %eax,%ecx
f0102e78:	c1 e9 0c             	shr    $0xc,%ecx
f0102e7b:	83 c4 10             	add    $0x10,%esp
f0102e7e:	c7 c2 e8 03 19 f0    	mov    $0xf01903e8,%edx
f0102e84:	3b 0a                	cmp    (%edx),%ecx
f0102e86:	0f 83 2b 02 00 00    	jae    f01030b7 <mem_init+0x1c8a>
	memset(page2kva(pp1), 1, PGSIZE);
f0102e8c:	83 ec 04             	sub    $0x4,%esp
f0102e8f:	68 00 10 00 00       	push   $0x1000
f0102e94:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102e96:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102e9b:	50                   	push   %eax
f0102e9c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e9f:	e8 4b 20 00 00       	call   f0104eef <memset>
	return (pp - pages) << PGSHIFT;
f0102ea4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ea7:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f0102ead:	89 f9                	mov    %edi,%ecx
f0102eaf:	2b 08                	sub    (%eax),%ecx
f0102eb1:	89 c8                	mov    %ecx,%eax
f0102eb3:	c1 f8 03             	sar    $0x3,%eax
f0102eb6:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102eb9:	89 c1                	mov    %eax,%ecx
f0102ebb:	c1 e9 0c             	shr    $0xc,%ecx
f0102ebe:	83 c4 10             	add    $0x10,%esp
f0102ec1:	c7 c2 e8 03 19 f0    	mov    $0xf01903e8,%edx
f0102ec7:	3b 0a                	cmp    (%edx),%ecx
f0102ec9:	0f 83 fe 01 00 00    	jae    f01030cd <mem_init+0x1ca0>
	memset(page2kva(pp2), 2, PGSIZE);
f0102ecf:	83 ec 04             	sub    $0x4,%esp
f0102ed2:	68 00 10 00 00       	push   $0x1000
f0102ed7:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102ed9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102ede:	50                   	push   %eax
f0102edf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ee2:	e8 08 20 00 00       	call   f0104eef <memset>
	page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W);
f0102ee7:	6a 02                	push   $0x2
f0102ee9:	68 00 10 00 00       	push   $0x1000
f0102eee:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102ef1:	53                   	push   %ebx
f0102ef2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ef5:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0102efb:	ff 30                	pushl  (%eax)
f0102efd:	e8 a5 e4 ff ff       	call   f01013a7 <page_insert>
	assert(pp1->pp_ref == 1);
f0102f02:	83 c4 20             	add    $0x20,%esp
f0102f05:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102f0a:	0f 85 d3 01 00 00    	jne    f01030e3 <mem_init+0x1cb6>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102f10:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102f17:	01 01 01 
f0102f1a:	0f 85 e5 01 00 00    	jne    f0103105 <mem_init+0x1cd8>
	page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W);
f0102f20:	6a 02                	push   $0x2
f0102f22:	68 00 10 00 00       	push   $0x1000
f0102f27:	57                   	push   %edi
f0102f28:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102f2b:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0102f31:	ff 30                	pushl  (%eax)
f0102f33:	e8 6f e4 ff ff       	call   f01013a7 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102f38:	83 c4 10             	add    $0x10,%esp
f0102f3b:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102f42:	02 02 02 
f0102f45:	0f 85 dc 01 00 00    	jne    f0103127 <mem_init+0x1cfa>
	assert(pp2->pp_ref == 1);
f0102f4b:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102f50:	0f 85 f3 01 00 00    	jne    f0103149 <mem_init+0x1d1c>
	assert(pp1->pp_ref == 0);
f0102f56:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102f59:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102f5e:	0f 85 07 02 00 00    	jne    f010316b <mem_init+0x1d3e>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102f64:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102f6b:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102f6e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f71:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f0102f77:	89 f9                	mov    %edi,%ecx
f0102f79:	2b 08                	sub    (%eax),%ecx
f0102f7b:	89 c8                	mov    %ecx,%eax
f0102f7d:	c1 f8 03             	sar    $0x3,%eax
f0102f80:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102f83:	89 c1                	mov    %eax,%ecx
f0102f85:	c1 e9 0c             	shr    $0xc,%ecx
f0102f88:	c7 c2 e8 03 19 f0    	mov    $0xf01903e8,%edx
f0102f8e:	3b 0a                	cmp    (%edx),%ecx
f0102f90:	0f 83 f7 01 00 00    	jae    f010318d <mem_init+0x1d60>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102f96:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102f9d:	03 03 03 
f0102fa0:	0f 85 fd 01 00 00    	jne    f01031a3 <mem_init+0x1d76>
	page_remove(kern_pgdir, (void *)PGSIZE);
f0102fa6:	83 ec 08             	sub    $0x8,%esp
f0102fa9:	68 00 10 00 00       	push   $0x1000
f0102fae:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102fb1:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0102fb7:	ff 30                	pushl  (%eax)
f0102fb9:	e8 ac e3 ff ff       	call   f010136a <page_remove>
	assert(pp2->pp_ref == 0);
f0102fbe:	83 c4 10             	add    $0x10,%esp
f0102fc1:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102fc6:	0f 85 f9 01 00 00    	jne    f01031c5 <mem_init+0x1d98>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102fcc:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102fcf:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0102fd5:	8b 08                	mov    (%eax),%ecx
f0102fd7:	8b 11                	mov    (%ecx),%edx
f0102fd9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102fdf:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f0102fe5:	89 f7                	mov    %esi,%edi
f0102fe7:	2b 38                	sub    (%eax),%edi
f0102fe9:	89 f8                	mov    %edi,%eax
f0102feb:	c1 f8 03             	sar    $0x3,%eax
f0102fee:	c1 e0 0c             	shl    $0xc,%eax
f0102ff1:	39 c2                	cmp    %eax,%edx
f0102ff3:	0f 85 ee 01 00 00    	jne    f01031e7 <mem_init+0x1dba>
	kern_pgdir[0] = 0;
f0102ff9:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102fff:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0103004:	0f 85 ff 01 00 00    	jne    f0103209 <mem_init+0x1ddc>
	pp0->pp_ref = 0;
f010300a:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0103010:	83 ec 0c             	sub    $0xc,%esp
f0103013:	56                   	push   %esi
f0103014:	e8 ad e0 ff ff       	call   f01010c6 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0103019:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010301c:	8d 83 44 90 f7 ff    	lea    -0x86fbc(%ebx),%eax
f0103022:	89 04 24             	mov    %eax,(%esp)
f0103025:	e8 8a 0b 00 00       	call   f0103bb4 <cprintf>
}
f010302a:	83 c4 10             	add    $0x10,%esp
f010302d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103030:	5b                   	pop    %ebx
f0103031:	5e                   	pop    %esi
f0103032:	5f                   	pop    %edi
f0103033:	5d                   	pop    %ebp
f0103034:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103035:	50                   	push   %eax
f0103036:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103039:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f010303f:	50                   	push   %eax
f0103040:	68 ed 00 00 00       	push   $0xed
f0103045:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010304b:	50                   	push   %eax
f010304c:	e8 60 d0 ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f0103051:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103054:	8d 83 76 91 f7 ff    	lea    -0x86e8a(%ebx),%eax
f010305a:	50                   	push   %eax
f010305b:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0103061:	50                   	push   %eax
f0103062:	68 0e 04 00 00       	push   $0x40e
f0103067:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010306d:	50                   	push   %eax
f010306e:	e8 3e d0 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0103073:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103076:	8d 83 8c 91 f7 ff    	lea    -0x86e74(%ebx),%eax
f010307c:	50                   	push   %eax
f010307d:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0103083:	50                   	push   %eax
f0103084:	68 0f 04 00 00       	push   $0x40f
f0103089:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f010308f:	50                   	push   %eax
f0103090:	e8 1c d0 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f0103095:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103098:	8d 83 a2 91 f7 ff    	lea    -0x86e5e(%ebx),%eax
f010309e:	50                   	push   %eax
f010309f:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01030a5:	50                   	push   %eax
f01030a6:	68 10 04 00 00       	push   $0x410
f01030ab:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01030b1:	50                   	push   %eax
f01030b2:	e8 fa cf ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01030b7:	50                   	push   %eax
f01030b8:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f01030be:	50                   	push   %eax
f01030bf:	6a 56                	push   $0x56
f01030c1:	8d 83 b1 90 f7 ff    	lea    -0x86f4f(%ebx),%eax
f01030c7:	50                   	push   %eax
f01030c8:	e8 e4 cf ff ff       	call   f01000b1 <_panic>
f01030cd:	50                   	push   %eax
f01030ce:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f01030d4:	50                   	push   %eax
f01030d5:	6a 56                	push   $0x56
f01030d7:	8d 83 b1 90 f7 ff    	lea    -0x86f4f(%ebx),%eax
f01030dd:	50                   	push   %eax
f01030de:	e8 ce cf ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f01030e3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030e6:	8d 83 1c 92 f7 ff    	lea    -0x86de4(%ebx),%eax
f01030ec:	50                   	push   %eax
f01030ed:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01030f3:	50                   	push   %eax
f01030f4:	68 15 04 00 00       	push   $0x415
f01030f9:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01030ff:	50                   	push   %eax
f0103100:	e8 ac cf ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103105:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103108:	8d 83 d0 8f f7 ff    	lea    -0x87030(%ebx),%eax
f010310e:	50                   	push   %eax
f010310f:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0103115:	50                   	push   %eax
f0103116:	68 16 04 00 00       	push   $0x416
f010311b:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0103121:	50                   	push   %eax
f0103122:	e8 8a cf ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103127:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010312a:	8d 83 f4 8f f7 ff    	lea    -0x8700c(%ebx),%eax
f0103130:	50                   	push   %eax
f0103131:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0103137:	50                   	push   %eax
f0103138:	68 18 04 00 00       	push   $0x418
f010313d:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0103143:	50                   	push   %eax
f0103144:	e8 68 cf ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0103149:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010314c:	8d 83 3e 92 f7 ff    	lea    -0x86dc2(%ebx),%eax
f0103152:	50                   	push   %eax
f0103153:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0103159:	50                   	push   %eax
f010315a:	68 19 04 00 00       	push   $0x419
f010315f:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0103165:	50                   	push   %eax
f0103166:	e8 46 cf ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f010316b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010316e:	8d 83 a8 92 f7 ff    	lea    -0x86d58(%ebx),%eax
f0103174:	50                   	push   %eax
f0103175:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010317b:	50                   	push   %eax
f010317c:	68 1a 04 00 00       	push   $0x41a
f0103181:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0103187:	50                   	push   %eax
f0103188:	e8 24 cf ff ff       	call   f01000b1 <_panic>
f010318d:	50                   	push   %eax
f010318e:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f0103194:	50                   	push   %eax
f0103195:	6a 56                	push   $0x56
f0103197:	8d 83 b1 90 f7 ff    	lea    -0x86f4f(%ebx),%eax
f010319d:	50                   	push   %eax
f010319e:	e8 0e cf ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01031a3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01031a6:	8d 83 18 90 f7 ff    	lea    -0x86fe8(%ebx),%eax
f01031ac:	50                   	push   %eax
f01031ad:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01031b3:	50                   	push   %eax
f01031b4:	68 1c 04 00 00       	push   $0x41c
f01031b9:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01031bf:	50                   	push   %eax
f01031c0:	e8 ec ce ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f01031c5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01031c8:	8d 83 76 92 f7 ff    	lea    -0x86d8a(%ebx),%eax
f01031ce:	50                   	push   %eax
f01031cf:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01031d5:	50                   	push   %eax
f01031d6:	68 1e 04 00 00       	push   $0x41e
f01031db:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f01031e1:	50                   	push   %eax
f01031e2:	e8 ca ce ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01031e7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01031ea:	8d 83 24 8b f7 ff    	lea    -0x874dc(%ebx),%eax
f01031f0:	50                   	push   %eax
f01031f1:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01031f7:	50                   	push   %eax
f01031f8:	68 21 04 00 00       	push   $0x421
f01031fd:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0103203:	50                   	push   %eax
f0103204:	e8 a8 ce ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f0103209:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010320c:	8d 83 2d 92 f7 ff    	lea    -0x86dd3(%ebx),%eax
f0103212:	50                   	push   %eax
f0103213:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0103219:	50                   	push   %eax
f010321a:	68 23 04 00 00       	push   $0x423
f010321f:	8d 83 a5 90 f7 ff    	lea    -0x86f5b(%ebx),%eax
f0103225:	50                   	push   %eax
f0103226:	e8 86 ce ff ff       	call   f01000b1 <_panic>

f010322b <tlb_invalidate>:
{
f010322b:	55                   	push   %ebp
f010322c:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010322e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103231:	0f 01 38             	invlpg (%eax)
}
f0103234:	5d                   	pop    %ebp
f0103235:	c3                   	ret    

f0103236 <user_mem_check>:
{
f0103236:	55                   	push   %ebp
f0103237:	89 e5                	mov    %esp,%ebp
f0103239:	57                   	push   %edi
f010323a:	56                   	push   %esi
f010323b:	53                   	push   %ebx
f010323c:	83 ec 1c             	sub    $0x1c,%esp
f010323f:	e8 c5 d4 ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f0103244:	05 dc 9d 08 00       	add    $0x89ddc,%eax
f0103249:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010324c:	8b 75 14             	mov    0x14(%ebp),%esi
	void *end = ROUNDUP((void *)(va + len), PGSIZE);
f010324f:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103252:	03 7d 10             	add    0x10(%ebp),%edi
f0103255:	81 c7 ff 0f 00 00    	add    $0xfff,%edi
f010325b:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	void *start = ROUNDDOWN((void *)va, PGSIZE);
f0103261:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103264:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0103269:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010326c:	89 c3                	mov    %eax,%ebx
	for (; start < end; start += PGSIZE)
f010326e:	39 fb                	cmp    %edi,%ebx
f0103270:	73 60                	jae    f01032d2 <user_mem_check+0x9c>
		cur = pgdir_walk(env->env_pgdir, (void *)start, 0);
f0103272:	83 ec 04             	sub    $0x4,%esp
f0103275:	6a 00                	push   $0x0
f0103277:	53                   	push   %ebx
f0103278:	8b 45 08             	mov    0x8(%ebp),%eax
f010327b:	ff 70 5c             	pushl  0x5c(%eax)
f010327e:	e8 bb de ff ff       	call   f010113e <pgdir_walk>
		if ((int)start > ULIM || cur == NULL || ((uint32_t)(*cur) & perm) != perm)
f0103283:	89 da                	mov    %ebx,%edx
f0103285:	83 c4 10             	add    $0x10,%esp
f0103288:	81 fb 00 00 80 ef    	cmp    $0xef800000,%ebx
f010328e:	77 14                	ja     f01032a4 <user_mem_check+0x6e>
f0103290:	85 c0                	test   %eax,%eax
f0103292:	74 10                	je     f01032a4 <user_mem_check+0x6e>
f0103294:	89 f1                	mov    %esi,%ecx
f0103296:	23 08                	and    (%eax),%ecx
f0103298:	39 ce                	cmp    %ecx,%esi
f010329a:	75 08                	jne    f01032a4 <user_mem_check+0x6e>
	for (; start < end; start += PGSIZE)
f010329c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01032a2:	eb ca                	jmp    f010326e <user_mem_check+0x38>
			if (start == ROUNDDOWN((char *)va, PGSIZE))
f01032a4:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01032a7:	74 16                	je     f01032bf <user_mem_check+0x89>
				user_mem_check_addr = (uintptr_t)start;
f01032a9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032ac:	89 90 fc 26 00 00    	mov    %edx,0x26fc(%eax)
			return -E_FAULT;
f01032b2:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
}
f01032b7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01032ba:	5b                   	pop    %ebx
f01032bb:	5e                   	pop    %esi
f01032bc:	5f                   	pop    %edi
f01032bd:	5d                   	pop    %ebp
f01032be:	c3                   	ret    
				user_mem_check_addr = (uintptr_t)va;
f01032bf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032c2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032c5:	89 90 fc 26 00 00    	mov    %edx,0x26fc(%eax)
			return -E_FAULT;
f01032cb:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01032d0:	eb e5                	jmp    f01032b7 <user_mem_check+0x81>
	return 0;
f01032d2:	b8 00 00 00 00       	mov    $0x0,%eax
f01032d7:	eb de                	jmp    f01032b7 <user_mem_check+0x81>

f01032d9 <user_mem_assert>:
{
f01032d9:	55                   	push   %ebp
f01032da:	89 e5                	mov    %esp,%ebp
f01032dc:	56                   	push   %esi
f01032dd:	53                   	push   %ebx
f01032de:	e8 84 ce ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01032e3:	81 c3 3d 9d 08 00    	add    $0x89d3d,%ebx
f01032e9:	8b 75 08             	mov    0x8(%ebp),%esi
	if (user_mem_check(env, va, len, perm | PTE_U) < 0)
f01032ec:	8b 45 14             	mov    0x14(%ebp),%eax
f01032ef:	83 c8 04             	or     $0x4,%eax
f01032f2:	50                   	push   %eax
f01032f3:	ff 75 10             	pushl  0x10(%ebp)
f01032f6:	ff 75 0c             	pushl  0xc(%ebp)
f01032f9:	56                   	push   %esi
f01032fa:	e8 37 ff ff ff       	call   f0103236 <user_mem_check>
f01032ff:	83 c4 10             	add    $0x10,%esp
f0103302:	85 c0                	test   %eax,%eax
f0103304:	78 07                	js     f010330d <user_mem_assert+0x34>
}
f0103306:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103309:	5b                   	pop    %ebx
f010330a:	5e                   	pop    %esi
f010330b:	5d                   	pop    %ebp
f010330c:	c3                   	ret    
		cprintf("[%08x] user_mem_check assertion failure for "
f010330d:	83 ec 04             	sub    $0x4,%esp
f0103310:	ff b3 fc 26 00 00    	pushl  0x26fc(%ebx)
f0103316:	ff 76 48             	pushl  0x48(%esi)
f0103319:	8d 83 70 90 f7 ff    	lea    -0x86f90(%ebx),%eax
f010331f:	50                   	push   %eax
f0103320:	e8 8f 08 00 00       	call   f0103bb4 <cprintf>
		env_destroy(env); // may not return
f0103325:	89 34 24             	mov    %esi,(%esp)
f0103328:	e8 1d 07 00 00       	call   f0103a4a <env_destroy>
f010332d:	83 c4 10             	add    $0x10,%esp
}
f0103330:	eb d4                	jmp    f0103306 <user_mem_assert+0x2d>

f0103332 <__x86.get_pc_thunk.cx>:
f0103332:	8b 0c 24             	mov    (%esp),%ecx
f0103335:	c3                   	ret    

f0103336 <__x86.get_pc_thunk.di>:
f0103336:	8b 3c 24             	mov    (%esp),%edi
f0103339:	c3                   	ret    

f010333a <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f010333a:	55                   	push   %ebp
f010333b:	89 e5                	mov    %esp,%ebp
f010333d:	57                   	push   %edi
f010333e:	56                   	push   %esi
f010333f:	53                   	push   %ebx
f0103340:	83 ec 1c             	sub    $0x1c,%esp
f0103343:	e8 1f ce ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103348:	81 c3 d8 9c 08 00    	add    $0x89cd8,%ebx
    //
    // Hint: It is easier to use region_alloc if the caller can pass
    //   'va' and 'len' values that are not page-aligned.
    //   You should round va down, and round (va + len) up.
    //   (Watch out for corner-cases!)
    if ((uintptr_t)va >= UTOP)
f010334e:	81 fa ff ff bf ee    	cmp    $0xeebfffff,%edx
f0103354:	77 52                	ja     f01033a8 <region_alloc+0x6e>
f0103356:	89 c7                	mov    %eax,%edi
    {
        panic("Mapping virtual address above UTOP for user environment...\n");
    }
    void *start = ROUNDDOWN(va, PGSIZE);
f0103358:	89 d6                	mov    %edx,%esi
f010335a:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    void *end = ROUNDUP(va + len, PGSIZE);
f0103360:	8d 84 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%eax
f0103367:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010336c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    // corner case: end overflows 边界情况就是输入的数值不正确，超出了32-bit范围，发生溢出overflow。
    if (start > end)
f010336f:	39 c6                	cmp    %eax,%esi
f0103371:	77 50                	ja     f01033c3 <region_alloc+0x89>
        panic("region_alloc: requesting length too large.\n");

    for (void *addr = start; addr < end; addr += PGSIZE)
f0103373:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0103376:	0f 83 a0 00 00 00    	jae    f010341c <region_alloc+0xe2>
    {
        struct PageInfo *p = NULL;
        assert(p = page_alloc(0));
f010337c:	83 ec 0c             	sub    $0xc,%esp
f010337f:	6a 00                	push   $0x0
f0103381:	e8 b8 dc ff ff       	call   f010103e <page_alloc>
f0103386:	83 c4 10             	add    $0x10,%esp
f0103389:	85 c0                	test   %eax,%eax
f010338b:	74 51                	je     f01033de <region_alloc+0xa4>

        int result = page_insert(e->env_pgdir, p, addr, PTE_W | PTE_U);
f010338d:	6a 06                	push   $0x6
f010338f:	56                   	push   %esi
f0103390:	50                   	push   %eax
f0103391:	ff 77 5c             	pushl  0x5c(%edi)
f0103394:	e8 0e e0 ff ff       	call   f01013a7 <page_insert>
        assert(result >= 0);
f0103399:	83 c4 10             	add    $0x10,%esp
f010339c:	85 c0                	test   %eax,%eax
f010339e:	78 5d                	js     f01033fd <region_alloc+0xc3>
    for (void *addr = start; addr < end; addr += PGSIZE)
f01033a0:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01033a6:	eb cb                	jmp    f0103373 <region_alloc+0x39>
        panic("Mapping virtual address above UTOP for user environment...\n");
f01033a8:	83 ec 04             	sub    $0x4,%esp
f01033ab:	8d 83 34 93 f7 ff    	lea    -0x86ccc(%ebx),%eax
f01033b1:	50                   	push   %eax
f01033b2:	68 26 01 00 00       	push   $0x126
f01033b7:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f01033bd:	50                   	push   %eax
f01033be:	e8 ee cc ff ff       	call   f01000b1 <_panic>
        panic("region_alloc: requesting length too large.\n");
f01033c3:	83 ec 04             	sub    $0x4,%esp
f01033c6:	8d 83 70 93 f7 ff    	lea    -0x86c90(%ebx),%eax
f01033cc:	50                   	push   %eax
f01033cd:	68 2c 01 00 00       	push   $0x12c
f01033d2:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f01033d8:	50                   	push   %eax
f01033d9:	e8 d3 cc ff ff       	call   f01000b1 <_panic>
        assert(p = page_alloc(0));
f01033de:	8d 83 49 94 f7 ff    	lea    -0x86bb7(%ebx),%eax
f01033e4:	50                   	push   %eax
f01033e5:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01033eb:	50                   	push   %eax
f01033ec:	68 31 01 00 00       	push   $0x131
f01033f1:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f01033f7:	50                   	push   %eax
f01033f8:	e8 b4 cc ff ff       	call   f01000b1 <_panic>
        assert(result >= 0);
f01033fd:	8d 83 5b 94 f7 ff    	lea    -0x86ba5(%ebx),%eax
f0103403:	50                   	push   %eax
f0103404:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010340a:	50                   	push   %eax
f010340b:	68 34 01 00 00       	push   $0x134
f0103410:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f0103416:	50                   	push   %eax
f0103417:	e8 95 cc ff ff       	call   f01000b1 <_panic>
    }
}
f010341c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010341f:	5b                   	pop    %ebx
f0103420:	5e                   	pop    %esi
f0103421:	5f                   	pop    %edi
f0103422:	5d                   	pop    %ebp
f0103423:	c3                   	ret    

f0103424 <envid2env>:
{
f0103424:	55                   	push   %ebp
f0103425:	89 e5                	mov    %esp,%ebp
f0103427:	53                   	push   %ebx
f0103428:	e8 05 ff ff ff       	call   f0103332 <__x86.get_pc_thunk.cx>
f010342d:	81 c1 f3 9b 08 00    	add    $0x89bf3,%ecx
f0103433:	8b 55 08             	mov    0x8(%ebp),%edx
f0103436:	8b 5d 10             	mov    0x10(%ebp),%ebx
    if (envid == 0)
f0103439:	85 d2                	test   %edx,%edx
f010343b:	74 41                	je     f010347e <envid2env+0x5a>
    e = &envs[ENVX(envid)];
f010343d:	89 d0                	mov    %edx,%eax
f010343f:	25 ff 03 00 00       	and    $0x3ff,%eax
f0103444:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103447:	c1 e0 05             	shl    $0x5,%eax
f010344a:	03 81 0c 27 00 00    	add    0x270c(%ecx),%eax
    if (e->env_status == ENV_FREE || e->env_id != envid)
f0103450:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0103454:	74 3a                	je     f0103490 <envid2env+0x6c>
f0103456:	39 50 48             	cmp    %edx,0x48(%eax)
f0103459:	75 35                	jne    f0103490 <envid2env+0x6c>
    if (checkperm && e != curenv && e->env_parent_id != curenv->env_id)
f010345b:	84 db                	test   %bl,%bl
f010345d:	74 12                	je     f0103471 <envid2env+0x4d>
f010345f:	8b 91 08 27 00 00    	mov    0x2708(%ecx),%edx
f0103465:	39 c2                	cmp    %eax,%edx
f0103467:	74 08                	je     f0103471 <envid2env+0x4d>
f0103469:	8b 5a 48             	mov    0x48(%edx),%ebx
f010346c:	39 58 4c             	cmp    %ebx,0x4c(%eax)
f010346f:	75 2f                	jne    f01034a0 <envid2env+0x7c>
    *env_store = e;
f0103471:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103474:	89 03                	mov    %eax,(%ebx)
    return 0;
f0103476:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010347b:	5b                   	pop    %ebx
f010347c:	5d                   	pop    %ebp
f010347d:	c3                   	ret    
        *env_store = curenv;
f010347e:	8b 81 08 27 00 00    	mov    0x2708(%ecx),%eax
f0103484:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103487:	89 01                	mov    %eax,(%ecx)
        return 0;
f0103489:	b8 00 00 00 00       	mov    $0x0,%eax
f010348e:	eb eb                	jmp    f010347b <envid2env+0x57>
        *env_store = 0;
f0103490:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103493:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        return -E_BAD_ENV;
f0103499:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010349e:	eb db                	jmp    f010347b <envid2env+0x57>
        *env_store = 0;
f01034a0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034a3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        return -E_BAD_ENV;
f01034a9:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01034ae:	eb cb                	jmp    f010347b <envid2env+0x57>

f01034b0 <env_init_percpu>:
{
f01034b0:	55                   	push   %ebp
f01034b1:	89 e5                	mov    %esp,%ebp
f01034b3:	e8 51 d2 ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f01034b8:	05 68 9b 08 00       	add    $0x89b68,%eax
	asm volatile("lgdt (%0)" : : "r" (p));
f01034bd:	8d 80 e0 1f 00 00    	lea    0x1fe0(%eax),%eax
f01034c3:	0f 01 10             	lgdtl  (%eax)
    asm volatile("movw %%ax,%%gs"
f01034c6:	b8 23 00 00 00       	mov    $0x23,%eax
f01034cb:	8e e8                	mov    %eax,%gs
    asm volatile("movw %%ax,%%fs"
f01034cd:	8e e0                	mov    %eax,%fs
    asm volatile("movw %%ax,%%es"
f01034cf:	b8 10 00 00 00       	mov    $0x10,%eax
f01034d4:	8e c0                	mov    %eax,%es
    asm volatile("movw %%ax,%%ds"
f01034d6:	8e d8                	mov    %eax,%ds
    asm volatile("movw %%ax,%%ss"
f01034d8:	8e d0                	mov    %eax,%ss
    asm volatile("ljmp %0,$1f\n 1:\n"
f01034da:	ea e1 34 10 f0 08 00 	ljmp   $0x8,$0xf01034e1
	asm volatile("lldt %0" : : "r" (sel));
f01034e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01034e6:	0f 00 d0             	lldt   %ax
}
f01034e9:	5d                   	pop    %ebp
f01034ea:	c3                   	ret    

f01034eb <env_init>:
{
f01034eb:	55                   	push   %ebp
f01034ec:	89 e5                	mov    %esp,%ebp
f01034ee:	57                   	push   %edi
f01034ef:	56                   	push   %esi
f01034f0:	53                   	push   %ebx
f01034f1:	e8 40 fe ff ff       	call   f0103336 <__x86.get_pc_thunk.di>
f01034f6:	81 c7 2a 9b 08 00    	add    $0x89b2a,%edi
        envs[i].env_id = 0;
f01034fc:	8b b7 0c 27 00 00    	mov    0x270c(%edi),%esi
f0103502:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0103508:	8d 5e a0             	lea    -0x60(%esi),%ebx
f010350b:	ba 00 00 00 00       	mov    $0x0,%edx
f0103510:	89 c1                	mov    %eax,%ecx
f0103512:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
        envs[i].env_status = ENV_FREE;
f0103519:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
        envs[i].env_link = env_free_list;
f0103520:	89 50 44             	mov    %edx,0x44(%eax)
f0103523:	83 e8 60             	sub    $0x60,%eax
        env_free_list = &envs[i];
f0103526:	89 ca                	mov    %ecx,%edx
    for (i = NENV - 1; i >= 0; i--)
f0103528:	39 d8                	cmp    %ebx,%eax
f010352a:	75 e4                	jne    f0103510 <env_init+0x25>
f010352c:	89 b7 10 27 00 00    	mov    %esi,0x2710(%edi)
    env_init_percpu();
f0103532:	e8 79 ff ff ff       	call   f01034b0 <env_init_percpu>
}
f0103537:	5b                   	pop    %ebx
f0103538:	5e                   	pop    %esi
f0103539:	5f                   	pop    %edi
f010353a:	5d                   	pop    %ebp
f010353b:	c3                   	ret    

f010353c <env_alloc>:
{
f010353c:	55                   	push   %ebp
f010353d:	89 e5                	mov    %esp,%ebp
f010353f:	56                   	push   %esi
f0103540:	53                   	push   %ebx
f0103541:	e8 21 cc ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103546:	81 c3 da 9a 08 00    	add    $0x89ada,%ebx
    if (!(e = env_free_list))
f010354c:	8b b3 10 27 00 00    	mov    0x2710(%ebx),%esi
f0103552:	85 f6                	test   %esi,%esi
f0103554:	0f 84 60 01 00 00    	je     f01036ba <env_alloc+0x17e>
    if (!(p = page_alloc(ALLOC_ZERO)))
f010355a:	83 ec 0c             	sub    $0xc,%esp
f010355d:	6a 01                	push   $0x1
f010355f:	e8 da da ff ff       	call   f010103e <page_alloc>
f0103564:	83 c4 10             	add    $0x10,%esp
f0103567:	85 c0                	test   %eax,%eax
f0103569:	0f 84 52 01 00 00    	je     f01036c1 <env_alloc+0x185>
    p->pp_ref++;
f010356f:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0103574:	c7 c2 f0 03 19 f0    	mov    $0xf01903f0,%edx
f010357a:	2b 02                	sub    (%edx),%eax
f010357c:	c1 f8 03             	sar    $0x3,%eax
f010357f:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0103582:	89 c1                	mov    %eax,%ecx
f0103584:	c1 e9 0c             	shr    $0xc,%ecx
f0103587:	c7 c2 e8 03 19 f0    	mov    $0xf01903e8,%edx
f010358d:	3b 0a                	cmp    (%edx),%ecx
f010358f:	0f 83 f6 00 00 00    	jae    f010368b <env_alloc+0x14f>
	return (void *)(pa + KERNBASE);
f0103595:	2d 00 00 00 10       	sub    $0x10000000,%eax
    e->env_pgdir = page2kva(p);
f010359a:	89 46 5c             	mov    %eax,0x5c(%esi)
    memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f010359d:	83 ec 04             	sub    $0x4,%esp
f01035a0:	68 00 10 00 00       	push   $0x1000
f01035a5:	c7 c2 ec 03 19 f0    	mov    $0xf01903ec,%edx
f01035ab:	ff 32                	pushl  (%edx)
f01035ad:	50                   	push   %eax
f01035ae:	e8 f1 19 00 00       	call   f0104fa4 <memcpy>
    e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01035b3:	8b 46 5c             	mov    0x5c(%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f01035b6:	83 c4 10             	add    $0x10,%esp
f01035b9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01035be:	0f 86 dd 00 00 00    	jbe    f01036a1 <env_alloc+0x165>
	return (physaddr_t)kva - KERNBASE;
f01035c4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01035ca:	83 ca 05             	or     $0x5,%edx
f01035cd:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
    generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01035d3:	8b 46 48             	mov    0x48(%esi),%eax
f01035d6:	05 00 10 00 00       	add    $0x1000,%eax
    if (generation <= 0) // Don't create a negative env_id.
f01035db:	25 00 fc ff ff       	and    $0xfffffc00,%eax
        generation = 1 << ENVGENSHIFT;
f01035e0:	ba 00 10 00 00       	mov    $0x1000,%edx
f01035e5:	0f 4e c2             	cmovle %edx,%eax
    e->env_id = generation | (e - envs);
f01035e8:	89 f2                	mov    %esi,%edx
f01035ea:	2b 93 0c 27 00 00    	sub    0x270c(%ebx),%edx
f01035f0:	c1 fa 05             	sar    $0x5,%edx
f01035f3:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01035f9:	09 d0                	or     %edx,%eax
f01035fb:	89 46 48             	mov    %eax,0x48(%esi)
    e->env_parent_id = parent_id;
f01035fe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103601:	89 46 4c             	mov    %eax,0x4c(%esi)
    e->env_type = ENV_TYPE_USER;
f0103604:	c7 46 50 00 00 00 00 	movl   $0x0,0x50(%esi)
    e->env_status = ENV_RUNNABLE;
f010360b:	c7 46 54 02 00 00 00 	movl   $0x2,0x54(%esi)
    e->env_runs = 0;
f0103612:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
    memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103619:	83 ec 04             	sub    $0x4,%esp
f010361c:	6a 44                	push   $0x44
f010361e:	6a 00                	push   $0x0
f0103620:	56                   	push   %esi
f0103621:	e8 c9 18 00 00       	call   f0104eef <memset>
    e->env_tf.tf_ds = GD_UD | 3;
f0103626:	66 c7 46 24 23 00    	movw   $0x23,0x24(%esi)
    e->env_tf.tf_es = GD_UD | 3;
f010362c:	66 c7 46 20 23 00    	movw   $0x23,0x20(%esi)
    e->env_tf.tf_ss = GD_UD | 3;
f0103632:	66 c7 46 40 23 00    	movw   $0x23,0x40(%esi)
    e->env_tf.tf_esp = USTACKTOP;
f0103638:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
    e->env_tf.tf_cs = GD_UT | 3;
f010363f:	66 c7 46 34 1b 00    	movw   $0x1b,0x34(%esi)
    env_free_list = e->env_link;
f0103645:	8b 46 44             	mov    0x44(%esi),%eax
f0103648:	89 83 10 27 00 00    	mov    %eax,0x2710(%ebx)
    *newenv_store = e;
f010364e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103651:	89 30                	mov    %esi,(%eax)
    cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103653:	8b 4e 48             	mov    0x48(%esi),%ecx
f0103656:	8b 83 08 27 00 00    	mov    0x2708(%ebx),%eax
f010365c:	83 c4 10             	add    $0x10,%esp
f010365f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103664:	85 c0                	test   %eax,%eax
f0103666:	74 03                	je     f010366b <env_alloc+0x12f>
f0103668:	8b 50 48             	mov    0x48(%eax),%edx
f010366b:	83 ec 04             	sub    $0x4,%esp
f010366e:	51                   	push   %ecx
f010366f:	52                   	push   %edx
f0103670:	8d 83 67 94 f7 ff    	lea    -0x86b99(%ebx),%eax
f0103676:	50                   	push   %eax
f0103677:	e8 38 05 00 00       	call   f0103bb4 <cprintf>
    return 0;
f010367c:	83 c4 10             	add    $0x10,%esp
f010367f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103684:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103687:	5b                   	pop    %ebx
f0103688:	5e                   	pop    %esi
f0103689:	5d                   	pop    %ebp
f010368a:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010368b:	50                   	push   %eax
f010368c:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f0103692:	50                   	push   %eax
f0103693:	6a 56                	push   $0x56
f0103695:	8d 83 b1 90 f7 ff    	lea    -0x86f4f(%ebx),%eax
f010369b:	50                   	push   %eax
f010369c:	e8 10 ca ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01036a1:	50                   	push   %eax
f01036a2:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f01036a8:	50                   	push   %eax
f01036a9:	68 d0 00 00 00       	push   $0xd0
f01036ae:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f01036b4:	50                   	push   %eax
f01036b5:	e8 f7 c9 ff ff       	call   f01000b1 <_panic>
        return -E_NO_FREE_ENV;
f01036ba:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01036bf:	eb c3                	jmp    f0103684 <env_alloc+0x148>
        return -E_NO_MEM;
f01036c1:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01036c6:	eb bc                	jmp    f0103684 <env_alloc+0x148>

f01036c8 <env_create>:
// This function is ONLY called during kernel initialization,
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void env_create(uint8_t *binary, enum EnvType type)
{
f01036c8:	55                   	push   %ebp
f01036c9:	89 e5                	mov    %esp,%ebp
f01036cb:	57                   	push   %edi
f01036cc:	56                   	push   %esi
f01036cd:	53                   	push   %ebx
f01036ce:	83 ec 34             	sub    $0x34,%esp
f01036d1:	e8 91 ca ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01036d6:	81 c3 4a 99 08 00    	add    $0x8994a,%ebx
f01036dc:	8b 7d 08             	mov    0x8(%ebp),%edi
    // LAB 3: Your code here.
    struct Env *newenv;
    if (env_alloc(&newenv, 0) < 0)
f01036df:	6a 00                	push   $0x0
f01036e1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01036e4:	50                   	push   %eax
f01036e5:	e8 52 fe ff ff       	call   f010353c <env_alloc>
f01036ea:	83 c4 10             	add    $0x10,%esp
f01036ed:	85 c0                	test   %eax,%eax
f01036ef:	78 3a                	js     f010372b <env_create+0x63>
        panic("env_create: ");
    load_icode(newenv, binary);
f01036f1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01036f4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    if (elf->e_magic != ELF_MAGIC)
f01036f7:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01036fd:	75 47                	jne    f0103746 <env_create+0x7e>
    ph = (struct Proghdr *)((uint8_t *)elf + elf->e_phoff);
f01036ff:	89 fe                	mov    %edi,%esi
f0103701:	03 77 1c             	add    0x1c(%edi),%esi
    eph = ph + elf->e_phnum;
f0103704:	0f b7 47 2c          	movzwl 0x2c(%edi),%eax
f0103708:	c1 e0 05             	shl    $0x5,%eax
f010370b:	01 f0                	add    %esi,%eax
f010370d:	89 c1                	mov    %eax,%ecx
    lcr3(PADDR(e->env_pgdir));
f010370f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103712:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103715:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010371a:	76 45                	jbe    f0103761 <env_create+0x99>
	return (physaddr_t)kva - KERNBASE;
f010371c:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103721:	0f 22 d8             	mov    %eax,%cr3
f0103724:	89 7d 08             	mov    %edi,0x8(%ebp)
f0103727:	89 cf                	mov    %ecx,%edi
f0103729:	eb 6d                	jmp    f0103798 <env_create+0xd0>
        panic("env_create: ");
f010372b:	83 ec 04             	sub    $0x4,%esp
f010372e:	8d 83 7c 94 f7 ff    	lea    -0x86b84(%ebx),%eax
f0103734:	50                   	push   %eax
f0103735:	68 a1 01 00 00       	push   $0x1a1
f010373a:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f0103740:	50                   	push   %eax
f0103741:	e8 6b c9 ff ff       	call   f01000b1 <_panic>
        panic("Elf binary sequence not valid at header magic number...\n");
f0103746:	83 ec 04             	sub    $0x4,%esp
f0103749:	8d 83 9c 93 f7 ff    	lea    -0x86c64(%ebx),%eax
f010374f:	50                   	push   %eax
f0103750:	68 72 01 00 00       	push   $0x172
f0103755:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f010375b:	50                   	push   %eax
f010375c:	e8 50 c9 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103761:	50                   	push   %eax
f0103762:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f0103768:	50                   	push   %eax
f0103769:	68 7a 01 00 00       	push   $0x17a
f010376e:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f0103774:	50                   	push   %eax
f0103775:	e8 37 c9 ff ff       	call   f01000b1 <_panic>
            panic("ELF size in memory less than size in file...\n");
f010377a:	83 ec 04             	sub    $0x4,%esp
f010377d:	8d 83 d8 93 f7 ff    	lea    -0x86c28(%ebx),%eax
f0103783:	50                   	push   %eax
f0103784:	68 80 01 00 00       	push   $0x180
f0103789:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f010378f:	50                   	push   %eax
f0103790:	e8 1c c9 ff ff       	call   f01000b1 <_panic>
    for (; ph < eph; ph++)
f0103795:	83 c6 20             	add    $0x20,%esi
f0103798:	39 f7                	cmp    %esi,%edi
f010379a:	76 49                	jbe    f01037e5 <env_create+0x11d>
        if (ph->p_type != ELF_PROG_LOAD)
f010379c:	83 3e 01             	cmpl   $0x1,(%esi)
f010379f:	75 f4                	jne    f0103795 <env_create+0xcd>
        if (ph->p_memsz < ph->p_filesz)
f01037a1:	8b 4e 14             	mov    0x14(%esi),%ecx
f01037a4:	3b 4e 10             	cmp    0x10(%esi),%ecx
f01037a7:	72 d1                	jb     f010377a <env_create+0xb2>
        region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f01037a9:	8b 56 08             	mov    0x8(%esi),%edx
f01037ac:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01037af:	e8 86 fb ff ff       	call   f010333a <region_alloc>
        memset((void *)(ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
f01037b4:	8b 46 10             	mov    0x10(%esi),%eax
f01037b7:	83 ec 04             	sub    $0x4,%esp
f01037ba:	8b 56 14             	mov    0x14(%esi),%edx
f01037bd:	29 c2                	sub    %eax,%edx
f01037bf:	52                   	push   %edx
f01037c0:	6a 00                	push   $0x0
f01037c2:	03 46 08             	add    0x8(%esi),%eax
f01037c5:	50                   	push   %eax
f01037c6:	e8 24 17 00 00       	call   f0104eef <memset>
        memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f01037cb:	83 c4 0c             	add    $0xc,%esp
f01037ce:	ff 76 10             	pushl  0x10(%esi)
f01037d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01037d4:	03 46 04             	add    0x4(%esi),%eax
f01037d7:	50                   	push   %eax
f01037d8:	ff 76 08             	pushl  0x8(%esi)
f01037db:	e8 c4 17 00 00       	call   f0104fa4 <memcpy>
f01037e0:	83 c4 10             	add    $0x10,%esp
f01037e3:	eb b0                	jmp    f0103795 <env_create+0xcd>
f01037e5:	8b 7d 08             	mov    0x8(%ebp),%edi
    e->env_tf.tf_eip = elf->e_entry;
f01037e8:	8b 47 18             	mov    0x18(%edi),%eax
f01037eb:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01037ee:	89 47 30             	mov    %eax,0x30(%edi)
    region_alloc(e, (void *)(USTACKTOP - PGSIZE), PGSIZE);
f01037f1:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01037f6:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01037fb:	89 f8                	mov    %edi,%eax
f01037fd:	e8 38 fb ff ff       	call   f010333a <region_alloc>
    lcr3(PADDR(kern_pgdir));
f0103802:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0103808:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010380a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010380f:	76 19                	jbe    f010382a <env_create+0x162>
	return (physaddr_t)kva - KERNBASE;
f0103811:	05 00 00 00 10       	add    $0x10000000,%eax
f0103816:	0f 22 d8             	mov    %eax,%cr3
    newenv->env_type = type;
f0103819:	8b 55 0c             	mov    0xc(%ebp),%edx
f010381c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010381f:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103822:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103825:	5b                   	pop    %ebx
f0103826:	5e                   	pop    %esi
f0103827:	5f                   	pop    %edi
f0103828:	5d                   	pop    %ebp
f0103829:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010382a:	50                   	push   %eax
f010382b:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f0103831:	50                   	push   %eax
f0103832:	68 92 01 00 00       	push   $0x192
f0103837:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f010383d:	50                   	push   %eax
f010383e:	e8 6e c8 ff ff       	call   f01000b1 <_panic>

f0103843 <env_free>:

//
// Frees env e and all memory it uses.
//
void env_free(struct Env *e)
{
f0103843:	55                   	push   %ebp
f0103844:	89 e5                	mov    %esp,%ebp
f0103846:	57                   	push   %edi
f0103847:	56                   	push   %esi
f0103848:	53                   	push   %ebx
f0103849:	83 ec 2c             	sub    $0x2c,%esp
f010384c:	e8 16 c9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103851:	81 c3 cf 97 08 00    	add    $0x897cf,%ebx
    physaddr_t pa;

    // If freeing the current environment, switch to kern_pgdir
    // before freeing the page directory, just in case the page
    // gets reused.
    if (e == curenv)
f0103857:	8b 93 08 27 00 00    	mov    0x2708(%ebx),%edx
f010385d:	3b 55 08             	cmp    0x8(%ebp),%edx
f0103860:	75 17                	jne    f0103879 <env_free+0x36>
        lcr3(PADDR(kern_pgdir));
f0103862:	c7 c0 ec 03 19 f0    	mov    $0xf01903ec,%eax
f0103868:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010386a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010386f:	76 46                	jbe    f01038b7 <env_free+0x74>
	return (physaddr_t)kva - KERNBASE;
f0103871:	05 00 00 00 10       	add    $0x10000000,%eax
f0103876:	0f 22 d8             	mov    %eax,%cr3

    // Note the environment's demise.
    cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103879:	8b 45 08             	mov    0x8(%ebp),%eax
f010387c:	8b 48 48             	mov    0x48(%eax),%ecx
f010387f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103884:	85 d2                	test   %edx,%edx
f0103886:	74 03                	je     f010388b <env_free+0x48>
f0103888:	8b 42 48             	mov    0x48(%edx),%eax
f010388b:	83 ec 04             	sub    $0x4,%esp
f010388e:	51                   	push   %ecx
f010388f:	50                   	push   %eax
f0103890:	8d 83 89 94 f7 ff    	lea    -0x86b77(%ebx),%eax
f0103896:	50                   	push   %eax
f0103897:	e8 18 03 00 00       	call   f0103bb4 <cprintf>
f010389c:	83 c4 10             	add    $0x10,%esp
f010389f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	if (PGNUM(pa) >= npages)
f01038a6:	c7 c0 e8 03 19 f0    	mov    $0xf01903e8,%eax
f01038ac:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (PGNUM(pa) >= npages)
f01038af:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01038b2:	e9 9f 00 00 00       	jmp    f0103956 <env_free+0x113>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01038b7:	50                   	push   %eax
f01038b8:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f01038be:	50                   	push   %eax
f01038bf:	68 b3 01 00 00       	push   $0x1b3
f01038c4:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f01038ca:	50                   	push   %eax
f01038cb:	e8 e1 c7 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01038d0:	50                   	push   %eax
f01038d1:	8d 83 14 88 f7 ff    	lea    -0x877ec(%ebx),%eax
f01038d7:	50                   	push   %eax
f01038d8:	68 c3 01 00 00       	push   $0x1c3
f01038dd:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f01038e3:	50                   	push   %eax
f01038e4:	e8 c8 c7 ff ff       	call   f01000b1 <_panic>
f01038e9:	83 c6 04             	add    $0x4,%esi
        // find the pa and va of the page table
        pa = PTE_ADDR(e->env_pgdir[pdeno]);
        pt = (pte_t *)KADDR(pa);

        // unmap all PTEs in this page table
        for (pteno = 0; pteno <= PTX(~0); pteno++)
f01038ec:	39 fe                	cmp    %edi,%esi
f01038ee:	74 24                	je     f0103914 <env_free+0xd1>
        {
            if (pt[pteno] & PTE_P)
f01038f0:	f6 06 01             	testb  $0x1,(%esi)
f01038f3:	74 f4                	je     f01038e9 <env_free+0xa6>
                page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01038f5:	83 ec 08             	sub    $0x8,%esp
f01038f8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01038fb:	01 f0                	add    %esi,%eax
f01038fd:	c1 e0 0a             	shl    $0xa,%eax
f0103900:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103903:	50                   	push   %eax
f0103904:	8b 45 08             	mov    0x8(%ebp),%eax
f0103907:	ff 70 5c             	pushl  0x5c(%eax)
f010390a:	e8 5b da ff ff       	call   f010136a <page_remove>
f010390f:	83 c4 10             	add    $0x10,%esp
f0103912:	eb d5                	jmp    f01038e9 <env_free+0xa6>
        }

        // free the page table itself
        e->env_pgdir[pdeno] = 0;
f0103914:	8b 45 08             	mov    0x8(%ebp),%eax
f0103917:	8b 40 5c             	mov    0x5c(%eax),%eax
f010391a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010391d:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f0103924:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103927:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010392a:	3b 10                	cmp    (%eax),%edx
f010392c:	73 6f                	jae    f010399d <env_free+0x15a>
        page_decref(pa2page(pa));
f010392e:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103931:	c7 c0 f0 03 19 f0    	mov    $0xf01903f0,%eax
f0103937:	8b 00                	mov    (%eax),%eax
f0103939:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010393c:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f010393f:	50                   	push   %eax
f0103940:	e8 d0 d7 ff ff       	call   f0101115 <page_decref>
f0103945:	83 c4 10             	add    $0x10,%esp
f0103948:	83 45 dc 04          	addl   $0x4,-0x24(%ebp)
f010394c:	8b 45 dc             	mov    -0x24(%ebp),%eax
    for (pdeno = 0; pdeno < PDX(UTOP); pdeno++)
f010394f:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f0103954:	74 5f                	je     f01039b5 <env_free+0x172>
        if (!(e->env_pgdir[pdeno] & PTE_P))
f0103956:	8b 45 08             	mov    0x8(%ebp),%eax
f0103959:	8b 40 5c             	mov    0x5c(%eax),%eax
f010395c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010395f:	8b 04 10             	mov    (%eax,%edx,1),%eax
f0103962:	a8 01                	test   $0x1,%al
f0103964:	74 e2                	je     f0103948 <env_free+0x105>
        pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103966:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f010396b:	89 c2                	mov    %eax,%edx
f010396d:	c1 ea 0c             	shr    $0xc,%edx
f0103970:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0103973:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103976:	39 11                	cmp    %edx,(%ecx)
f0103978:	0f 86 52 ff ff ff    	jbe    f01038d0 <env_free+0x8d>
	return (void *)(pa + KERNBASE);
f010397e:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi
                page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103984:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103987:	c1 e2 14             	shl    $0x14,%edx
f010398a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010398d:	8d b8 00 10 00 f0    	lea    -0xffff000(%eax),%edi
f0103993:	f7 d8                	neg    %eax
f0103995:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103998:	e9 53 ff ff ff       	jmp    f01038f0 <env_free+0xad>
		panic("pa2page called with invalid pa");
f010399d:	83 ec 04             	sub    $0x4,%esp
f01039a0:	8d 83 94 89 f7 ff    	lea    -0x8766c(%ebx),%eax
f01039a6:	50                   	push   %eax
f01039a7:	6a 4f                	push   $0x4f
f01039a9:	8d 83 b1 90 f7 ff    	lea    -0x86f4f(%ebx),%eax
f01039af:	50                   	push   %eax
f01039b0:	e8 fc c6 ff ff       	call   f01000b1 <_panic>
    }

    // free the page directory
    pa = PADDR(e->env_pgdir);
f01039b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01039b8:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01039bb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01039c0:	76 57                	jbe    f0103a19 <env_free+0x1d6>
    e->env_pgdir = 0;
f01039c2:	8b 55 08             	mov    0x8(%ebp),%edx
f01039c5:	c7 42 5c 00 00 00 00 	movl   $0x0,0x5c(%edx)
	return (physaddr_t)kva - KERNBASE;
f01039cc:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f01039d1:	c1 e8 0c             	shr    $0xc,%eax
f01039d4:	c7 c2 e8 03 19 f0    	mov    $0xf01903e8,%edx
f01039da:	3b 02                	cmp    (%edx),%eax
f01039dc:	73 54                	jae    f0103a32 <env_free+0x1ef>
    page_decref(pa2page(pa));
f01039de:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01039e1:	c7 c2 f0 03 19 f0    	mov    $0xf01903f0,%edx
f01039e7:	8b 12                	mov    (%edx),%edx
f01039e9:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01039ec:	50                   	push   %eax
f01039ed:	e8 23 d7 ff ff       	call   f0101115 <page_decref>

    // return the environment to the free list
    e->env_status = ENV_FREE;
f01039f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01039f5:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
    e->env_link = env_free_list;
f01039fc:	8b 83 10 27 00 00    	mov    0x2710(%ebx),%eax
f0103a02:	8b 55 08             	mov    0x8(%ebp),%edx
f0103a05:	89 42 44             	mov    %eax,0x44(%edx)
    env_free_list = e;
f0103a08:	89 93 10 27 00 00    	mov    %edx,0x2710(%ebx)
}
f0103a0e:	83 c4 10             	add    $0x10,%esp
f0103a11:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a14:	5b                   	pop    %ebx
f0103a15:	5e                   	pop    %esi
f0103a16:	5f                   	pop    %edi
f0103a17:	5d                   	pop    %ebp
f0103a18:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103a19:	50                   	push   %eax
f0103a1a:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f0103a20:	50                   	push   %eax
f0103a21:	68 d2 01 00 00       	push   $0x1d2
f0103a26:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f0103a2c:	50                   	push   %eax
f0103a2d:	e8 7f c6 ff ff       	call   f01000b1 <_panic>
		panic("pa2page called with invalid pa");
f0103a32:	83 ec 04             	sub    $0x4,%esp
f0103a35:	8d 83 94 89 f7 ff    	lea    -0x8766c(%ebx),%eax
f0103a3b:	50                   	push   %eax
f0103a3c:	6a 4f                	push   $0x4f
f0103a3e:	8d 83 b1 90 f7 ff    	lea    -0x86f4f(%ebx),%eax
f0103a44:	50                   	push   %eax
f0103a45:	e8 67 c6 ff ff       	call   f01000b1 <_panic>

f0103a4a <env_destroy>:

//
// Frees environment e.
//
void env_destroy(struct Env *e)
{
f0103a4a:	55                   	push   %ebp
f0103a4b:	89 e5                	mov    %esp,%ebp
f0103a4d:	53                   	push   %ebx
f0103a4e:	83 ec 10             	sub    $0x10,%esp
f0103a51:	e8 11 c7 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103a56:	81 c3 ca 95 08 00    	add    $0x895ca,%ebx
    env_free(e);
f0103a5c:	ff 75 08             	pushl  0x8(%ebp)
f0103a5f:	e8 df fd ff ff       	call   f0103843 <env_free>

    cprintf("Destroyed the only environment - nothing more to do!\n");
f0103a64:	8d 83 08 94 f7 ff    	lea    -0x86bf8(%ebx),%eax
f0103a6a:	89 04 24             	mov    %eax,(%esp)
f0103a6d:	e8 42 01 00 00       	call   f0103bb4 <cprintf>
f0103a72:	83 c4 10             	add    $0x10,%esp
    while (1)
        monitor(NULL);
f0103a75:	83 ec 0c             	sub    $0xc,%esp
f0103a78:	6a 00                	push   $0x0
f0103a7a:	e8 51 ce ff ff       	call   f01008d0 <monitor>
f0103a7f:	83 c4 10             	add    $0x10,%esp
f0103a82:	eb f1                	jmp    f0103a75 <env_destroy+0x2b>

f0103a84 <env_pop_tf>:
// This exits the kernel and starts executing some environment's code.
//
// This function does not return.
//
void env_pop_tf(struct Trapframe *tf)
{
f0103a84:	55                   	push   %ebp
f0103a85:	89 e5                	mov    %esp,%ebp
f0103a87:	53                   	push   %ebx
f0103a88:	83 ec 08             	sub    $0x8,%esp
f0103a8b:	e8 d7 c6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103a90:	81 c3 90 95 08 00    	add    $0x89590,%ebx
    asm volatile(
f0103a96:	8b 65 08             	mov    0x8(%ebp),%esp
f0103a99:	61                   	popa   
f0103a9a:	07                   	pop    %es
f0103a9b:	1f                   	pop    %ds
f0103a9c:	83 c4 08             	add    $0x8,%esp
f0103a9f:	cf                   	iret   
        "\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
        "\tiret\n"
        :
        : "g"(tf)
        : "memory");
    panic("iret failed"); /* mostly to placate the compiler */
f0103aa0:	8d 83 9f 94 f7 ff    	lea    -0x86b61(%ebx),%eax
f0103aa6:	50                   	push   %eax
f0103aa7:	68 fa 01 00 00       	push   $0x1fa
f0103aac:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f0103ab2:	50                   	push   %eax
f0103ab3:	e8 f9 c5 ff ff       	call   f01000b1 <_panic>

f0103ab8 <env_run>:
// Note: if this is the first call to env_run, curenv is NULL.
//
// This function does not return.
//
void env_run(struct Env *e)
{
f0103ab8:	55                   	push   %ebp
f0103ab9:	89 e5                	mov    %esp,%ebp
f0103abb:	53                   	push   %ebx
f0103abc:	83 ec 04             	sub    $0x4,%esp
f0103abf:	e8 a3 c6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103ac4:	81 c3 5c 95 08 00    	add    $0x8955c,%ebx
f0103aca:	8b 45 08             	mov    0x8(%ebp),%eax
    //	e->env_tf.  Go back through the code you wrote above
    //	and make sure you have set the relevant parts of
    //	e->env_tf to sensible values.

    // LAB 3: Your code here.
    if (curenv != NULL && curenv->env_status == ENV_RUNNING)
f0103acd:	8b 93 08 27 00 00    	mov    0x2708(%ebx),%edx
f0103ad3:	85 d2                	test   %edx,%edx
f0103ad5:	74 06                	je     f0103add <env_run+0x25>
f0103ad7:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0103adb:	74 35                	je     f0103b12 <env_run+0x5a>
    {
        curenv->env_status = ENV_RUNNABLE;
    }

    curenv = e;
f0103add:	89 83 08 27 00 00    	mov    %eax,0x2708(%ebx)
    curenv->env_status = ENV_RUNNING;
f0103ae3:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
    curenv->env_runs++;
f0103aea:	83 40 58 01          	addl   $0x1,0x58(%eax)
    lcr3(PADDR(curenv->env_pgdir));
f0103aee:	8b 50 5c             	mov    0x5c(%eax),%edx
	if ((uint32_t)kva < KERNBASE)
f0103af1:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103af7:	77 22                	ja     f0103b1b <env_run+0x63>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103af9:	52                   	push   %edx
f0103afa:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f0103b00:	50                   	push   %eax
f0103b01:	68 1f 02 00 00       	push   $0x21f
f0103b06:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f0103b0c:	50                   	push   %eax
f0103b0d:	e8 9f c5 ff ff       	call   f01000b1 <_panic>
        curenv->env_status = ENV_RUNNABLE;
f0103b12:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
f0103b19:	eb c2                	jmp    f0103add <env_run+0x25>
	return (physaddr_t)kva - KERNBASE;
f0103b1b:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103b21:	0f 22 da             	mov    %edx,%cr3

    // unlock_kernel();
    // iret退出内核, 回到用户环境执行,
    // 在load_icode() 中 env_tf保存了可执行文件的eip等信息
    env_pop_tf(&curenv->env_tf);
f0103b24:	83 ec 0c             	sub    $0xc,%esp
f0103b27:	50                   	push   %eax
f0103b28:	e8 57 ff ff ff       	call   f0103a84 <env_pop_tf>

f0103b2d <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103b2d:	55                   	push   %ebp
f0103b2e:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103b30:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b33:	ba 70 00 00 00       	mov    $0x70,%edx
f0103b38:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103b39:	ba 71 00 00 00       	mov    $0x71,%edx
f0103b3e:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103b3f:	0f b6 c0             	movzbl %al,%eax
}
f0103b42:	5d                   	pop    %ebp
f0103b43:	c3                   	ret    

f0103b44 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103b44:	55                   	push   %ebp
f0103b45:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103b47:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b4a:	ba 70 00 00 00       	mov    $0x70,%edx
f0103b4f:	ee                   	out    %al,(%dx)
f0103b50:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b53:	ba 71 00 00 00       	mov    $0x71,%edx
f0103b58:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103b59:	5d                   	pop    %ebp
f0103b5a:	c3                   	ret    

f0103b5b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103b5b:	55                   	push   %ebp
f0103b5c:	89 e5                	mov    %esp,%ebp
f0103b5e:	53                   	push   %ebx
f0103b5f:	83 ec 10             	sub    $0x10,%esp
f0103b62:	e8 00 c6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103b67:	81 c3 b9 94 08 00    	add    $0x894b9,%ebx
	cputchar(ch);
f0103b6d:	ff 75 08             	pushl  0x8(%ebp)
f0103b70:	e8 69 cb ff ff       	call   f01006de <cputchar>
	*cnt++;
}
f0103b75:	83 c4 10             	add    $0x10,%esp
f0103b78:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b7b:	c9                   	leave  
f0103b7c:	c3                   	ret    

f0103b7d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103b7d:	55                   	push   %ebp
f0103b7e:	89 e5                	mov    %esp,%ebp
f0103b80:	53                   	push   %ebx
f0103b81:	83 ec 14             	sub    $0x14,%esp
f0103b84:	e8 de c5 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103b89:	81 c3 97 94 08 00    	add    $0x89497,%ebx
	int cnt = 0;
f0103b8f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103b96:	ff 75 0c             	pushl  0xc(%ebp)
f0103b99:	ff 75 08             	pushl  0x8(%ebp)
f0103b9c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103b9f:	50                   	push   %eax
f0103ba0:	8d 83 3b 6b f7 ff    	lea    -0x894c5(%ebx),%eax
f0103ba6:	50                   	push   %eax
f0103ba7:	e8 c2 0b 00 00       	call   f010476e <vprintfmt>
	return cnt;
}
f0103bac:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103baf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103bb2:	c9                   	leave  
f0103bb3:	c3                   	ret    

f0103bb4 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103bb4:	55                   	push   %ebp
f0103bb5:	89 e5                	mov    %esp,%ebp
f0103bb7:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103bba:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103bbd:	50                   	push   %eax
f0103bbe:	ff 75 08             	pushl  0x8(%ebp)
f0103bc1:	e8 b7 ff ff ff       	call   f0103b7d <vcprintf>
	va_end(ap);

	return cnt;
}
f0103bc6:	c9                   	leave  
f0103bc7:	c3                   	ret    

f0103bc8 <trap_init_percpu>:
	trap_init_percpu();
}

// Initialize and load the per-CPU TSS and IDT
void trap_init_percpu(void)
{
f0103bc8:	55                   	push   %ebp
f0103bc9:	89 e5                	mov    %esp,%ebp
f0103bcb:	57                   	push   %edi
f0103bcc:	56                   	push   %esi
f0103bcd:	53                   	push   %ebx
f0103bce:	83 ec 04             	sub    $0x4,%esp
f0103bd1:	e8 91 c5 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103bd6:	81 c3 4a 94 08 00    	add    $0x8944a,%ebx
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103bdc:	c7 83 44 2f 00 00 00 	movl   $0xf0000000,0x2f44(%ebx)
f0103be3:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103be6:	66 c7 83 48 2f 00 00 	movw   $0x10,0x2f48(%ebx)
f0103bed:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0103bef:	66 c7 83 a6 2f 00 00 	movw   $0x68,0x2fa6(%ebx)
f0103bf6:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t)(&ts),
f0103bf8:	c7 c0 00 c3 11 f0    	mov    $0xf011c300,%eax
f0103bfe:	66 c7 40 28 67 00    	movw   $0x67,0x28(%eax)
f0103c04:	8d b3 40 2f 00 00    	lea    0x2f40(%ebx),%esi
f0103c0a:	66 89 70 2a          	mov    %si,0x2a(%eax)
f0103c0e:	89 f2                	mov    %esi,%edx
f0103c10:	c1 ea 10             	shr    $0x10,%edx
f0103c13:	88 50 2c             	mov    %dl,0x2c(%eax)
f0103c16:	0f b6 50 2d          	movzbl 0x2d(%eax),%edx
f0103c1a:	83 e2 f0             	and    $0xfffffff0,%edx
f0103c1d:	83 ca 09             	or     $0x9,%edx
f0103c20:	83 e2 9f             	and    $0xffffff9f,%edx
f0103c23:	83 ca 80             	or     $0xffffff80,%edx
f0103c26:	88 55 f3             	mov    %dl,-0xd(%ebp)
f0103c29:	88 50 2d             	mov    %dl,0x2d(%eax)
f0103c2c:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
f0103c30:	83 e1 c0             	and    $0xffffffc0,%ecx
f0103c33:	83 c9 40             	or     $0x40,%ecx
f0103c36:	83 e1 7f             	and    $0x7f,%ecx
f0103c39:	88 48 2e             	mov    %cl,0x2e(%eax)
f0103c3c:	c1 ee 18             	shr    $0x18,%esi
f0103c3f:	89 f1                	mov    %esi,%ecx
f0103c41:	88 48 2f             	mov    %cl,0x2f(%eax)
							  sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103c44:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
f0103c48:	83 e2 ef             	and    $0xffffffef,%edx
f0103c4b:	88 50 2d             	mov    %dl,0x2d(%eax)
	asm volatile("ltr %0" : : "r" (sel));
f0103c4e:	b8 28 00 00 00       	mov    $0x28,%eax
f0103c53:	0f 00 d8             	ltr    %ax
	asm volatile("lidt (%0)" : : "r" (p));
f0103c56:	8d 83 e8 1f 00 00    	lea    0x1fe8(%ebx),%eax
f0103c5c:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103c5f:	83 c4 04             	add    $0x4,%esp
f0103c62:	5b                   	pop    %ebx
f0103c63:	5e                   	pop    %esi
f0103c64:	5f                   	pop    %edi
f0103c65:	5d                   	pop    %ebp
f0103c66:	c3                   	ret    

f0103c67 <trap_init>:
{
f0103c67:	55                   	push   %ebp
f0103c68:	89 e5                	mov    %esp,%ebp
f0103c6a:	53                   	push   %ebx
f0103c6b:	e8 1b 05 00 00       	call   f010418b <__x86.get_pc_thunk.dx>
f0103c70:	81 c2 b0 93 08 00    	add    $0x893b0,%edx
	for (int i = 0; i < 32; ++i)
f0103c76:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i], 0, GD_KT, handlers[i], 0);
f0103c7b:	8b 8c 82 c0 20 00 00 	mov    0x20c0(%edx,%eax,4),%ecx
f0103c82:	66 89 8c c2 20 27 00 	mov    %cx,0x2720(%edx,%eax,8)
f0103c89:	00 
f0103c8a:	8d 9c c2 20 27 00 00 	lea    0x2720(%edx,%eax,8),%ebx
f0103c91:	66 c7 43 02 08 00    	movw   $0x8,0x2(%ebx)
f0103c97:	c6 84 c2 24 27 00 00 	movb   $0x0,0x2724(%edx,%eax,8)
f0103c9e:	00 
f0103c9f:	c6 84 c2 25 27 00 00 	movb   $0x8e,0x2725(%edx,%eax,8)
f0103ca6:	8e 
f0103ca7:	c1 e9 10             	shr    $0x10,%ecx
f0103caa:	66 89 4b 06          	mov    %cx,0x6(%ebx)
	for (int i = 0; i < 32; ++i)
f0103cae:	83 c0 01             	add    $0x1,%eax
f0103cb1:	83 f8 20             	cmp    $0x20,%eax
f0103cb4:	75 c5                	jne    f0103c7b <trap_init+0x14>
	SETGATE(idt[T_BRKPT], 0, GD_KT, handlers[T_BRKPT], 3);
f0103cb6:	c7 c0 a2 41 10 f0    	mov    $0xf01041a2,%eax
f0103cbc:	66 89 82 38 27 00 00 	mov    %ax,0x2738(%edx)
f0103cc3:	66 c7 82 3a 27 00 00 	movw   $0x8,0x273a(%edx)
f0103cca:	08 00 
f0103ccc:	c6 82 3c 27 00 00 00 	movb   $0x0,0x273c(%edx)
f0103cd3:	c6 82 3d 27 00 00 ee 	movb   $0xee,0x273d(%edx)
f0103cda:	c1 e8 10             	shr    $0x10,%eax
f0103cdd:	66 89 82 3e 27 00 00 	mov    %ax,0x273e(%edx)
	SETGATE(idt[T_SYSCALL], 0, GD_KT, handlers[T_SYSCALL], 3);
f0103ce4:	c7 c0 ee 41 10 f0    	mov    $0xf01041ee,%eax
f0103cea:	66 89 82 a0 28 00 00 	mov    %ax,0x28a0(%edx)
f0103cf1:	66 c7 82 a2 28 00 00 	movw   $0x8,0x28a2(%edx)
f0103cf8:	08 00 
f0103cfa:	c6 82 a4 28 00 00 00 	movb   $0x0,0x28a4(%edx)
f0103d01:	c6 82 a5 28 00 00 ee 	movb   $0xee,0x28a5(%edx)
f0103d08:	c1 e8 10             	shr    $0x10,%eax
f0103d0b:	66 89 82 a6 28 00 00 	mov    %ax,0x28a6(%edx)
	trap_init_percpu();
f0103d12:	e8 b1 fe ff ff       	call   f0103bc8 <trap_init_percpu>
}
f0103d17:	5b                   	pop    %ebx
f0103d18:	5d                   	pop    %ebp
f0103d19:	c3                   	ret    

f0103d1a <print_regs>:
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
	}
}

void print_regs(struct PushRegs *regs)
{
f0103d1a:	55                   	push   %ebp
f0103d1b:	89 e5                	mov    %esp,%ebp
f0103d1d:	56                   	push   %esi
f0103d1e:	53                   	push   %ebx
f0103d1f:	e8 43 c4 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103d24:	81 c3 fc 92 08 00    	add    $0x892fc,%ebx
f0103d2a:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103d2d:	83 ec 08             	sub    $0x8,%esp
f0103d30:	ff 36                	pushl  (%esi)
f0103d32:	8d 83 ab 94 f7 ff    	lea    -0x86b55(%ebx),%eax
f0103d38:	50                   	push   %eax
f0103d39:	e8 76 fe ff ff       	call   f0103bb4 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103d3e:	83 c4 08             	add    $0x8,%esp
f0103d41:	ff 76 04             	pushl  0x4(%esi)
f0103d44:	8d 83 ba 94 f7 ff    	lea    -0x86b46(%ebx),%eax
f0103d4a:	50                   	push   %eax
f0103d4b:	e8 64 fe ff ff       	call   f0103bb4 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103d50:	83 c4 08             	add    $0x8,%esp
f0103d53:	ff 76 08             	pushl  0x8(%esi)
f0103d56:	8d 83 c9 94 f7 ff    	lea    -0x86b37(%ebx),%eax
f0103d5c:	50                   	push   %eax
f0103d5d:	e8 52 fe ff ff       	call   f0103bb4 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103d62:	83 c4 08             	add    $0x8,%esp
f0103d65:	ff 76 0c             	pushl  0xc(%esi)
f0103d68:	8d 83 d8 94 f7 ff    	lea    -0x86b28(%ebx),%eax
f0103d6e:	50                   	push   %eax
f0103d6f:	e8 40 fe ff ff       	call   f0103bb4 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103d74:	83 c4 08             	add    $0x8,%esp
f0103d77:	ff 76 10             	pushl  0x10(%esi)
f0103d7a:	8d 83 e7 94 f7 ff    	lea    -0x86b19(%ebx),%eax
f0103d80:	50                   	push   %eax
f0103d81:	e8 2e fe ff ff       	call   f0103bb4 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103d86:	83 c4 08             	add    $0x8,%esp
f0103d89:	ff 76 14             	pushl  0x14(%esi)
f0103d8c:	8d 83 f6 94 f7 ff    	lea    -0x86b0a(%ebx),%eax
f0103d92:	50                   	push   %eax
f0103d93:	e8 1c fe ff ff       	call   f0103bb4 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103d98:	83 c4 08             	add    $0x8,%esp
f0103d9b:	ff 76 18             	pushl  0x18(%esi)
f0103d9e:	8d 83 05 95 f7 ff    	lea    -0x86afb(%ebx),%eax
f0103da4:	50                   	push   %eax
f0103da5:	e8 0a fe ff ff       	call   f0103bb4 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103daa:	83 c4 08             	add    $0x8,%esp
f0103dad:	ff 76 1c             	pushl  0x1c(%esi)
f0103db0:	8d 83 14 95 f7 ff    	lea    -0x86aec(%ebx),%eax
f0103db6:	50                   	push   %eax
f0103db7:	e8 f8 fd ff ff       	call   f0103bb4 <cprintf>
}
f0103dbc:	83 c4 10             	add    $0x10,%esp
f0103dbf:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103dc2:	5b                   	pop    %ebx
f0103dc3:	5e                   	pop    %esi
f0103dc4:	5d                   	pop    %ebp
f0103dc5:	c3                   	ret    

f0103dc6 <print_trapframe>:
{
f0103dc6:	55                   	push   %ebp
f0103dc7:	89 e5                	mov    %esp,%ebp
f0103dc9:	57                   	push   %edi
f0103dca:	56                   	push   %esi
f0103dcb:	53                   	push   %ebx
f0103dcc:	83 ec 14             	sub    $0x14,%esp
f0103dcf:	e8 93 c3 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103dd4:	81 c3 4c 92 08 00    	add    $0x8924c,%ebx
f0103dda:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("TRAP frame at %p\n", tf);
f0103ddd:	56                   	push   %esi
f0103dde:	8d 83 4a 96 f7 ff    	lea    -0x869b6(%ebx),%eax
f0103de4:	50                   	push   %eax
f0103de5:	e8 ca fd ff ff       	call   f0103bb4 <cprintf>
	print_regs(&tf->tf_regs);
f0103dea:	89 34 24             	mov    %esi,(%esp)
f0103ded:	e8 28 ff ff ff       	call   f0103d1a <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103df2:	83 c4 08             	add    $0x8,%esp
f0103df5:	0f b7 46 20          	movzwl 0x20(%esi),%eax
f0103df9:	50                   	push   %eax
f0103dfa:	8d 83 65 95 f7 ff    	lea    -0x86a9b(%ebx),%eax
f0103e00:	50                   	push   %eax
f0103e01:	e8 ae fd ff ff       	call   f0103bb4 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103e06:	83 c4 08             	add    $0x8,%esp
f0103e09:	0f b7 46 24          	movzwl 0x24(%esi),%eax
f0103e0d:	50                   	push   %eax
f0103e0e:	8d 83 78 95 f7 ff    	lea    -0x86a88(%ebx),%eax
f0103e14:	50                   	push   %eax
f0103e15:	e8 9a fd ff ff       	call   f0103bb4 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103e1a:	8b 56 28             	mov    0x28(%esi),%edx
	if (trapno < ARRAY_SIZE(excnames))
f0103e1d:	83 c4 10             	add    $0x10,%esp
f0103e20:	83 fa 13             	cmp    $0x13,%edx
f0103e23:	0f 86 e9 00 00 00    	jbe    f0103f12 <print_trapframe+0x14c>
	return "(unknown trap)";
f0103e29:	83 fa 30             	cmp    $0x30,%edx
f0103e2c:	8d 83 23 95 f7 ff    	lea    -0x86add(%ebx),%eax
f0103e32:	8d 8b 2f 95 f7 ff    	lea    -0x86ad1(%ebx),%ecx
f0103e38:	0f 45 c1             	cmovne %ecx,%eax
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103e3b:	83 ec 04             	sub    $0x4,%esp
f0103e3e:	50                   	push   %eax
f0103e3f:	52                   	push   %edx
f0103e40:	8d 83 8b 95 f7 ff    	lea    -0x86a75(%ebx),%eax
f0103e46:	50                   	push   %eax
f0103e47:	e8 68 fd ff ff       	call   f0103bb4 <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103e4c:	83 c4 10             	add    $0x10,%esp
f0103e4f:	39 b3 20 2f 00 00    	cmp    %esi,0x2f20(%ebx)
f0103e55:	0f 84 c3 00 00 00    	je     f0103f1e <print_trapframe+0x158>
	cprintf("  err  0x%08x", tf->tf_err);
f0103e5b:	83 ec 08             	sub    $0x8,%esp
f0103e5e:	ff 76 2c             	pushl  0x2c(%esi)
f0103e61:	8d 83 ac 95 f7 ff    	lea    -0x86a54(%ebx),%eax
f0103e67:	50                   	push   %eax
f0103e68:	e8 47 fd ff ff       	call   f0103bb4 <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f0103e6d:	83 c4 10             	add    $0x10,%esp
f0103e70:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0103e74:	0f 85 c9 00 00 00    	jne    f0103f43 <print_trapframe+0x17d>
				tf->tf_err & 1 ? "protection" : "not-present");
f0103e7a:	8b 46 2c             	mov    0x2c(%esi),%eax
		cprintf(" [%s, %s, %s]\n",
f0103e7d:	89 c2                	mov    %eax,%edx
f0103e7f:	83 e2 01             	and    $0x1,%edx
f0103e82:	8d 8b 3e 95 f7 ff    	lea    -0x86ac2(%ebx),%ecx
f0103e88:	8d 93 49 95 f7 ff    	lea    -0x86ab7(%ebx),%edx
f0103e8e:	0f 44 ca             	cmove  %edx,%ecx
f0103e91:	89 c2                	mov    %eax,%edx
f0103e93:	83 e2 02             	and    $0x2,%edx
f0103e96:	8d 93 55 95 f7 ff    	lea    -0x86aab(%ebx),%edx
f0103e9c:	8d bb 5b 95 f7 ff    	lea    -0x86aa5(%ebx),%edi
f0103ea2:	0f 44 d7             	cmove  %edi,%edx
f0103ea5:	83 e0 04             	and    $0x4,%eax
f0103ea8:	8d 83 60 95 f7 ff    	lea    -0x86aa0(%ebx),%eax
f0103eae:	8d bb 75 96 f7 ff    	lea    -0x8698b(%ebx),%edi
f0103eb4:	0f 44 c7             	cmove  %edi,%eax
f0103eb7:	51                   	push   %ecx
f0103eb8:	52                   	push   %edx
f0103eb9:	50                   	push   %eax
f0103eba:	8d 83 ba 95 f7 ff    	lea    -0x86a46(%ebx),%eax
f0103ec0:	50                   	push   %eax
f0103ec1:	e8 ee fc ff ff       	call   f0103bb4 <cprintf>
f0103ec6:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103ec9:	83 ec 08             	sub    $0x8,%esp
f0103ecc:	ff 76 30             	pushl  0x30(%esi)
f0103ecf:	8d 83 c9 95 f7 ff    	lea    -0x86a37(%ebx),%eax
f0103ed5:	50                   	push   %eax
f0103ed6:	e8 d9 fc ff ff       	call   f0103bb4 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103edb:	83 c4 08             	add    $0x8,%esp
f0103ede:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103ee2:	50                   	push   %eax
f0103ee3:	8d 83 d8 95 f7 ff    	lea    -0x86a28(%ebx),%eax
f0103ee9:	50                   	push   %eax
f0103eea:	e8 c5 fc ff ff       	call   f0103bb4 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103eef:	83 c4 08             	add    $0x8,%esp
f0103ef2:	ff 76 38             	pushl  0x38(%esi)
f0103ef5:	8d 83 eb 95 f7 ff    	lea    -0x86a15(%ebx),%eax
f0103efb:	50                   	push   %eax
f0103efc:	e8 b3 fc ff ff       	call   f0103bb4 <cprintf>
	if ((tf->tf_cs & 3) != 0)
f0103f01:	83 c4 10             	add    $0x10,%esp
f0103f04:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f0103f08:	75 50                	jne    f0103f5a <print_trapframe+0x194>
}
f0103f0a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103f0d:	5b                   	pop    %ebx
f0103f0e:	5e                   	pop    %esi
f0103f0f:	5f                   	pop    %edi
f0103f10:	5d                   	pop    %ebp
f0103f11:	c3                   	ret    
		return excnames[trapno];
f0103f12:	8b 84 93 40 20 00 00 	mov    0x2040(%ebx,%edx,4),%eax
f0103f19:	e9 1d ff ff ff       	jmp    f0103e3b <print_trapframe+0x75>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103f1e:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0103f22:	0f 85 33 ff ff ff    	jne    f0103e5b <print_trapframe+0x95>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103f28:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103f2b:	83 ec 08             	sub    $0x8,%esp
f0103f2e:	50                   	push   %eax
f0103f2f:	8d 83 9d 95 f7 ff    	lea    -0x86a63(%ebx),%eax
f0103f35:	50                   	push   %eax
f0103f36:	e8 79 fc ff ff       	call   f0103bb4 <cprintf>
f0103f3b:	83 c4 10             	add    $0x10,%esp
f0103f3e:	e9 18 ff ff ff       	jmp    f0103e5b <print_trapframe+0x95>
		cprintf("\n");
f0103f43:	83 ec 0c             	sub    $0xc,%esp
f0103f46:	8d 83 ff 92 f7 ff    	lea    -0x86d01(%ebx),%eax
f0103f4c:	50                   	push   %eax
f0103f4d:	e8 62 fc ff ff       	call   f0103bb4 <cprintf>
f0103f52:	83 c4 10             	add    $0x10,%esp
f0103f55:	e9 6f ff ff ff       	jmp    f0103ec9 <print_trapframe+0x103>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103f5a:	83 ec 08             	sub    $0x8,%esp
f0103f5d:	ff 76 3c             	pushl  0x3c(%esi)
f0103f60:	8d 83 fa 95 f7 ff    	lea    -0x86a06(%ebx),%eax
f0103f66:	50                   	push   %eax
f0103f67:	e8 48 fc ff ff       	call   f0103bb4 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103f6c:	83 c4 08             	add    $0x8,%esp
f0103f6f:	0f b7 46 40          	movzwl 0x40(%esi),%eax
f0103f73:	50                   	push   %eax
f0103f74:	8d 83 09 96 f7 ff    	lea    -0x869f7(%ebx),%eax
f0103f7a:	50                   	push   %eax
f0103f7b:	e8 34 fc ff ff       	call   f0103bb4 <cprintf>
f0103f80:	83 c4 10             	add    $0x10,%esp
}
f0103f83:	eb 85                	jmp    f0103f0a <print_trapframe+0x144>

f0103f85 <syscall_handler>:
	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
	env_run(curenv);
}
void syscall_handler(struct Trapframe *tf)
{
f0103f85:	55                   	push   %ebp
f0103f86:	89 e5                	mov    %esp,%ebp
f0103f88:	56                   	push   %esi
f0103f89:	53                   	push   %ebx
f0103f8a:	e8 d8 c1 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103f8f:	81 c3 91 90 08 00    	add    $0x89091,%ebx
f0103f95:	8b 75 08             	mov    0x8(%ebp),%esi
	// this function extracts registers from Trapframe and passes them onto real syscall dispatcher
	struct PushRegs *pushRegs = &tf->tf_regs;
	pushRegs->reg_eax = syscall(pushRegs->reg_eax, pushRegs->reg_edx, pushRegs->reg_ecx, pushRegs->reg_ebx, pushRegs->reg_edi, pushRegs->reg_esi);
f0103f98:	83 ec 08             	sub    $0x8,%esp
f0103f9b:	ff 76 04             	pushl  0x4(%esi)
f0103f9e:	ff 36                	pushl  (%esi)
f0103fa0:	ff 76 10             	pushl  0x10(%esi)
f0103fa3:	ff 76 18             	pushl  0x18(%esi)
f0103fa6:	ff 76 14             	pushl  0x14(%esi)
f0103fa9:	ff 76 1c             	pushl  0x1c(%esi)
f0103fac:	e8 56 02 00 00       	call   f0104207 <syscall>
f0103fb1:	89 46 1c             	mov    %eax,0x1c(%esi)
}
f0103fb4:	83 c4 20             	add    $0x20,%esp
f0103fb7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103fba:	5b                   	pop    %ebx
f0103fbb:	5e                   	pop    %esi
f0103fbc:	5d                   	pop    %ebp
f0103fbd:	c3                   	ret    

f0103fbe <page_fault_handler>:
void page_fault_handler(struct Trapframe *tf)
{
f0103fbe:	55                   	push   %ebp
f0103fbf:	89 e5                	mov    %esp,%ebp
f0103fc1:	57                   	push   %edi
f0103fc2:	56                   	push   %esi
f0103fc3:	53                   	push   %ebx
f0103fc4:	83 ec 0c             	sub    $0xc,%esp
f0103fc7:	e8 9b c1 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103fcc:	81 c3 54 90 08 00    	add    $0x89054,%ebx
f0103fd2:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103fd5:	0f 20 d0             	mov    %cr2,%eax
		panic("page_fault in kernel mode, fault address %d\n", fault_va);
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103fd8:	ff 77 30             	pushl  0x30(%edi)
f0103fdb:	50                   	push   %eax
f0103fdc:	c7 c6 28 f7 18 f0    	mov    $0xf018f728,%esi
f0103fe2:	8b 06                	mov    (%esi),%eax
f0103fe4:	ff 70 48             	pushl  0x48(%eax)
f0103fe7:	8d 83 c0 97 f7 ff    	lea    -0x86840(%ebx),%eax
f0103fed:	50                   	push   %eax
f0103fee:	e8 c1 fb ff ff       	call   f0103bb4 <cprintf>
			curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103ff3:	89 3c 24             	mov    %edi,(%esp)
f0103ff6:	e8 cb fd ff ff       	call   f0103dc6 <print_trapframe>
	env_destroy(curenv);
f0103ffb:	83 c4 04             	add    $0x4,%esp
f0103ffe:	ff 36                	pushl  (%esi)
f0104000:	e8 45 fa ff ff       	call   f0103a4a <env_destroy>
}
f0104005:	83 c4 10             	add    $0x10,%esp
f0104008:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010400b:	5b                   	pop    %ebx
f010400c:	5e                   	pop    %esi
f010400d:	5f                   	pop    %edi
f010400e:	5d                   	pop    %ebp
f010400f:	c3                   	ret    

f0104010 <trap>:
{
f0104010:	55                   	push   %ebp
f0104011:	89 e5                	mov    %esp,%ebp
f0104013:	57                   	push   %edi
f0104014:	56                   	push   %esi
f0104015:	53                   	push   %ebx
f0104016:	83 ec 0c             	sub    $0xc,%esp
f0104019:	e8 49 c1 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010401e:	81 c3 02 90 08 00    	add    $0x89002,%ebx
f0104024:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::
f0104027:	fc                   	cld    
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0104028:	9c                   	pushf  
f0104029:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f010402a:	f6 c4 02             	test   $0x2,%ah
f010402d:	74 1f                	je     f010404e <trap+0x3e>
f010402f:	8d 83 1c 96 f7 ff    	lea    -0x869e4(%ebx),%eax
f0104035:	50                   	push   %eax
f0104036:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f010403c:	50                   	push   %eax
f010403d:	68 d2 00 00 00       	push   $0xd2
f0104042:	8d 83 35 96 f7 ff    	lea    -0x869cb(%ebx),%eax
f0104048:	50                   	push   %eax
f0104049:	e8 63 c0 ff ff       	call   f01000b1 <_panic>
	cprintf("Incoming TRAP frame at %p\n", tf);
f010404e:	83 ec 08             	sub    $0x8,%esp
f0104051:	56                   	push   %esi
f0104052:	8d 83 41 96 f7 ff    	lea    -0x869bf(%ebx),%eax
f0104058:	50                   	push   %eax
f0104059:	e8 56 fb ff ff       	call   f0103bb4 <cprintf>
	if ((tf->tf_cs & 3) == 3)
f010405e:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104062:	83 e0 03             	and    $0x3,%eax
f0104065:	83 c4 10             	add    $0x10,%esp
f0104068:	66 83 f8 03          	cmp    $0x3,%ax
f010406c:	75 1d                	jne    f010408b <trap+0x7b>
		assert(curenv);
f010406e:	c7 c0 28 f7 18 f0    	mov    $0xf018f728,%eax
f0104074:	8b 00                	mov    (%eax),%eax
f0104076:	85 c0                	test   %eax,%eax
f0104078:	74 48                	je     f01040c2 <trap+0xb2>
		curenv->env_tf = *tf;
f010407a:	b9 11 00 00 00       	mov    $0x11,%ecx
f010407f:	89 c7                	mov    %eax,%edi
f0104081:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f0104083:	c7 c0 28 f7 18 f0    	mov    $0xf018f728,%eax
f0104089:	8b 30                	mov    (%eax),%esi
	last_tf = tf;
f010408b:	89 b3 20 2f 00 00    	mov    %esi,0x2f20(%ebx)
	switch (tf->tf_trapno)
f0104091:	8b 46 28             	mov    0x28(%esi),%eax
f0104094:	83 f8 03             	cmp    $0x3,%eax
f0104097:	0f 84 86 00 00 00    	je     f0104123 <trap+0x113>
f010409d:	83 f8 03             	cmp    $0x3,%eax
f01040a0:	76 3f                	jbe    f01040e1 <trap+0xd1>
f01040a2:	83 f8 0e             	cmp    $0xe,%eax
f01040a5:	0f 84 86 00 00 00    	je     f0104131 <trap+0x121>
f01040ab:	83 f8 30             	cmp    $0x30,%eax
f01040ae:	0f 85 8b 00 00 00    	jne    f010413f <trap+0x12f>
		syscall_handler(tf);
f01040b4:	83 ec 0c             	sub    $0xc,%esp
f01040b7:	56                   	push   %esi
f01040b8:	e8 c8 fe ff ff       	call   f0103f85 <syscall_handler>
f01040bd:	83 c4 10             	add    $0x10,%esp
f01040c0:	eb 30                	jmp    f01040f2 <trap+0xe2>
		assert(curenv);
f01040c2:	8d 83 5c 96 f7 ff    	lea    -0x869a4(%ebx),%eax
f01040c8:	50                   	push   %eax
f01040c9:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f01040cf:	50                   	push   %eax
f01040d0:	68 d9 00 00 00       	push   $0xd9
f01040d5:	8d 83 35 96 f7 ff    	lea    -0x869cb(%ebx),%eax
f01040db:	50                   	push   %eax
f01040dc:	e8 d0 bf ff ff       	call   f01000b1 <_panic>
	switch (tf->tf_trapno)
f01040e1:	83 f8 01             	cmp    $0x1,%eax
f01040e4:	75 59                	jne    f010413f <trap+0x12f>
		monitor(tf);
f01040e6:	83 ec 0c             	sub    $0xc,%esp
f01040e9:	56                   	push   %esi
f01040ea:	e8 e1 c7 ff ff       	call   f01008d0 <monitor>
f01040ef:	83 c4 10             	add    $0x10,%esp
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01040f2:	c7 c0 28 f7 18 f0    	mov    $0xf018f728,%eax
f01040f8:	8b 00                	mov    (%eax),%eax
f01040fa:	85 c0                	test   %eax,%eax
f01040fc:	74 06                	je     f0104104 <trap+0xf4>
f01040fe:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104102:	74 7e                	je     f0104182 <trap+0x172>
f0104104:	8d 83 e4 97 f7 ff    	lea    -0x8681c(%ebx),%eax
f010410a:	50                   	push   %eax
f010410b:	8d 83 cb 90 f7 ff    	lea    -0x86f35(%ebx),%eax
f0104111:	50                   	push   %eax
f0104112:	68 eb 00 00 00       	push   $0xeb
f0104117:	8d 83 35 96 f7 ff    	lea    -0x869cb(%ebx),%eax
f010411d:	50                   	push   %eax
f010411e:	e8 8e bf ff ff       	call   f01000b1 <_panic>
		monitor(tf);
f0104123:	83 ec 0c             	sub    $0xc,%esp
f0104126:	56                   	push   %esi
f0104127:	e8 a4 c7 ff ff       	call   f01008d0 <monitor>
f010412c:	83 c4 10             	add    $0x10,%esp
f010412f:	eb c1                	jmp    f01040f2 <trap+0xe2>
		page_fault_handler(tf);
f0104131:	83 ec 0c             	sub    $0xc,%esp
f0104134:	56                   	push   %esi
f0104135:	e8 84 fe ff ff       	call   f0103fbe <page_fault_handler>
f010413a:	83 c4 10             	add    $0x10,%esp
f010413d:	eb b3                	jmp    f01040f2 <trap+0xe2>
	print_trapframe(tf);
f010413f:	83 ec 0c             	sub    $0xc,%esp
f0104142:	56                   	push   %esi
f0104143:	e8 7e fc ff ff       	call   f0103dc6 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0104148:	83 c4 10             	add    $0x10,%esp
f010414b:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104150:	74 15                	je     f0104167 <trap+0x157>
		env_destroy(curenv);
f0104152:	83 ec 0c             	sub    $0xc,%esp
f0104155:	c7 c0 28 f7 18 f0    	mov    $0xf018f728,%eax
f010415b:	ff 30                	pushl  (%eax)
f010415d:	e8 e8 f8 ff ff       	call   f0103a4a <env_destroy>
f0104162:	83 c4 10             	add    $0x10,%esp
f0104165:	eb 8b                	jmp    f01040f2 <trap+0xe2>
		panic("unhandled trap in kernel");
f0104167:	83 ec 04             	sub    $0x4,%esp
f010416a:	8d 83 63 96 f7 ff    	lea    -0x8699d(%ebx),%eax
f0104170:	50                   	push   %eax
f0104171:	68 c0 00 00 00       	push   $0xc0
f0104176:	8d 83 35 96 f7 ff    	lea    -0x869cb(%ebx),%eax
f010417c:	50                   	push   %eax
f010417d:	e8 2f bf ff ff       	call   f01000b1 <_panic>
	env_run(curenv);
f0104182:	83 ec 0c             	sub    $0xc,%esp
f0104185:	50                   	push   %eax
f0104186:	e8 2d f9 ff ff       	call   f0103ab8 <env_run>

f010418b <__x86.get_pc_thunk.dx>:
f010418b:	8b 14 24             	mov    (%esp),%edx
f010418e:	c3                   	ret    
f010418f:	90                   	nop

f0104190 <handler0>:
TH(0)
f0104190:	6a 00                	push   $0x0
f0104192:	6a 00                	push   $0x0
f0104194:	eb 5e                	jmp    f01041f4 <_alltraps>

f0104196 <handler1>:
TH(1)
f0104196:	6a 00                	push   $0x0
f0104198:	6a 01                	push   $0x1
f010419a:	eb 58                	jmp    f01041f4 <_alltraps>

f010419c <handler2>:
TH(2)
f010419c:	6a 00                	push   $0x0
f010419e:	6a 02                	push   $0x2
f01041a0:	eb 52                	jmp    f01041f4 <_alltraps>

f01041a2 <handler3>:
TH(3)
f01041a2:	6a 00                	push   $0x0
f01041a4:	6a 03                	push   $0x3
f01041a6:	eb 4c                	jmp    f01041f4 <_alltraps>

f01041a8 <handler4>:
TH(4)
f01041a8:	6a 00                	push   $0x0
f01041aa:	6a 04                	push   $0x4
f01041ac:	eb 46                	jmp    f01041f4 <_alltraps>

f01041ae <handler5>:
TH(5)
f01041ae:	6a 00                	push   $0x0
f01041b0:	6a 05                	push   $0x5
f01041b2:	eb 40                	jmp    f01041f4 <_alltraps>

f01041b4 <handler6>:
TH(6)
f01041b4:	6a 00                	push   $0x0
f01041b6:	6a 06                	push   $0x6
f01041b8:	eb 3a                	jmp    f01041f4 <_alltraps>

f01041ba <handler7>:
TH(7)
f01041ba:	6a 00                	push   $0x0
f01041bc:	6a 07                	push   $0x7
f01041be:	eb 34                	jmp    f01041f4 <_alltraps>

f01041c0 <handler8>:
THE(8)
f01041c0:	6a 08                	push   $0x8
f01041c2:	eb 30                	jmp    f01041f4 <_alltraps>

f01041c4 <handler10>:
THE(10)
f01041c4:	6a 0a                	push   $0xa
f01041c6:	eb 2c                	jmp    f01041f4 <_alltraps>

f01041c8 <handler11>:
THE(11)
f01041c8:	6a 0b                	push   $0xb
f01041ca:	eb 28                	jmp    f01041f4 <_alltraps>

f01041cc <handler12>:
THE(12)
f01041cc:	6a 0c                	push   $0xc
f01041ce:	eb 24                	jmp    f01041f4 <_alltraps>

f01041d0 <handler13>:
THE(13)
f01041d0:	6a 0d                	push   $0xd
f01041d2:	eb 20                	jmp    f01041f4 <_alltraps>

f01041d4 <handler14>:
THE(14)
f01041d4:	6a 0e                	push   $0xe
f01041d6:	eb 1c                	jmp    f01041f4 <_alltraps>

f01041d8 <handler16>:
TH(16)
f01041d8:	6a 00                	push   $0x0
f01041da:	6a 10                	push   $0x10
f01041dc:	eb 16                	jmp    f01041f4 <_alltraps>

f01041de <handler17>:
THE(17)
f01041de:	6a 11                	push   $0x11
f01041e0:	eb 12                	jmp    f01041f4 <_alltraps>

f01041e2 <handler18>:
TH(18)
f01041e2:	6a 00                	push   $0x0
f01041e4:	6a 12                	push   $0x12
f01041e6:	eb 0c                	jmp    f01041f4 <_alltraps>

f01041e8 <handler19>:
TH(19)
f01041e8:	6a 00                	push   $0x0
f01041ea:	6a 13                	push   $0x13
f01041ec:	eb 06                	jmp    f01041f4 <_alltraps>

f01041ee <handler48>:
f01041ee:	6a 00                	push   $0x0
f01041f0:	6a 30                	push   $0x30
f01041f2:	eb 00                	jmp    f01041f4 <_alltraps>

f01041f4 <_alltraps>:
 *	3.pushl %esp to pass a pointer to the Trapframe as an argument to trap()
 *	4.call trap (can ever return?)trap
 */
.globl _alltraps
_alltraps:
	push %ds;
f01041f4:	1e                   	push   %ds
	push %es;
f01041f5:	06                   	push   %es
	pushal;
f01041f6:	60                   	pusha  

	movw 	$(GD_KD), %ax
f01041f7:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f01041fb:	8e d8                	mov    %eax,%ds
    movw %ax, %es
f01041fd:	8e c0                	mov    %eax,%es

	pushl %esp
f01041ff:	54                   	push   %esp
	call trap
f0104200:	e8 0b fe ff ff       	call   f0104010 <trap>

f0104205 <trap_spin>:
trap_spin:
    jmp trap_spin
f0104205:	eb fe                	jmp    f0104205 <trap_spin>

f0104207 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104207:	55                   	push   %ebp
f0104208:	89 e5                	mov    %esp,%ebp
f010420a:	53                   	push   %ebx
f010420b:	83 ec 14             	sub    $0x14,%esp
f010420e:	e8 54 bf ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104213:	81 c3 0d 8e 08 00    	add    $0x88e0d,%ebx
f0104219:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	// panic("syscall not implemented");
	switch (syscallno)
f010421c:	83 f8 01             	cmp    $0x1,%eax
f010421f:	74 4d                	je     f010426e <syscall+0x67>
f0104221:	83 f8 01             	cmp    $0x1,%eax
f0104224:	72 11                	jb     f0104237 <syscall+0x30>
f0104226:	83 f8 02             	cmp    $0x2,%eax
f0104229:	74 4a                	je     f0104275 <syscall+0x6e>
f010422b:	83 f8 03             	cmp    $0x3,%eax
f010422e:	74 52                	je     f0104282 <syscall+0x7b>
		return sys_getenvid();
	case SYS_env_destroy:
		return sys_env_destroy(sys_getenvid());
	case NSYSCALLS:
	default:
		return -E_INVAL;
f0104230:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104235:	eb 32                	jmp    f0104269 <syscall+0x62>
	user_mem_assert(curenv, s, len, 0);
f0104237:	6a 00                	push   $0x0
f0104239:	ff 75 10             	pushl  0x10(%ebp)
f010423c:	ff 75 0c             	pushl  0xc(%ebp)
f010423f:	c7 c0 28 f7 18 f0    	mov    $0xf018f728,%eax
f0104245:	ff 30                	pushl  (%eax)
f0104247:	e8 8d f0 ff ff       	call   f01032d9 <user_mem_assert>
	cprintf("%.*s", len, s);
f010424c:	83 c4 0c             	add    $0xc,%esp
f010424f:	ff 75 0c             	pushl  0xc(%ebp)
f0104252:	ff 75 10             	pushl  0x10(%ebp)
f0104255:	8d 83 10 98 f7 ff    	lea    -0x867f0(%ebx),%eax
f010425b:	50                   	push   %eax
f010425c:	e8 53 f9 ff ff       	call   f0103bb4 <cprintf>
f0104261:	83 c4 10             	add    $0x10,%esp
		return 0;
f0104264:	b8 00 00 00 00       	mov    $0x0,%eax
	}
}
f0104269:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010426c:	c9                   	leave  
f010426d:	c3                   	ret    
	return cons_getc();
f010426e:	e8 ef c2 ff ff       	call   f0100562 <cons_getc>
		return sys_cgetc();
f0104273:	eb f4                	jmp    f0104269 <syscall+0x62>
	return curenv->env_id;
f0104275:	c7 c0 28 f7 18 f0    	mov    $0xf018f728,%eax
f010427b:	8b 00                	mov    (%eax),%eax
f010427d:	8b 40 48             	mov    0x48(%eax),%eax
		return sys_getenvid();
f0104280:	eb e7                	jmp    f0104269 <syscall+0x62>
	if ((r = envid2env(envid, &e, 1)) < 0)
f0104282:	83 ec 04             	sub    $0x4,%esp
f0104285:	6a 01                	push   $0x1
f0104287:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010428a:	50                   	push   %eax
	return curenv->env_id;
f010428b:	c7 c0 28 f7 18 f0    	mov    $0xf018f728,%eax
f0104291:	8b 00                	mov    (%eax),%eax
	if ((r = envid2env(envid, &e, 1)) < 0)
f0104293:	ff 70 48             	pushl  0x48(%eax)
f0104296:	e8 89 f1 ff ff       	call   f0103424 <envid2env>
f010429b:	83 c4 10             	add    $0x10,%esp
f010429e:	85 c0                	test   %eax,%eax
f01042a0:	78 c7                	js     f0104269 <syscall+0x62>
	if (e == curenv)
f01042a2:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01042a5:	c7 c0 28 f7 18 f0    	mov    $0xf018f728,%eax
f01042ab:	8b 00                	mov    (%eax),%eax
f01042ad:	39 c2                	cmp    %eax,%edx
f01042af:	74 2d                	je     f01042de <syscall+0xd7>
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f01042b1:	83 ec 04             	sub    $0x4,%esp
f01042b4:	ff 72 48             	pushl  0x48(%edx)
f01042b7:	ff 70 48             	pushl  0x48(%eax)
f01042ba:	8d 83 30 98 f7 ff    	lea    -0x867d0(%ebx),%eax
f01042c0:	50                   	push   %eax
f01042c1:	e8 ee f8 ff ff       	call   f0103bb4 <cprintf>
f01042c6:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01042c9:	83 ec 0c             	sub    $0xc,%esp
f01042cc:	ff 75 f4             	pushl  -0xc(%ebp)
f01042cf:	e8 76 f7 ff ff       	call   f0103a4a <env_destroy>
f01042d4:	83 c4 10             	add    $0x10,%esp
	return 0;
f01042d7:	b8 00 00 00 00       	mov    $0x0,%eax
		return sys_env_destroy(sys_getenvid());
f01042dc:	eb 8b                	jmp    f0104269 <syscall+0x62>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01042de:	83 ec 08             	sub    $0x8,%esp
f01042e1:	ff 70 48             	pushl  0x48(%eax)
f01042e4:	8d 83 15 98 f7 ff    	lea    -0x867eb(%ebx),%eax
f01042ea:	50                   	push   %eax
f01042eb:	e8 c4 f8 ff ff       	call   f0103bb4 <cprintf>
f01042f0:	83 c4 10             	add    $0x10,%esp
f01042f3:	eb d4                	jmp    f01042c9 <syscall+0xc2>

f01042f5 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
			   int type, uintptr_t addr)
{
f01042f5:	55                   	push   %ebp
f01042f6:	89 e5                	mov    %esp,%ebp
f01042f8:	57                   	push   %edi
f01042f9:	56                   	push   %esi
f01042fa:	53                   	push   %ebx
f01042fb:	83 ec 14             	sub    $0x14,%esp
f01042fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104301:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104304:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104307:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010430a:	8b 32                	mov    (%edx),%esi
f010430c:	8b 01                	mov    (%ecx),%eax
f010430e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104311:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r)
f0104318:	eb 2f                	jmp    f0104349 <stab_binsearch+0x54>
	{
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f010431a:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f010431d:	39 c6                	cmp    %eax,%esi
f010431f:	7f 49                	jg     f010436a <stab_binsearch+0x75>
f0104321:	0f b6 0a             	movzbl (%edx),%ecx
f0104324:	83 ea 0c             	sub    $0xc,%edx
f0104327:	39 f9                	cmp    %edi,%ecx
f0104329:	75 ef                	jne    f010431a <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr)
f010432b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010432e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104331:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104335:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104338:	73 35                	jae    f010436f <stab_binsearch+0x7a>
		{
			*region_left = m;
f010433a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010433d:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f010433f:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0104342:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r)
f0104349:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f010434c:	7f 4e                	jg     f010439c <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f010434e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104351:	01 f0                	add    %esi,%eax
f0104353:	89 c3                	mov    %eax,%ebx
f0104355:	c1 eb 1f             	shr    $0x1f,%ebx
f0104358:	01 c3                	add    %eax,%ebx
f010435a:	d1 fb                	sar    %ebx
f010435c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010435f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104362:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0104366:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0104368:	eb b3                	jmp    f010431d <stab_binsearch+0x28>
			l = true_m + 1;
f010436a:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f010436d:	eb da                	jmp    f0104349 <stab_binsearch+0x54>
		}
		else if (stabs[m].n_value > addr)
f010436f:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104372:	76 14                	jbe    f0104388 <stab_binsearch+0x93>
		{
			*region_right = m - 1;
f0104374:	83 e8 01             	sub    $0x1,%eax
f0104377:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010437a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010437d:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f010437f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104386:	eb c1                	jmp    f0104349 <stab_binsearch+0x54>
		}
		else
		{
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104388:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010438b:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010438d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104391:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0104393:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010439a:	eb ad                	jmp    f0104349 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f010439c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01043a0:	74 16                	je     f01043b8 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else
	{
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01043a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01043a5:	8b 00                	mov    (%eax),%eax
			 l > *region_left && stabs[l].n_type != type;
f01043a7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01043aa:	8b 0e                	mov    (%esi),%ecx
f01043ac:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01043af:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01043b2:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f01043b6:	eb 12                	jmp    f01043ca <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f01043b8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043bb:	8b 00                	mov    (%eax),%eax
f01043bd:	83 e8 01             	sub    $0x1,%eax
f01043c0:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01043c3:	89 07                	mov    %eax,(%edi)
f01043c5:	eb 16                	jmp    f01043dd <stab_binsearch+0xe8>
			 l--)
f01043c7:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f01043ca:	39 c1                	cmp    %eax,%ecx
f01043cc:	7d 0a                	jge    f01043d8 <stab_binsearch+0xe3>
			 l > *region_left && stabs[l].n_type != type;
f01043ce:	0f b6 1a             	movzbl (%edx),%ebx
f01043d1:	83 ea 0c             	sub    $0xc,%edx
f01043d4:	39 fb                	cmp    %edi,%ebx
f01043d6:	75 ef                	jne    f01043c7 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f01043d8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01043db:	89 07                	mov    %eax,(%edi)
	}
}
f01043dd:	83 c4 14             	add    $0x14,%esp
f01043e0:	5b                   	pop    %ebx
f01043e1:	5e                   	pop    %esi
f01043e2:	5f                   	pop    %edi
f01043e3:	5d                   	pop    %ebp
f01043e4:	c3                   	ret    

f01043e5 <debuginfo_eip>:
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01043e5:	55                   	push   %ebp
f01043e6:	89 e5                	mov    %esp,%ebp
f01043e8:	57                   	push   %edi
f01043e9:	56                   	push   %esi
f01043ea:	53                   	push   %ebx
f01043eb:	83 ec 4c             	sub    $0x4c,%esp
f01043ee:	e8 43 ef ff ff       	call   f0103336 <__x86.get_pc_thunk.di>
f01043f3:	81 c7 2d 8c 08 00    	add    $0x88c2d,%edi
f01043f9:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01043fc:	8d 87 48 98 f7 ff    	lea    -0x867b8(%edi),%eax
f0104402:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0104404:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010440b:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f010440e:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0104415:	8b 45 08             	mov    0x8(%ebp),%eax
f0104418:	89 46 10             	mov    %eax,0x10(%esi)
	info->eip_fn_narg = 0;
f010441b:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM)
f0104422:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0104427:	0f 87 2c 01 00 00    	ja     f0104559 <debuginfo_eip+0x174>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f010442d:	a1 00 00 20 00       	mov    0x200000,%eax
f0104432:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stab_end = usd->stab_end;
f0104435:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f010443a:	8b 1d 08 00 20 00    	mov    0x200008,%ebx
f0104440:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
		stabstr_end = usd->stabstr_end;
f0104443:	8b 1d 0c 00 20 00    	mov    0x20000c,%ebx
f0104449:	89 5d bc             	mov    %ebx,-0x44(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010444c:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f010444f:	39 4d b4             	cmp    %ecx,-0x4c(%ebp)
f0104452:	0f 83 e9 01 00 00    	jae    f0104641 <debuginfo_eip+0x25c>
f0104458:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f010445c:	0f 85 e6 01 00 00    	jne    f0104648 <debuginfo_eip+0x263>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104462:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104469:	8b 5d b8             	mov    -0x48(%ebp),%ebx
f010446c:	29 d8                	sub    %ebx,%eax
f010446e:	c1 f8 02             	sar    $0x2,%eax
f0104471:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0104477:	83 e8 01             	sub    $0x1,%eax
f010447a:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010447d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0104480:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104483:	ff 75 08             	pushl  0x8(%ebp)
f0104486:	6a 64                	push   $0x64
f0104488:	89 d8                	mov    %ebx,%eax
f010448a:	e8 66 fe ff ff       	call   f01042f5 <stab_binsearch>
	if (lfile == 0)
f010448f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104492:	83 c4 08             	add    $0x8,%esp
f0104495:	85 c0                	test   %eax,%eax
f0104497:	0f 84 b2 01 00 00    	je     f010464f <debuginfo_eip+0x26a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010449d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01044a0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01044a3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01044a6:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01044a9:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01044ac:	ff 75 08             	pushl  0x8(%ebp)
f01044af:	6a 24                	push   $0x24
f01044b1:	89 d8                	mov    %ebx,%eax
f01044b3:	e8 3d fe ff ff       	call   f01042f5 <stab_binsearch>

	if (lfun <= rfun)
f01044b8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01044bb:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01044be:	83 c4 08             	add    $0x8,%esp
f01044c1:	39 d0                	cmp    %edx,%eax
f01044c3:	0f 8f b6 00 00 00    	jg     f010457f <debuginfo_eip+0x19a>
	{
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01044c9:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01044cc:	8d 1c 8b             	lea    (%ebx,%ecx,4),%ebx
f01044cf:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
f01044d2:	8b 0b                	mov    (%ebx),%ecx
f01044d4:	89 cb                	mov    %ecx,%ebx
f01044d6:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f01044d9:	2b 4d b4             	sub    -0x4c(%ebp),%ecx
f01044dc:	39 cb                	cmp    %ecx,%ebx
f01044de:	73 06                	jae    f01044e6 <debuginfo_eip+0x101>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01044e0:	03 5d b4             	add    -0x4c(%ebp),%ebx
f01044e3:	89 5e 08             	mov    %ebx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01044e6:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01044e9:	8b 4b 08             	mov    0x8(%ebx),%ecx
f01044ec:	89 4e 10             	mov    %ecx,0x10(%esi)
		addr -= info->eip_fn_addr;
f01044ef:	29 4d 08             	sub    %ecx,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f01044f2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01044f5:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01044f8:	83 ec 08             	sub    $0x8,%esp
f01044fb:	6a 3a                	push   $0x3a
f01044fd:	ff 76 08             	pushl  0x8(%esi)
f0104500:	89 fb                	mov    %edi,%ebx
f0104502:	e8 cc 09 00 00       	call   f0104ed3 <strfind>
f0104507:	2b 46 08             	sub    0x8(%esi),%eax
f010450a:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f010450d:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104510:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104513:	83 c4 08             	add    $0x8,%esp
f0104516:	ff 75 08             	pushl  0x8(%ebp)
f0104519:	6a 44                	push   $0x44
f010451b:	8b 7d b8             	mov    -0x48(%ebp),%edi
f010451e:	89 f8                	mov    %edi,%eax
f0104520:	e8 d0 fd ff ff       	call   f01042f5 <stab_binsearch>
	if (lline <= rline)
f0104525:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0104528:	83 c4 10             	add    $0x10,%esp
f010452b:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f010452e:	0f 8f 22 01 00 00    	jg     f0104656 <debuginfo_eip+0x271>
	{
		info->eip_line = stabs[lline].n_desc;
f0104534:	89 d0                	mov    %edx,%eax
f0104536:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104539:	c1 e2 02             	shl    $0x2,%edx
f010453c:	0f b7 4c 17 06       	movzwl 0x6(%edi,%edx,1),%ecx
f0104541:	89 4e 04             	mov    %ecx,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile && stabs[lline].n_type != N_SOL && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104544:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104547:	8d 54 17 04          	lea    0x4(%edi,%edx,1),%edx
f010454b:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f010454f:	bf 01 00 00 00       	mov    $0x1,%edi
f0104554:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104557:	eb 48                	jmp    f01045a1 <debuginfo_eip+0x1bc>
		stabstr_end = __STABSTR_END__;
f0104559:	c7 c0 6f 22 11 f0    	mov    $0xf011226f,%eax
f010455f:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0104562:	c7 c0 e1 f6 10 f0    	mov    $0xf010f6e1,%eax
f0104568:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		stab_end = __STAB_END__;
f010456b:	c7 c0 e0 f6 10 f0    	mov    $0xf010f6e0,%eax
		stabs = __STAB_BEGIN__;
f0104571:	c7 c3 64 6a 10 f0    	mov    $0xf0106a64,%ebx
f0104577:	89 5d b8             	mov    %ebx,-0x48(%ebp)
f010457a:	e9 cd fe ff ff       	jmp    f010444c <debuginfo_eip+0x67>
		info->eip_fn_addr = addr;
f010457f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104582:	89 46 10             	mov    %eax,0x10(%esi)
		lline = lfile;
f0104585:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104588:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010458b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010458e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104591:	e9 62 ff ff ff       	jmp    f01044f8 <debuginfo_eip+0x113>
f0104596:	83 e8 01             	sub    $0x1,%eax
f0104599:	83 ea 0c             	sub    $0xc,%edx
f010459c:	89 f9                	mov    %edi,%ecx
f010459e:	88 4d c4             	mov    %cl,-0x3c(%ebp)
f01045a1:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile && stabs[lline].n_type != N_SOL && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01045a4:	39 c3                	cmp    %eax,%ebx
f01045a6:	7f 24                	jg     f01045cc <debuginfo_eip+0x1e7>
f01045a8:	0f b6 0a             	movzbl (%edx),%ecx
f01045ab:	80 f9 84             	cmp    $0x84,%cl
f01045ae:	74 46                	je     f01045f6 <debuginfo_eip+0x211>
f01045b0:	80 f9 64             	cmp    $0x64,%cl
f01045b3:	75 e1                	jne    f0104596 <debuginfo_eip+0x1b1>
f01045b5:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f01045b9:	74 db                	je     f0104596 <debuginfo_eip+0x1b1>
f01045bb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01045be:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01045c2:	74 3b                	je     f01045ff <debuginfo_eip+0x21a>
f01045c4:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01045c7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01045ca:	eb 33                	jmp    f01045ff <debuginfo_eip+0x21a>
f01045cc:	8b 75 0c             	mov    0xc(%ebp),%esi
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01045cf:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01045d2:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
			 lline < rfun && stabs[lline].n_type == N_PSYM;
			 lline++)
			info->eip_fn_narg++;

	return 0;
f01045d5:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01045da:	39 da                	cmp    %ebx,%edx
f01045dc:	0f 8d 80 00 00 00    	jge    f0104662 <debuginfo_eip+0x27d>
		for (lline = lfun + 1;
f01045e2:	83 c2 01             	add    $0x1,%edx
f01045e5:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01045e8:	89 d0                	mov    %edx,%eax
f01045ea:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01045ed:	8b 7d b8             	mov    -0x48(%ebp),%edi
f01045f0:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f01045f4:	eb 32                	jmp    f0104628 <debuginfo_eip+0x243>
f01045f6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01045f9:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01045fd:	75 1d                	jne    f010461c <debuginfo_eip+0x237>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01045ff:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104602:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0104605:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104608:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010460b:	8b 7d b4             	mov    -0x4c(%ebp),%edi
f010460e:	29 f8                	sub    %edi,%eax
f0104610:	39 c2                	cmp    %eax,%edx
f0104612:	73 bb                	jae    f01045cf <debuginfo_eip+0x1ea>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104614:	89 f8                	mov    %edi,%eax
f0104616:	01 d0                	add    %edx,%eax
f0104618:	89 06                	mov    %eax,(%esi)
f010461a:	eb b3                	jmp    f01045cf <debuginfo_eip+0x1ea>
f010461c:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010461f:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104622:	eb db                	jmp    f01045ff <debuginfo_eip+0x21a>
			info->eip_fn_narg++;
f0104624:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0104628:	39 c3                	cmp    %eax,%ebx
f010462a:	7e 31                	jle    f010465d <debuginfo_eip+0x278>
			 lline < rfun && stabs[lline].n_type == N_PSYM;
f010462c:	0f b6 0a             	movzbl (%edx),%ecx
f010462f:	83 c0 01             	add    $0x1,%eax
f0104632:	83 c2 0c             	add    $0xc,%edx
f0104635:	80 f9 a0             	cmp    $0xa0,%cl
f0104638:	74 ea                	je     f0104624 <debuginfo_eip+0x23f>
	return 0;
f010463a:	b8 00 00 00 00       	mov    $0x0,%eax
f010463f:	eb 21                	jmp    f0104662 <debuginfo_eip+0x27d>
		return -1;
f0104641:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104646:	eb 1a                	jmp    f0104662 <debuginfo_eip+0x27d>
f0104648:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010464d:	eb 13                	jmp    f0104662 <debuginfo_eip+0x27d>
		return -1;
f010464f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104654:	eb 0c                	jmp    f0104662 <debuginfo_eip+0x27d>
		return -1;
f0104656:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010465b:	eb 05                	jmp    f0104662 <debuginfo_eip+0x27d>
	return 0;
f010465d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104662:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104665:	5b                   	pop    %ebx
f0104666:	5e                   	pop    %esi
f0104667:	5f                   	pop    %edi
f0104668:	5d                   	pop    %ebp
f0104669:	c3                   	ret    

f010466a <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void *), void *putdat,
		 unsigned long long num, unsigned base, int width, int padc)
{
f010466a:	55                   	push   %ebp
f010466b:	89 e5                	mov    %esp,%ebp
f010466d:	57                   	push   %edi
f010466e:	56                   	push   %esi
f010466f:	53                   	push   %ebx
f0104670:	83 ec 2c             	sub    $0x2c,%esp
f0104673:	e8 ba ec ff ff       	call   f0103332 <__x86.get_pc_thunk.cx>
f0104678:	81 c1 a8 89 08 00    	add    $0x889a8,%ecx
f010467e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0104681:	89 c7                	mov    %eax,%edi
f0104683:	89 d6                	mov    %edx,%esi
f0104685:	8b 45 08             	mov    0x8(%ebp),%eax
f0104688:	8b 55 0c             	mov    0xc(%ebp),%edx
f010468b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010468e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base)
f0104691:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104694:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104699:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f010469c:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010469f:	39 d3                	cmp    %edx,%ebx
f01046a1:	72 09                	jb     f01046ac <printnum+0x42>
f01046a3:	39 45 10             	cmp    %eax,0x10(%ebp)
f01046a6:	0f 87 83 00 00 00    	ja     f010472f <printnum+0xc5>
	{
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01046ac:	83 ec 0c             	sub    $0xc,%esp
f01046af:	ff 75 18             	pushl  0x18(%ebp)
f01046b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01046b5:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01046b8:	53                   	push   %ebx
f01046b9:	ff 75 10             	pushl  0x10(%ebp)
f01046bc:	83 ec 08             	sub    $0x8,%esp
f01046bf:	ff 75 dc             	pushl  -0x24(%ebp)
f01046c2:	ff 75 d8             	pushl  -0x28(%ebp)
f01046c5:	ff 75 d4             	pushl  -0x2c(%ebp)
f01046c8:	ff 75 d0             	pushl  -0x30(%ebp)
f01046cb:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01046ce:	e8 1d 0a 00 00       	call   f01050f0 <__udivdi3>
f01046d3:	83 c4 18             	add    $0x18,%esp
f01046d6:	52                   	push   %edx
f01046d7:	50                   	push   %eax
f01046d8:	89 f2                	mov    %esi,%edx
f01046da:	89 f8                	mov    %edi,%eax
f01046dc:	e8 89 ff ff ff       	call   f010466a <printnum>
f01046e1:	83 c4 20             	add    $0x20,%esp
f01046e4:	eb 13                	jmp    f01046f9 <printnum+0x8f>
	}
	else
	{
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01046e6:	83 ec 08             	sub    $0x8,%esp
f01046e9:	56                   	push   %esi
f01046ea:	ff 75 18             	pushl  0x18(%ebp)
f01046ed:	ff d7                	call   *%edi
f01046ef:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f01046f2:	83 eb 01             	sub    $0x1,%ebx
f01046f5:	85 db                	test   %ebx,%ebx
f01046f7:	7f ed                	jg     f01046e6 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01046f9:	83 ec 08             	sub    $0x8,%esp
f01046fc:	56                   	push   %esi
f01046fd:	83 ec 04             	sub    $0x4,%esp
f0104700:	ff 75 dc             	pushl  -0x24(%ebp)
f0104703:	ff 75 d8             	pushl  -0x28(%ebp)
f0104706:	ff 75 d4             	pushl  -0x2c(%ebp)
f0104709:	ff 75 d0             	pushl  -0x30(%ebp)
f010470c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010470f:	89 f3                	mov    %esi,%ebx
f0104711:	e8 fa 0a 00 00       	call   f0105210 <__umoddi3>
f0104716:	83 c4 14             	add    $0x14,%esp
f0104719:	0f be 84 06 52 98 f7 	movsbl -0x867ae(%esi,%eax,1),%eax
f0104720:	ff 
f0104721:	50                   	push   %eax
f0104722:	ff d7                	call   *%edi
}
f0104724:	83 c4 10             	add    $0x10,%esp
f0104727:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010472a:	5b                   	pop    %ebx
f010472b:	5e                   	pop    %esi
f010472c:	5f                   	pop    %edi
f010472d:	5d                   	pop    %ebp
f010472e:	c3                   	ret    
f010472f:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0104732:	eb be                	jmp    f01046f2 <printnum+0x88>

f0104734 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104734:	55                   	push   %ebp
f0104735:	89 e5                	mov    %esp,%ebp
f0104737:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010473a:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010473e:	8b 10                	mov    (%eax),%edx
f0104740:	3b 50 04             	cmp    0x4(%eax),%edx
f0104743:	73 0a                	jae    f010474f <sprintputch+0x1b>
		*b->buf++ = ch;
f0104745:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104748:	89 08                	mov    %ecx,(%eax)
f010474a:	8b 45 08             	mov    0x8(%ebp),%eax
f010474d:	88 02                	mov    %al,(%edx)
}
f010474f:	5d                   	pop    %ebp
f0104750:	c3                   	ret    

f0104751 <printfmt>:
{
f0104751:	55                   	push   %ebp
f0104752:	89 e5                	mov    %esp,%ebp
f0104754:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0104757:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010475a:	50                   	push   %eax
f010475b:	ff 75 10             	pushl  0x10(%ebp)
f010475e:	ff 75 0c             	pushl  0xc(%ebp)
f0104761:	ff 75 08             	pushl  0x8(%ebp)
f0104764:	e8 05 00 00 00       	call   f010476e <vprintfmt>
}
f0104769:	83 c4 10             	add    $0x10,%esp
f010476c:	c9                   	leave  
f010476d:	c3                   	ret    

f010476e <vprintfmt>:
{
f010476e:	55                   	push   %ebp
f010476f:	89 e5                	mov    %esp,%ebp
f0104771:	57                   	push   %edi
f0104772:	56                   	push   %esi
f0104773:	53                   	push   %ebx
f0104774:	83 ec 2c             	sub    $0x2c,%esp
f0104777:	e8 eb b9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010477c:	81 c3 a4 88 08 00    	add    $0x888a4,%ebx
f0104782:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104785:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104788:	e9 c3 03 00 00       	jmp    f0104b50 <.L35+0x48>
		padc = ' ';
f010478d:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0104791:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0104798:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f010479f:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01047a6:	b9 00 00 00 00       	mov    $0x0,%ecx
f01047ab:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *)fmt++)
f01047ae:	8d 47 01             	lea    0x1(%edi),%eax
f01047b1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01047b4:	0f b6 17             	movzbl (%edi),%edx
f01047b7:	8d 42 dd             	lea    -0x23(%edx),%eax
f01047ba:	3c 55                	cmp    $0x55,%al
f01047bc:	0f 87 16 04 00 00    	ja     f0104bd8 <.L22>
f01047c2:	0f b6 c0             	movzbl %al,%eax
f01047c5:	89 d9                	mov    %ebx,%ecx
f01047c7:	03 8c 83 dc 98 f7 ff 	add    -0x86724(%ebx,%eax,4),%ecx
f01047ce:	ff e1                	jmp    *%ecx

f01047d0 <.L69>:
f01047d0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01047d3:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01047d7:	eb d5                	jmp    f01047ae <vprintfmt+0x40>

f01047d9 <.L28>:
		switch (ch = *(unsigned char *)fmt++)
f01047d9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f01047dc:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01047e0:	eb cc                	jmp    f01047ae <vprintfmt+0x40>

f01047e2 <.L29>:
		switch (ch = *(unsigned char *)fmt++)
f01047e2:	0f b6 d2             	movzbl %dl,%edx
f01047e5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0;; ++fmt)
f01047e8:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f01047ed:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01047f0:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01047f4:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01047f7:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01047fa:	83 f9 09             	cmp    $0x9,%ecx
f01047fd:	77 55                	ja     f0104854 <.L23+0xf>
			for (precision = 0;; ++fmt)
f01047ff:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0104802:	eb e9                	jmp    f01047ed <.L29+0xb>

f0104804 <.L26>:
			precision = va_arg(ap, int);
f0104804:	8b 45 14             	mov    0x14(%ebp),%eax
f0104807:	8b 00                	mov    (%eax),%eax
f0104809:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010480c:	8b 45 14             	mov    0x14(%ebp),%eax
f010480f:	8d 40 04             	lea    0x4(%eax),%eax
f0104812:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *)fmt++)
f0104815:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0104818:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010481c:	79 90                	jns    f01047ae <vprintfmt+0x40>
				width = precision, precision = -1;
f010481e:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0104821:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104824:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f010482b:	eb 81                	jmp    f01047ae <vprintfmt+0x40>

f010482d <.L27>:
f010482d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104830:	85 c0                	test   %eax,%eax
f0104832:	ba 00 00 00 00       	mov    $0x0,%edx
f0104837:	0f 49 d0             	cmovns %eax,%edx
f010483a:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *)fmt++)
f010483d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104840:	e9 69 ff ff ff       	jmp    f01047ae <vprintfmt+0x40>

f0104845 <.L23>:
f0104845:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0104848:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010484f:	e9 5a ff ff ff       	jmp    f01047ae <vprintfmt+0x40>
f0104854:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0104857:	eb bf                	jmp    f0104818 <.L26+0x14>

f0104859 <.L33>:
			lflag++;
f0104859:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *)fmt++)
f010485d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0104860:	e9 49 ff ff ff       	jmp    f01047ae <vprintfmt+0x40>

f0104865 <.L30>:
			putch(va_arg(ap, int), putdat);
f0104865:	8b 45 14             	mov    0x14(%ebp),%eax
f0104868:	8d 78 04             	lea    0x4(%eax),%edi
f010486b:	83 ec 08             	sub    $0x8,%esp
f010486e:	56                   	push   %esi
f010486f:	ff 30                	pushl  (%eax)
f0104871:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104874:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0104877:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f010487a:	e9 ce 02 00 00       	jmp    f0104b4d <.L35+0x45>

f010487f <.L32>:
			err = va_arg(ap, int);
f010487f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104882:	8d 78 04             	lea    0x4(%eax),%edi
f0104885:	8b 00                	mov    (%eax),%eax
f0104887:	99                   	cltd   
f0104888:	31 d0                	xor    %edx,%eax
f010488a:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010488c:	83 f8 06             	cmp    $0x6,%eax
f010488f:	7f 27                	jg     f01048b8 <.L32+0x39>
f0104891:	8b 94 83 90 20 00 00 	mov    0x2090(%ebx,%eax,4),%edx
f0104898:	85 d2                	test   %edx,%edx
f010489a:	74 1c                	je     f01048b8 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f010489c:	52                   	push   %edx
f010489d:	8d 83 dd 90 f7 ff    	lea    -0x86f23(%ebx),%eax
f01048a3:	50                   	push   %eax
f01048a4:	56                   	push   %esi
f01048a5:	ff 75 08             	pushl  0x8(%ebp)
f01048a8:	e8 a4 fe ff ff       	call   f0104751 <printfmt>
f01048ad:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01048b0:	89 7d 14             	mov    %edi,0x14(%ebp)
f01048b3:	e9 95 02 00 00       	jmp    f0104b4d <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f01048b8:	50                   	push   %eax
f01048b9:	8d 83 6a 98 f7 ff    	lea    -0x86796(%ebx),%eax
f01048bf:	50                   	push   %eax
f01048c0:	56                   	push   %esi
f01048c1:	ff 75 08             	pushl  0x8(%ebp)
f01048c4:	e8 88 fe ff ff       	call   f0104751 <printfmt>
f01048c9:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01048cc:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01048cf:	e9 79 02 00 00       	jmp    f0104b4d <.L35+0x45>

f01048d4 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f01048d4:	8b 45 14             	mov    0x14(%ebp),%eax
f01048d7:	83 c0 04             	add    $0x4,%eax
f01048da:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01048dd:	8b 45 14             	mov    0x14(%ebp),%eax
f01048e0:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01048e2:	85 ff                	test   %edi,%edi
f01048e4:	8d 83 63 98 f7 ff    	lea    -0x8679d(%ebx),%eax
f01048ea:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01048ed:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01048f1:	0f 8e b5 00 00 00    	jle    f01049ac <.L36+0xd8>
f01048f7:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01048fb:	75 08                	jne    f0104905 <.L36+0x31>
f01048fd:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104900:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0104903:	eb 6d                	jmp    f0104972 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104905:	83 ec 08             	sub    $0x8,%esp
f0104908:	ff 75 cc             	pushl  -0x34(%ebp)
f010490b:	57                   	push   %edi
f010490c:	e8 7e 04 00 00       	call   f0104d8f <strnlen>
f0104911:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0104914:	29 c2                	sub    %eax,%edx
f0104916:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0104919:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010491c:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104920:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104923:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104926:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0104928:	eb 10                	jmp    f010493a <.L36+0x66>
					putch(padc, putdat);
f010492a:	83 ec 08             	sub    $0x8,%esp
f010492d:	56                   	push   %esi
f010492e:	ff 75 e0             	pushl  -0x20(%ebp)
f0104931:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0104934:	83 ef 01             	sub    $0x1,%edi
f0104937:	83 c4 10             	add    $0x10,%esp
f010493a:	85 ff                	test   %edi,%edi
f010493c:	7f ec                	jg     f010492a <.L36+0x56>
f010493e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104941:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0104944:	85 d2                	test   %edx,%edx
f0104946:	b8 00 00 00 00       	mov    $0x0,%eax
f010494b:	0f 49 c2             	cmovns %edx,%eax
f010494e:	29 c2                	sub    %eax,%edx
f0104950:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0104953:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104956:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0104959:	eb 17                	jmp    f0104972 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f010495b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010495f:	75 30                	jne    f0104991 <.L36+0xbd>
					putch(ch, putdat);
f0104961:	83 ec 08             	sub    $0x8,%esp
f0104964:	ff 75 0c             	pushl  0xc(%ebp)
f0104967:	50                   	push   %eax
f0104968:	ff 55 08             	call   *0x8(%ebp)
f010496b:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010496e:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0104972:	83 c7 01             	add    $0x1,%edi
f0104975:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0104979:	0f be c2             	movsbl %dl,%eax
f010497c:	85 c0                	test   %eax,%eax
f010497e:	74 52                	je     f01049d2 <.L36+0xfe>
f0104980:	85 f6                	test   %esi,%esi
f0104982:	78 d7                	js     f010495b <.L36+0x87>
f0104984:	83 ee 01             	sub    $0x1,%esi
f0104987:	79 d2                	jns    f010495b <.L36+0x87>
f0104989:	8b 75 0c             	mov    0xc(%ebp),%esi
f010498c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010498f:	eb 32                	jmp    f01049c3 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f0104991:	0f be d2             	movsbl %dl,%edx
f0104994:	83 ea 20             	sub    $0x20,%edx
f0104997:	83 fa 5e             	cmp    $0x5e,%edx
f010499a:	76 c5                	jbe    f0104961 <.L36+0x8d>
					putch('?', putdat);
f010499c:	83 ec 08             	sub    $0x8,%esp
f010499f:	ff 75 0c             	pushl  0xc(%ebp)
f01049a2:	6a 3f                	push   $0x3f
f01049a4:	ff 55 08             	call   *0x8(%ebp)
f01049a7:	83 c4 10             	add    $0x10,%esp
f01049aa:	eb c2                	jmp    f010496e <.L36+0x9a>
f01049ac:	89 75 0c             	mov    %esi,0xc(%ebp)
f01049af:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01049b2:	eb be                	jmp    f0104972 <.L36+0x9e>
				putch(' ', putdat);
f01049b4:	83 ec 08             	sub    $0x8,%esp
f01049b7:	56                   	push   %esi
f01049b8:	6a 20                	push   $0x20
f01049ba:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01049bd:	83 ef 01             	sub    $0x1,%edi
f01049c0:	83 c4 10             	add    $0x10,%esp
f01049c3:	85 ff                	test   %edi,%edi
f01049c5:	7f ed                	jg     f01049b4 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01049c7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01049ca:	89 45 14             	mov    %eax,0x14(%ebp)
f01049cd:	e9 7b 01 00 00       	jmp    f0104b4d <.L35+0x45>
f01049d2:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01049d5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01049d8:	eb e9                	jmp    f01049c3 <.L36+0xef>

f01049da <.L31>:
f01049da:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01049dd:	83 f9 01             	cmp    $0x1,%ecx
f01049e0:	7e 40                	jle    f0104a22 <.L31+0x48>
		return va_arg(*ap, long long);
f01049e2:	8b 45 14             	mov    0x14(%ebp),%eax
f01049e5:	8b 50 04             	mov    0x4(%eax),%edx
f01049e8:	8b 00                	mov    (%eax),%eax
f01049ea:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01049ed:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01049f0:	8b 45 14             	mov    0x14(%ebp),%eax
f01049f3:	8d 40 08             	lea    0x8(%eax),%eax
f01049f6:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long)num < 0)
f01049f9:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01049fd:	79 55                	jns    f0104a54 <.L31+0x7a>
				putch('-', putdat);
f01049ff:	83 ec 08             	sub    $0x8,%esp
f0104a02:	56                   	push   %esi
f0104a03:	6a 2d                	push   $0x2d
f0104a05:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long)num;
f0104a08:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104a0b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104a0e:	f7 da                	neg    %edx
f0104a10:	83 d1 00             	adc    $0x0,%ecx
f0104a13:	f7 d9                	neg    %ecx
f0104a15:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0104a18:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104a1d:	e9 10 01 00 00       	jmp    f0104b32 <.L35+0x2a>
	else if (lflag)
f0104a22:	85 c9                	test   %ecx,%ecx
f0104a24:	75 17                	jne    f0104a3d <.L31+0x63>
		return va_arg(*ap, int);
f0104a26:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a29:	8b 00                	mov    (%eax),%eax
f0104a2b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104a2e:	99                   	cltd   
f0104a2f:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104a32:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a35:	8d 40 04             	lea    0x4(%eax),%eax
f0104a38:	89 45 14             	mov    %eax,0x14(%ebp)
f0104a3b:	eb bc                	jmp    f01049f9 <.L31+0x1f>
		return va_arg(*ap, long);
f0104a3d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a40:	8b 00                	mov    (%eax),%eax
f0104a42:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104a45:	99                   	cltd   
f0104a46:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104a49:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a4c:	8d 40 04             	lea    0x4(%eax),%eax
f0104a4f:	89 45 14             	mov    %eax,0x14(%ebp)
f0104a52:	eb a5                	jmp    f01049f9 <.L31+0x1f>
			num = getint(&ap, lflag);
f0104a54:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104a57:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0104a5a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104a5f:	e9 ce 00 00 00       	jmp    f0104b32 <.L35+0x2a>

f0104a64 <.L37>:
f0104a64:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104a67:	83 f9 01             	cmp    $0x1,%ecx
f0104a6a:	7e 18                	jle    f0104a84 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f0104a6c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a6f:	8b 10                	mov    (%eax),%edx
f0104a71:	8b 48 04             	mov    0x4(%eax),%ecx
f0104a74:	8d 40 08             	lea    0x8(%eax),%eax
f0104a77:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104a7a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104a7f:	e9 ae 00 00 00       	jmp    f0104b32 <.L35+0x2a>
	else if (lflag)
f0104a84:	85 c9                	test   %ecx,%ecx
f0104a86:	75 1a                	jne    f0104aa2 <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f0104a88:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a8b:	8b 10                	mov    (%eax),%edx
f0104a8d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104a92:	8d 40 04             	lea    0x4(%eax),%eax
f0104a95:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104a98:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104a9d:	e9 90 00 00 00       	jmp    f0104b32 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0104aa2:	8b 45 14             	mov    0x14(%ebp),%eax
f0104aa5:	8b 10                	mov    (%eax),%edx
f0104aa7:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104aac:	8d 40 04             	lea    0x4(%eax),%eax
f0104aaf:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104ab2:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104ab7:	eb 79                	jmp    f0104b32 <.L35+0x2a>

f0104ab9 <.L34>:
f0104ab9:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104abc:	83 f9 01             	cmp    $0x1,%ecx
f0104abf:	7e 15                	jle    f0104ad6 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f0104ac1:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ac4:	8b 10                	mov    (%eax),%edx
f0104ac6:	8b 48 04             	mov    0x4(%eax),%ecx
f0104ac9:	8d 40 08             	lea    0x8(%eax),%eax
f0104acc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0104acf:	b8 08 00 00 00       	mov    $0x8,%eax
f0104ad4:	eb 5c                	jmp    f0104b32 <.L35+0x2a>
	else if (lflag)
f0104ad6:	85 c9                	test   %ecx,%ecx
f0104ad8:	75 17                	jne    f0104af1 <.L34+0x38>
		return va_arg(*ap, unsigned int);
f0104ada:	8b 45 14             	mov    0x14(%ebp),%eax
f0104add:	8b 10                	mov    (%eax),%edx
f0104adf:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104ae4:	8d 40 04             	lea    0x4(%eax),%eax
f0104ae7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0104aea:	b8 08 00 00 00       	mov    $0x8,%eax
f0104aef:	eb 41                	jmp    f0104b32 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0104af1:	8b 45 14             	mov    0x14(%ebp),%eax
f0104af4:	8b 10                	mov    (%eax),%edx
f0104af6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104afb:	8d 40 04             	lea    0x4(%eax),%eax
f0104afe:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0104b01:	b8 08 00 00 00       	mov    $0x8,%eax
f0104b06:	eb 2a                	jmp    f0104b32 <.L35+0x2a>

f0104b08 <.L35>:
			putch('0', putdat);
f0104b08:	83 ec 08             	sub    $0x8,%esp
f0104b0b:	56                   	push   %esi
f0104b0c:	6a 30                	push   $0x30
f0104b0e:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0104b11:	83 c4 08             	add    $0x8,%esp
f0104b14:	56                   	push   %esi
f0104b15:	6a 78                	push   $0x78
f0104b17:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
f0104b1a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b1d:	8b 10                	mov    (%eax),%edx
f0104b1f:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0104b24:	83 c4 10             	add    $0x10,%esp
			num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
f0104b27:	8d 40 04             	lea    0x4(%eax),%eax
f0104b2a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104b2d:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0104b32:	83 ec 0c             	sub    $0xc,%esp
f0104b35:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104b39:	57                   	push   %edi
f0104b3a:	ff 75 e0             	pushl  -0x20(%ebp)
f0104b3d:	50                   	push   %eax
f0104b3e:	51                   	push   %ecx
f0104b3f:	52                   	push   %edx
f0104b40:	89 f2                	mov    %esi,%edx
f0104b42:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b45:	e8 20 fb ff ff       	call   f010466a <printnum>
			break;
f0104b4a:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0104b4d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *)fmt++) != '%')
f0104b50:	83 c7 01             	add    $0x1,%edi
f0104b53:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104b57:	83 f8 25             	cmp    $0x25,%eax
f0104b5a:	0f 84 2d fc ff ff    	je     f010478d <vprintfmt+0x1f>
			if (ch == '\0')
f0104b60:	85 c0                	test   %eax,%eax
f0104b62:	0f 84 91 00 00 00    	je     f0104bf9 <.L22+0x21>
			putch(ch, putdat);
f0104b68:	83 ec 08             	sub    $0x8,%esp
f0104b6b:	56                   	push   %esi
f0104b6c:	50                   	push   %eax
f0104b6d:	ff 55 08             	call   *0x8(%ebp)
f0104b70:	83 c4 10             	add    $0x10,%esp
f0104b73:	eb db                	jmp    f0104b50 <.L35+0x48>

f0104b75 <.L38>:
f0104b75:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104b78:	83 f9 01             	cmp    $0x1,%ecx
f0104b7b:	7e 15                	jle    f0104b92 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0104b7d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b80:	8b 10                	mov    (%eax),%edx
f0104b82:	8b 48 04             	mov    0x4(%eax),%ecx
f0104b85:	8d 40 08             	lea    0x8(%eax),%eax
f0104b88:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104b8b:	b8 10 00 00 00       	mov    $0x10,%eax
f0104b90:	eb a0                	jmp    f0104b32 <.L35+0x2a>
	else if (lflag)
f0104b92:	85 c9                	test   %ecx,%ecx
f0104b94:	75 17                	jne    f0104bad <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0104b96:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b99:	8b 10                	mov    (%eax),%edx
f0104b9b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104ba0:	8d 40 04             	lea    0x4(%eax),%eax
f0104ba3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104ba6:	b8 10 00 00 00       	mov    $0x10,%eax
f0104bab:	eb 85                	jmp    f0104b32 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0104bad:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bb0:	8b 10                	mov    (%eax),%edx
f0104bb2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104bb7:	8d 40 04             	lea    0x4(%eax),%eax
f0104bba:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104bbd:	b8 10 00 00 00       	mov    $0x10,%eax
f0104bc2:	e9 6b ff ff ff       	jmp    f0104b32 <.L35+0x2a>

f0104bc7 <.L25>:
			putch(ch, putdat);
f0104bc7:	83 ec 08             	sub    $0x8,%esp
f0104bca:	56                   	push   %esi
f0104bcb:	6a 25                	push   $0x25
f0104bcd:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104bd0:	83 c4 10             	add    $0x10,%esp
f0104bd3:	e9 75 ff ff ff       	jmp    f0104b4d <.L35+0x45>

f0104bd8 <.L22>:
			putch('%', putdat);
f0104bd8:	83 ec 08             	sub    $0x8,%esp
f0104bdb:	56                   	push   %esi
f0104bdc:	6a 25                	push   $0x25
f0104bde:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104be1:	83 c4 10             	add    $0x10,%esp
f0104be4:	89 f8                	mov    %edi,%eax
f0104be6:	eb 03                	jmp    f0104beb <.L22+0x13>
f0104be8:	83 e8 01             	sub    $0x1,%eax
f0104beb:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0104bef:	75 f7                	jne    f0104be8 <.L22+0x10>
f0104bf1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104bf4:	e9 54 ff ff ff       	jmp    f0104b4d <.L35+0x45>
}
f0104bf9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104bfc:	5b                   	pop    %ebx
f0104bfd:	5e                   	pop    %esi
f0104bfe:	5f                   	pop    %edi
f0104bff:	5d                   	pop    %ebp
f0104c00:	c3                   	ret    

f0104c01 <vsnprintf>:

int vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104c01:	55                   	push   %ebp
f0104c02:	89 e5                	mov    %esp,%ebp
f0104c04:	53                   	push   %ebx
f0104c05:	83 ec 14             	sub    $0x14,%esp
f0104c08:	e8 5a b5 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104c0d:	81 c3 13 84 08 00    	add    $0x88413,%ebx
f0104c13:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c16:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf + n - 1, 0};
f0104c19:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104c1c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104c20:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104c23:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104c2a:	85 c0                	test   %eax,%eax
f0104c2c:	74 2b                	je     f0104c59 <vsnprintf+0x58>
f0104c2e:	85 d2                	test   %edx,%edx
f0104c30:	7e 27                	jle    f0104c59 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void *)sprintputch, &b, fmt, ap);
f0104c32:	ff 75 14             	pushl  0x14(%ebp)
f0104c35:	ff 75 10             	pushl  0x10(%ebp)
f0104c38:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104c3b:	50                   	push   %eax
f0104c3c:	8d 83 14 77 f7 ff    	lea    -0x888ec(%ebx),%eax
f0104c42:	50                   	push   %eax
f0104c43:	e8 26 fb ff ff       	call   f010476e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104c48:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104c4b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104c4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104c51:	83 c4 10             	add    $0x10,%esp
}
f0104c54:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104c57:	c9                   	leave  
f0104c58:	c3                   	ret    
		return -E_INVAL;
f0104c59:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104c5e:	eb f4                	jmp    f0104c54 <vsnprintf+0x53>

f0104c60 <snprintf>:

int snprintf(char *buf, int n, const char *fmt, ...)
{
f0104c60:	55                   	push   %ebp
f0104c61:	89 e5                	mov    %esp,%ebp
f0104c63:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104c66:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104c69:	50                   	push   %eax
f0104c6a:	ff 75 10             	pushl  0x10(%ebp)
f0104c6d:	ff 75 0c             	pushl  0xc(%ebp)
f0104c70:	ff 75 08             	pushl  0x8(%ebp)
f0104c73:	e8 89 ff ff ff       	call   f0104c01 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104c78:	c9                   	leave  
f0104c79:	c3                   	ret    

f0104c7a <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104c7a:	55                   	push   %ebp
f0104c7b:	89 e5                	mov    %esp,%ebp
f0104c7d:	57                   	push   %edi
f0104c7e:	56                   	push   %esi
f0104c7f:	53                   	push   %ebx
f0104c80:	83 ec 1c             	sub    $0x1c,%esp
f0104c83:	e8 df b4 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104c88:	81 c3 98 83 08 00    	add    $0x88398,%ebx
f0104c8e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104c91:	85 c0                	test   %eax,%eax
f0104c93:	74 13                	je     f0104ca8 <readline+0x2e>
		cprintf("%s", prompt);
f0104c95:	83 ec 08             	sub    $0x8,%esp
f0104c98:	50                   	push   %eax
f0104c99:	8d 83 dd 90 f7 ff    	lea    -0x86f23(%ebx),%eax
f0104c9f:	50                   	push   %eax
f0104ca0:	e8 0f ef ff ff       	call   f0103bb4 <cprintf>
f0104ca5:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104ca8:	83 ec 0c             	sub    $0xc,%esp
f0104cab:	6a 00                	push   $0x0
f0104cad:	e8 4d ba ff ff       	call   f01006ff <iscons>
f0104cb2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104cb5:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0104cb8:	bf 00 00 00 00       	mov    $0x0,%edi
f0104cbd:	eb 46                	jmp    f0104d05 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0104cbf:	83 ec 08             	sub    $0x8,%esp
f0104cc2:	50                   	push   %eax
f0104cc3:	8d 83 34 9a f7 ff    	lea    -0x865cc(%ebx),%eax
f0104cc9:	50                   	push   %eax
f0104cca:	e8 e5 ee ff ff       	call   f0103bb4 <cprintf>
			return NULL;
f0104ccf:	83 c4 10             	add    $0x10,%esp
f0104cd2:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0104cd7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104cda:	5b                   	pop    %ebx
f0104cdb:	5e                   	pop    %esi
f0104cdc:	5f                   	pop    %edi
f0104cdd:	5d                   	pop    %ebp
f0104cde:	c3                   	ret    
			if (echoing)
f0104cdf:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104ce3:	75 05                	jne    f0104cea <readline+0x70>
			i--;
f0104ce5:	83 ef 01             	sub    $0x1,%edi
f0104ce8:	eb 1b                	jmp    f0104d05 <readline+0x8b>
				cputchar('\b');
f0104cea:	83 ec 0c             	sub    $0xc,%esp
f0104ced:	6a 08                	push   $0x8
f0104cef:	e8 ea b9 ff ff       	call   f01006de <cputchar>
f0104cf4:	83 c4 10             	add    $0x10,%esp
f0104cf7:	eb ec                	jmp    f0104ce5 <readline+0x6b>
			buf[i++] = c;
f0104cf9:	89 f0                	mov    %esi,%eax
f0104cfb:	88 84 3b c0 2f 00 00 	mov    %al,0x2fc0(%ebx,%edi,1)
f0104d02:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0104d05:	e8 e4 b9 ff ff       	call   f01006ee <getchar>
f0104d0a:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0104d0c:	85 c0                	test   %eax,%eax
f0104d0e:	78 af                	js     f0104cbf <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104d10:	83 f8 08             	cmp    $0x8,%eax
f0104d13:	0f 94 c2             	sete   %dl
f0104d16:	83 f8 7f             	cmp    $0x7f,%eax
f0104d19:	0f 94 c0             	sete   %al
f0104d1c:	08 c2                	or     %al,%dl
f0104d1e:	74 04                	je     f0104d24 <readline+0xaa>
f0104d20:	85 ff                	test   %edi,%edi
f0104d22:	7f bb                	jg     f0104cdf <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104d24:	83 fe 1f             	cmp    $0x1f,%esi
f0104d27:	7e 1c                	jle    f0104d45 <readline+0xcb>
f0104d29:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0104d2f:	7f 14                	jg     f0104d45 <readline+0xcb>
			if (echoing)
f0104d31:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104d35:	74 c2                	je     f0104cf9 <readline+0x7f>
				cputchar(c);
f0104d37:	83 ec 0c             	sub    $0xc,%esp
f0104d3a:	56                   	push   %esi
f0104d3b:	e8 9e b9 ff ff       	call   f01006de <cputchar>
f0104d40:	83 c4 10             	add    $0x10,%esp
f0104d43:	eb b4                	jmp    f0104cf9 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0104d45:	83 fe 0a             	cmp    $0xa,%esi
f0104d48:	74 05                	je     f0104d4f <readline+0xd5>
f0104d4a:	83 fe 0d             	cmp    $0xd,%esi
f0104d4d:	75 b6                	jne    f0104d05 <readline+0x8b>
			if (echoing)
f0104d4f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104d53:	75 13                	jne    f0104d68 <readline+0xee>
			buf[i] = 0;
f0104d55:	c6 84 3b c0 2f 00 00 	movb   $0x0,0x2fc0(%ebx,%edi,1)
f0104d5c:	00 
			return buf;
f0104d5d:	8d 83 c0 2f 00 00    	lea    0x2fc0(%ebx),%eax
f0104d63:	e9 6f ff ff ff       	jmp    f0104cd7 <readline+0x5d>
				cputchar('\n');
f0104d68:	83 ec 0c             	sub    $0xc,%esp
f0104d6b:	6a 0a                	push   $0xa
f0104d6d:	e8 6c b9 ff ff       	call   f01006de <cputchar>
f0104d72:	83 c4 10             	add    $0x10,%esp
f0104d75:	eb de                	jmp    f0104d55 <readline+0xdb>

f0104d77 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104d77:	55                   	push   %ebp
f0104d78:	89 e5                	mov    %esp,%ebp
f0104d7a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104d7d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d82:	eb 03                	jmp    f0104d87 <strlen+0x10>
		n++;
f0104d84:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0104d87:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104d8b:	75 f7                	jne    f0104d84 <strlen+0xd>
	return n;
}
f0104d8d:	5d                   	pop    %ebp
f0104d8e:	c3                   	ret    

f0104d8f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104d8f:	55                   	push   %ebp
f0104d90:	89 e5                	mov    %esp,%ebp
f0104d92:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104d95:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104d98:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d9d:	eb 03                	jmp    f0104da2 <strnlen+0x13>
		n++;
f0104d9f:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104da2:	39 d0                	cmp    %edx,%eax
f0104da4:	74 06                	je     f0104dac <strnlen+0x1d>
f0104da6:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104daa:	75 f3                	jne    f0104d9f <strnlen+0x10>
	return n;
}
f0104dac:	5d                   	pop    %ebp
f0104dad:	c3                   	ret    

f0104dae <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104dae:	55                   	push   %ebp
f0104daf:	89 e5                	mov    %esp,%ebp
f0104db1:	53                   	push   %ebx
f0104db2:	8b 45 08             	mov    0x8(%ebp),%eax
f0104db5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104db8:	89 c2                	mov    %eax,%edx
f0104dba:	83 c1 01             	add    $0x1,%ecx
f0104dbd:	83 c2 01             	add    $0x1,%edx
f0104dc0:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104dc4:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104dc7:	84 db                	test   %bl,%bl
f0104dc9:	75 ef                	jne    f0104dba <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104dcb:	5b                   	pop    %ebx
f0104dcc:	5d                   	pop    %ebp
f0104dcd:	c3                   	ret    

f0104dce <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104dce:	55                   	push   %ebp
f0104dcf:	89 e5                	mov    %esp,%ebp
f0104dd1:	53                   	push   %ebx
f0104dd2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104dd5:	53                   	push   %ebx
f0104dd6:	e8 9c ff ff ff       	call   f0104d77 <strlen>
f0104ddb:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104dde:	ff 75 0c             	pushl  0xc(%ebp)
f0104de1:	01 d8                	add    %ebx,%eax
f0104de3:	50                   	push   %eax
f0104de4:	e8 c5 ff ff ff       	call   f0104dae <strcpy>
	return dst;
}
f0104de9:	89 d8                	mov    %ebx,%eax
f0104deb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104dee:	c9                   	leave  
f0104def:	c3                   	ret    

f0104df0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104df0:	55                   	push   %ebp
f0104df1:	89 e5                	mov    %esp,%ebp
f0104df3:	56                   	push   %esi
f0104df4:	53                   	push   %ebx
f0104df5:	8b 75 08             	mov    0x8(%ebp),%esi
f0104df8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104dfb:	89 f3                	mov    %esi,%ebx
f0104dfd:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104e00:	89 f2                	mov    %esi,%edx
f0104e02:	eb 0f                	jmp    f0104e13 <strncpy+0x23>
		*dst++ = *src;
f0104e04:	83 c2 01             	add    $0x1,%edx
f0104e07:	0f b6 01             	movzbl (%ecx),%eax
f0104e0a:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104e0d:	80 39 01             	cmpb   $0x1,(%ecx)
f0104e10:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0104e13:	39 da                	cmp    %ebx,%edx
f0104e15:	75 ed                	jne    f0104e04 <strncpy+0x14>
	}
	return ret;
}
f0104e17:	89 f0                	mov    %esi,%eax
f0104e19:	5b                   	pop    %ebx
f0104e1a:	5e                   	pop    %esi
f0104e1b:	5d                   	pop    %ebp
f0104e1c:	c3                   	ret    

f0104e1d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104e1d:	55                   	push   %ebp
f0104e1e:	89 e5                	mov    %esp,%ebp
f0104e20:	56                   	push   %esi
f0104e21:	53                   	push   %ebx
f0104e22:	8b 75 08             	mov    0x8(%ebp),%esi
f0104e25:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104e28:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104e2b:	89 f0                	mov    %esi,%eax
f0104e2d:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104e31:	85 c9                	test   %ecx,%ecx
f0104e33:	75 0b                	jne    f0104e40 <strlcpy+0x23>
f0104e35:	eb 17                	jmp    f0104e4e <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104e37:	83 c2 01             	add    $0x1,%edx
f0104e3a:	83 c0 01             	add    $0x1,%eax
f0104e3d:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0104e40:	39 d8                	cmp    %ebx,%eax
f0104e42:	74 07                	je     f0104e4b <strlcpy+0x2e>
f0104e44:	0f b6 0a             	movzbl (%edx),%ecx
f0104e47:	84 c9                	test   %cl,%cl
f0104e49:	75 ec                	jne    f0104e37 <strlcpy+0x1a>
		*dst = '\0';
f0104e4b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104e4e:	29 f0                	sub    %esi,%eax
}
f0104e50:	5b                   	pop    %ebx
f0104e51:	5e                   	pop    %esi
f0104e52:	5d                   	pop    %ebp
f0104e53:	c3                   	ret    

f0104e54 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104e54:	55                   	push   %ebp
f0104e55:	89 e5                	mov    %esp,%ebp
f0104e57:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104e5a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104e5d:	eb 06                	jmp    f0104e65 <strcmp+0x11>
		p++, q++;
f0104e5f:	83 c1 01             	add    $0x1,%ecx
f0104e62:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0104e65:	0f b6 01             	movzbl (%ecx),%eax
f0104e68:	84 c0                	test   %al,%al
f0104e6a:	74 04                	je     f0104e70 <strcmp+0x1c>
f0104e6c:	3a 02                	cmp    (%edx),%al
f0104e6e:	74 ef                	je     f0104e5f <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104e70:	0f b6 c0             	movzbl %al,%eax
f0104e73:	0f b6 12             	movzbl (%edx),%edx
f0104e76:	29 d0                	sub    %edx,%eax
}
f0104e78:	5d                   	pop    %ebp
f0104e79:	c3                   	ret    

f0104e7a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104e7a:	55                   	push   %ebp
f0104e7b:	89 e5                	mov    %esp,%ebp
f0104e7d:	53                   	push   %ebx
f0104e7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e81:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104e84:	89 c3                	mov    %eax,%ebx
f0104e86:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104e89:	eb 06                	jmp    f0104e91 <strncmp+0x17>
		n--, p++, q++;
f0104e8b:	83 c0 01             	add    $0x1,%eax
f0104e8e:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0104e91:	39 d8                	cmp    %ebx,%eax
f0104e93:	74 16                	je     f0104eab <strncmp+0x31>
f0104e95:	0f b6 08             	movzbl (%eax),%ecx
f0104e98:	84 c9                	test   %cl,%cl
f0104e9a:	74 04                	je     f0104ea0 <strncmp+0x26>
f0104e9c:	3a 0a                	cmp    (%edx),%cl
f0104e9e:	74 eb                	je     f0104e8b <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104ea0:	0f b6 00             	movzbl (%eax),%eax
f0104ea3:	0f b6 12             	movzbl (%edx),%edx
f0104ea6:	29 d0                	sub    %edx,%eax
}
f0104ea8:	5b                   	pop    %ebx
f0104ea9:	5d                   	pop    %ebp
f0104eaa:	c3                   	ret    
		return 0;
f0104eab:	b8 00 00 00 00       	mov    $0x0,%eax
f0104eb0:	eb f6                	jmp    f0104ea8 <strncmp+0x2e>

f0104eb2 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104eb2:	55                   	push   %ebp
f0104eb3:	89 e5                	mov    %esp,%ebp
f0104eb5:	8b 45 08             	mov    0x8(%ebp),%eax
f0104eb8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104ebc:	0f b6 10             	movzbl (%eax),%edx
f0104ebf:	84 d2                	test   %dl,%dl
f0104ec1:	74 09                	je     f0104ecc <strchr+0x1a>
		if (*s == c)
f0104ec3:	38 ca                	cmp    %cl,%dl
f0104ec5:	74 0a                	je     f0104ed1 <strchr+0x1f>
	for (; *s; s++)
f0104ec7:	83 c0 01             	add    $0x1,%eax
f0104eca:	eb f0                	jmp    f0104ebc <strchr+0xa>
			return (char *) s;
	return 0;
f0104ecc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104ed1:	5d                   	pop    %ebp
f0104ed2:	c3                   	ret    

f0104ed3 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104ed3:	55                   	push   %ebp
f0104ed4:	89 e5                	mov    %esp,%ebp
f0104ed6:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ed9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104edd:	eb 03                	jmp    f0104ee2 <strfind+0xf>
f0104edf:	83 c0 01             	add    $0x1,%eax
f0104ee2:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104ee5:	38 ca                	cmp    %cl,%dl
f0104ee7:	74 04                	je     f0104eed <strfind+0x1a>
f0104ee9:	84 d2                	test   %dl,%dl
f0104eeb:	75 f2                	jne    f0104edf <strfind+0xc>
			break;
	return (char *) s;
}
f0104eed:	5d                   	pop    %ebp
f0104eee:	c3                   	ret    

f0104eef <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104eef:	55                   	push   %ebp
f0104ef0:	89 e5                	mov    %esp,%ebp
f0104ef2:	57                   	push   %edi
f0104ef3:	56                   	push   %esi
f0104ef4:	53                   	push   %ebx
f0104ef5:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104ef8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104efb:	85 c9                	test   %ecx,%ecx
f0104efd:	74 13                	je     f0104f12 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104eff:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104f05:	75 05                	jne    f0104f0c <memset+0x1d>
f0104f07:	f6 c1 03             	test   $0x3,%cl
f0104f0a:	74 0d                	je     f0104f19 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104f0c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104f0f:	fc                   	cld    
f0104f10:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104f12:	89 f8                	mov    %edi,%eax
f0104f14:	5b                   	pop    %ebx
f0104f15:	5e                   	pop    %esi
f0104f16:	5f                   	pop    %edi
f0104f17:	5d                   	pop    %ebp
f0104f18:	c3                   	ret    
		c &= 0xFF;
f0104f19:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104f1d:	89 d3                	mov    %edx,%ebx
f0104f1f:	c1 e3 08             	shl    $0x8,%ebx
f0104f22:	89 d0                	mov    %edx,%eax
f0104f24:	c1 e0 18             	shl    $0x18,%eax
f0104f27:	89 d6                	mov    %edx,%esi
f0104f29:	c1 e6 10             	shl    $0x10,%esi
f0104f2c:	09 f0                	or     %esi,%eax
f0104f2e:	09 c2                	or     %eax,%edx
f0104f30:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0104f32:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0104f35:	89 d0                	mov    %edx,%eax
f0104f37:	fc                   	cld    
f0104f38:	f3 ab                	rep stos %eax,%es:(%edi)
f0104f3a:	eb d6                	jmp    f0104f12 <memset+0x23>

f0104f3c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104f3c:	55                   	push   %ebp
f0104f3d:	89 e5                	mov    %esp,%ebp
f0104f3f:	57                   	push   %edi
f0104f40:	56                   	push   %esi
f0104f41:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f44:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104f47:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104f4a:	39 c6                	cmp    %eax,%esi
f0104f4c:	73 35                	jae    f0104f83 <memmove+0x47>
f0104f4e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104f51:	39 c2                	cmp    %eax,%edx
f0104f53:	76 2e                	jbe    f0104f83 <memmove+0x47>
		s += n;
		d += n;
f0104f55:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104f58:	89 d6                	mov    %edx,%esi
f0104f5a:	09 fe                	or     %edi,%esi
f0104f5c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104f62:	74 0c                	je     f0104f70 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104f64:	83 ef 01             	sub    $0x1,%edi
f0104f67:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0104f6a:	fd                   	std    
f0104f6b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104f6d:	fc                   	cld    
f0104f6e:	eb 21                	jmp    f0104f91 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104f70:	f6 c1 03             	test   $0x3,%cl
f0104f73:	75 ef                	jne    f0104f64 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104f75:	83 ef 04             	sub    $0x4,%edi
f0104f78:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104f7b:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0104f7e:	fd                   	std    
f0104f7f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104f81:	eb ea                	jmp    f0104f6d <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104f83:	89 f2                	mov    %esi,%edx
f0104f85:	09 c2                	or     %eax,%edx
f0104f87:	f6 c2 03             	test   $0x3,%dl
f0104f8a:	74 09                	je     f0104f95 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104f8c:	89 c7                	mov    %eax,%edi
f0104f8e:	fc                   	cld    
f0104f8f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104f91:	5e                   	pop    %esi
f0104f92:	5f                   	pop    %edi
f0104f93:	5d                   	pop    %ebp
f0104f94:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104f95:	f6 c1 03             	test   $0x3,%cl
f0104f98:	75 f2                	jne    f0104f8c <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104f9a:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0104f9d:	89 c7                	mov    %eax,%edi
f0104f9f:	fc                   	cld    
f0104fa0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104fa2:	eb ed                	jmp    f0104f91 <memmove+0x55>

f0104fa4 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104fa4:	55                   	push   %ebp
f0104fa5:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104fa7:	ff 75 10             	pushl  0x10(%ebp)
f0104faa:	ff 75 0c             	pushl  0xc(%ebp)
f0104fad:	ff 75 08             	pushl  0x8(%ebp)
f0104fb0:	e8 87 ff ff ff       	call   f0104f3c <memmove>
}
f0104fb5:	c9                   	leave  
f0104fb6:	c3                   	ret    

f0104fb7 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104fb7:	55                   	push   %ebp
f0104fb8:	89 e5                	mov    %esp,%ebp
f0104fba:	56                   	push   %esi
f0104fbb:	53                   	push   %ebx
f0104fbc:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fbf:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104fc2:	89 c6                	mov    %eax,%esi
f0104fc4:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104fc7:	39 f0                	cmp    %esi,%eax
f0104fc9:	74 1c                	je     f0104fe7 <memcmp+0x30>
		if (*s1 != *s2)
f0104fcb:	0f b6 08             	movzbl (%eax),%ecx
f0104fce:	0f b6 1a             	movzbl (%edx),%ebx
f0104fd1:	38 d9                	cmp    %bl,%cl
f0104fd3:	75 08                	jne    f0104fdd <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0104fd5:	83 c0 01             	add    $0x1,%eax
f0104fd8:	83 c2 01             	add    $0x1,%edx
f0104fdb:	eb ea                	jmp    f0104fc7 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0104fdd:	0f b6 c1             	movzbl %cl,%eax
f0104fe0:	0f b6 db             	movzbl %bl,%ebx
f0104fe3:	29 d8                	sub    %ebx,%eax
f0104fe5:	eb 05                	jmp    f0104fec <memcmp+0x35>
	}

	return 0;
f0104fe7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104fec:	5b                   	pop    %ebx
f0104fed:	5e                   	pop    %esi
f0104fee:	5d                   	pop    %ebp
f0104fef:	c3                   	ret    

f0104ff0 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104ff0:	55                   	push   %ebp
f0104ff1:	89 e5                	mov    %esp,%ebp
f0104ff3:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ff6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104ff9:	89 c2                	mov    %eax,%edx
f0104ffb:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104ffe:	39 d0                	cmp    %edx,%eax
f0105000:	73 09                	jae    f010500b <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105002:	38 08                	cmp    %cl,(%eax)
f0105004:	74 05                	je     f010500b <memfind+0x1b>
	for (; s < ends; s++)
f0105006:	83 c0 01             	add    $0x1,%eax
f0105009:	eb f3                	jmp    f0104ffe <memfind+0xe>
			break;
	return (void *) s;
}
f010500b:	5d                   	pop    %ebp
f010500c:	c3                   	ret    

f010500d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010500d:	55                   	push   %ebp
f010500e:	89 e5                	mov    %esp,%ebp
f0105010:	57                   	push   %edi
f0105011:	56                   	push   %esi
f0105012:	53                   	push   %ebx
f0105013:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105016:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105019:	eb 03                	jmp    f010501e <strtol+0x11>
		s++;
f010501b:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f010501e:	0f b6 01             	movzbl (%ecx),%eax
f0105021:	3c 20                	cmp    $0x20,%al
f0105023:	74 f6                	je     f010501b <strtol+0xe>
f0105025:	3c 09                	cmp    $0x9,%al
f0105027:	74 f2                	je     f010501b <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0105029:	3c 2b                	cmp    $0x2b,%al
f010502b:	74 2e                	je     f010505b <strtol+0x4e>
	int neg = 0;
f010502d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0105032:	3c 2d                	cmp    $0x2d,%al
f0105034:	74 2f                	je     f0105065 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105036:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010503c:	75 05                	jne    f0105043 <strtol+0x36>
f010503e:	80 39 30             	cmpb   $0x30,(%ecx)
f0105041:	74 2c                	je     f010506f <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105043:	85 db                	test   %ebx,%ebx
f0105045:	75 0a                	jne    f0105051 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105047:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f010504c:	80 39 30             	cmpb   $0x30,(%ecx)
f010504f:	74 28                	je     f0105079 <strtol+0x6c>
		base = 10;
f0105051:	b8 00 00 00 00       	mov    $0x0,%eax
f0105056:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105059:	eb 50                	jmp    f01050ab <strtol+0x9e>
		s++;
f010505b:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f010505e:	bf 00 00 00 00       	mov    $0x0,%edi
f0105063:	eb d1                	jmp    f0105036 <strtol+0x29>
		s++, neg = 1;
f0105065:	83 c1 01             	add    $0x1,%ecx
f0105068:	bf 01 00 00 00       	mov    $0x1,%edi
f010506d:	eb c7                	jmp    f0105036 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010506f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105073:	74 0e                	je     f0105083 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0105075:	85 db                	test   %ebx,%ebx
f0105077:	75 d8                	jne    f0105051 <strtol+0x44>
		s++, base = 8;
f0105079:	83 c1 01             	add    $0x1,%ecx
f010507c:	bb 08 00 00 00       	mov    $0x8,%ebx
f0105081:	eb ce                	jmp    f0105051 <strtol+0x44>
		s += 2, base = 16;
f0105083:	83 c1 02             	add    $0x2,%ecx
f0105086:	bb 10 00 00 00       	mov    $0x10,%ebx
f010508b:	eb c4                	jmp    f0105051 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f010508d:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105090:	89 f3                	mov    %esi,%ebx
f0105092:	80 fb 19             	cmp    $0x19,%bl
f0105095:	77 29                	ja     f01050c0 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0105097:	0f be d2             	movsbl %dl,%edx
f010509a:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010509d:	3b 55 10             	cmp    0x10(%ebp),%edx
f01050a0:	7d 30                	jge    f01050d2 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01050a2:	83 c1 01             	add    $0x1,%ecx
f01050a5:	0f af 45 10          	imul   0x10(%ebp),%eax
f01050a9:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f01050ab:	0f b6 11             	movzbl (%ecx),%edx
f01050ae:	8d 72 d0             	lea    -0x30(%edx),%esi
f01050b1:	89 f3                	mov    %esi,%ebx
f01050b3:	80 fb 09             	cmp    $0x9,%bl
f01050b6:	77 d5                	ja     f010508d <strtol+0x80>
			dig = *s - '0';
f01050b8:	0f be d2             	movsbl %dl,%edx
f01050bb:	83 ea 30             	sub    $0x30,%edx
f01050be:	eb dd                	jmp    f010509d <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f01050c0:	8d 72 bf             	lea    -0x41(%edx),%esi
f01050c3:	89 f3                	mov    %esi,%ebx
f01050c5:	80 fb 19             	cmp    $0x19,%bl
f01050c8:	77 08                	ja     f01050d2 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01050ca:	0f be d2             	movsbl %dl,%edx
f01050cd:	83 ea 37             	sub    $0x37,%edx
f01050d0:	eb cb                	jmp    f010509d <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01050d2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01050d6:	74 05                	je     f01050dd <strtol+0xd0>
		*endptr = (char *) s;
f01050d8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01050db:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01050dd:	89 c2                	mov    %eax,%edx
f01050df:	f7 da                	neg    %edx
f01050e1:	85 ff                	test   %edi,%edi
f01050e3:	0f 45 c2             	cmovne %edx,%eax
}
f01050e6:	5b                   	pop    %ebx
f01050e7:	5e                   	pop    %esi
f01050e8:	5f                   	pop    %edi
f01050e9:	5d                   	pop    %ebp
f01050ea:	c3                   	ret    
f01050eb:	66 90                	xchg   %ax,%ax
f01050ed:	66 90                	xchg   %ax,%ax
f01050ef:	90                   	nop

f01050f0 <__udivdi3>:
f01050f0:	55                   	push   %ebp
f01050f1:	57                   	push   %edi
f01050f2:	56                   	push   %esi
f01050f3:	53                   	push   %ebx
f01050f4:	83 ec 1c             	sub    $0x1c,%esp
f01050f7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01050fb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01050ff:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105103:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0105107:	85 d2                	test   %edx,%edx
f0105109:	75 35                	jne    f0105140 <__udivdi3+0x50>
f010510b:	39 f3                	cmp    %esi,%ebx
f010510d:	0f 87 bd 00 00 00    	ja     f01051d0 <__udivdi3+0xe0>
f0105113:	85 db                	test   %ebx,%ebx
f0105115:	89 d9                	mov    %ebx,%ecx
f0105117:	75 0b                	jne    f0105124 <__udivdi3+0x34>
f0105119:	b8 01 00 00 00       	mov    $0x1,%eax
f010511e:	31 d2                	xor    %edx,%edx
f0105120:	f7 f3                	div    %ebx
f0105122:	89 c1                	mov    %eax,%ecx
f0105124:	31 d2                	xor    %edx,%edx
f0105126:	89 f0                	mov    %esi,%eax
f0105128:	f7 f1                	div    %ecx
f010512a:	89 c6                	mov    %eax,%esi
f010512c:	89 e8                	mov    %ebp,%eax
f010512e:	89 f7                	mov    %esi,%edi
f0105130:	f7 f1                	div    %ecx
f0105132:	89 fa                	mov    %edi,%edx
f0105134:	83 c4 1c             	add    $0x1c,%esp
f0105137:	5b                   	pop    %ebx
f0105138:	5e                   	pop    %esi
f0105139:	5f                   	pop    %edi
f010513a:	5d                   	pop    %ebp
f010513b:	c3                   	ret    
f010513c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105140:	39 f2                	cmp    %esi,%edx
f0105142:	77 7c                	ja     f01051c0 <__udivdi3+0xd0>
f0105144:	0f bd fa             	bsr    %edx,%edi
f0105147:	83 f7 1f             	xor    $0x1f,%edi
f010514a:	0f 84 98 00 00 00    	je     f01051e8 <__udivdi3+0xf8>
f0105150:	89 f9                	mov    %edi,%ecx
f0105152:	b8 20 00 00 00       	mov    $0x20,%eax
f0105157:	29 f8                	sub    %edi,%eax
f0105159:	d3 e2                	shl    %cl,%edx
f010515b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010515f:	89 c1                	mov    %eax,%ecx
f0105161:	89 da                	mov    %ebx,%edx
f0105163:	d3 ea                	shr    %cl,%edx
f0105165:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0105169:	09 d1                	or     %edx,%ecx
f010516b:	89 f2                	mov    %esi,%edx
f010516d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105171:	89 f9                	mov    %edi,%ecx
f0105173:	d3 e3                	shl    %cl,%ebx
f0105175:	89 c1                	mov    %eax,%ecx
f0105177:	d3 ea                	shr    %cl,%edx
f0105179:	89 f9                	mov    %edi,%ecx
f010517b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010517f:	d3 e6                	shl    %cl,%esi
f0105181:	89 eb                	mov    %ebp,%ebx
f0105183:	89 c1                	mov    %eax,%ecx
f0105185:	d3 eb                	shr    %cl,%ebx
f0105187:	09 de                	or     %ebx,%esi
f0105189:	89 f0                	mov    %esi,%eax
f010518b:	f7 74 24 08          	divl   0x8(%esp)
f010518f:	89 d6                	mov    %edx,%esi
f0105191:	89 c3                	mov    %eax,%ebx
f0105193:	f7 64 24 0c          	mull   0xc(%esp)
f0105197:	39 d6                	cmp    %edx,%esi
f0105199:	72 0c                	jb     f01051a7 <__udivdi3+0xb7>
f010519b:	89 f9                	mov    %edi,%ecx
f010519d:	d3 e5                	shl    %cl,%ebp
f010519f:	39 c5                	cmp    %eax,%ebp
f01051a1:	73 5d                	jae    f0105200 <__udivdi3+0x110>
f01051a3:	39 d6                	cmp    %edx,%esi
f01051a5:	75 59                	jne    f0105200 <__udivdi3+0x110>
f01051a7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01051aa:	31 ff                	xor    %edi,%edi
f01051ac:	89 fa                	mov    %edi,%edx
f01051ae:	83 c4 1c             	add    $0x1c,%esp
f01051b1:	5b                   	pop    %ebx
f01051b2:	5e                   	pop    %esi
f01051b3:	5f                   	pop    %edi
f01051b4:	5d                   	pop    %ebp
f01051b5:	c3                   	ret    
f01051b6:	8d 76 00             	lea    0x0(%esi),%esi
f01051b9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01051c0:	31 ff                	xor    %edi,%edi
f01051c2:	31 c0                	xor    %eax,%eax
f01051c4:	89 fa                	mov    %edi,%edx
f01051c6:	83 c4 1c             	add    $0x1c,%esp
f01051c9:	5b                   	pop    %ebx
f01051ca:	5e                   	pop    %esi
f01051cb:	5f                   	pop    %edi
f01051cc:	5d                   	pop    %ebp
f01051cd:	c3                   	ret    
f01051ce:	66 90                	xchg   %ax,%ax
f01051d0:	31 ff                	xor    %edi,%edi
f01051d2:	89 e8                	mov    %ebp,%eax
f01051d4:	89 f2                	mov    %esi,%edx
f01051d6:	f7 f3                	div    %ebx
f01051d8:	89 fa                	mov    %edi,%edx
f01051da:	83 c4 1c             	add    $0x1c,%esp
f01051dd:	5b                   	pop    %ebx
f01051de:	5e                   	pop    %esi
f01051df:	5f                   	pop    %edi
f01051e0:	5d                   	pop    %ebp
f01051e1:	c3                   	ret    
f01051e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01051e8:	39 f2                	cmp    %esi,%edx
f01051ea:	72 06                	jb     f01051f2 <__udivdi3+0x102>
f01051ec:	31 c0                	xor    %eax,%eax
f01051ee:	39 eb                	cmp    %ebp,%ebx
f01051f0:	77 d2                	ja     f01051c4 <__udivdi3+0xd4>
f01051f2:	b8 01 00 00 00       	mov    $0x1,%eax
f01051f7:	eb cb                	jmp    f01051c4 <__udivdi3+0xd4>
f01051f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105200:	89 d8                	mov    %ebx,%eax
f0105202:	31 ff                	xor    %edi,%edi
f0105204:	eb be                	jmp    f01051c4 <__udivdi3+0xd4>
f0105206:	66 90                	xchg   %ax,%ax
f0105208:	66 90                	xchg   %ax,%ax
f010520a:	66 90                	xchg   %ax,%ax
f010520c:	66 90                	xchg   %ax,%ax
f010520e:	66 90                	xchg   %ax,%ax

f0105210 <__umoddi3>:
f0105210:	55                   	push   %ebp
f0105211:	57                   	push   %edi
f0105212:	56                   	push   %esi
f0105213:	53                   	push   %ebx
f0105214:	83 ec 1c             	sub    $0x1c,%esp
f0105217:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010521b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010521f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0105223:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105227:	85 ed                	test   %ebp,%ebp
f0105229:	89 f0                	mov    %esi,%eax
f010522b:	89 da                	mov    %ebx,%edx
f010522d:	75 19                	jne    f0105248 <__umoddi3+0x38>
f010522f:	39 df                	cmp    %ebx,%edi
f0105231:	0f 86 b1 00 00 00    	jbe    f01052e8 <__umoddi3+0xd8>
f0105237:	f7 f7                	div    %edi
f0105239:	89 d0                	mov    %edx,%eax
f010523b:	31 d2                	xor    %edx,%edx
f010523d:	83 c4 1c             	add    $0x1c,%esp
f0105240:	5b                   	pop    %ebx
f0105241:	5e                   	pop    %esi
f0105242:	5f                   	pop    %edi
f0105243:	5d                   	pop    %ebp
f0105244:	c3                   	ret    
f0105245:	8d 76 00             	lea    0x0(%esi),%esi
f0105248:	39 dd                	cmp    %ebx,%ebp
f010524a:	77 f1                	ja     f010523d <__umoddi3+0x2d>
f010524c:	0f bd cd             	bsr    %ebp,%ecx
f010524f:	83 f1 1f             	xor    $0x1f,%ecx
f0105252:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105256:	0f 84 b4 00 00 00    	je     f0105310 <__umoddi3+0x100>
f010525c:	b8 20 00 00 00       	mov    $0x20,%eax
f0105261:	89 c2                	mov    %eax,%edx
f0105263:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105267:	29 c2                	sub    %eax,%edx
f0105269:	89 c1                	mov    %eax,%ecx
f010526b:	89 f8                	mov    %edi,%eax
f010526d:	d3 e5                	shl    %cl,%ebp
f010526f:	89 d1                	mov    %edx,%ecx
f0105271:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0105275:	d3 e8                	shr    %cl,%eax
f0105277:	09 c5                	or     %eax,%ebp
f0105279:	8b 44 24 04          	mov    0x4(%esp),%eax
f010527d:	89 c1                	mov    %eax,%ecx
f010527f:	d3 e7                	shl    %cl,%edi
f0105281:	89 d1                	mov    %edx,%ecx
f0105283:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0105287:	89 df                	mov    %ebx,%edi
f0105289:	d3 ef                	shr    %cl,%edi
f010528b:	89 c1                	mov    %eax,%ecx
f010528d:	89 f0                	mov    %esi,%eax
f010528f:	d3 e3                	shl    %cl,%ebx
f0105291:	89 d1                	mov    %edx,%ecx
f0105293:	89 fa                	mov    %edi,%edx
f0105295:	d3 e8                	shr    %cl,%eax
f0105297:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010529c:	09 d8                	or     %ebx,%eax
f010529e:	f7 f5                	div    %ebp
f01052a0:	d3 e6                	shl    %cl,%esi
f01052a2:	89 d1                	mov    %edx,%ecx
f01052a4:	f7 64 24 08          	mull   0x8(%esp)
f01052a8:	39 d1                	cmp    %edx,%ecx
f01052aa:	89 c3                	mov    %eax,%ebx
f01052ac:	89 d7                	mov    %edx,%edi
f01052ae:	72 06                	jb     f01052b6 <__umoddi3+0xa6>
f01052b0:	75 0e                	jne    f01052c0 <__umoddi3+0xb0>
f01052b2:	39 c6                	cmp    %eax,%esi
f01052b4:	73 0a                	jae    f01052c0 <__umoddi3+0xb0>
f01052b6:	2b 44 24 08          	sub    0x8(%esp),%eax
f01052ba:	19 ea                	sbb    %ebp,%edx
f01052bc:	89 d7                	mov    %edx,%edi
f01052be:	89 c3                	mov    %eax,%ebx
f01052c0:	89 ca                	mov    %ecx,%edx
f01052c2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f01052c7:	29 de                	sub    %ebx,%esi
f01052c9:	19 fa                	sbb    %edi,%edx
f01052cb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01052cf:	89 d0                	mov    %edx,%eax
f01052d1:	d3 e0                	shl    %cl,%eax
f01052d3:	89 d9                	mov    %ebx,%ecx
f01052d5:	d3 ee                	shr    %cl,%esi
f01052d7:	d3 ea                	shr    %cl,%edx
f01052d9:	09 f0                	or     %esi,%eax
f01052db:	83 c4 1c             	add    $0x1c,%esp
f01052de:	5b                   	pop    %ebx
f01052df:	5e                   	pop    %esi
f01052e0:	5f                   	pop    %edi
f01052e1:	5d                   	pop    %ebp
f01052e2:	c3                   	ret    
f01052e3:	90                   	nop
f01052e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01052e8:	85 ff                	test   %edi,%edi
f01052ea:	89 f9                	mov    %edi,%ecx
f01052ec:	75 0b                	jne    f01052f9 <__umoddi3+0xe9>
f01052ee:	b8 01 00 00 00       	mov    $0x1,%eax
f01052f3:	31 d2                	xor    %edx,%edx
f01052f5:	f7 f7                	div    %edi
f01052f7:	89 c1                	mov    %eax,%ecx
f01052f9:	89 d8                	mov    %ebx,%eax
f01052fb:	31 d2                	xor    %edx,%edx
f01052fd:	f7 f1                	div    %ecx
f01052ff:	89 f0                	mov    %esi,%eax
f0105301:	f7 f1                	div    %ecx
f0105303:	e9 31 ff ff ff       	jmp    f0105239 <__umoddi3+0x29>
f0105308:	90                   	nop
f0105309:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105310:	39 dd                	cmp    %ebx,%ebp
f0105312:	72 08                	jb     f010531c <__umoddi3+0x10c>
f0105314:	39 f7                	cmp    %esi,%edi
f0105316:	0f 87 21 ff ff ff    	ja     f010523d <__umoddi3+0x2d>
f010531c:	89 da                	mov    %ebx,%edx
f010531e:	89 f0                	mov    %esi,%eax
f0105320:	29 f8                	sub    %edi,%eax
f0105322:	19 ea                	sbb    %ebp,%edx
f0105324:	e9 14 ff ff ff       	jmp    f010523d <__umoddi3+0x2d>
