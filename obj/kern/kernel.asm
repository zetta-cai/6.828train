
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
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 68 00 00 00       	call   f01000a6 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	e8 72 01 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f010004a:	81 c3 be 12 01 00    	add    $0x112be,%ebx
f0100050:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("entering test_backtrace %d\n", x);
f0100053:	83 ec 08             	sub    $0x8,%esp
f0100056:	56                   	push   %esi
f0100057:	8d 83 58 08 ff ff    	lea    -0xf7a8(%ebx),%eax
f010005d:	50                   	push   %eax
f010005e:	e8 aa 0a 00 00       	call   f0100b0d <cprintf>
	if (x > 0)
f0100063:	83 c4 10             	add    $0x10,%esp
f0100066:	85 f6                	test   %esi,%esi
f0100068:	7f 2b                	jg     f0100095 <test_backtrace+0x55>
		test_backtrace(x-1);
	else
		mon_backtrace(0, 0, 0);
f010006a:	83 ec 04             	sub    $0x4,%esp
f010006d:	6a 00                	push   $0x0
f010006f:	6a 00                	push   $0x0
f0100071:	6a 00                	push   $0x0
f0100073:	e8 22 08 00 00       	call   f010089a <mon_backtrace>
f0100078:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007b:	83 ec 08             	sub    $0x8,%esp
f010007e:	56                   	push   %esi
f010007f:	8d 83 74 08 ff ff    	lea    -0xf78c(%ebx),%eax
f0100085:	50                   	push   %eax
f0100086:	e8 82 0a 00 00       	call   f0100b0d <cprintf>
}
f010008b:	83 c4 10             	add    $0x10,%esp
f010008e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100091:	5b                   	pop    %ebx
f0100092:	5e                   	pop    %esi
f0100093:	5d                   	pop    %ebp
f0100094:	c3                   	ret    
		test_backtrace(x-1);
f0100095:	83 ec 0c             	sub    $0xc,%esp
f0100098:	8d 46 ff             	lea    -0x1(%esi),%eax
f010009b:	50                   	push   %eax
f010009c:	e8 9f ff ff ff       	call   f0100040 <test_backtrace>
f01000a1:	83 c4 10             	add    $0x10,%esp
f01000a4:	eb d5                	jmp    f010007b <test_backtrace+0x3b>

f01000a6 <i386_init>:

void
i386_init(void)
{
f01000a6:	55                   	push   %ebp
f01000a7:	89 e5                	mov    %esp,%ebp
f01000a9:	53                   	push   %ebx
f01000aa:	83 ec 08             	sub    $0x8,%esp
f01000ad:	e8 0a 01 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f01000b2:	81 c3 56 12 01 00    	add    $0x11256,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000b8:	c7 c2 60 30 11 f0    	mov    $0xf0113060,%edx
f01000be:	c7 c0 a0 36 11 f0    	mov    $0xf01136a0,%eax
f01000c4:	29 d0                	sub    %edx,%eax
f01000c6:	50                   	push   %eax
f01000c7:	6a 00                	push   $0x0
f01000c9:	52                   	push   %edx
f01000ca:	e8 53 16 00 00       	call   f0101722 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cf:	e8 3d 05 00 00       	call   f0100611 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d4:	83 c4 08             	add    $0x8,%esp
f01000d7:	68 ac 1a 00 00       	push   $0x1aac
f01000dc:	8d 83 8f 08 ff ff    	lea    -0xf771(%ebx),%eax
f01000e2:	50                   	push   %eax
f01000e3:	e8 25 0a 00 00       	call   f0100b0d <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000e8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000ef:	e8 4c ff ff ff       	call   f0100040 <test_backtrace>
f01000f4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000f7:	83 ec 0c             	sub    $0xc,%esp
f01000fa:	6a 00                	push   $0x0
f01000fc:	e8 54 08 00 00       	call   f0100955 <monitor>
f0100101:	83 c4 10             	add    $0x10,%esp
f0100104:	eb f1                	jmp    f01000f7 <i386_init+0x51>

f0100106 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100106:	55                   	push   %ebp
f0100107:	89 e5                	mov    %esp,%ebp
f0100109:	57                   	push   %edi
f010010a:	56                   	push   %esi
f010010b:	53                   	push   %ebx
f010010c:	83 ec 0c             	sub    $0xc,%esp
f010010f:	e8 a8 00 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100114:	81 c3 f4 11 01 00    	add    $0x111f4,%ebx
f010011a:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f010011d:	c7 c0 a4 36 11 f0    	mov    $0xf01136a4,%eax
f0100123:	83 38 00             	cmpl   $0x0,(%eax)
f0100126:	74 0f                	je     f0100137 <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100128:	83 ec 0c             	sub    $0xc,%esp
f010012b:	6a 00                	push   $0x0
f010012d:	e8 23 08 00 00       	call   f0100955 <monitor>
f0100132:	83 c4 10             	add    $0x10,%esp
f0100135:	eb f1                	jmp    f0100128 <_panic+0x22>
	panicstr = fmt;
f0100137:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f0100139:	fa                   	cli    
f010013a:	fc                   	cld    
	va_start(ap, fmt);
f010013b:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f010013e:	83 ec 04             	sub    $0x4,%esp
f0100141:	ff 75 0c             	pushl  0xc(%ebp)
f0100144:	ff 75 08             	pushl  0x8(%ebp)
f0100147:	8d 83 aa 08 ff ff    	lea    -0xf756(%ebx),%eax
f010014d:	50                   	push   %eax
f010014e:	e8 ba 09 00 00       	call   f0100b0d <cprintf>
	vcprintf(fmt, ap);
f0100153:	83 c4 08             	add    $0x8,%esp
f0100156:	56                   	push   %esi
f0100157:	57                   	push   %edi
f0100158:	e8 79 09 00 00       	call   f0100ad6 <vcprintf>
	cprintf("\n");
f010015d:	8d 83 e6 08 ff ff    	lea    -0xf71a(%ebx),%eax
f0100163:	89 04 24             	mov    %eax,(%esp)
f0100166:	e8 a2 09 00 00       	call   f0100b0d <cprintf>
f010016b:	83 c4 10             	add    $0x10,%esp
f010016e:	eb b8                	jmp    f0100128 <_panic+0x22>

f0100170 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100170:	55                   	push   %ebp
f0100171:	89 e5                	mov    %esp,%ebp
f0100173:	56                   	push   %esi
f0100174:	53                   	push   %ebx
f0100175:	e8 42 00 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f010017a:	81 c3 8e 11 01 00    	add    $0x1118e,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100180:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100183:	83 ec 04             	sub    $0x4,%esp
f0100186:	ff 75 0c             	pushl  0xc(%ebp)
f0100189:	ff 75 08             	pushl  0x8(%ebp)
f010018c:	8d 83 c2 08 ff ff    	lea    -0xf73e(%ebx),%eax
f0100192:	50                   	push   %eax
f0100193:	e8 75 09 00 00       	call   f0100b0d <cprintf>
	vcprintf(fmt, ap);
f0100198:	83 c4 08             	add    $0x8,%esp
f010019b:	56                   	push   %esi
f010019c:	ff 75 10             	pushl  0x10(%ebp)
f010019f:	e8 32 09 00 00       	call   f0100ad6 <vcprintf>
	cprintf("\n");
f01001a4:	8d 83 e6 08 ff ff    	lea    -0xf71a(%ebx),%eax
f01001aa:	89 04 24             	mov    %eax,(%esp)
f01001ad:	e8 5b 09 00 00       	call   f0100b0d <cprintf>
	va_end(ap);
}
f01001b2:	83 c4 10             	add    $0x10,%esp
f01001b5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01001b8:	5b                   	pop    %ebx
f01001b9:	5e                   	pop    %esi
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <__x86.get_pc_thunk.bx>:
f01001bc:	8b 1c 24             	mov    (%esp),%ebx
f01001bf:	c3                   	ret    

f01001c0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001c0:	55                   	push   %ebp
f01001c1:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001c3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001c8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001c9:	a8 01                	test   $0x1,%al
f01001cb:	74 0b                	je     f01001d8 <serial_proc_data+0x18>
f01001cd:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001d2:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001d3:	0f b6 c0             	movzbl %al,%eax
}
f01001d6:	5d                   	pop    %ebp
f01001d7:	c3                   	ret    
		return -1;
f01001d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01001dd:	eb f7                	jmp    f01001d6 <serial_proc_data+0x16>

f01001df <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001df:	55                   	push   %ebp
f01001e0:	89 e5                	mov    %esp,%ebp
f01001e2:	56                   	push   %esi
f01001e3:	53                   	push   %ebx
f01001e4:	e8 d3 ff ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01001e9:	81 c3 1f 11 01 00    	add    $0x1111f,%ebx
f01001ef:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d6                	call   *%esi
f01001f3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f6:	74 2e                	je     f0100226 <cons_intr+0x47>
		if (c == 0)
f01001f8:	85 c0                	test   %eax,%eax
f01001fa:	74 f5                	je     f01001f1 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f01001fc:	8b 8b 7c 1f 00 00    	mov    0x1f7c(%ebx),%ecx
f0100202:	8d 51 01             	lea    0x1(%ecx),%edx
f0100205:	89 93 7c 1f 00 00    	mov    %edx,0x1f7c(%ebx)
f010020b:	88 84 0b 78 1d 00 00 	mov    %al,0x1d78(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f0100212:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100218:	75 d7                	jne    f01001f1 <cons_intr+0x12>
			cons.wpos = 0;
f010021a:	c7 83 7c 1f 00 00 00 	movl   $0x0,0x1f7c(%ebx)
f0100221:	00 00 00 
f0100224:	eb cb                	jmp    f01001f1 <cons_intr+0x12>
	}
}
f0100226:	5b                   	pop    %ebx
f0100227:	5e                   	pop    %esi
f0100228:	5d                   	pop    %ebp
f0100229:	c3                   	ret    

f010022a <kbd_proc_data>:
{
f010022a:	55                   	push   %ebp
f010022b:	89 e5                	mov    %esp,%ebp
f010022d:	56                   	push   %esi
f010022e:	53                   	push   %ebx
f010022f:	e8 88 ff ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100234:	81 c3 d4 10 01 00    	add    $0x110d4,%ebx
f010023a:	ba 64 00 00 00       	mov    $0x64,%edx
f010023f:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f0100240:	a8 01                	test   $0x1,%al
f0100242:	0f 84 06 01 00 00    	je     f010034e <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f0100248:	a8 20                	test   $0x20,%al
f010024a:	0f 85 05 01 00 00    	jne    f0100355 <kbd_proc_data+0x12b>
f0100250:	ba 60 00 00 00       	mov    $0x60,%edx
f0100255:	ec                   	in     (%dx),%al
f0100256:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100258:	3c e0                	cmp    $0xe0,%al
f010025a:	0f 84 93 00 00 00    	je     f01002f3 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f0100260:	84 c0                	test   %al,%al
f0100262:	0f 88 a0 00 00 00    	js     f0100308 <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f0100268:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f010026e:	f6 c1 40             	test   $0x40,%cl
f0100271:	74 0e                	je     f0100281 <kbd_proc_data+0x57>
		data |= 0x80;
f0100273:	83 c8 80             	or     $0xffffff80,%eax
f0100276:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100278:	83 e1 bf             	and    $0xffffffbf,%ecx
f010027b:	89 8b 58 1d 00 00    	mov    %ecx,0x1d58(%ebx)
	shift |= shiftcode[data];
f0100281:	0f b6 d2             	movzbl %dl,%edx
f0100284:	0f b6 84 13 18 0a ff 	movzbl -0xf5e8(%ebx,%edx,1),%eax
f010028b:	ff 
f010028c:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f0100292:	0f b6 8c 13 18 09 ff 	movzbl -0xf6e8(%ebx,%edx,1),%ecx
f0100299:	ff 
f010029a:	31 c8                	xor    %ecx,%eax
f010029c:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f01002a2:	89 c1                	mov    %eax,%ecx
f01002a4:	83 e1 03             	and    $0x3,%ecx
f01002a7:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
f01002ae:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002b2:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f01002b5:	a8 08                	test   $0x8,%al
f01002b7:	74 0d                	je     f01002c6 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f01002b9:	89 f2                	mov    %esi,%edx
f01002bb:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f01002be:	83 f9 19             	cmp    $0x19,%ecx
f01002c1:	77 7a                	ja     f010033d <kbd_proc_data+0x113>
			c += 'A' - 'a';
f01002c3:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002c6:	f7 d0                	not    %eax
f01002c8:	a8 06                	test   $0x6,%al
f01002ca:	75 33                	jne    f01002ff <kbd_proc_data+0xd5>
f01002cc:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f01002d2:	75 2b                	jne    f01002ff <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f01002d4:	83 ec 0c             	sub    $0xc,%esp
f01002d7:	8d 83 dc 08 ff ff    	lea    -0xf724(%ebx),%eax
f01002dd:	50                   	push   %eax
f01002de:	e8 2a 08 00 00       	call   f0100b0d <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002e8:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ed:	ee                   	out    %al,(%dx)
f01002ee:	83 c4 10             	add    $0x10,%esp
f01002f1:	eb 0c                	jmp    f01002ff <kbd_proc_data+0xd5>
		shift |= E0ESC;
f01002f3:	83 8b 58 1d 00 00 40 	orl    $0x40,0x1d58(%ebx)
		return 0;
f01002fa:	be 00 00 00 00       	mov    $0x0,%esi
}
f01002ff:	89 f0                	mov    %esi,%eax
f0100301:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100304:	5b                   	pop    %ebx
f0100305:	5e                   	pop    %esi
f0100306:	5d                   	pop    %ebp
f0100307:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100308:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f010030e:	89 ce                	mov    %ecx,%esi
f0100310:	83 e6 40             	and    $0x40,%esi
f0100313:	83 e0 7f             	and    $0x7f,%eax
f0100316:	85 f6                	test   %esi,%esi
f0100318:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010031b:	0f b6 d2             	movzbl %dl,%edx
f010031e:	0f b6 84 13 18 0a ff 	movzbl -0xf5e8(%ebx,%edx,1),%eax
f0100325:	ff 
f0100326:	83 c8 40             	or     $0x40,%eax
f0100329:	0f b6 c0             	movzbl %al,%eax
f010032c:	f7 d0                	not    %eax
f010032e:	21 c8                	and    %ecx,%eax
f0100330:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
		return 0;
f0100336:	be 00 00 00 00       	mov    $0x0,%esi
f010033b:	eb c2                	jmp    f01002ff <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f010033d:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100340:	8d 4e 20             	lea    0x20(%esi),%ecx
f0100343:	83 fa 1a             	cmp    $0x1a,%edx
f0100346:	0f 42 f1             	cmovb  %ecx,%esi
f0100349:	e9 78 ff ff ff       	jmp    f01002c6 <kbd_proc_data+0x9c>
		return -1;
f010034e:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100353:	eb aa                	jmp    f01002ff <kbd_proc_data+0xd5>
		return -1;
f0100355:	be ff ff ff ff       	mov    $0xffffffff,%esi
f010035a:	eb a3                	jmp    f01002ff <kbd_proc_data+0xd5>

f010035c <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010035c:	55                   	push   %ebp
f010035d:	89 e5                	mov    %esp,%ebp
f010035f:	57                   	push   %edi
f0100360:	56                   	push   %esi
f0100361:	53                   	push   %ebx
f0100362:	83 ec 1c             	sub    $0x1c,%esp
f0100365:	e8 52 fe ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f010036a:	81 c3 9e 0f 01 00    	add    $0x10f9e,%ebx
f0100370:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100373:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100378:	bf fd 03 00 00       	mov    $0x3fd,%edi
f010037d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100382:	eb 09                	jmp    f010038d <cons_putc+0x31>
f0100384:	89 ca                	mov    %ecx,%edx
f0100386:	ec                   	in     (%dx),%al
f0100387:	ec                   	in     (%dx),%al
f0100388:	ec                   	in     (%dx),%al
f0100389:	ec                   	in     (%dx),%al
	     i++)
f010038a:	83 c6 01             	add    $0x1,%esi
f010038d:	89 fa                	mov    %edi,%edx
f010038f:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100390:	a8 20                	test   $0x20,%al
f0100392:	75 08                	jne    f010039c <cons_putc+0x40>
f0100394:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010039a:	7e e8                	jle    f0100384 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f010039c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010039f:	89 f8                	mov    %edi,%eax
f01003a1:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003a4:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003a9:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003aa:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003af:	bf 79 03 00 00       	mov    $0x379,%edi
f01003b4:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003b9:	eb 09                	jmp    f01003c4 <cons_putc+0x68>
f01003bb:	89 ca                	mov    %ecx,%edx
f01003bd:	ec                   	in     (%dx),%al
f01003be:	ec                   	in     (%dx),%al
f01003bf:	ec                   	in     (%dx),%al
f01003c0:	ec                   	in     (%dx),%al
f01003c1:	83 c6 01             	add    $0x1,%esi
f01003c4:	89 fa                	mov    %edi,%edx
f01003c6:	ec                   	in     (%dx),%al
f01003c7:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003cd:	7f 04                	jg     f01003d3 <cons_putc+0x77>
f01003cf:	84 c0                	test   %al,%al
f01003d1:	79 e8                	jns    f01003bb <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003d3:	ba 78 03 00 00       	mov    $0x378,%edx
f01003d8:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f01003dc:	ee                   	out    %al,(%dx)
f01003dd:	ba 7a 03 00 00       	mov    $0x37a,%edx
f01003e2:	b8 0d 00 00 00       	mov    $0xd,%eax
f01003e7:	ee                   	out    %al,(%dx)
f01003e8:	b8 08 00 00 00       	mov    $0x8,%eax
f01003ed:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f01003ee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01003f1:	89 fa                	mov    %edi,%edx
f01003f3:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01003f9:	89 f8                	mov    %edi,%eax
f01003fb:	80 cc 07             	or     $0x7,%ah
f01003fe:	85 d2                	test   %edx,%edx
f0100400:	0f 45 c7             	cmovne %edi,%eax
f0100403:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100406:	0f b6 c0             	movzbl %al,%eax
f0100409:	83 f8 09             	cmp    $0x9,%eax
f010040c:	0f 84 b9 00 00 00    	je     f01004cb <cons_putc+0x16f>
f0100412:	83 f8 09             	cmp    $0x9,%eax
f0100415:	7e 74                	jle    f010048b <cons_putc+0x12f>
f0100417:	83 f8 0a             	cmp    $0xa,%eax
f010041a:	0f 84 9e 00 00 00    	je     f01004be <cons_putc+0x162>
f0100420:	83 f8 0d             	cmp    $0xd,%eax
f0100423:	0f 85 d9 00 00 00    	jne    f0100502 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f0100429:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f0100430:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100436:	c1 e8 16             	shr    $0x16,%eax
f0100439:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010043c:	c1 e0 04             	shl    $0x4,%eax
f010043f:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
	if (crt_pos >= CRT_SIZE) {
f0100446:	66 81 bb 80 1f 00 00 	cmpw   $0x7cf,0x1f80(%ebx)
f010044d:	cf 07 
f010044f:	0f 87 d4 00 00 00    	ja     f0100529 <cons_putc+0x1cd>
	outb(addr_6845, 14);
f0100455:	8b 8b 88 1f 00 00    	mov    0x1f88(%ebx),%ecx
f010045b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100460:	89 ca                	mov    %ecx,%edx
f0100462:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100463:	0f b7 9b 80 1f 00 00 	movzwl 0x1f80(%ebx),%ebx
f010046a:	8d 71 01             	lea    0x1(%ecx),%esi
f010046d:	89 d8                	mov    %ebx,%eax
f010046f:	66 c1 e8 08          	shr    $0x8,%ax
f0100473:	89 f2                	mov    %esi,%edx
f0100475:	ee                   	out    %al,(%dx)
f0100476:	b8 0f 00 00 00       	mov    $0xf,%eax
f010047b:	89 ca                	mov    %ecx,%edx
f010047d:	ee                   	out    %al,(%dx)
f010047e:	89 d8                	mov    %ebx,%eax
f0100480:	89 f2                	mov    %esi,%edx
f0100482:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100483:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100486:	5b                   	pop    %ebx
f0100487:	5e                   	pop    %esi
f0100488:	5f                   	pop    %edi
f0100489:	5d                   	pop    %ebp
f010048a:	c3                   	ret    
	switch (c & 0xff) {
f010048b:	83 f8 08             	cmp    $0x8,%eax
f010048e:	75 72                	jne    f0100502 <cons_putc+0x1a6>
		if (crt_pos > 0) {
f0100490:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f0100497:	66 85 c0             	test   %ax,%ax
f010049a:	74 b9                	je     f0100455 <cons_putc+0xf9>
			crt_pos--;
f010049c:	83 e8 01             	sub    $0x1,%eax
f010049f:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f01004ad:	b2 00                	mov    $0x0,%dl
f01004af:	83 ca 20             	or     $0x20,%edx
f01004b2:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f01004b8:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01004bc:	eb 88                	jmp    f0100446 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f01004be:	66 83 83 80 1f 00 00 	addw   $0x50,0x1f80(%ebx)
f01004c5:	50 
f01004c6:	e9 5e ff ff ff       	jmp    f0100429 <cons_putc+0xcd>
		cons_putc(' ');
f01004cb:	b8 20 00 00 00       	mov    $0x20,%eax
f01004d0:	e8 87 fe ff ff       	call   f010035c <cons_putc>
		cons_putc(' ');
f01004d5:	b8 20 00 00 00       	mov    $0x20,%eax
f01004da:	e8 7d fe ff ff       	call   f010035c <cons_putc>
		cons_putc(' ');
f01004df:	b8 20 00 00 00       	mov    $0x20,%eax
f01004e4:	e8 73 fe ff ff       	call   f010035c <cons_putc>
		cons_putc(' ');
f01004e9:	b8 20 00 00 00       	mov    $0x20,%eax
f01004ee:	e8 69 fe ff ff       	call   f010035c <cons_putc>
		cons_putc(' ');
f01004f3:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f8:	e8 5f fe ff ff       	call   f010035c <cons_putc>
f01004fd:	e9 44 ff ff ff       	jmp    f0100446 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100502:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f0100509:	8d 50 01             	lea    0x1(%eax),%edx
f010050c:	66 89 93 80 1f 00 00 	mov    %dx,0x1f80(%ebx)
f0100513:	0f b7 c0             	movzwl %ax,%eax
f0100516:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f010051c:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f0100520:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100524:	e9 1d ff ff ff       	jmp    f0100446 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100529:	8b 83 84 1f 00 00    	mov    0x1f84(%ebx),%eax
f010052f:	83 ec 04             	sub    $0x4,%esp
f0100532:	68 00 0f 00 00       	push   $0xf00
f0100537:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010053d:	52                   	push   %edx
f010053e:	50                   	push   %eax
f010053f:	e8 2b 12 00 00       	call   f010176f <memmove>
			crt_buf[i] = 0x0700 | ' ';
f0100544:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f010054a:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100550:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100556:	83 c4 10             	add    $0x10,%esp
f0100559:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010055e:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100561:	39 d0                	cmp    %edx,%eax
f0100563:	75 f4                	jne    f0100559 <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100565:	66 83 ab 80 1f 00 00 	subw   $0x50,0x1f80(%ebx)
f010056c:	50 
f010056d:	e9 e3 fe ff ff       	jmp    f0100455 <cons_putc+0xf9>

f0100572 <serial_intr>:
{
f0100572:	e8 e7 01 00 00       	call   f010075e <__x86.get_pc_thunk.ax>
f0100577:	05 91 0d 01 00       	add    $0x10d91,%eax
	if (serial_exists)
f010057c:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f0100583:	75 02                	jne    f0100587 <serial_intr+0x15>
f0100585:	f3 c3                	repz ret 
{
f0100587:	55                   	push   %ebp
f0100588:	89 e5                	mov    %esp,%ebp
f010058a:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f010058d:	8d 80 b8 ee fe ff    	lea    -0x11148(%eax),%eax
f0100593:	e8 47 fc ff ff       	call   f01001df <cons_intr>
}
f0100598:	c9                   	leave  
f0100599:	c3                   	ret    

f010059a <kbd_intr>:
{
f010059a:	55                   	push   %ebp
f010059b:	89 e5                	mov    %esp,%ebp
f010059d:	83 ec 08             	sub    $0x8,%esp
f01005a0:	e8 b9 01 00 00       	call   f010075e <__x86.get_pc_thunk.ax>
f01005a5:	05 63 0d 01 00       	add    $0x10d63,%eax
	cons_intr(kbd_proc_data);
f01005aa:	8d 80 22 ef fe ff    	lea    -0x110de(%eax),%eax
f01005b0:	e8 2a fc ff ff       	call   f01001df <cons_intr>
}
f01005b5:	c9                   	leave  
f01005b6:	c3                   	ret    

f01005b7 <cons_getc>:
{
f01005b7:	55                   	push   %ebp
f01005b8:	89 e5                	mov    %esp,%ebp
f01005ba:	53                   	push   %ebx
f01005bb:	83 ec 04             	sub    $0x4,%esp
f01005be:	e8 f9 fb ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01005c3:	81 c3 45 0d 01 00    	add    $0x10d45,%ebx
	serial_intr();
f01005c9:	e8 a4 ff ff ff       	call   f0100572 <serial_intr>
	kbd_intr();
f01005ce:	e8 c7 ff ff ff       	call   f010059a <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01005d3:	8b 93 78 1f 00 00    	mov    0x1f78(%ebx),%edx
	return 0;
f01005d9:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01005de:	3b 93 7c 1f 00 00    	cmp    0x1f7c(%ebx),%edx
f01005e4:	74 19                	je     f01005ff <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f01005e6:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005e9:	89 8b 78 1f 00 00    	mov    %ecx,0x1f78(%ebx)
f01005ef:	0f b6 84 13 78 1d 00 	movzbl 0x1d78(%ebx,%edx,1),%eax
f01005f6:	00 
		if (cons.rpos == CONSBUFSIZE)
f01005f7:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01005fd:	74 06                	je     f0100605 <cons_getc+0x4e>
}
f01005ff:	83 c4 04             	add    $0x4,%esp
f0100602:	5b                   	pop    %ebx
f0100603:	5d                   	pop    %ebp
f0100604:	c3                   	ret    
			cons.rpos = 0;
f0100605:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
f010060c:	00 00 00 
f010060f:	eb ee                	jmp    f01005ff <cons_getc+0x48>

f0100611 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100611:	55                   	push   %ebp
f0100612:	89 e5                	mov    %esp,%ebp
f0100614:	57                   	push   %edi
f0100615:	56                   	push   %esi
f0100616:	53                   	push   %ebx
f0100617:	83 ec 1c             	sub    $0x1c,%esp
f010061a:	e8 9d fb ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f010061f:	81 c3 e9 0c 01 00    	add    $0x10ce9,%ebx
	was = *cp;
f0100625:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010062c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100633:	5a a5 
	if (*cp != 0xA55A) {
f0100635:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010063c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100640:	0f 84 bc 00 00 00    	je     f0100702 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f0100646:	c7 83 88 1f 00 00 b4 	movl   $0x3b4,0x1f88(%ebx)
f010064d:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100650:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100657:	8b bb 88 1f 00 00    	mov    0x1f88(%ebx),%edi
f010065d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100662:	89 fa                	mov    %edi,%edx
f0100664:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100665:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100668:	89 ca                	mov    %ecx,%edx
f010066a:	ec                   	in     (%dx),%al
f010066b:	0f b6 f0             	movzbl %al,%esi
f010066e:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100671:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100676:	89 fa                	mov    %edi,%edx
f0100678:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100679:	89 ca                	mov    %ecx,%edx
f010067b:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010067c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010067f:	89 bb 84 1f 00 00    	mov    %edi,0x1f84(%ebx)
	pos |= inb(addr_6845 + 1);
f0100685:	0f b6 c0             	movzbl %al,%eax
f0100688:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010068a:	66 89 b3 80 1f 00 00 	mov    %si,0x1f80(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100691:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100696:	89 c8                	mov    %ecx,%eax
f0100698:	ba fa 03 00 00       	mov    $0x3fa,%edx
f010069d:	ee                   	out    %al,(%dx)
f010069e:	bf fb 03 00 00       	mov    $0x3fb,%edi
f01006a3:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006a8:	89 fa                	mov    %edi,%edx
f01006aa:	ee                   	out    %al,(%dx)
f01006ab:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006b0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006b5:	ee                   	out    %al,(%dx)
f01006b6:	be f9 03 00 00       	mov    $0x3f9,%esi
f01006bb:	89 c8                	mov    %ecx,%eax
f01006bd:	89 f2                	mov    %esi,%edx
f01006bf:	ee                   	out    %al,(%dx)
f01006c0:	b8 03 00 00 00       	mov    $0x3,%eax
f01006c5:	89 fa                	mov    %edi,%edx
f01006c7:	ee                   	out    %al,(%dx)
f01006c8:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006cd:	89 c8                	mov    %ecx,%eax
f01006cf:	ee                   	out    %al,(%dx)
f01006d0:	b8 01 00 00 00       	mov    $0x1,%eax
f01006d5:	89 f2                	mov    %esi,%edx
f01006d7:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006d8:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01006dd:	ec                   	in     (%dx),%al
f01006de:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01006e0:	3c ff                	cmp    $0xff,%al
f01006e2:	0f 95 83 8c 1f 00 00 	setne  0x1f8c(%ebx)
f01006e9:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01006ee:	ec                   	in     (%dx),%al
f01006ef:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006f4:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006f5:	80 f9 ff             	cmp    $0xff,%cl
f01006f8:	74 25                	je     f010071f <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f01006fa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006fd:	5b                   	pop    %ebx
f01006fe:	5e                   	pop    %esi
f01006ff:	5f                   	pop    %edi
f0100700:	5d                   	pop    %ebp
f0100701:	c3                   	ret    
		*cp = was;
f0100702:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100709:	c7 83 88 1f 00 00 d4 	movl   $0x3d4,0x1f88(%ebx)
f0100710:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100713:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f010071a:	e9 38 ff ff ff       	jmp    f0100657 <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f010071f:	83 ec 0c             	sub    $0xc,%esp
f0100722:	8d 83 e8 08 ff ff    	lea    -0xf718(%ebx),%eax
f0100728:	50                   	push   %eax
f0100729:	e8 df 03 00 00       	call   f0100b0d <cprintf>
f010072e:	83 c4 10             	add    $0x10,%esp
}
f0100731:	eb c7                	jmp    f01006fa <cons_init+0xe9>

f0100733 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100733:	55                   	push   %ebp
f0100734:	89 e5                	mov    %esp,%ebp
f0100736:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100739:	8b 45 08             	mov    0x8(%ebp),%eax
f010073c:	e8 1b fc ff ff       	call   f010035c <cons_putc>
}
f0100741:	c9                   	leave  
f0100742:	c3                   	ret    

f0100743 <getchar>:

int
getchar(void)
{
f0100743:	55                   	push   %ebp
f0100744:	89 e5                	mov    %esp,%ebp
f0100746:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100749:	e8 69 fe ff ff       	call   f01005b7 <cons_getc>
f010074e:	85 c0                	test   %eax,%eax
f0100750:	74 f7                	je     f0100749 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100752:	c9                   	leave  
f0100753:	c3                   	ret    

f0100754 <iscons>:

int
iscons(int fdnum)
{
f0100754:	55                   	push   %ebp
f0100755:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100757:	b8 01 00 00 00       	mov    $0x1,%eax
f010075c:	5d                   	pop    %ebp
f010075d:	c3                   	ret    

f010075e <__x86.get_pc_thunk.ax>:
f010075e:	8b 04 24             	mov    (%esp),%eax
f0100761:	c3                   	ret    

f0100762 <mon_help>:
};

/***** Implementations of basic kernel monitor commands *****/

int mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100762:	55                   	push   %ebp
f0100763:	89 e5                	mov    %esp,%ebp
f0100765:	56                   	push   %esi
f0100766:	53                   	push   %ebx
f0100767:	e8 50 fa ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f010076c:	81 c3 9c 0b 01 00    	add    $0x10b9c,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100772:	83 ec 04             	sub    $0x4,%esp
f0100775:	8d 83 18 0b ff ff    	lea    -0xf4e8(%ebx),%eax
f010077b:	50                   	push   %eax
f010077c:	8d 83 36 0b ff ff    	lea    -0xf4ca(%ebx),%eax
f0100782:	50                   	push   %eax
f0100783:	8d b3 3b 0b ff ff    	lea    -0xf4c5(%ebx),%esi
f0100789:	56                   	push   %esi
f010078a:	e8 7e 03 00 00       	call   f0100b0d <cprintf>
f010078f:	83 c4 0c             	add    $0xc,%esp
f0100792:	8d 83 e8 0b ff ff    	lea    -0xf418(%ebx),%eax
f0100798:	50                   	push   %eax
f0100799:	8d 83 44 0b ff ff    	lea    -0xf4bc(%ebx),%eax
f010079f:	50                   	push   %eax
f01007a0:	56                   	push   %esi
f01007a1:	e8 67 03 00 00       	call   f0100b0d <cprintf>
f01007a6:	83 c4 0c             	add    $0xc,%esp
f01007a9:	8d 83 4d 0b ff ff    	lea    -0xf4b3(%ebx),%eax
f01007af:	50                   	push   %eax
f01007b0:	8d 83 64 0b ff ff    	lea    -0xf49c(%ebx),%eax
f01007b6:	50                   	push   %eax
f01007b7:	56                   	push   %esi
f01007b8:	e8 50 03 00 00       	call   f0100b0d <cprintf>
	return 0;
}
f01007bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01007c2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007c5:	5b                   	pop    %ebx
f01007c6:	5e                   	pop    %esi
f01007c7:	5d                   	pop    %ebp
f01007c8:	c3                   	ret    

f01007c9 <mon_kerninfo>:

int mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007c9:	55                   	push   %ebp
f01007ca:	89 e5                	mov    %esp,%ebp
f01007cc:	57                   	push   %edi
f01007cd:	56                   	push   %esi
f01007ce:	53                   	push   %ebx
f01007cf:	83 ec 18             	sub    $0x18,%esp
f01007d2:	e8 e5 f9 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01007d7:	81 c3 31 0b 01 00    	add    $0x10b31,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007dd:	8d 83 6e 0b ff ff    	lea    -0xf492(%ebx),%eax
f01007e3:	50                   	push   %eax
f01007e4:	e8 24 03 00 00       	call   f0100b0d <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007e9:	83 c4 08             	add    $0x8,%esp
f01007ec:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01007f2:	8d 83 10 0c ff ff    	lea    -0xf3f0(%ebx),%eax
f01007f8:	50                   	push   %eax
f01007f9:	e8 0f 03 00 00       	call   f0100b0d <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007fe:	83 c4 0c             	add    $0xc,%esp
f0100801:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100807:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f010080d:	50                   	push   %eax
f010080e:	57                   	push   %edi
f010080f:	8d 83 38 0c ff ff    	lea    -0xf3c8(%ebx),%eax
f0100815:	50                   	push   %eax
f0100816:	e8 f2 02 00 00       	call   f0100b0d <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010081b:	83 c4 0c             	add    $0xc,%esp
f010081e:	c7 c0 59 1b 10 f0    	mov    $0xf0101b59,%eax
f0100824:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010082a:	52                   	push   %edx
f010082b:	50                   	push   %eax
f010082c:	8d 83 5c 0c ff ff    	lea    -0xf3a4(%ebx),%eax
f0100832:	50                   	push   %eax
f0100833:	e8 d5 02 00 00       	call   f0100b0d <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100838:	83 c4 0c             	add    $0xc,%esp
f010083b:	c7 c0 60 30 11 f0    	mov    $0xf0113060,%eax
f0100841:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100847:	52                   	push   %edx
f0100848:	50                   	push   %eax
f0100849:	8d 83 80 0c ff ff    	lea    -0xf380(%ebx),%eax
f010084f:	50                   	push   %eax
f0100850:	e8 b8 02 00 00       	call   f0100b0d <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100855:	83 c4 0c             	add    $0xc,%esp
f0100858:	c7 c6 a0 36 11 f0    	mov    $0xf01136a0,%esi
f010085e:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0100864:	50                   	push   %eax
f0100865:	56                   	push   %esi
f0100866:	8d 83 a4 0c ff ff    	lea    -0xf35c(%ebx),%eax
f010086c:	50                   	push   %eax
f010086d:	e8 9b 02 00 00       	call   f0100b0d <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100872:	83 c4 08             	add    $0x8,%esp
			ROUNDUP(end - entry, 1024) / 1024);
f0100875:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010087b:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f010087d:	c1 fe 0a             	sar    $0xa,%esi
f0100880:	56                   	push   %esi
f0100881:	8d 83 c8 0c ff ff    	lea    -0xf338(%ebx),%eax
f0100887:	50                   	push   %eax
f0100888:	e8 80 02 00 00       	call   f0100b0d <cprintf>
	return 0;
}
f010088d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100892:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100895:	5b                   	pop    %ebx
f0100896:	5e                   	pop    %esi
f0100897:	5f                   	pop    %edi
f0100898:	5d                   	pop    %ebp
f0100899:	c3                   	ret    

f010089a <mon_backtrace>:

int mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010089a:	55                   	push   %ebp
f010089b:	89 e5                	mov    %esp,%ebp
f010089d:	57                   	push   %edi
f010089e:	56                   	push   %esi
f010089f:	53                   	push   %ebx
f01008a0:	83 ec 48             	sub    $0x48,%esp
f01008a3:	e8 14 f9 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01008a8:	81 c3 60 0a 01 00    	add    $0x10a60,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008ae:	89 ee                	mov    %ebp,%esi
	// 利用 ebp 的初始值0判断是否停止
	// 利用数组指针运算来获取 eip 以及 args
	uint32_t ebp, eip, *ptr_ebp;
	struct Eipdebuginfo info;
	ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f01008b0:	8d 83 87 0b ff ff    	lea    -0xf479(%ebx),%eax
f01008b6:	50                   	push   %eax
f01008b7:	e8 51 02 00 00       	call   f0100b0d <cprintf>
	while (ebp != 0)
f01008bc:	83 c4 10             	add    $0x10,%esp
	{
		ptr_ebp = (uint32_t *)ebp;
		eip = ptr_ebp[1];

		cprintf("ebp %x  eip %x  args %08x %08x %08x %08x %08x\n",
f01008bf:	8d 83 f4 0c ff ff    	lea    -0xf30c(%ebx),%eax
f01008c5:	89 45 c4             	mov    %eax,-0x3c(%ebp)
				ebp, eip, ptr_ebp[2], ptr_ebp[3], ptr_ebp[4], ptr_ebp[5], ptr_ebp[6]);

		int ret = debuginfo_eip(eip, &info);
f01008c8:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008cb:	89 45 c0             	mov    %eax,-0x40(%ebp)
f01008ce:	89 f0                	mov    %esi,%eax
	while (ebp != 0)
f01008d0:	eb 02                	jmp    f01008d4 <mon_backtrace+0x3a>
		if (ret == 0){
			cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
			cprintf("%s:%d: %.*s+%d\n",
					info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
		}
		ebp = ptr_ebp[0];
f01008d2:	8b 06                	mov    (%esi),%eax
	while (ebp != 0)
f01008d4:	85 c0                	test   %eax,%eax
f01008d6:	74 75                	je     f010094d <mon_backtrace+0xb3>
		ptr_ebp = (uint32_t *)ebp;
f01008d8:	89 c6                	mov    %eax,%esi
		eip = ptr_ebp[1];
f01008da:	8b 78 04             	mov    0x4(%eax),%edi
		cprintf("ebp %x  eip %x  args %08x %08x %08x %08x %08x\n",
f01008dd:	ff 70 18             	pushl  0x18(%eax)
f01008e0:	ff 70 14             	pushl  0x14(%eax)
f01008e3:	ff 70 10             	pushl  0x10(%eax)
f01008e6:	ff 70 0c             	pushl  0xc(%eax)
f01008e9:	ff 70 08             	pushl  0x8(%eax)
f01008ec:	57                   	push   %edi
f01008ed:	50                   	push   %eax
f01008ee:	ff 75 c4             	pushl  -0x3c(%ebp)
f01008f1:	e8 17 02 00 00       	call   f0100b0d <cprintf>
		int ret = debuginfo_eip(eip, &info);
f01008f6:	83 c4 18             	add    $0x18,%esp
f01008f9:	ff 75 c0             	pushl  -0x40(%ebp)
f01008fc:	57                   	push   %edi
f01008fd:	e8 0f 03 00 00       	call   f0100c11 <debuginfo_eip>
		if (ret == 0){
f0100902:	83 c4 10             	add    $0x10,%esp
f0100905:	85 c0                	test   %eax,%eax
f0100907:	75 c9                	jne    f01008d2 <mon_backtrace+0x38>
			cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
f0100909:	83 ec 08             	sub    $0x8,%esp
f010090c:	89 f8                	mov    %edi,%eax
f010090e:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100911:	50                   	push   %eax
f0100912:	ff 75 d8             	pushl  -0x28(%ebp)
f0100915:	ff 75 dc             	pushl  -0x24(%ebp)
f0100918:	ff 75 d4             	pushl  -0x2c(%ebp)
f010091b:	ff 75 d0             	pushl  -0x30(%ebp)
f010091e:	8d 83 99 0b ff ff    	lea    -0xf467(%ebx),%eax
f0100924:	89 45 bc             	mov    %eax,-0x44(%ebp)
f0100927:	50                   	push   %eax
f0100928:	e8 e0 01 00 00       	call   f0100b0d <cprintf>
			cprintf("%s:%d: %.*s+%d\n",
f010092d:	83 c4 18             	add    $0x18,%esp
f0100930:	2b 7d e0             	sub    -0x20(%ebp),%edi
f0100933:	57                   	push   %edi
f0100934:	ff 75 d8             	pushl  -0x28(%ebp)
f0100937:	ff 75 dc             	pushl  -0x24(%ebp)
f010093a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010093d:	ff 75 d0             	pushl  -0x30(%ebp)
f0100940:	ff 75 bc             	pushl  -0x44(%ebp)
f0100943:	e8 c5 01 00 00       	call   f0100b0d <cprintf>
f0100948:	83 c4 20             	add    $0x20,%esp
f010094b:	eb 85                	jmp    f01008d2 <mon_backtrace+0x38>
	}
	return 0;
}
f010094d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100950:	5b                   	pop    %ebx
f0100951:	5e                   	pop    %esi
f0100952:	5f                   	pop    %edi
f0100953:	5d                   	pop    %ebp
f0100954:	c3                   	ret    

f0100955 <monitor>:
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void monitor(struct Trapframe *tf)
{
f0100955:	55                   	push   %ebp
f0100956:	89 e5                	mov    %esp,%ebp
f0100958:	57                   	push   %edi
f0100959:	56                   	push   %esi
f010095a:	53                   	push   %ebx
f010095b:	83 ec 68             	sub    $0x68,%esp
f010095e:	e8 59 f8 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100963:	81 c3 a5 09 01 00    	add    $0x109a5,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100969:	8d 83 24 0d ff ff    	lea    -0xf2dc(%ebx),%eax
f010096f:	50                   	push   %eax
f0100970:	e8 98 01 00 00       	call   f0100b0d <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100975:	8d 83 48 0d ff ff    	lea    -0xf2b8(%ebx),%eax
f010097b:	89 04 24             	mov    %eax,(%esp)
f010097e:	e8 8a 01 00 00       	call   f0100b0d <cprintf>
f0100983:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100986:	8d bb ad 0b ff ff    	lea    -0xf453(%ebx),%edi
f010098c:	eb 4a                	jmp    f01009d8 <monitor+0x83>
f010098e:	83 ec 08             	sub    $0x8,%esp
f0100991:	0f be c0             	movsbl %al,%eax
f0100994:	50                   	push   %eax
f0100995:	57                   	push   %edi
f0100996:	e8 4a 0d 00 00       	call   f01016e5 <strchr>
f010099b:	83 c4 10             	add    $0x10,%esp
f010099e:	85 c0                	test   %eax,%eax
f01009a0:	74 08                	je     f01009aa <monitor+0x55>
			*buf++ = 0;
f01009a2:	c6 06 00             	movb   $0x0,(%esi)
f01009a5:	8d 76 01             	lea    0x1(%esi),%esi
f01009a8:	eb 79                	jmp    f0100a23 <monitor+0xce>
		if (*buf == 0)
f01009aa:	80 3e 00             	cmpb   $0x0,(%esi)
f01009ad:	74 7f                	je     f0100a2e <monitor+0xd9>
		if (argc == MAXARGS - 1)
f01009af:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f01009b3:	74 0f                	je     f01009c4 <monitor+0x6f>
		argv[argc++] = buf;
f01009b5:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009b8:	8d 48 01             	lea    0x1(%eax),%ecx
f01009bb:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f01009be:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f01009c2:	eb 44                	jmp    f0100a08 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009c4:	83 ec 08             	sub    $0x8,%esp
f01009c7:	6a 10                	push   $0x10
f01009c9:	8d 83 b2 0b ff ff    	lea    -0xf44e(%ebx),%eax
f01009cf:	50                   	push   %eax
f01009d0:	e8 38 01 00 00       	call   f0100b0d <cprintf>
f01009d5:	83 c4 10             	add    $0x10,%esp

	while (1)
	{
		buf = readline("K> ");
f01009d8:	8d 83 a9 0b ff ff    	lea    -0xf457(%ebx),%eax
f01009de:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01009e1:	83 ec 0c             	sub    $0xc,%esp
f01009e4:	ff 75 a4             	pushl  -0x5c(%ebp)
f01009e7:	e8 c1 0a 00 00       	call   f01014ad <readline>
f01009ec:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01009ee:	83 c4 10             	add    $0x10,%esp
f01009f1:	85 c0                	test   %eax,%eax
f01009f3:	74 ec                	je     f01009e1 <monitor+0x8c>
	argv[argc] = 0;
f01009f5:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01009fc:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100a03:	eb 1e                	jmp    f0100a23 <monitor+0xce>
			buf++;
f0100a05:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a08:	0f b6 06             	movzbl (%esi),%eax
f0100a0b:	84 c0                	test   %al,%al
f0100a0d:	74 14                	je     f0100a23 <monitor+0xce>
f0100a0f:	83 ec 08             	sub    $0x8,%esp
f0100a12:	0f be c0             	movsbl %al,%eax
f0100a15:	50                   	push   %eax
f0100a16:	57                   	push   %edi
f0100a17:	e8 c9 0c 00 00       	call   f01016e5 <strchr>
f0100a1c:	83 c4 10             	add    $0x10,%esp
f0100a1f:	85 c0                	test   %eax,%eax
f0100a21:	74 e2                	je     f0100a05 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f0100a23:	0f b6 06             	movzbl (%esi),%eax
f0100a26:	84 c0                	test   %al,%al
f0100a28:	0f 85 60 ff ff ff    	jne    f010098e <monitor+0x39>
	argv[argc] = 0;
f0100a2e:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100a31:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100a38:	00 
	if (argc == 0)
f0100a39:	85 c0                	test   %eax,%eax
f0100a3b:	74 9b                	je     f01009d8 <monitor+0x83>
f0100a3d:	8d b3 18 1d 00 00    	lea    0x1d18(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++)
f0100a43:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a4a:	83 ec 08             	sub    $0x8,%esp
f0100a4d:	ff 36                	pushl  (%esi)
f0100a4f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a52:	e8 30 0c 00 00       	call   f0101687 <strcmp>
f0100a57:	83 c4 10             	add    $0x10,%esp
f0100a5a:	85 c0                	test   %eax,%eax
f0100a5c:	74 29                	je     f0100a87 <monitor+0x132>
	for (i = 0; i < ARRAY_SIZE(commands); i++)
f0100a5e:	83 45 a0 01          	addl   $0x1,-0x60(%ebp)
f0100a62:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100a65:	83 c6 0c             	add    $0xc,%esi
f0100a68:	83 f8 03             	cmp    $0x3,%eax
f0100a6b:	75 dd                	jne    f0100a4a <monitor+0xf5>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a6d:	83 ec 08             	sub    $0x8,%esp
f0100a70:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a73:	8d 83 cf 0b ff ff    	lea    -0xf431(%ebx),%eax
f0100a79:	50                   	push   %eax
f0100a7a:	e8 8e 00 00 00       	call   f0100b0d <cprintf>
f0100a7f:	83 c4 10             	add    $0x10,%esp
f0100a82:	e9 51 ff ff ff       	jmp    f01009d8 <monitor+0x83>
			return commands[i].func(argc, argv, tf);
f0100a87:	83 ec 04             	sub    $0x4,%esp
f0100a8a:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100a8d:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a90:	ff 75 08             	pushl  0x8(%ebp)
f0100a93:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a96:	52                   	push   %edx
f0100a97:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100a9a:	ff 94 83 20 1d 00 00 	call   *0x1d20(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100aa1:	83 c4 10             	add    $0x10,%esp
f0100aa4:	85 c0                	test   %eax,%eax
f0100aa6:	0f 89 2c ff ff ff    	jns    f01009d8 <monitor+0x83>
				break;
	}
}
f0100aac:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100aaf:	5b                   	pop    %ebx
f0100ab0:	5e                   	pop    %esi
f0100ab1:	5f                   	pop    %edi
f0100ab2:	5d                   	pop    %ebp
f0100ab3:	c3                   	ret    

f0100ab4 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100ab4:	55                   	push   %ebp
f0100ab5:	89 e5                	mov    %esp,%ebp
f0100ab7:	53                   	push   %ebx
f0100ab8:	83 ec 10             	sub    $0x10,%esp
f0100abb:	e8 fc f6 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100ac0:	81 c3 48 08 01 00    	add    $0x10848,%ebx
	cputchar(ch);
f0100ac6:	ff 75 08             	pushl  0x8(%ebp)
f0100ac9:	e8 65 fc ff ff       	call   f0100733 <cputchar>
	*cnt++;
}
f0100ace:	83 c4 10             	add    $0x10,%esp
f0100ad1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ad4:	c9                   	leave  
f0100ad5:	c3                   	ret    

f0100ad6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100ad6:	55                   	push   %ebp
f0100ad7:	89 e5                	mov    %esp,%ebp
f0100ad9:	53                   	push   %ebx
f0100ada:	83 ec 14             	sub    $0x14,%esp
f0100add:	e8 da f6 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100ae2:	81 c3 26 08 01 00    	add    $0x10826,%ebx
	int cnt = 0;
f0100ae8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100aef:	ff 75 0c             	pushl  0xc(%ebp)
f0100af2:	ff 75 08             	pushl  0x8(%ebp)
f0100af5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100af8:	50                   	push   %eax
f0100af9:	8d 83 ac f7 fe ff    	lea    -0x10854(%ebx),%eax
f0100aff:	50                   	push   %eax
f0100b00:	e8 98 04 00 00       	call   f0100f9d <vprintfmt>
	return cnt;
}
f0100b05:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b08:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b0b:	c9                   	leave  
f0100b0c:	c3                   	ret    

f0100b0d <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100b0d:	55                   	push   %ebp
f0100b0e:	89 e5                	mov    %esp,%ebp
f0100b10:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100b13:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100b16:	50                   	push   %eax
f0100b17:	ff 75 08             	pushl  0x8(%ebp)
f0100b1a:	e8 b7 ff ff ff       	call   f0100ad6 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100b1f:	c9                   	leave  
f0100b20:	c3                   	ret    

f0100b21 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100b21:	55                   	push   %ebp
f0100b22:	89 e5                	mov    %esp,%ebp
f0100b24:	57                   	push   %edi
f0100b25:	56                   	push   %esi
f0100b26:	53                   	push   %ebx
f0100b27:	83 ec 14             	sub    $0x14,%esp
f0100b2a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100b2d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100b30:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100b33:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100b36:	8b 32                	mov    (%edx),%esi
f0100b38:	8b 01                	mov    (%ecx),%eax
f0100b3a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b3d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100b44:	eb 2f                	jmp    f0100b75 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100b46:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100b49:	39 c6                	cmp    %eax,%esi
f0100b4b:	7f 49                	jg     f0100b96 <stab_binsearch+0x75>
f0100b4d:	0f b6 0a             	movzbl (%edx),%ecx
f0100b50:	83 ea 0c             	sub    $0xc,%edx
f0100b53:	39 f9                	cmp    %edi,%ecx
f0100b55:	75 ef                	jne    f0100b46 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b57:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b5a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100b5d:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100b61:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b64:	73 35                	jae    f0100b9b <stab_binsearch+0x7a>
			*region_left = m;
f0100b66:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b69:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0100b6b:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0100b6e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100b75:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100b78:	7f 4e                	jg     f0100bc8 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100b7a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100b7d:	01 f0                	add    %esi,%eax
f0100b7f:	89 c3                	mov    %eax,%ebx
f0100b81:	c1 eb 1f             	shr    $0x1f,%ebx
f0100b84:	01 c3                	add    %eax,%ebx
f0100b86:	d1 fb                	sar    %ebx
f0100b88:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b8b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100b8e:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100b92:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100b94:	eb b3                	jmp    f0100b49 <stab_binsearch+0x28>
			l = true_m + 1;
f0100b96:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100b99:	eb da                	jmp    f0100b75 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100b9b:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b9e:	76 14                	jbe    f0100bb4 <stab_binsearch+0x93>
			*region_right = m - 1;
f0100ba0:	83 e8 01             	sub    $0x1,%eax
f0100ba3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100ba6:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100ba9:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0100bab:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100bb2:	eb c1                	jmp    f0100b75 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100bb4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100bb7:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100bb9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100bbd:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100bbf:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100bc6:	eb ad                	jmp    f0100b75 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100bc8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100bcc:	74 16                	je     f0100be4 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100bce:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bd1:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100bd3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100bd6:	8b 0e                	mov    (%esi),%ecx
f0100bd8:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100bdb:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100bde:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100be2:	eb 12                	jmp    f0100bf6 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100be4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100be7:	8b 00                	mov    (%eax),%eax
f0100be9:	83 e8 01             	sub    $0x1,%eax
f0100bec:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100bef:	89 07                	mov    %eax,(%edi)
f0100bf1:	eb 16                	jmp    f0100c09 <stab_binsearch+0xe8>
		     l--)
f0100bf3:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100bf6:	39 c1                	cmp    %eax,%ecx
f0100bf8:	7d 0a                	jge    f0100c04 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0100bfa:	0f b6 1a             	movzbl (%edx),%ebx
f0100bfd:	83 ea 0c             	sub    $0xc,%edx
f0100c00:	39 fb                	cmp    %edi,%ebx
f0100c02:	75 ef                	jne    f0100bf3 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0100c04:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c07:	89 07                	mov    %eax,(%edi)
	}
}
f0100c09:	83 c4 14             	add    $0x14,%esp
f0100c0c:	5b                   	pop    %ebx
f0100c0d:	5e                   	pop    %esi
f0100c0e:	5f                   	pop    %edi
f0100c0f:	5d                   	pop    %ebp
f0100c10:	c3                   	ret    

f0100c11 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100c11:	55                   	push   %ebp
f0100c12:	89 e5                	mov    %esp,%ebp
f0100c14:	57                   	push   %edi
f0100c15:	56                   	push   %esi
f0100c16:	53                   	push   %ebx
f0100c17:	83 ec 3c             	sub    $0x3c,%esp
f0100c1a:	e8 9d f5 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100c1f:	81 c3 e9 06 01 00    	add    $0x106e9,%ebx
f0100c25:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100c28:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100c2b:	8d 83 70 0d ff ff    	lea    -0xf290(%ebx),%eax
f0100c31:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0100c33:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100c3a:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100c3d:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100c44:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100c47:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100c4e:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100c54:	0f 86 37 01 00 00    	jbe    f0100d91 <debuginfo_eip+0x180>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c5a:	c7 c0 51 60 10 f0    	mov    $0xf0106051,%eax
f0100c60:	39 83 fc ff ff ff    	cmp    %eax,-0x4(%ebx)
f0100c66:	0f 86 04 02 00 00    	jbe    f0100e70 <debuginfo_eip+0x25f>
f0100c6c:	c7 c0 f3 79 10 f0    	mov    $0xf01079f3,%eax
f0100c72:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100c76:	0f 85 fb 01 00 00    	jne    f0100e77 <debuginfo_eip+0x266>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100c7c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100c83:	c7 c0 94 22 10 f0    	mov    $0xf0102294,%eax
f0100c89:	c7 c2 50 60 10 f0    	mov    $0xf0106050,%edx
f0100c8f:	29 c2                	sub    %eax,%edx
f0100c91:	c1 fa 02             	sar    $0x2,%edx
f0100c94:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100c9a:	83 ea 01             	sub    $0x1,%edx
f0100c9d:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100ca0:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ca3:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ca6:	83 ec 08             	sub    $0x8,%esp
f0100ca9:	57                   	push   %edi
f0100caa:	6a 64                	push   $0x64
f0100cac:	e8 70 fe ff ff       	call   f0100b21 <stab_binsearch>
	if (lfile == 0)
f0100cb1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cb4:	83 c4 10             	add    $0x10,%esp
f0100cb7:	85 c0                	test   %eax,%eax
f0100cb9:	0f 84 bf 01 00 00    	je     f0100e7e <debuginfo_eip+0x26d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100cbf:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100cc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cc5:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100cc8:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100ccb:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100cce:	83 ec 08             	sub    $0x8,%esp
f0100cd1:	57                   	push   %edi
f0100cd2:	6a 24                	push   $0x24
f0100cd4:	c7 c0 94 22 10 f0    	mov    $0xf0102294,%eax
f0100cda:	e8 42 fe ff ff       	call   f0100b21 <stab_binsearch>

	if (lfun <= rfun) {
f0100cdf:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ce2:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0100ce5:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0100ce8:	83 c4 10             	add    $0x10,%esp
f0100ceb:	39 c8                	cmp    %ecx,%eax
f0100ced:	0f 8f b6 00 00 00    	jg     f0100da9 <debuginfo_eip+0x198>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100cf3:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100cf6:	c7 c1 94 22 10 f0    	mov    $0xf0102294,%ecx
f0100cfc:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0100cff:	8b 11                	mov    (%ecx),%edx
f0100d01:	89 55 c0             	mov    %edx,-0x40(%ebp)
f0100d04:	c7 c2 f3 79 10 f0    	mov    $0xf01079f3,%edx
f0100d0a:	81 ea 51 60 10 f0    	sub    $0xf0106051,%edx
f0100d10:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f0100d13:	73 0c                	jae    f0100d21 <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100d15:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0100d18:	81 c2 51 60 10 f0    	add    $0xf0106051,%edx
f0100d1e:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100d21:	8b 51 08             	mov    0x8(%ecx),%edx
f0100d24:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0100d27:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0100d29:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100d2c:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100d2f:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100d32:	83 ec 08             	sub    $0x8,%esp
f0100d35:	6a 3a                	push   $0x3a
f0100d37:	ff 76 08             	pushl  0x8(%esi)
f0100d3a:	e8 c7 09 00 00       	call   f0101706 <strfind>
f0100d3f:	2b 46 08             	sub    0x8(%esi),%eax
f0100d42:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100d45:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100d48:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100d4b:	83 c4 08             	add    $0x8,%esp
f0100d4e:	57                   	push   %edi
f0100d4f:	6a 44                	push   $0x44
f0100d51:	c7 c0 94 22 10 f0    	mov    $0xf0102294,%eax
f0100d57:	e8 c5 fd ff ff       	call   f0100b21 <stab_binsearch>
    if (lline <= rline) {
f0100d5c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100d5f:	83 c4 10             	add    $0x10,%esp
f0100d62:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100d65:	0f 8f 1a 01 00 00    	jg     f0100e85 <debuginfo_eip+0x274>
        info->eip_line = stabs[lline].n_desc;
f0100d6b:	89 d0                	mov    %edx,%eax
f0100d6d:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100d70:	c1 e2 02             	shl    $0x2,%edx
f0100d73:	c7 c1 94 22 10 f0    	mov    $0xf0102294,%ecx
f0100d79:	0f b7 7c 0a 06       	movzwl 0x6(%edx,%ecx,1),%edi
f0100d7e:	89 7e 04             	mov    %edi,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d81:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d84:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f0100d88:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0100d8c:	89 75 0c             	mov    %esi,0xc(%ebp)
f0100d8f:	eb 36                	jmp    f0100dc7 <debuginfo_eip+0x1b6>
  	        panic("User address");
f0100d91:	83 ec 04             	sub    $0x4,%esp
f0100d94:	8d 83 7a 0d ff ff    	lea    -0xf286(%ebx),%eax
f0100d9a:	50                   	push   %eax
f0100d9b:	6a 7f                	push   $0x7f
f0100d9d:	8d 83 87 0d ff ff    	lea    -0xf279(%ebx),%eax
f0100da3:	50                   	push   %eax
f0100da4:	e8 5d f3 ff ff       	call   f0100106 <_panic>
		info->eip_fn_addr = addr;
f0100da9:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100dac:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100daf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100db2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100db5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100db8:	e9 75 ff ff ff       	jmp    f0100d32 <debuginfo_eip+0x121>
f0100dbd:	83 e8 01             	sub    $0x1,%eax
f0100dc0:	83 ea 0c             	sub    $0xc,%edx
f0100dc3:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0100dc7:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f0100dca:	39 c7                	cmp    %eax,%edi
f0100dcc:	7f 24                	jg     f0100df2 <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f0100dce:	0f b6 0a             	movzbl (%edx),%ecx
f0100dd1:	80 f9 84             	cmp    $0x84,%cl
f0100dd4:	74 46                	je     f0100e1c <debuginfo_eip+0x20b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100dd6:	80 f9 64             	cmp    $0x64,%cl
f0100dd9:	75 e2                	jne    f0100dbd <debuginfo_eip+0x1ac>
f0100ddb:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0100ddf:	74 dc                	je     f0100dbd <debuginfo_eip+0x1ac>
f0100de1:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100de4:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0100de8:	74 3b                	je     f0100e25 <debuginfo_eip+0x214>
f0100dea:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100ded:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100df0:	eb 33                	jmp    f0100e25 <debuginfo_eip+0x214>
f0100df2:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100df5:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100df8:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100dfb:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100e00:	39 fa                	cmp    %edi,%edx
f0100e02:	0f 8d 89 00 00 00    	jge    f0100e91 <debuginfo_eip+0x280>
		for (lline = lfun + 1;
f0100e08:	83 c2 01             	add    $0x1,%edx
f0100e0b:	89 d0                	mov    %edx,%eax
f0100e0d:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f0100e10:	c7 c2 94 22 10 f0    	mov    $0xf0102294,%edx
f0100e16:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f0100e1a:	eb 3b                	jmp    f0100e57 <debuginfo_eip+0x246>
f0100e1c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100e1f:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0100e23:	75 26                	jne    f0100e4b <debuginfo_eip+0x23a>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100e25:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100e28:	c7 c0 94 22 10 f0    	mov    $0xf0102294,%eax
f0100e2e:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100e31:	c7 c0 f3 79 10 f0    	mov    $0xf01079f3,%eax
f0100e37:	81 e8 51 60 10 f0    	sub    $0xf0106051,%eax
f0100e3d:	39 c2                	cmp    %eax,%edx
f0100e3f:	73 b4                	jae    f0100df5 <debuginfo_eip+0x1e4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100e41:	81 c2 51 60 10 f0    	add    $0xf0106051,%edx
f0100e47:	89 16                	mov    %edx,(%esi)
f0100e49:	eb aa                	jmp    f0100df5 <debuginfo_eip+0x1e4>
f0100e4b:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100e4e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100e51:	eb d2                	jmp    f0100e25 <debuginfo_eip+0x214>
			info->eip_fn_narg++;
f0100e53:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0100e57:	39 c7                	cmp    %eax,%edi
f0100e59:	7e 31                	jle    f0100e8c <debuginfo_eip+0x27b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100e5b:	0f b6 0a             	movzbl (%edx),%ecx
f0100e5e:	83 c0 01             	add    $0x1,%eax
f0100e61:	83 c2 0c             	add    $0xc,%edx
f0100e64:	80 f9 a0             	cmp    $0xa0,%cl
f0100e67:	74 ea                	je     f0100e53 <debuginfo_eip+0x242>
	return 0;
f0100e69:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e6e:	eb 21                	jmp    f0100e91 <debuginfo_eip+0x280>
		return -1;
f0100e70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e75:	eb 1a                	jmp    f0100e91 <debuginfo_eip+0x280>
f0100e77:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e7c:	eb 13                	jmp    f0100e91 <debuginfo_eip+0x280>
		return -1;
f0100e7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e83:	eb 0c                	jmp    f0100e91 <debuginfo_eip+0x280>
        return -1;
f0100e85:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e8a:	eb 05                	jmp    f0100e91 <debuginfo_eip+0x280>
	return 0;
f0100e8c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100e91:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e94:	5b                   	pop    %ebx
f0100e95:	5e                   	pop    %esi
f0100e96:	5f                   	pop    %edi
f0100e97:	5d                   	pop    %ebp
f0100e98:	c3                   	ret    

f0100e99 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100e99:	55                   	push   %ebp
f0100e9a:	89 e5                	mov    %esp,%ebp
f0100e9c:	57                   	push   %edi
f0100e9d:	56                   	push   %esi
f0100e9e:	53                   	push   %ebx
f0100e9f:	83 ec 2c             	sub    $0x2c,%esp
f0100ea2:	e8 02 06 00 00       	call   f01014a9 <__x86.get_pc_thunk.cx>
f0100ea7:	81 c1 61 04 01 00    	add    $0x10461,%ecx
f0100ead:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100eb0:	89 c7                	mov    %eax,%edi
f0100eb2:	89 d6                	mov    %edx,%esi
f0100eb4:	8b 45 08             	mov    0x8(%ebp),%eax
f0100eb7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100eba:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100ebd:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100ec0:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100ec3:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100ec8:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0100ecb:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100ece:	39 d3                	cmp    %edx,%ebx
f0100ed0:	72 09                	jb     f0100edb <printnum+0x42>
f0100ed2:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100ed5:	0f 87 83 00 00 00    	ja     f0100f5e <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100edb:	83 ec 0c             	sub    $0xc,%esp
f0100ede:	ff 75 18             	pushl  0x18(%ebp)
f0100ee1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee4:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100ee7:	53                   	push   %ebx
f0100ee8:	ff 75 10             	pushl  0x10(%ebp)
f0100eeb:	83 ec 08             	sub    $0x8,%esp
f0100eee:	ff 75 dc             	pushl  -0x24(%ebp)
f0100ef1:	ff 75 d8             	pushl  -0x28(%ebp)
f0100ef4:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100ef7:	ff 75 d0             	pushl  -0x30(%ebp)
f0100efa:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100efd:	e8 1e 0a 00 00       	call   f0101920 <__udivdi3>
f0100f02:	83 c4 18             	add    $0x18,%esp
f0100f05:	52                   	push   %edx
f0100f06:	50                   	push   %eax
f0100f07:	89 f2                	mov    %esi,%edx
f0100f09:	89 f8                	mov    %edi,%eax
f0100f0b:	e8 89 ff ff ff       	call   f0100e99 <printnum>
f0100f10:	83 c4 20             	add    $0x20,%esp
f0100f13:	eb 13                	jmp    f0100f28 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100f15:	83 ec 08             	sub    $0x8,%esp
f0100f18:	56                   	push   %esi
f0100f19:	ff 75 18             	pushl  0x18(%ebp)
f0100f1c:	ff d7                	call   *%edi
f0100f1e:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100f21:	83 eb 01             	sub    $0x1,%ebx
f0100f24:	85 db                	test   %ebx,%ebx
f0100f26:	7f ed                	jg     f0100f15 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100f28:	83 ec 08             	sub    $0x8,%esp
f0100f2b:	56                   	push   %esi
f0100f2c:	83 ec 04             	sub    $0x4,%esp
f0100f2f:	ff 75 dc             	pushl  -0x24(%ebp)
f0100f32:	ff 75 d8             	pushl  -0x28(%ebp)
f0100f35:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100f38:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f3b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100f3e:	89 f3                	mov    %esi,%ebx
f0100f40:	e8 fb 0a 00 00       	call   f0101a40 <__umoddi3>
f0100f45:	83 c4 14             	add    $0x14,%esp
f0100f48:	0f be 84 06 95 0d ff 	movsbl -0xf26b(%esi,%eax,1),%eax
f0100f4f:	ff 
f0100f50:	50                   	push   %eax
f0100f51:	ff d7                	call   *%edi
}
f0100f53:	83 c4 10             	add    $0x10,%esp
f0100f56:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f59:	5b                   	pop    %ebx
f0100f5a:	5e                   	pop    %esi
f0100f5b:	5f                   	pop    %edi
f0100f5c:	5d                   	pop    %ebp
f0100f5d:	c3                   	ret    
f0100f5e:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100f61:	eb be                	jmp    f0100f21 <printnum+0x88>

f0100f63 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100f63:	55                   	push   %ebp
f0100f64:	89 e5                	mov    %esp,%ebp
f0100f66:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100f69:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100f6d:	8b 10                	mov    (%eax),%edx
f0100f6f:	3b 50 04             	cmp    0x4(%eax),%edx
f0100f72:	73 0a                	jae    f0100f7e <sprintputch+0x1b>
		*b->buf++ = ch;
f0100f74:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100f77:	89 08                	mov    %ecx,(%eax)
f0100f79:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f7c:	88 02                	mov    %al,(%edx)
}
f0100f7e:	5d                   	pop    %ebp
f0100f7f:	c3                   	ret    

f0100f80 <printfmt>:
{
f0100f80:	55                   	push   %ebp
f0100f81:	89 e5                	mov    %esp,%ebp
f0100f83:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100f86:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100f89:	50                   	push   %eax
f0100f8a:	ff 75 10             	pushl  0x10(%ebp)
f0100f8d:	ff 75 0c             	pushl  0xc(%ebp)
f0100f90:	ff 75 08             	pushl  0x8(%ebp)
f0100f93:	e8 05 00 00 00       	call   f0100f9d <vprintfmt>
}
f0100f98:	83 c4 10             	add    $0x10,%esp
f0100f9b:	c9                   	leave  
f0100f9c:	c3                   	ret    

f0100f9d <vprintfmt>:
{
f0100f9d:	55                   	push   %ebp
f0100f9e:	89 e5                	mov    %esp,%ebp
f0100fa0:	57                   	push   %edi
f0100fa1:	56                   	push   %esi
f0100fa2:	53                   	push   %ebx
f0100fa3:	83 ec 2c             	sub    $0x2c,%esp
f0100fa6:	e8 11 f2 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100fab:	81 c3 5d 03 01 00    	add    $0x1035d,%ebx
f0100fb1:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100fb4:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100fb7:	e9 c3 03 00 00       	jmp    f010137f <.L35+0x48>
		padc = ' ';
f0100fbc:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0100fc0:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0100fc7:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f0100fce:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0100fd5:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100fda:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100fdd:	8d 47 01             	lea    0x1(%edi),%eax
f0100fe0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100fe3:	0f b6 17             	movzbl (%edi),%edx
f0100fe6:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100fe9:	3c 55                	cmp    $0x55,%al
f0100feb:	0f 87 16 04 00 00    	ja     f0101407 <.L22>
f0100ff1:	0f b6 c0             	movzbl %al,%eax
f0100ff4:	89 d9                	mov    %ebx,%ecx
f0100ff6:	03 8c 83 24 0e ff ff 	add    -0xf1dc(%ebx,%eax,4),%ecx
f0100ffd:	ff e1                	jmp    *%ecx

f0100fff <.L69>:
f0100fff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0101002:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0101006:	eb d5                	jmp    f0100fdd <vprintfmt+0x40>

f0101008 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0101008:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f010100b:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010100f:	eb cc                	jmp    f0100fdd <vprintfmt+0x40>

f0101011 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0101011:	0f b6 d2             	movzbl %dl,%edx
f0101014:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0101017:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f010101c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010101f:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0101023:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0101026:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0101029:	83 f9 09             	cmp    $0x9,%ecx
f010102c:	77 55                	ja     f0101083 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f010102e:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0101031:	eb e9                	jmp    f010101c <.L29+0xb>

f0101033 <.L26>:
			precision = va_arg(ap, int);
f0101033:	8b 45 14             	mov    0x14(%ebp),%eax
f0101036:	8b 00                	mov    (%eax),%eax
f0101038:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010103b:	8b 45 14             	mov    0x14(%ebp),%eax
f010103e:	8d 40 04             	lea    0x4(%eax),%eax
f0101041:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101044:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0101047:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010104b:	79 90                	jns    f0100fdd <vprintfmt+0x40>
				width = precision, precision = -1;
f010104d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101050:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101053:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f010105a:	eb 81                	jmp    f0100fdd <vprintfmt+0x40>

f010105c <.L27>:
f010105c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010105f:	85 c0                	test   %eax,%eax
f0101061:	ba 00 00 00 00       	mov    $0x0,%edx
f0101066:	0f 49 d0             	cmovns %eax,%edx
f0101069:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010106c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010106f:	e9 69 ff ff ff       	jmp    f0100fdd <vprintfmt+0x40>

f0101074 <.L23>:
f0101074:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0101077:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010107e:	e9 5a ff ff ff       	jmp    f0100fdd <vprintfmt+0x40>
f0101083:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101086:	eb bf                	jmp    f0101047 <.L26+0x14>

f0101088 <.L33>:
			lflag++;
f0101088:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010108c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f010108f:	e9 49 ff ff ff       	jmp    f0100fdd <vprintfmt+0x40>

f0101094 <.L30>:
			putch(va_arg(ap, int), putdat);
f0101094:	8b 45 14             	mov    0x14(%ebp),%eax
f0101097:	8d 78 04             	lea    0x4(%eax),%edi
f010109a:	83 ec 08             	sub    $0x8,%esp
f010109d:	56                   	push   %esi
f010109e:	ff 30                	pushl  (%eax)
f01010a0:	ff 55 08             	call   *0x8(%ebp)
			break;
f01010a3:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01010a6:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f01010a9:	e9 ce 02 00 00       	jmp    f010137c <.L35+0x45>

f01010ae <.L32>:
			err = va_arg(ap, int);
f01010ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b1:	8d 78 04             	lea    0x4(%eax),%edi
f01010b4:	8b 00                	mov    (%eax),%eax
f01010b6:	99                   	cltd   
f01010b7:	31 d0                	xor    %edx,%eax
f01010b9:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01010bb:	83 f8 06             	cmp    $0x6,%eax
f01010be:	7f 27                	jg     f01010e7 <.L32+0x39>
f01010c0:	8b 94 83 3c 1d 00 00 	mov    0x1d3c(%ebx,%eax,4),%edx
f01010c7:	85 d2                	test   %edx,%edx
f01010c9:	74 1c                	je     f01010e7 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f01010cb:	52                   	push   %edx
f01010cc:	8d 83 b6 0d ff ff    	lea    -0xf24a(%ebx),%eax
f01010d2:	50                   	push   %eax
f01010d3:	56                   	push   %esi
f01010d4:	ff 75 08             	pushl  0x8(%ebp)
f01010d7:	e8 a4 fe ff ff       	call   f0100f80 <printfmt>
f01010dc:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01010df:	89 7d 14             	mov    %edi,0x14(%ebp)
f01010e2:	e9 95 02 00 00       	jmp    f010137c <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f01010e7:	50                   	push   %eax
f01010e8:	8d 83 ad 0d ff ff    	lea    -0xf253(%ebx),%eax
f01010ee:	50                   	push   %eax
f01010ef:	56                   	push   %esi
f01010f0:	ff 75 08             	pushl  0x8(%ebp)
f01010f3:	e8 88 fe ff ff       	call   f0100f80 <printfmt>
f01010f8:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01010fb:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01010fe:	e9 79 02 00 00       	jmp    f010137c <.L35+0x45>

f0101103 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0101103:	8b 45 14             	mov    0x14(%ebp),%eax
f0101106:	83 c0 04             	add    $0x4,%eax
f0101109:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010110c:	8b 45 14             	mov    0x14(%ebp),%eax
f010110f:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101111:	85 ff                	test   %edi,%edi
f0101113:	8d 83 a6 0d ff ff    	lea    -0xf25a(%ebx),%eax
f0101119:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010111c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101120:	0f 8e b5 00 00 00    	jle    f01011db <.L36+0xd8>
f0101126:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010112a:	75 08                	jne    f0101134 <.L36+0x31>
f010112c:	89 75 0c             	mov    %esi,0xc(%ebp)
f010112f:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101132:	eb 6d                	jmp    f01011a1 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101134:	83 ec 08             	sub    $0x8,%esp
f0101137:	ff 75 cc             	pushl  -0x34(%ebp)
f010113a:	57                   	push   %edi
f010113b:	e8 82 04 00 00       	call   f01015c2 <strnlen>
f0101140:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101143:	29 c2                	sub    %eax,%edx
f0101145:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0101148:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010114b:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010114f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101152:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101155:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101157:	eb 10                	jmp    f0101169 <.L36+0x66>
					putch(padc, putdat);
f0101159:	83 ec 08             	sub    $0x8,%esp
f010115c:	56                   	push   %esi
f010115d:	ff 75 e0             	pushl  -0x20(%ebp)
f0101160:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101163:	83 ef 01             	sub    $0x1,%edi
f0101166:	83 c4 10             	add    $0x10,%esp
f0101169:	85 ff                	test   %edi,%edi
f010116b:	7f ec                	jg     f0101159 <.L36+0x56>
f010116d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101170:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0101173:	85 d2                	test   %edx,%edx
f0101175:	b8 00 00 00 00       	mov    $0x0,%eax
f010117a:	0f 49 c2             	cmovns %edx,%eax
f010117d:	29 c2                	sub    %eax,%edx
f010117f:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101182:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101185:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101188:	eb 17                	jmp    f01011a1 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f010118a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010118e:	75 30                	jne    f01011c0 <.L36+0xbd>
					putch(ch, putdat);
f0101190:	83 ec 08             	sub    $0x8,%esp
f0101193:	ff 75 0c             	pushl  0xc(%ebp)
f0101196:	50                   	push   %eax
f0101197:	ff 55 08             	call   *0x8(%ebp)
f010119a:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010119d:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f01011a1:	83 c7 01             	add    $0x1,%edi
f01011a4:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f01011a8:	0f be c2             	movsbl %dl,%eax
f01011ab:	85 c0                	test   %eax,%eax
f01011ad:	74 52                	je     f0101201 <.L36+0xfe>
f01011af:	85 f6                	test   %esi,%esi
f01011b1:	78 d7                	js     f010118a <.L36+0x87>
f01011b3:	83 ee 01             	sub    $0x1,%esi
f01011b6:	79 d2                	jns    f010118a <.L36+0x87>
f01011b8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01011bb:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01011be:	eb 32                	jmp    f01011f2 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01011c0:	0f be d2             	movsbl %dl,%edx
f01011c3:	83 ea 20             	sub    $0x20,%edx
f01011c6:	83 fa 5e             	cmp    $0x5e,%edx
f01011c9:	76 c5                	jbe    f0101190 <.L36+0x8d>
					putch('?', putdat);
f01011cb:	83 ec 08             	sub    $0x8,%esp
f01011ce:	ff 75 0c             	pushl  0xc(%ebp)
f01011d1:	6a 3f                	push   $0x3f
f01011d3:	ff 55 08             	call   *0x8(%ebp)
f01011d6:	83 c4 10             	add    $0x10,%esp
f01011d9:	eb c2                	jmp    f010119d <.L36+0x9a>
f01011db:	89 75 0c             	mov    %esi,0xc(%ebp)
f01011de:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01011e1:	eb be                	jmp    f01011a1 <.L36+0x9e>
				putch(' ', putdat);
f01011e3:	83 ec 08             	sub    $0x8,%esp
f01011e6:	56                   	push   %esi
f01011e7:	6a 20                	push   $0x20
f01011e9:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01011ec:	83 ef 01             	sub    $0x1,%edi
f01011ef:	83 c4 10             	add    $0x10,%esp
f01011f2:	85 ff                	test   %edi,%edi
f01011f4:	7f ed                	jg     f01011e3 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01011f6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01011f9:	89 45 14             	mov    %eax,0x14(%ebp)
f01011fc:	e9 7b 01 00 00       	jmp    f010137c <.L35+0x45>
f0101201:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101204:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101207:	eb e9                	jmp    f01011f2 <.L36+0xef>

f0101209 <.L31>:
f0101209:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010120c:	83 f9 01             	cmp    $0x1,%ecx
f010120f:	7e 40                	jle    f0101251 <.L31+0x48>
		return va_arg(*ap, long long);
f0101211:	8b 45 14             	mov    0x14(%ebp),%eax
f0101214:	8b 50 04             	mov    0x4(%eax),%edx
f0101217:	8b 00                	mov    (%eax),%eax
f0101219:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010121c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010121f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101222:	8d 40 08             	lea    0x8(%eax),%eax
f0101225:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101228:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010122c:	79 55                	jns    f0101283 <.L31+0x7a>
				putch('-', putdat);
f010122e:	83 ec 08             	sub    $0x8,%esp
f0101231:	56                   	push   %esi
f0101232:	6a 2d                	push   $0x2d
f0101234:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101237:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010123a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010123d:	f7 da                	neg    %edx
f010123f:	83 d1 00             	adc    $0x0,%ecx
f0101242:	f7 d9                	neg    %ecx
f0101244:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101247:	b8 0a 00 00 00       	mov    $0xa,%eax
f010124c:	e9 10 01 00 00       	jmp    f0101361 <.L35+0x2a>
	else if (lflag)
f0101251:	85 c9                	test   %ecx,%ecx
f0101253:	75 17                	jne    f010126c <.L31+0x63>
		return va_arg(*ap, int);
f0101255:	8b 45 14             	mov    0x14(%ebp),%eax
f0101258:	8b 00                	mov    (%eax),%eax
f010125a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010125d:	99                   	cltd   
f010125e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101261:	8b 45 14             	mov    0x14(%ebp),%eax
f0101264:	8d 40 04             	lea    0x4(%eax),%eax
f0101267:	89 45 14             	mov    %eax,0x14(%ebp)
f010126a:	eb bc                	jmp    f0101228 <.L31+0x1f>
		return va_arg(*ap, long);
f010126c:	8b 45 14             	mov    0x14(%ebp),%eax
f010126f:	8b 00                	mov    (%eax),%eax
f0101271:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101274:	99                   	cltd   
f0101275:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101278:	8b 45 14             	mov    0x14(%ebp),%eax
f010127b:	8d 40 04             	lea    0x4(%eax),%eax
f010127e:	89 45 14             	mov    %eax,0x14(%ebp)
f0101281:	eb a5                	jmp    f0101228 <.L31+0x1f>
			num = getint(&ap, lflag);
f0101283:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101286:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101289:	b8 0a 00 00 00       	mov    $0xa,%eax
f010128e:	e9 ce 00 00 00       	jmp    f0101361 <.L35+0x2a>

f0101293 <.L37>:
f0101293:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101296:	83 f9 01             	cmp    $0x1,%ecx
f0101299:	7e 18                	jle    f01012b3 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f010129b:	8b 45 14             	mov    0x14(%ebp),%eax
f010129e:	8b 10                	mov    (%eax),%edx
f01012a0:	8b 48 04             	mov    0x4(%eax),%ecx
f01012a3:	8d 40 08             	lea    0x8(%eax),%eax
f01012a6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012a9:	b8 0a 00 00 00       	mov    $0xa,%eax
f01012ae:	e9 ae 00 00 00       	jmp    f0101361 <.L35+0x2a>
	else if (lflag)
f01012b3:	85 c9                	test   %ecx,%ecx
f01012b5:	75 1a                	jne    f01012d1 <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f01012b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01012ba:	8b 10                	mov    (%eax),%edx
f01012bc:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012c1:	8d 40 04             	lea    0x4(%eax),%eax
f01012c4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012c7:	b8 0a 00 00 00       	mov    $0xa,%eax
f01012cc:	e9 90 00 00 00       	jmp    f0101361 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01012d1:	8b 45 14             	mov    0x14(%ebp),%eax
f01012d4:	8b 10                	mov    (%eax),%edx
f01012d6:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012db:	8d 40 04             	lea    0x4(%eax),%eax
f01012de:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012e1:	b8 0a 00 00 00       	mov    $0xa,%eax
f01012e6:	eb 79                	jmp    f0101361 <.L35+0x2a>

f01012e8 <.L34>:
f01012e8:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01012eb:	83 f9 01             	cmp    $0x1,%ecx
f01012ee:	7e 15                	jle    f0101305 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f01012f0:	8b 45 14             	mov    0x14(%ebp),%eax
f01012f3:	8b 10                	mov    (%eax),%edx
f01012f5:	8b 48 04             	mov    0x4(%eax),%ecx
f01012f8:	8d 40 08             	lea    0x8(%eax),%eax
f01012fb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01012fe:	b8 08 00 00 00       	mov    $0x8,%eax
f0101303:	eb 5c                	jmp    f0101361 <.L35+0x2a>
	else if (lflag)
f0101305:	85 c9                	test   %ecx,%ecx
f0101307:	75 17                	jne    f0101320 <.L34+0x38>
		return va_arg(*ap, unsigned int);
f0101309:	8b 45 14             	mov    0x14(%ebp),%eax
f010130c:	8b 10                	mov    (%eax),%edx
f010130e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101313:	8d 40 04             	lea    0x4(%eax),%eax
f0101316:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0101319:	b8 08 00 00 00       	mov    $0x8,%eax
f010131e:	eb 41                	jmp    f0101361 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101320:	8b 45 14             	mov    0x14(%ebp),%eax
f0101323:	8b 10                	mov    (%eax),%edx
f0101325:	b9 00 00 00 00       	mov    $0x0,%ecx
f010132a:	8d 40 04             	lea    0x4(%eax),%eax
f010132d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0101330:	b8 08 00 00 00       	mov    $0x8,%eax
f0101335:	eb 2a                	jmp    f0101361 <.L35+0x2a>

f0101337 <.L35>:
			putch('0', putdat);
f0101337:	83 ec 08             	sub    $0x8,%esp
f010133a:	56                   	push   %esi
f010133b:	6a 30                	push   $0x30
f010133d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101340:	83 c4 08             	add    $0x8,%esp
f0101343:	56                   	push   %esi
f0101344:	6a 78                	push   $0x78
f0101346:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0101349:	8b 45 14             	mov    0x14(%ebp),%eax
f010134c:	8b 10                	mov    (%eax),%edx
f010134e:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0101353:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101356:	8d 40 04             	lea    0x4(%eax),%eax
f0101359:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010135c:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0101361:	83 ec 0c             	sub    $0xc,%esp
f0101364:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101368:	57                   	push   %edi
f0101369:	ff 75 e0             	pushl  -0x20(%ebp)
f010136c:	50                   	push   %eax
f010136d:	51                   	push   %ecx
f010136e:	52                   	push   %edx
f010136f:	89 f2                	mov    %esi,%edx
f0101371:	8b 45 08             	mov    0x8(%ebp),%eax
f0101374:	e8 20 fb ff ff       	call   f0100e99 <printnum>
			break;
f0101379:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f010137c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010137f:	83 c7 01             	add    $0x1,%edi
f0101382:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101386:	83 f8 25             	cmp    $0x25,%eax
f0101389:	0f 84 2d fc ff ff    	je     f0100fbc <vprintfmt+0x1f>
			if (ch == '\0')
f010138f:	85 c0                	test   %eax,%eax
f0101391:	0f 84 91 00 00 00    	je     f0101428 <.L22+0x21>
			putch(ch, putdat);
f0101397:	83 ec 08             	sub    $0x8,%esp
f010139a:	56                   	push   %esi
f010139b:	50                   	push   %eax
f010139c:	ff 55 08             	call   *0x8(%ebp)
f010139f:	83 c4 10             	add    $0x10,%esp
f01013a2:	eb db                	jmp    f010137f <.L35+0x48>

f01013a4 <.L38>:
f01013a4:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01013a7:	83 f9 01             	cmp    $0x1,%ecx
f01013aa:	7e 15                	jle    f01013c1 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f01013ac:	8b 45 14             	mov    0x14(%ebp),%eax
f01013af:	8b 10                	mov    (%eax),%edx
f01013b1:	8b 48 04             	mov    0x4(%eax),%ecx
f01013b4:	8d 40 08             	lea    0x8(%eax),%eax
f01013b7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01013ba:	b8 10 00 00 00       	mov    $0x10,%eax
f01013bf:	eb a0                	jmp    f0101361 <.L35+0x2a>
	else if (lflag)
f01013c1:	85 c9                	test   %ecx,%ecx
f01013c3:	75 17                	jne    f01013dc <.L38+0x38>
		return va_arg(*ap, unsigned int);
f01013c5:	8b 45 14             	mov    0x14(%ebp),%eax
f01013c8:	8b 10                	mov    (%eax),%edx
f01013ca:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013cf:	8d 40 04             	lea    0x4(%eax),%eax
f01013d2:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01013d5:	b8 10 00 00 00       	mov    $0x10,%eax
f01013da:	eb 85                	jmp    f0101361 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01013dc:	8b 45 14             	mov    0x14(%ebp),%eax
f01013df:	8b 10                	mov    (%eax),%edx
f01013e1:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013e6:	8d 40 04             	lea    0x4(%eax),%eax
f01013e9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01013ec:	b8 10 00 00 00       	mov    $0x10,%eax
f01013f1:	e9 6b ff ff ff       	jmp    f0101361 <.L35+0x2a>

f01013f6 <.L25>:
			putch(ch, putdat);
f01013f6:	83 ec 08             	sub    $0x8,%esp
f01013f9:	56                   	push   %esi
f01013fa:	6a 25                	push   $0x25
f01013fc:	ff 55 08             	call   *0x8(%ebp)
			break;
f01013ff:	83 c4 10             	add    $0x10,%esp
f0101402:	e9 75 ff ff ff       	jmp    f010137c <.L35+0x45>

f0101407 <.L22>:
			putch('%', putdat);
f0101407:	83 ec 08             	sub    $0x8,%esp
f010140a:	56                   	push   %esi
f010140b:	6a 25                	push   $0x25
f010140d:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101410:	83 c4 10             	add    $0x10,%esp
f0101413:	89 f8                	mov    %edi,%eax
f0101415:	eb 03                	jmp    f010141a <.L22+0x13>
f0101417:	83 e8 01             	sub    $0x1,%eax
f010141a:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f010141e:	75 f7                	jne    f0101417 <.L22+0x10>
f0101420:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101423:	e9 54 ff ff ff       	jmp    f010137c <.L35+0x45>
}
f0101428:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010142b:	5b                   	pop    %ebx
f010142c:	5e                   	pop    %esi
f010142d:	5f                   	pop    %edi
f010142e:	5d                   	pop    %ebp
f010142f:	c3                   	ret    

f0101430 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101430:	55                   	push   %ebp
f0101431:	89 e5                	mov    %esp,%ebp
f0101433:	53                   	push   %ebx
f0101434:	83 ec 14             	sub    $0x14,%esp
f0101437:	e8 80 ed ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f010143c:	81 c3 cc fe 00 00    	add    $0xfecc,%ebx
f0101442:	8b 45 08             	mov    0x8(%ebp),%eax
f0101445:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101448:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010144b:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010144f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101452:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101459:	85 c0                	test   %eax,%eax
f010145b:	74 2b                	je     f0101488 <vsnprintf+0x58>
f010145d:	85 d2                	test   %edx,%edx
f010145f:	7e 27                	jle    f0101488 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101461:	ff 75 14             	pushl  0x14(%ebp)
f0101464:	ff 75 10             	pushl  0x10(%ebp)
f0101467:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010146a:	50                   	push   %eax
f010146b:	8d 83 5b fc fe ff    	lea    -0x103a5(%ebx),%eax
f0101471:	50                   	push   %eax
f0101472:	e8 26 fb ff ff       	call   f0100f9d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101477:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010147a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010147d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101480:	83 c4 10             	add    $0x10,%esp
}
f0101483:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101486:	c9                   	leave  
f0101487:	c3                   	ret    
		return -E_INVAL;
f0101488:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010148d:	eb f4                	jmp    f0101483 <vsnprintf+0x53>

f010148f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010148f:	55                   	push   %ebp
f0101490:	89 e5                	mov    %esp,%ebp
f0101492:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101495:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101498:	50                   	push   %eax
f0101499:	ff 75 10             	pushl  0x10(%ebp)
f010149c:	ff 75 0c             	pushl  0xc(%ebp)
f010149f:	ff 75 08             	pushl  0x8(%ebp)
f01014a2:	e8 89 ff ff ff       	call   f0101430 <vsnprintf>
	va_end(ap);

	return rc;
}
f01014a7:	c9                   	leave  
f01014a8:	c3                   	ret    

f01014a9 <__x86.get_pc_thunk.cx>:
f01014a9:	8b 0c 24             	mov    (%esp),%ecx
f01014ac:	c3                   	ret    

f01014ad <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01014ad:	55                   	push   %ebp
f01014ae:	89 e5                	mov    %esp,%ebp
f01014b0:	57                   	push   %edi
f01014b1:	56                   	push   %esi
f01014b2:	53                   	push   %ebx
f01014b3:	83 ec 1c             	sub    $0x1c,%esp
f01014b6:	e8 01 ed ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01014bb:	81 c3 4d fe 00 00    	add    $0xfe4d,%ebx
f01014c1:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01014c4:	85 c0                	test   %eax,%eax
f01014c6:	74 13                	je     f01014db <readline+0x2e>
		cprintf("%s", prompt);
f01014c8:	83 ec 08             	sub    $0x8,%esp
f01014cb:	50                   	push   %eax
f01014cc:	8d 83 b6 0d ff ff    	lea    -0xf24a(%ebx),%eax
f01014d2:	50                   	push   %eax
f01014d3:	e8 35 f6 ff ff       	call   f0100b0d <cprintf>
f01014d8:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01014db:	83 ec 0c             	sub    $0xc,%esp
f01014de:	6a 00                	push   $0x0
f01014e0:	e8 6f f2 ff ff       	call   f0100754 <iscons>
f01014e5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01014e8:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01014eb:	bf 00 00 00 00       	mov    $0x0,%edi
f01014f0:	eb 46                	jmp    f0101538 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01014f2:	83 ec 08             	sub    $0x8,%esp
f01014f5:	50                   	push   %eax
f01014f6:	8d 83 7c 0f ff ff    	lea    -0xf084(%ebx),%eax
f01014fc:	50                   	push   %eax
f01014fd:	e8 0b f6 ff ff       	call   f0100b0d <cprintf>
			return NULL;
f0101502:	83 c4 10             	add    $0x10,%esp
f0101505:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f010150a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010150d:	5b                   	pop    %ebx
f010150e:	5e                   	pop    %esi
f010150f:	5f                   	pop    %edi
f0101510:	5d                   	pop    %ebp
f0101511:	c3                   	ret    
			if (echoing)
f0101512:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101516:	75 05                	jne    f010151d <readline+0x70>
			i--;
f0101518:	83 ef 01             	sub    $0x1,%edi
f010151b:	eb 1b                	jmp    f0101538 <readline+0x8b>
				cputchar('\b');
f010151d:	83 ec 0c             	sub    $0xc,%esp
f0101520:	6a 08                	push   $0x8
f0101522:	e8 0c f2 ff ff       	call   f0100733 <cputchar>
f0101527:	83 c4 10             	add    $0x10,%esp
f010152a:	eb ec                	jmp    f0101518 <readline+0x6b>
			buf[i++] = c;
f010152c:	89 f0                	mov    %esi,%eax
f010152e:	88 84 3b 98 1f 00 00 	mov    %al,0x1f98(%ebx,%edi,1)
f0101535:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0101538:	e8 06 f2 ff ff       	call   f0100743 <getchar>
f010153d:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f010153f:	85 c0                	test   %eax,%eax
f0101541:	78 af                	js     f01014f2 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101543:	83 f8 08             	cmp    $0x8,%eax
f0101546:	0f 94 c2             	sete   %dl
f0101549:	83 f8 7f             	cmp    $0x7f,%eax
f010154c:	0f 94 c0             	sete   %al
f010154f:	08 c2                	or     %al,%dl
f0101551:	74 04                	je     f0101557 <readline+0xaa>
f0101553:	85 ff                	test   %edi,%edi
f0101555:	7f bb                	jg     f0101512 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101557:	83 fe 1f             	cmp    $0x1f,%esi
f010155a:	7e 1c                	jle    f0101578 <readline+0xcb>
f010155c:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0101562:	7f 14                	jg     f0101578 <readline+0xcb>
			if (echoing)
f0101564:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101568:	74 c2                	je     f010152c <readline+0x7f>
				cputchar(c);
f010156a:	83 ec 0c             	sub    $0xc,%esp
f010156d:	56                   	push   %esi
f010156e:	e8 c0 f1 ff ff       	call   f0100733 <cputchar>
f0101573:	83 c4 10             	add    $0x10,%esp
f0101576:	eb b4                	jmp    f010152c <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0101578:	83 fe 0a             	cmp    $0xa,%esi
f010157b:	74 05                	je     f0101582 <readline+0xd5>
f010157d:	83 fe 0d             	cmp    $0xd,%esi
f0101580:	75 b6                	jne    f0101538 <readline+0x8b>
			if (echoing)
f0101582:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101586:	75 13                	jne    f010159b <readline+0xee>
			buf[i] = 0;
f0101588:	c6 84 3b 98 1f 00 00 	movb   $0x0,0x1f98(%ebx,%edi,1)
f010158f:	00 
			return buf;
f0101590:	8d 83 98 1f 00 00    	lea    0x1f98(%ebx),%eax
f0101596:	e9 6f ff ff ff       	jmp    f010150a <readline+0x5d>
				cputchar('\n');
f010159b:	83 ec 0c             	sub    $0xc,%esp
f010159e:	6a 0a                	push   $0xa
f01015a0:	e8 8e f1 ff ff       	call   f0100733 <cputchar>
f01015a5:	83 c4 10             	add    $0x10,%esp
f01015a8:	eb de                	jmp    f0101588 <readline+0xdb>

f01015aa <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01015aa:	55                   	push   %ebp
f01015ab:	89 e5                	mov    %esp,%ebp
f01015ad:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01015b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01015b5:	eb 03                	jmp    f01015ba <strlen+0x10>
		n++;
f01015b7:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01015ba:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01015be:	75 f7                	jne    f01015b7 <strlen+0xd>
	return n;
}
f01015c0:	5d                   	pop    %ebp
f01015c1:	c3                   	ret    

f01015c2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01015c2:	55                   	push   %ebp
f01015c3:	89 e5                	mov    %esp,%ebp
f01015c5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015c8:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01015cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01015d0:	eb 03                	jmp    f01015d5 <strnlen+0x13>
		n++;
f01015d2:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01015d5:	39 d0                	cmp    %edx,%eax
f01015d7:	74 06                	je     f01015df <strnlen+0x1d>
f01015d9:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01015dd:	75 f3                	jne    f01015d2 <strnlen+0x10>
	return n;
}
f01015df:	5d                   	pop    %ebp
f01015e0:	c3                   	ret    

f01015e1 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01015e1:	55                   	push   %ebp
f01015e2:	89 e5                	mov    %esp,%ebp
f01015e4:	53                   	push   %ebx
f01015e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01015eb:	89 c2                	mov    %eax,%edx
f01015ed:	83 c1 01             	add    $0x1,%ecx
f01015f0:	83 c2 01             	add    $0x1,%edx
f01015f3:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01015f7:	88 5a ff             	mov    %bl,-0x1(%edx)
f01015fa:	84 db                	test   %bl,%bl
f01015fc:	75 ef                	jne    f01015ed <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01015fe:	5b                   	pop    %ebx
f01015ff:	5d                   	pop    %ebp
f0101600:	c3                   	ret    

f0101601 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101601:	55                   	push   %ebp
f0101602:	89 e5                	mov    %esp,%ebp
f0101604:	53                   	push   %ebx
f0101605:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101608:	53                   	push   %ebx
f0101609:	e8 9c ff ff ff       	call   f01015aa <strlen>
f010160e:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101611:	ff 75 0c             	pushl  0xc(%ebp)
f0101614:	01 d8                	add    %ebx,%eax
f0101616:	50                   	push   %eax
f0101617:	e8 c5 ff ff ff       	call   f01015e1 <strcpy>
	return dst;
}
f010161c:	89 d8                	mov    %ebx,%eax
f010161e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101621:	c9                   	leave  
f0101622:	c3                   	ret    

f0101623 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101623:	55                   	push   %ebp
f0101624:	89 e5                	mov    %esp,%ebp
f0101626:	56                   	push   %esi
f0101627:	53                   	push   %ebx
f0101628:	8b 75 08             	mov    0x8(%ebp),%esi
f010162b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010162e:	89 f3                	mov    %esi,%ebx
f0101630:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101633:	89 f2                	mov    %esi,%edx
f0101635:	eb 0f                	jmp    f0101646 <strncpy+0x23>
		*dst++ = *src;
f0101637:	83 c2 01             	add    $0x1,%edx
f010163a:	0f b6 01             	movzbl (%ecx),%eax
f010163d:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101640:	80 39 01             	cmpb   $0x1,(%ecx)
f0101643:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101646:	39 da                	cmp    %ebx,%edx
f0101648:	75 ed                	jne    f0101637 <strncpy+0x14>
	}
	return ret;
}
f010164a:	89 f0                	mov    %esi,%eax
f010164c:	5b                   	pop    %ebx
f010164d:	5e                   	pop    %esi
f010164e:	5d                   	pop    %ebp
f010164f:	c3                   	ret    

f0101650 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101650:	55                   	push   %ebp
f0101651:	89 e5                	mov    %esp,%ebp
f0101653:	56                   	push   %esi
f0101654:	53                   	push   %ebx
f0101655:	8b 75 08             	mov    0x8(%ebp),%esi
f0101658:	8b 55 0c             	mov    0xc(%ebp),%edx
f010165b:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010165e:	89 f0                	mov    %esi,%eax
f0101660:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101664:	85 c9                	test   %ecx,%ecx
f0101666:	75 0b                	jne    f0101673 <strlcpy+0x23>
f0101668:	eb 17                	jmp    f0101681 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010166a:	83 c2 01             	add    $0x1,%edx
f010166d:	83 c0 01             	add    $0x1,%eax
f0101670:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101673:	39 d8                	cmp    %ebx,%eax
f0101675:	74 07                	je     f010167e <strlcpy+0x2e>
f0101677:	0f b6 0a             	movzbl (%edx),%ecx
f010167a:	84 c9                	test   %cl,%cl
f010167c:	75 ec                	jne    f010166a <strlcpy+0x1a>
		*dst = '\0';
f010167e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101681:	29 f0                	sub    %esi,%eax
}
f0101683:	5b                   	pop    %ebx
f0101684:	5e                   	pop    %esi
f0101685:	5d                   	pop    %ebp
f0101686:	c3                   	ret    

f0101687 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101687:	55                   	push   %ebp
f0101688:	89 e5                	mov    %esp,%ebp
f010168a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010168d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101690:	eb 06                	jmp    f0101698 <strcmp+0x11>
		p++, q++;
f0101692:	83 c1 01             	add    $0x1,%ecx
f0101695:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101698:	0f b6 01             	movzbl (%ecx),%eax
f010169b:	84 c0                	test   %al,%al
f010169d:	74 04                	je     f01016a3 <strcmp+0x1c>
f010169f:	3a 02                	cmp    (%edx),%al
f01016a1:	74 ef                	je     f0101692 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01016a3:	0f b6 c0             	movzbl %al,%eax
f01016a6:	0f b6 12             	movzbl (%edx),%edx
f01016a9:	29 d0                	sub    %edx,%eax
}
f01016ab:	5d                   	pop    %ebp
f01016ac:	c3                   	ret    

f01016ad <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01016ad:	55                   	push   %ebp
f01016ae:	89 e5                	mov    %esp,%ebp
f01016b0:	53                   	push   %ebx
f01016b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01016b4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016b7:	89 c3                	mov    %eax,%ebx
f01016b9:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01016bc:	eb 06                	jmp    f01016c4 <strncmp+0x17>
		n--, p++, q++;
f01016be:	83 c0 01             	add    $0x1,%eax
f01016c1:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01016c4:	39 d8                	cmp    %ebx,%eax
f01016c6:	74 16                	je     f01016de <strncmp+0x31>
f01016c8:	0f b6 08             	movzbl (%eax),%ecx
f01016cb:	84 c9                	test   %cl,%cl
f01016cd:	74 04                	je     f01016d3 <strncmp+0x26>
f01016cf:	3a 0a                	cmp    (%edx),%cl
f01016d1:	74 eb                	je     f01016be <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01016d3:	0f b6 00             	movzbl (%eax),%eax
f01016d6:	0f b6 12             	movzbl (%edx),%edx
f01016d9:	29 d0                	sub    %edx,%eax
}
f01016db:	5b                   	pop    %ebx
f01016dc:	5d                   	pop    %ebp
f01016dd:	c3                   	ret    
		return 0;
f01016de:	b8 00 00 00 00       	mov    $0x0,%eax
f01016e3:	eb f6                	jmp    f01016db <strncmp+0x2e>

f01016e5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01016e5:	55                   	push   %ebp
f01016e6:	89 e5                	mov    %esp,%ebp
f01016e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01016eb:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01016ef:	0f b6 10             	movzbl (%eax),%edx
f01016f2:	84 d2                	test   %dl,%dl
f01016f4:	74 09                	je     f01016ff <strchr+0x1a>
		if (*s == c)
f01016f6:	38 ca                	cmp    %cl,%dl
f01016f8:	74 0a                	je     f0101704 <strchr+0x1f>
	for (; *s; s++)
f01016fa:	83 c0 01             	add    $0x1,%eax
f01016fd:	eb f0                	jmp    f01016ef <strchr+0xa>
			return (char *) s;
	return 0;
f01016ff:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101704:	5d                   	pop    %ebp
f0101705:	c3                   	ret    

f0101706 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101706:	55                   	push   %ebp
f0101707:	89 e5                	mov    %esp,%ebp
f0101709:	8b 45 08             	mov    0x8(%ebp),%eax
f010170c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101710:	eb 03                	jmp    f0101715 <strfind+0xf>
f0101712:	83 c0 01             	add    $0x1,%eax
f0101715:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101718:	38 ca                	cmp    %cl,%dl
f010171a:	74 04                	je     f0101720 <strfind+0x1a>
f010171c:	84 d2                	test   %dl,%dl
f010171e:	75 f2                	jne    f0101712 <strfind+0xc>
			break;
	return (char *) s;
}
f0101720:	5d                   	pop    %ebp
f0101721:	c3                   	ret    

f0101722 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101722:	55                   	push   %ebp
f0101723:	89 e5                	mov    %esp,%ebp
f0101725:	57                   	push   %edi
f0101726:	56                   	push   %esi
f0101727:	53                   	push   %ebx
f0101728:	8b 7d 08             	mov    0x8(%ebp),%edi
f010172b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010172e:	85 c9                	test   %ecx,%ecx
f0101730:	74 13                	je     f0101745 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101732:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101738:	75 05                	jne    f010173f <memset+0x1d>
f010173a:	f6 c1 03             	test   $0x3,%cl
f010173d:	74 0d                	je     f010174c <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010173f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101742:	fc                   	cld    
f0101743:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101745:	89 f8                	mov    %edi,%eax
f0101747:	5b                   	pop    %ebx
f0101748:	5e                   	pop    %esi
f0101749:	5f                   	pop    %edi
f010174a:	5d                   	pop    %ebp
f010174b:	c3                   	ret    
		c &= 0xFF;
f010174c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101750:	89 d3                	mov    %edx,%ebx
f0101752:	c1 e3 08             	shl    $0x8,%ebx
f0101755:	89 d0                	mov    %edx,%eax
f0101757:	c1 e0 18             	shl    $0x18,%eax
f010175a:	89 d6                	mov    %edx,%esi
f010175c:	c1 e6 10             	shl    $0x10,%esi
f010175f:	09 f0                	or     %esi,%eax
f0101761:	09 c2                	or     %eax,%edx
f0101763:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0101765:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101768:	89 d0                	mov    %edx,%eax
f010176a:	fc                   	cld    
f010176b:	f3 ab                	rep stos %eax,%es:(%edi)
f010176d:	eb d6                	jmp    f0101745 <memset+0x23>

f010176f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010176f:	55                   	push   %ebp
f0101770:	89 e5                	mov    %esp,%ebp
f0101772:	57                   	push   %edi
f0101773:	56                   	push   %esi
f0101774:	8b 45 08             	mov    0x8(%ebp),%eax
f0101777:	8b 75 0c             	mov    0xc(%ebp),%esi
f010177a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010177d:	39 c6                	cmp    %eax,%esi
f010177f:	73 35                	jae    f01017b6 <memmove+0x47>
f0101781:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101784:	39 c2                	cmp    %eax,%edx
f0101786:	76 2e                	jbe    f01017b6 <memmove+0x47>
		s += n;
		d += n;
f0101788:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010178b:	89 d6                	mov    %edx,%esi
f010178d:	09 fe                	or     %edi,%esi
f010178f:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101795:	74 0c                	je     f01017a3 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101797:	83 ef 01             	sub    $0x1,%edi
f010179a:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f010179d:	fd                   	std    
f010179e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01017a0:	fc                   	cld    
f01017a1:	eb 21                	jmp    f01017c4 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01017a3:	f6 c1 03             	test   $0x3,%cl
f01017a6:	75 ef                	jne    f0101797 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01017a8:	83 ef 04             	sub    $0x4,%edi
f01017ab:	8d 72 fc             	lea    -0x4(%edx),%esi
f01017ae:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01017b1:	fd                   	std    
f01017b2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01017b4:	eb ea                	jmp    f01017a0 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01017b6:	89 f2                	mov    %esi,%edx
f01017b8:	09 c2                	or     %eax,%edx
f01017ba:	f6 c2 03             	test   $0x3,%dl
f01017bd:	74 09                	je     f01017c8 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01017bf:	89 c7                	mov    %eax,%edi
f01017c1:	fc                   	cld    
f01017c2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01017c4:	5e                   	pop    %esi
f01017c5:	5f                   	pop    %edi
f01017c6:	5d                   	pop    %ebp
f01017c7:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01017c8:	f6 c1 03             	test   $0x3,%cl
f01017cb:	75 f2                	jne    f01017bf <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01017cd:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01017d0:	89 c7                	mov    %eax,%edi
f01017d2:	fc                   	cld    
f01017d3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01017d5:	eb ed                	jmp    f01017c4 <memmove+0x55>

f01017d7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01017d7:	55                   	push   %ebp
f01017d8:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01017da:	ff 75 10             	pushl  0x10(%ebp)
f01017dd:	ff 75 0c             	pushl  0xc(%ebp)
f01017e0:	ff 75 08             	pushl  0x8(%ebp)
f01017e3:	e8 87 ff ff ff       	call   f010176f <memmove>
}
f01017e8:	c9                   	leave  
f01017e9:	c3                   	ret    

f01017ea <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01017ea:	55                   	push   %ebp
f01017eb:	89 e5                	mov    %esp,%ebp
f01017ed:	56                   	push   %esi
f01017ee:	53                   	push   %ebx
f01017ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01017f2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01017f5:	89 c6                	mov    %eax,%esi
f01017f7:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01017fa:	39 f0                	cmp    %esi,%eax
f01017fc:	74 1c                	je     f010181a <memcmp+0x30>
		if (*s1 != *s2)
f01017fe:	0f b6 08             	movzbl (%eax),%ecx
f0101801:	0f b6 1a             	movzbl (%edx),%ebx
f0101804:	38 d9                	cmp    %bl,%cl
f0101806:	75 08                	jne    f0101810 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101808:	83 c0 01             	add    $0x1,%eax
f010180b:	83 c2 01             	add    $0x1,%edx
f010180e:	eb ea                	jmp    f01017fa <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0101810:	0f b6 c1             	movzbl %cl,%eax
f0101813:	0f b6 db             	movzbl %bl,%ebx
f0101816:	29 d8                	sub    %ebx,%eax
f0101818:	eb 05                	jmp    f010181f <memcmp+0x35>
	}

	return 0;
f010181a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010181f:	5b                   	pop    %ebx
f0101820:	5e                   	pop    %esi
f0101821:	5d                   	pop    %ebp
f0101822:	c3                   	ret    

f0101823 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101823:	55                   	push   %ebp
f0101824:	89 e5                	mov    %esp,%ebp
f0101826:	8b 45 08             	mov    0x8(%ebp),%eax
f0101829:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010182c:	89 c2                	mov    %eax,%edx
f010182e:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101831:	39 d0                	cmp    %edx,%eax
f0101833:	73 09                	jae    f010183e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101835:	38 08                	cmp    %cl,(%eax)
f0101837:	74 05                	je     f010183e <memfind+0x1b>
	for (; s < ends; s++)
f0101839:	83 c0 01             	add    $0x1,%eax
f010183c:	eb f3                	jmp    f0101831 <memfind+0xe>
			break;
	return (void *) s;
}
f010183e:	5d                   	pop    %ebp
f010183f:	c3                   	ret    

f0101840 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101840:	55                   	push   %ebp
f0101841:	89 e5                	mov    %esp,%ebp
f0101843:	57                   	push   %edi
f0101844:	56                   	push   %esi
f0101845:	53                   	push   %ebx
f0101846:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101849:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010184c:	eb 03                	jmp    f0101851 <strtol+0x11>
		s++;
f010184e:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0101851:	0f b6 01             	movzbl (%ecx),%eax
f0101854:	3c 20                	cmp    $0x20,%al
f0101856:	74 f6                	je     f010184e <strtol+0xe>
f0101858:	3c 09                	cmp    $0x9,%al
f010185a:	74 f2                	je     f010184e <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f010185c:	3c 2b                	cmp    $0x2b,%al
f010185e:	74 2e                	je     f010188e <strtol+0x4e>
	int neg = 0;
f0101860:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0101865:	3c 2d                	cmp    $0x2d,%al
f0101867:	74 2f                	je     f0101898 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101869:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010186f:	75 05                	jne    f0101876 <strtol+0x36>
f0101871:	80 39 30             	cmpb   $0x30,(%ecx)
f0101874:	74 2c                	je     f01018a2 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101876:	85 db                	test   %ebx,%ebx
f0101878:	75 0a                	jne    f0101884 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010187a:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f010187f:	80 39 30             	cmpb   $0x30,(%ecx)
f0101882:	74 28                	je     f01018ac <strtol+0x6c>
		base = 10;
f0101884:	b8 00 00 00 00       	mov    $0x0,%eax
f0101889:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010188c:	eb 50                	jmp    f01018de <strtol+0x9e>
		s++;
f010188e:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0101891:	bf 00 00 00 00       	mov    $0x0,%edi
f0101896:	eb d1                	jmp    f0101869 <strtol+0x29>
		s++, neg = 1;
f0101898:	83 c1 01             	add    $0x1,%ecx
f010189b:	bf 01 00 00 00       	mov    $0x1,%edi
f01018a0:	eb c7                	jmp    f0101869 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01018a2:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01018a6:	74 0e                	je     f01018b6 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01018a8:	85 db                	test   %ebx,%ebx
f01018aa:	75 d8                	jne    f0101884 <strtol+0x44>
		s++, base = 8;
f01018ac:	83 c1 01             	add    $0x1,%ecx
f01018af:	bb 08 00 00 00       	mov    $0x8,%ebx
f01018b4:	eb ce                	jmp    f0101884 <strtol+0x44>
		s += 2, base = 16;
f01018b6:	83 c1 02             	add    $0x2,%ecx
f01018b9:	bb 10 00 00 00       	mov    $0x10,%ebx
f01018be:	eb c4                	jmp    f0101884 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01018c0:	8d 72 9f             	lea    -0x61(%edx),%esi
f01018c3:	89 f3                	mov    %esi,%ebx
f01018c5:	80 fb 19             	cmp    $0x19,%bl
f01018c8:	77 29                	ja     f01018f3 <strtol+0xb3>
			dig = *s - 'a' + 10;
f01018ca:	0f be d2             	movsbl %dl,%edx
f01018cd:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01018d0:	3b 55 10             	cmp    0x10(%ebp),%edx
f01018d3:	7d 30                	jge    f0101905 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01018d5:	83 c1 01             	add    $0x1,%ecx
f01018d8:	0f af 45 10          	imul   0x10(%ebp),%eax
f01018dc:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f01018de:	0f b6 11             	movzbl (%ecx),%edx
f01018e1:	8d 72 d0             	lea    -0x30(%edx),%esi
f01018e4:	89 f3                	mov    %esi,%ebx
f01018e6:	80 fb 09             	cmp    $0x9,%bl
f01018e9:	77 d5                	ja     f01018c0 <strtol+0x80>
			dig = *s - '0';
f01018eb:	0f be d2             	movsbl %dl,%edx
f01018ee:	83 ea 30             	sub    $0x30,%edx
f01018f1:	eb dd                	jmp    f01018d0 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f01018f3:	8d 72 bf             	lea    -0x41(%edx),%esi
f01018f6:	89 f3                	mov    %esi,%ebx
f01018f8:	80 fb 19             	cmp    $0x19,%bl
f01018fb:	77 08                	ja     f0101905 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01018fd:	0f be d2             	movsbl %dl,%edx
f0101900:	83 ea 37             	sub    $0x37,%edx
f0101903:	eb cb                	jmp    f01018d0 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0101905:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101909:	74 05                	je     f0101910 <strtol+0xd0>
		*endptr = (char *) s;
f010190b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010190e:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0101910:	89 c2                	mov    %eax,%edx
f0101912:	f7 da                	neg    %edx
f0101914:	85 ff                	test   %edi,%edi
f0101916:	0f 45 c2             	cmovne %edx,%eax
}
f0101919:	5b                   	pop    %ebx
f010191a:	5e                   	pop    %esi
f010191b:	5f                   	pop    %edi
f010191c:	5d                   	pop    %ebp
f010191d:	c3                   	ret    
f010191e:	66 90                	xchg   %ax,%ax

f0101920 <__udivdi3>:
f0101920:	55                   	push   %ebp
f0101921:	57                   	push   %edi
f0101922:	56                   	push   %esi
f0101923:	53                   	push   %ebx
f0101924:	83 ec 1c             	sub    $0x1c,%esp
f0101927:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010192b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010192f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101933:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0101937:	85 d2                	test   %edx,%edx
f0101939:	75 35                	jne    f0101970 <__udivdi3+0x50>
f010193b:	39 f3                	cmp    %esi,%ebx
f010193d:	0f 87 bd 00 00 00    	ja     f0101a00 <__udivdi3+0xe0>
f0101943:	85 db                	test   %ebx,%ebx
f0101945:	89 d9                	mov    %ebx,%ecx
f0101947:	75 0b                	jne    f0101954 <__udivdi3+0x34>
f0101949:	b8 01 00 00 00       	mov    $0x1,%eax
f010194e:	31 d2                	xor    %edx,%edx
f0101950:	f7 f3                	div    %ebx
f0101952:	89 c1                	mov    %eax,%ecx
f0101954:	31 d2                	xor    %edx,%edx
f0101956:	89 f0                	mov    %esi,%eax
f0101958:	f7 f1                	div    %ecx
f010195a:	89 c6                	mov    %eax,%esi
f010195c:	89 e8                	mov    %ebp,%eax
f010195e:	89 f7                	mov    %esi,%edi
f0101960:	f7 f1                	div    %ecx
f0101962:	89 fa                	mov    %edi,%edx
f0101964:	83 c4 1c             	add    $0x1c,%esp
f0101967:	5b                   	pop    %ebx
f0101968:	5e                   	pop    %esi
f0101969:	5f                   	pop    %edi
f010196a:	5d                   	pop    %ebp
f010196b:	c3                   	ret    
f010196c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101970:	39 f2                	cmp    %esi,%edx
f0101972:	77 7c                	ja     f01019f0 <__udivdi3+0xd0>
f0101974:	0f bd fa             	bsr    %edx,%edi
f0101977:	83 f7 1f             	xor    $0x1f,%edi
f010197a:	0f 84 98 00 00 00    	je     f0101a18 <__udivdi3+0xf8>
f0101980:	89 f9                	mov    %edi,%ecx
f0101982:	b8 20 00 00 00       	mov    $0x20,%eax
f0101987:	29 f8                	sub    %edi,%eax
f0101989:	d3 e2                	shl    %cl,%edx
f010198b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010198f:	89 c1                	mov    %eax,%ecx
f0101991:	89 da                	mov    %ebx,%edx
f0101993:	d3 ea                	shr    %cl,%edx
f0101995:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101999:	09 d1                	or     %edx,%ecx
f010199b:	89 f2                	mov    %esi,%edx
f010199d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01019a1:	89 f9                	mov    %edi,%ecx
f01019a3:	d3 e3                	shl    %cl,%ebx
f01019a5:	89 c1                	mov    %eax,%ecx
f01019a7:	d3 ea                	shr    %cl,%edx
f01019a9:	89 f9                	mov    %edi,%ecx
f01019ab:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01019af:	d3 e6                	shl    %cl,%esi
f01019b1:	89 eb                	mov    %ebp,%ebx
f01019b3:	89 c1                	mov    %eax,%ecx
f01019b5:	d3 eb                	shr    %cl,%ebx
f01019b7:	09 de                	or     %ebx,%esi
f01019b9:	89 f0                	mov    %esi,%eax
f01019bb:	f7 74 24 08          	divl   0x8(%esp)
f01019bf:	89 d6                	mov    %edx,%esi
f01019c1:	89 c3                	mov    %eax,%ebx
f01019c3:	f7 64 24 0c          	mull   0xc(%esp)
f01019c7:	39 d6                	cmp    %edx,%esi
f01019c9:	72 0c                	jb     f01019d7 <__udivdi3+0xb7>
f01019cb:	89 f9                	mov    %edi,%ecx
f01019cd:	d3 e5                	shl    %cl,%ebp
f01019cf:	39 c5                	cmp    %eax,%ebp
f01019d1:	73 5d                	jae    f0101a30 <__udivdi3+0x110>
f01019d3:	39 d6                	cmp    %edx,%esi
f01019d5:	75 59                	jne    f0101a30 <__udivdi3+0x110>
f01019d7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01019da:	31 ff                	xor    %edi,%edi
f01019dc:	89 fa                	mov    %edi,%edx
f01019de:	83 c4 1c             	add    $0x1c,%esp
f01019e1:	5b                   	pop    %ebx
f01019e2:	5e                   	pop    %esi
f01019e3:	5f                   	pop    %edi
f01019e4:	5d                   	pop    %ebp
f01019e5:	c3                   	ret    
f01019e6:	8d 76 00             	lea    0x0(%esi),%esi
f01019e9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01019f0:	31 ff                	xor    %edi,%edi
f01019f2:	31 c0                	xor    %eax,%eax
f01019f4:	89 fa                	mov    %edi,%edx
f01019f6:	83 c4 1c             	add    $0x1c,%esp
f01019f9:	5b                   	pop    %ebx
f01019fa:	5e                   	pop    %esi
f01019fb:	5f                   	pop    %edi
f01019fc:	5d                   	pop    %ebp
f01019fd:	c3                   	ret    
f01019fe:	66 90                	xchg   %ax,%ax
f0101a00:	31 ff                	xor    %edi,%edi
f0101a02:	89 e8                	mov    %ebp,%eax
f0101a04:	89 f2                	mov    %esi,%edx
f0101a06:	f7 f3                	div    %ebx
f0101a08:	89 fa                	mov    %edi,%edx
f0101a0a:	83 c4 1c             	add    $0x1c,%esp
f0101a0d:	5b                   	pop    %ebx
f0101a0e:	5e                   	pop    %esi
f0101a0f:	5f                   	pop    %edi
f0101a10:	5d                   	pop    %ebp
f0101a11:	c3                   	ret    
f0101a12:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101a18:	39 f2                	cmp    %esi,%edx
f0101a1a:	72 06                	jb     f0101a22 <__udivdi3+0x102>
f0101a1c:	31 c0                	xor    %eax,%eax
f0101a1e:	39 eb                	cmp    %ebp,%ebx
f0101a20:	77 d2                	ja     f01019f4 <__udivdi3+0xd4>
f0101a22:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a27:	eb cb                	jmp    f01019f4 <__udivdi3+0xd4>
f0101a29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a30:	89 d8                	mov    %ebx,%eax
f0101a32:	31 ff                	xor    %edi,%edi
f0101a34:	eb be                	jmp    f01019f4 <__udivdi3+0xd4>
f0101a36:	66 90                	xchg   %ax,%ax
f0101a38:	66 90                	xchg   %ax,%ax
f0101a3a:	66 90                	xchg   %ax,%ax
f0101a3c:	66 90                	xchg   %ax,%ax
f0101a3e:	66 90                	xchg   %ax,%ax

f0101a40 <__umoddi3>:
f0101a40:	55                   	push   %ebp
f0101a41:	57                   	push   %edi
f0101a42:	56                   	push   %esi
f0101a43:	53                   	push   %ebx
f0101a44:	83 ec 1c             	sub    $0x1c,%esp
f0101a47:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0101a4b:	8b 74 24 30          	mov    0x30(%esp),%esi
f0101a4f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101a53:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101a57:	85 ed                	test   %ebp,%ebp
f0101a59:	89 f0                	mov    %esi,%eax
f0101a5b:	89 da                	mov    %ebx,%edx
f0101a5d:	75 19                	jne    f0101a78 <__umoddi3+0x38>
f0101a5f:	39 df                	cmp    %ebx,%edi
f0101a61:	0f 86 b1 00 00 00    	jbe    f0101b18 <__umoddi3+0xd8>
f0101a67:	f7 f7                	div    %edi
f0101a69:	89 d0                	mov    %edx,%eax
f0101a6b:	31 d2                	xor    %edx,%edx
f0101a6d:	83 c4 1c             	add    $0x1c,%esp
f0101a70:	5b                   	pop    %ebx
f0101a71:	5e                   	pop    %esi
f0101a72:	5f                   	pop    %edi
f0101a73:	5d                   	pop    %ebp
f0101a74:	c3                   	ret    
f0101a75:	8d 76 00             	lea    0x0(%esi),%esi
f0101a78:	39 dd                	cmp    %ebx,%ebp
f0101a7a:	77 f1                	ja     f0101a6d <__umoddi3+0x2d>
f0101a7c:	0f bd cd             	bsr    %ebp,%ecx
f0101a7f:	83 f1 1f             	xor    $0x1f,%ecx
f0101a82:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101a86:	0f 84 b4 00 00 00    	je     f0101b40 <__umoddi3+0x100>
f0101a8c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101a91:	89 c2                	mov    %eax,%edx
f0101a93:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101a97:	29 c2                	sub    %eax,%edx
f0101a99:	89 c1                	mov    %eax,%ecx
f0101a9b:	89 f8                	mov    %edi,%eax
f0101a9d:	d3 e5                	shl    %cl,%ebp
f0101a9f:	89 d1                	mov    %edx,%ecx
f0101aa1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101aa5:	d3 e8                	shr    %cl,%eax
f0101aa7:	09 c5                	or     %eax,%ebp
f0101aa9:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101aad:	89 c1                	mov    %eax,%ecx
f0101aaf:	d3 e7                	shl    %cl,%edi
f0101ab1:	89 d1                	mov    %edx,%ecx
f0101ab3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101ab7:	89 df                	mov    %ebx,%edi
f0101ab9:	d3 ef                	shr    %cl,%edi
f0101abb:	89 c1                	mov    %eax,%ecx
f0101abd:	89 f0                	mov    %esi,%eax
f0101abf:	d3 e3                	shl    %cl,%ebx
f0101ac1:	89 d1                	mov    %edx,%ecx
f0101ac3:	89 fa                	mov    %edi,%edx
f0101ac5:	d3 e8                	shr    %cl,%eax
f0101ac7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101acc:	09 d8                	or     %ebx,%eax
f0101ace:	f7 f5                	div    %ebp
f0101ad0:	d3 e6                	shl    %cl,%esi
f0101ad2:	89 d1                	mov    %edx,%ecx
f0101ad4:	f7 64 24 08          	mull   0x8(%esp)
f0101ad8:	39 d1                	cmp    %edx,%ecx
f0101ada:	89 c3                	mov    %eax,%ebx
f0101adc:	89 d7                	mov    %edx,%edi
f0101ade:	72 06                	jb     f0101ae6 <__umoddi3+0xa6>
f0101ae0:	75 0e                	jne    f0101af0 <__umoddi3+0xb0>
f0101ae2:	39 c6                	cmp    %eax,%esi
f0101ae4:	73 0a                	jae    f0101af0 <__umoddi3+0xb0>
f0101ae6:	2b 44 24 08          	sub    0x8(%esp),%eax
f0101aea:	19 ea                	sbb    %ebp,%edx
f0101aec:	89 d7                	mov    %edx,%edi
f0101aee:	89 c3                	mov    %eax,%ebx
f0101af0:	89 ca                	mov    %ecx,%edx
f0101af2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0101af7:	29 de                	sub    %ebx,%esi
f0101af9:	19 fa                	sbb    %edi,%edx
f0101afb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0101aff:	89 d0                	mov    %edx,%eax
f0101b01:	d3 e0                	shl    %cl,%eax
f0101b03:	89 d9                	mov    %ebx,%ecx
f0101b05:	d3 ee                	shr    %cl,%esi
f0101b07:	d3 ea                	shr    %cl,%edx
f0101b09:	09 f0                	or     %esi,%eax
f0101b0b:	83 c4 1c             	add    $0x1c,%esp
f0101b0e:	5b                   	pop    %ebx
f0101b0f:	5e                   	pop    %esi
f0101b10:	5f                   	pop    %edi
f0101b11:	5d                   	pop    %ebp
f0101b12:	c3                   	ret    
f0101b13:	90                   	nop
f0101b14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b18:	85 ff                	test   %edi,%edi
f0101b1a:	89 f9                	mov    %edi,%ecx
f0101b1c:	75 0b                	jne    f0101b29 <__umoddi3+0xe9>
f0101b1e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101b23:	31 d2                	xor    %edx,%edx
f0101b25:	f7 f7                	div    %edi
f0101b27:	89 c1                	mov    %eax,%ecx
f0101b29:	89 d8                	mov    %ebx,%eax
f0101b2b:	31 d2                	xor    %edx,%edx
f0101b2d:	f7 f1                	div    %ecx
f0101b2f:	89 f0                	mov    %esi,%eax
f0101b31:	f7 f1                	div    %ecx
f0101b33:	e9 31 ff ff ff       	jmp    f0101a69 <__umoddi3+0x29>
f0101b38:	90                   	nop
f0101b39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b40:	39 dd                	cmp    %ebx,%ebp
f0101b42:	72 08                	jb     f0101b4c <__umoddi3+0x10c>
f0101b44:	39 f7                	cmp    %esi,%edi
f0101b46:	0f 87 21 ff ff ff    	ja     f0101a6d <__umoddi3+0x2d>
f0101b4c:	89 da                	mov    %ebx,%edx
f0101b4e:	89 f0                	mov    %esi,%eax
f0101b50:	29 f8                	sub    %edi,%eax
f0101b52:	19 ea                	sbb    %ebp,%edx
f0101b54:	e9 14 ff ff ff       	jmp    f0101a6d <__umoddi3+0x2d>
