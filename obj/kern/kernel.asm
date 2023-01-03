
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 30 11 f0       	mov    $0xf0113000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 03 01 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010004c:	81 c3 bc 42 01 00    	add    $0x142bc,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 60 60 11 f0    	mov    $0xf0116060,%edx
f0100058:	c7 c0 c0 66 11 f0    	mov    $0xf01166c0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 f8 22 00 00       	call   f0102361 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 98 e4 fe ff    	lea    -0x11b68(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 4e 17 00 00       	call   f01017d0 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 71 0c 00 00       	call   f0100cf8 <mem_init>
f0100087:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008a:	83 ec 0c             	sub    $0xc,%esp
f010008d:	6a 00                	push   $0x0
f010008f:	e8 8c 07 00 00       	call   f0100820 <monitor>
f0100094:	83 c4 10             	add    $0x10,%esp
f0100097:	eb f1                	jmp    f010008a <i386_init+0x4a>

f0100099 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100099:	55                   	push   %ebp
f010009a:	89 e5                	mov    %esp,%ebp
f010009c:	57                   	push   %edi
f010009d:	56                   	push   %esi
f010009e:	53                   	push   %ebx
f010009f:	83 ec 0c             	sub    $0xc,%esp
f01000a2:	e8 a8 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f01000a7:	81 c3 61 42 01 00    	add    $0x14261,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 c4 66 11 f0    	mov    $0xf01166c4,%eax
f01000b6:	83 38 00             	cmpl   $0x0,(%eax)
f01000b9:	74 0f                	je     f01000ca <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000bb:	83 ec 0c             	sub    $0xc,%esp
f01000be:	6a 00                	push   $0x0
f01000c0:	e8 5b 07 00 00       	call   f0100820 <monitor>
f01000c5:	83 c4 10             	add    $0x10,%esp
f01000c8:	eb f1                	jmp    f01000bb <_panic+0x22>
	panicstr = fmt;
f01000ca:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000cc:	fa                   	cli    
f01000cd:	fc                   	cld    
	va_start(ap, fmt);
f01000ce:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d1:	83 ec 04             	sub    $0x4,%esp
f01000d4:	ff 75 0c             	pushl  0xc(%ebp)
f01000d7:	ff 75 08             	pushl  0x8(%ebp)
f01000da:	8d 83 b3 e4 fe ff    	lea    -0x11b4d(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 ea 16 00 00       	call   f01017d0 <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 a9 16 00 00       	call   f0101799 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 ef e4 fe ff    	lea    -0x11b11(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 d2 16 00 00       	call   f01017d0 <cprintf>
f01000fe:	83 c4 10             	add    $0x10,%esp
f0100101:	eb b8                	jmp    f01000bb <_panic+0x22>

f0100103 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100103:	55                   	push   %ebp
f0100104:	89 e5                	mov    %esp,%ebp
f0100106:	56                   	push   %esi
f0100107:	53                   	push   %ebx
f0100108:	e8 42 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010010d:	81 c3 fb 41 01 00    	add    $0x141fb,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 cb e4 fe ff    	lea    -0x11b35(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 a5 16 00 00       	call   f01017d0 <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 62 16 00 00       	call   f0101799 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 ef e4 fe ff    	lea    -0x11b11(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 8b 16 00 00       	call   f01017d0 <cprintf>
	va_end(ap);
}
f0100145:	83 c4 10             	add    $0x10,%esp
f0100148:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010014b:	5b                   	pop    %ebx
f010014c:	5e                   	pop    %esi
f010014d:	5d                   	pop    %ebp
f010014e:	c3                   	ret    

f010014f <__x86.get_pc_thunk.bx>:
f010014f:	8b 1c 24             	mov    (%esp),%ebx
f0100152:	c3                   	ret    

f0100153 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100153:	55                   	push   %ebp
f0100154:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100156:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010015b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 0b                	je     f010016b <serial_proc_data+0x18>
f0100160:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100165:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100166:	0f b6 c0             	movzbl %al,%eax
}
f0100169:	5d                   	pop    %ebp
f010016a:	c3                   	ret    
		return -1;
f010016b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100170:	eb f7                	jmp    f0100169 <serial_proc_data+0x16>

f0100172 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100172:	55                   	push   %ebp
f0100173:	89 e5                	mov    %esp,%ebp
f0100175:	56                   	push   %esi
f0100176:	53                   	push   %ebx
f0100177:	e8 d3 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010017c:	81 c3 8c 41 01 00    	add    $0x1418c,%ebx
f0100182:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f0100184:	ff d6                	call   *%esi
f0100186:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100189:	74 2e                	je     f01001b9 <cons_intr+0x47>
		if (c == 0)
f010018b:	85 c0                	test   %eax,%eax
f010018d:	74 f5                	je     f0100184 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f010018f:	8b 8b 7c 1f 00 00    	mov    0x1f7c(%ebx),%ecx
f0100195:	8d 51 01             	lea    0x1(%ecx),%edx
f0100198:	89 93 7c 1f 00 00    	mov    %edx,0x1f7c(%ebx)
f010019e:	88 84 0b 78 1d 00 00 	mov    %al,0x1d78(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001a5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001ab:	75 d7                	jne    f0100184 <cons_intr+0x12>
			cons.wpos = 0;
f01001ad:	c7 83 7c 1f 00 00 00 	movl   $0x0,0x1f7c(%ebx)
f01001b4:	00 00 00 
f01001b7:	eb cb                	jmp    f0100184 <cons_intr+0x12>
	}
}
f01001b9:	5b                   	pop    %ebx
f01001ba:	5e                   	pop    %esi
f01001bb:	5d                   	pop    %ebp
f01001bc:	c3                   	ret    

f01001bd <kbd_proc_data>:
{
f01001bd:	55                   	push   %ebp
f01001be:	89 e5                	mov    %esp,%ebp
f01001c0:	56                   	push   %esi
f01001c1:	53                   	push   %ebx
f01001c2:	e8 88 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01001c7:	81 c3 41 41 01 00    	add    $0x14141,%ebx
f01001cd:	ba 64 00 00 00       	mov    $0x64,%edx
f01001d2:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001d3:	a8 01                	test   $0x1,%al
f01001d5:	0f 84 06 01 00 00    	je     f01002e1 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f01001db:	a8 20                	test   $0x20,%al
f01001dd:	0f 85 05 01 00 00    	jne    f01002e8 <kbd_proc_data+0x12b>
f01001e3:	ba 60 00 00 00       	mov    $0x60,%edx
f01001e8:	ec                   	in     (%dx),%al
f01001e9:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001eb:	3c e0                	cmp    $0xe0,%al
f01001ed:	0f 84 93 00 00 00    	je     f0100286 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f01001f3:	84 c0                	test   %al,%al
f01001f5:	0f 88 a0 00 00 00    	js     f010029b <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f01001fb:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x57>
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 8b 58 1d 00 00    	mov    %ecx,0x1d58(%ebx)
	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
f0100217:	0f b6 84 13 18 e6 fe 	movzbl -0x119e8(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 18 e5 fe 	movzbl -0x11ae8(%ebx,%edx,1),%ecx
f010022c:	ff 
f010022d:	31 c8                	xor    %ecx,%eax
f010022f:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100235:	89 c1                	mov    %eax,%ecx
f0100237:	83 e1 03             	and    $0x3,%ecx
f010023a:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
f0100241:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100245:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100248:	a8 08                	test   $0x8,%al
f010024a:	74 0d                	je     f0100259 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f010024c:	89 f2                	mov    %esi,%edx
f010024e:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100251:	83 f9 19             	cmp    $0x19,%ecx
f0100254:	77 7a                	ja     f01002d0 <kbd_proc_data+0x113>
			c += 'A' - 'a';
f0100256:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100259:	f7 d0                	not    %eax
f010025b:	a8 06                	test   $0x6,%al
f010025d:	75 33                	jne    f0100292 <kbd_proc_data+0xd5>
f010025f:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f0100265:	75 2b                	jne    f0100292 <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f0100267:	83 ec 0c             	sub    $0xc,%esp
f010026a:	8d 83 e5 e4 fe ff    	lea    -0x11b1b(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 5a 15 00 00       	call   f01017d0 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100276:	b8 03 00 00 00       	mov    $0x3,%eax
f010027b:	ba 92 00 00 00       	mov    $0x92,%edx
f0100280:	ee                   	out    %al,(%dx)
f0100281:	83 c4 10             	add    $0x10,%esp
f0100284:	eb 0c                	jmp    f0100292 <kbd_proc_data+0xd5>
		shift |= E0ESC;
f0100286:	83 8b 58 1d 00 00 40 	orl    $0x40,0x1d58(%ebx)
		return 0;
f010028d:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100292:	89 f0                	mov    %esi,%eax
f0100294:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100297:	5b                   	pop    %ebx
f0100298:	5e                   	pop    %esi
f0100299:	5d                   	pop    %ebp
f010029a:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010029b:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f01002a1:	89 ce                	mov    %ecx,%esi
f01002a3:	83 e6 40             	and    $0x40,%esi
f01002a6:	83 e0 7f             	and    $0x7f,%eax
f01002a9:	85 f6                	test   %esi,%esi
f01002ab:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002ae:	0f b6 d2             	movzbl %dl,%edx
f01002b1:	0f b6 84 13 18 e6 fe 	movzbl -0x119e8(%ebx,%edx,1),%eax
f01002b8:	ff 
f01002b9:	83 c8 40             	or     $0x40,%eax
f01002bc:	0f b6 c0             	movzbl %al,%eax
f01002bf:	f7 d0                	not    %eax
f01002c1:	21 c8                	and    %ecx,%eax
f01002c3:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
		return 0;
f01002c9:	be 00 00 00 00       	mov    $0x0,%esi
f01002ce:	eb c2                	jmp    f0100292 <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f01002d0:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002d3:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002d6:	83 fa 1a             	cmp    $0x1a,%edx
f01002d9:	0f 42 f1             	cmovb  %ecx,%esi
f01002dc:	e9 78 ff ff ff       	jmp    f0100259 <kbd_proc_data+0x9c>
		return -1;
f01002e1:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002e6:	eb aa                	jmp    f0100292 <kbd_proc_data+0xd5>
		return -1;
f01002e8:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002ed:	eb a3                	jmp    f0100292 <kbd_proc_data+0xd5>

f01002ef <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ef:	55                   	push   %ebp
f01002f0:	89 e5                	mov    %esp,%ebp
f01002f2:	57                   	push   %edi
f01002f3:	56                   	push   %esi
f01002f4:	53                   	push   %ebx
f01002f5:	83 ec 1c             	sub    $0x1c,%esp
f01002f8:	e8 52 fe ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01002fd:	81 c3 0b 40 01 00    	add    $0x1400b,%ebx
f0100303:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100306:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010030b:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100310:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100315:	eb 09                	jmp    f0100320 <cons_putc+0x31>
f0100317:	89 ca                	mov    %ecx,%edx
f0100319:	ec                   	in     (%dx),%al
f010031a:	ec                   	in     (%dx),%al
f010031b:	ec                   	in     (%dx),%al
f010031c:	ec                   	in     (%dx),%al
	     i++)
f010031d:	83 c6 01             	add    $0x1,%esi
f0100320:	89 fa                	mov    %edi,%edx
f0100322:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100323:	a8 20                	test   $0x20,%al
f0100325:	75 08                	jne    f010032f <cons_putc+0x40>
f0100327:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010032d:	7e e8                	jle    f0100317 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f010032f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100332:	89 f8                	mov    %edi,%eax
f0100334:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100337:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010033c:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010033d:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100342:	bf 79 03 00 00       	mov    $0x379,%edi
f0100347:	b9 84 00 00 00       	mov    $0x84,%ecx
f010034c:	eb 09                	jmp    f0100357 <cons_putc+0x68>
f010034e:	89 ca                	mov    %ecx,%edx
f0100350:	ec                   	in     (%dx),%al
f0100351:	ec                   	in     (%dx),%al
f0100352:	ec                   	in     (%dx),%al
f0100353:	ec                   	in     (%dx),%al
f0100354:	83 c6 01             	add    $0x1,%esi
f0100357:	89 fa                	mov    %edi,%edx
f0100359:	ec                   	in     (%dx),%al
f010035a:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100360:	7f 04                	jg     f0100366 <cons_putc+0x77>
f0100362:	84 c0                	test   %al,%al
f0100364:	79 e8                	jns    f010034e <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100366:	ba 78 03 00 00       	mov    $0x378,%edx
f010036b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f010036f:	ee                   	out    %al,(%dx)
f0100370:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100375:	b8 0d 00 00 00       	mov    $0xd,%eax
f010037a:	ee                   	out    %al,(%dx)
f010037b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100380:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100381:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100384:	89 fa                	mov    %edi,%edx
f0100386:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010038c:	89 f8                	mov    %edi,%eax
f010038e:	80 cc 07             	or     $0x7,%ah
f0100391:	85 d2                	test   %edx,%edx
f0100393:	0f 45 c7             	cmovne %edi,%eax
f0100396:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100399:	0f b6 c0             	movzbl %al,%eax
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	0f 84 b9 00 00 00    	je     f010045e <cons_putc+0x16f>
f01003a5:	83 f8 09             	cmp    $0x9,%eax
f01003a8:	7e 74                	jle    f010041e <cons_putc+0x12f>
f01003aa:	83 f8 0a             	cmp    $0xa,%eax
f01003ad:	0f 84 9e 00 00 00    	je     f0100451 <cons_putc+0x162>
f01003b3:	83 f8 0d             	cmp    $0xd,%eax
f01003b6:	0f 85 d9 00 00 00    	jne    f0100495 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f01003bc:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f01003c3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c9:	c1 e8 16             	shr    $0x16,%eax
f01003cc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003cf:	c1 e0 04             	shl    $0x4,%eax
f01003d2:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003d9:	66 81 bb 80 1f 00 00 	cmpw   $0x7cf,0x1f80(%ebx)
f01003e0:	cf 07 
f01003e2:	0f 87 d4 00 00 00    	ja     f01004bc <cons_putc+0x1cd>
	outb(addr_6845, 14);
f01003e8:	8b 8b 88 1f 00 00    	mov    0x1f88(%ebx),%ecx
f01003ee:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003f3:	89 ca                	mov    %ecx,%edx
f01003f5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003f6:	0f b7 9b 80 1f 00 00 	movzwl 0x1f80(%ebx),%ebx
f01003fd:	8d 71 01             	lea    0x1(%ecx),%esi
f0100400:	89 d8                	mov    %ebx,%eax
f0100402:	66 c1 e8 08          	shr    $0x8,%ax
f0100406:	89 f2                	mov    %esi,%edx
f0100408:	ee                   	out    %al,(%dx)
f0100409:	b8 0f 00 00 00       	mov    $0xf,%eax
f010040e:	89 ca                	mov    %ecx,%edx
f0100410:	ee                   	out    %al,(%dx)
f0100411:	89 d8                	mov    %ebx,%eax
f0100413:	89 f2                	mov    %esi,%edx
f0100415:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100416:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100419:	5b                   	pop    %ebx
f010041a:	5e                   	pop    %esi
f010041b:	5f                   	pop    %edi
f010041c:	5d                   	pop    %ebp
f010041d:	c3                   	ret    
	switch (c & 0xff) {
f010041e:	83 f8 08             	cmp    $0x8,%eax
f0100421:	75 72                	jne    f0100495 <cons_putc+0x1a6>
		if (crt_pos > 0) {
f0100423:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010042a:	66 85 c0             	test   %ax,%ax
f010042d:	74 b9                	je     f01003e8 <cons_putc+0xf9>
			crt_pos--;
f010042f:	83 e8 01             	sub    $0x1,%eax
f0100432:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100440:	b2 00                	mov    $0x0,%dl
f0100442:	83 ca 20             	or     $0x20,%edx
f0100445:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f010044b:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010044f:	eb 88                	jmp    f01003d9 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100451:	66 83 83 80 1f 00 00 	addw   $0x50,0x1f80(%ebx)
f0100458:	50 
f0100459:	e9 5e ff ff ff       	jmp    f01003bc <cons_putc+0xcd>
		cons_putc(' ');
f010045e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100463:	e8 87 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100468:	b8 20 00 00 00       	mov    $0x20,%eax
f010046d:	e8 7d fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100472:	b8 20 00 00 00       	mov    $0x20,%eax
f0100477:	e8 73 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f010047c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100481:	e8 69 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100486:	b8 20 00 00 00       	mov    $0x20,%eax
f010048b:	e8 5f fe ff ff       	call   f01002ef <cons_putc>
f0100490:	e9 44 ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100495:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010049c:	8d 50 01             	lea    0x1(%eax),%edx
f010049f:	66 89 93 80 1f 00 00 	mov    %dx,0x1f80(%ebx)
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f01004af:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004b3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b7:	e9 1d ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004bc:	8b 83 84 1f 00 00    	mov    0x1f84(%ebx),%eax
f01004c2:	83 ec 04             	sub    $0x4,%esp
f01004c5:	68 00 0f 00 00       	push   $0xf00
f01004ca:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004d0:	52                   	push   %edx
f01004d1:	50                   	push   %eax
f01004d2:	e8 d7 1e 00 00       	call   f01023ae <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004d7:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f01004dd:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004e3:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004e9:	83 c4 10             	add    $0x10,%esp
f01004ec:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004f1:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004f4:	39 d0                	cmp    %edx,%eax
f01004f6:	75 f4                	jne    f01004ec <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f01004f8:	66 83 ab 80 1f 00 00 	subw   $0x50,0x1f80(%ebx)
f01004ff:	50 
f0100500:	e9 e3 fe ff ff       	jmp    f01003e8 <cons_putc+0xf9>

f0100505 <serial_intr>:
{
f0100505:	e8 e7 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010050a:	05 fe 3d 01 00       	add    $0x13dfe,%eax
	if (serial_exists)
f010050f:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 4b be fe ff    	lea    -0x141b5(%eax),%eax
f0100526:	e8 47 fc ff ff       	call   f0100172 <cons_intr>
}
f010052b:	c9                   	leave  
f010052c:	c3                   	ret    

f010052d <kbd_intr>:
{
f010052d:	55                   	push   %ebp
f010052e:	89 e5                	mov    %esp,%ebp
f0100530:	83 ec 08             	sub    $0x8,%esp
f0100533:	e8 b9 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f0100538:	05 d0 3d 01 00       	add    $0x13dd0,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b5 be fe ff    	lea    -0x1414b(%eax),%eax
f0100543:	e8 2a fc ff ff       	call   f0100172 <cons_intr>
}
f0100548:	c9                   	leave  
f0100549:	c3                   	ret    

f010054a <cons_getc>:
{
f010054a:	55                   	push   %ebp
f010054b:	89 e5                	mov    %esp,%ebp
f010054d:	53                   	push   %ebx
f010054e:	83 ec 04             	sub    $0x4,%esp
f0100551:	e8 f9 fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100556:	81 c3 b2 3d 01 00    	add    $0x13db2,%ebx
	serial_intr();
f010055c:	e8 a4 ff ff ff       	call   f0100505 <serial_intr>
	kbd_intr();
f0100561:	e8 c7 ff ff ff       	call   f010052d <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100566:	8b 93 78 1f 00 00    	mov    0x1f78(%ebx),%edx
	return 0;
f010056c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100571:	3b 93 7c 1f 00 00    	cmp    0x1f7c(%ebx),%edx
f0100577:	74 19                	je     f0100592 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100579:	8d 4a 01             	lea    0x1(%edx),%ecx
f010057c:	89 8b 78 1f 00 00    	mov    %ecx,0x1f78(%ebx)
f0100582:	0f b6 84 13 78 1d 00 	movzbl 0x1d78(%ebx,%edx,1),%eax
f0100589:	00 
		if (cons.rpos == CONSBUFSIZE)
f010058a:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100590:	74 06                	je     f0100598 <cons_getc+0x4e>
}
f0100592:	83 c4 04             	add    $0x4,%esp
f0100595:	5b                   	pop    %ebx
f0100596:	5d                   	pop    %ebp
f0100597:	c3                   	ret    
			cons.rpos = 0;
f0100598:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
f010059f:	00 00 00 
f01005a2:	eb ee                	jmp    f0100592 <cons_getc+0x48>

f01005a4 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005a4:	55                   	push   %ebp
f01005a5:	89 e5                	mov    %esp,%ebp
f01005a7:	57                   	push   %edi
f01005a8:	56                   	push   %esi
f01005a9:	53                   	push   %ebx
f01005aa:	83 ec 1c             	sub    $0x1c,%esp
f01005ad:	e8 9d fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01005b2:	81 c3 56 3d 01 00    	add    $0x13d56,%ebx
	was = *cp;
f01005b8:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005bf:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005c6:	5a a5 
	if (*cp != 0xA55A) {
f01005c8:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005cf:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005d3:	0f 84 bc 00 00 00    	je     f0100695 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f01005d9:	c7 83 88 1f 00 00 b4 	movl   $0x3b4,0x1f88(%ebx)
f01005e0:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005e3:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f01005ea:	8b bb 88 1f 00 00    	mov    0x1f88(%ebx),%edi
f01005f0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005f5:	89 fa                	mov    %edi,%edx
f01005f7:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005f8:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005fb:	89 ca                	mov    %ecx,%edx
f01005fd:	ec                   	in     (%dx),%al
f01005fe:	0f b6 f0             	movzbl %al,%esi
f0100601:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100604:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100609:	89 fa                	mov    %edi,%edx
f010060b:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010060c:	89 ca                	mov    %ecx,%edx
f010060e:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010060f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100612:	89 bb 84 1f 00 00    	mov    %edi,0x1f84(%ebx)
	pos |= inb(addr_6845 + 1);
f0100618:	0f b6 c0             	movzbl %al,%eax
f010061b:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010061d:	66 89 b3 80 1f 00 00 	mov    %si,0x1f80(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100624:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100629:	89 c8                	mov    %ecx,%eax
f010062b:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100630:	ee                   	out    %al,(%dx)
f0100631:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100636:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010063b:	89 fa                	mov    %edi,%edx
f010063d:	ee                   	out    %al,(%dx)
f010063e:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100643:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100648:	ee                   	out    %al,(%dx)
f0100649:	be f9 03 00 00       	mov    $0x3f9,%esi
f010064e:	89 c8                	mov    %ecx,%eax
f0100650:	89 f2                	mov    %esi,%edx
f0100652:	ee                   	out    %al,(%dx)
f0100653:	b8 03 00 00 00       	mov    $0x3,%eax
f0100658:	89 fa                	mov    %edi,%edx
f010065a:	ee                   	out    %al,(%dx)
f010065b:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100660:	89 c8                	mov    %ecx,%eax
f0100662:	ee                   	out    %al,(%dx)
f0100663:	b8 01 00 00 00       	mov    $0x1,%eax
f0100668:	89 f2                	mov    %esi,%edx
f010066a:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010066b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100670:	ec                   	in     (%dx),%al
f0100671:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100673:	3c ff                	cmp    $0xff,%al
f0100675:	0f 95 83 8c 1f 00 00 	setne  0x1f8c(%ebx)
f010067c:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100681:	ec                   	in     (%dx),%al
f0100682:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100687:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100688:	80 f9 ff             	cmp    $0xff,%cl
f010068b:	74 25                	je     f01006b2 <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f010068d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100690:	5b                   	pop    %ebx
f0100691:	5e                   	pop    %esi
f0100692:	5f                   	pop    %edi
f0100693:	5d                   	pop    %ebp
f0100694:	c3                   	ret    
		*cp = was;
f0100695:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010069c:	c7 83 88 1f 00 00 d4 	movl   $0x3d4,0x1f88(%ebx)
f01006a3:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a6:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006ad:	e9 38 ff ff ff       	jmp    f01005ea <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006b2:	83 ec 0c             	sub    $0xc,%esp
f01006b5:	8d 83 f1 e4 fe ff    	lea    -0x11b0f(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 0f 11 00 00       	call   f01017d0 <cprintf>
f01006c1:	83 c4 10             	add    $0x10,%esp
}
f01006c4:	eb c7                	jmp    f010068d <cons_init+0xe9>

f01006c6 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006c6:	55                   	push   %ebp
f01006c7:	89 e5                	mov    %esp,%ebp
f01006c9:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01006cf:	e8 1b fc ff ff       	call   f01002ef <cons_putc>
}
f01006d4:	c9                   	leave  
f01006d5:	c3                   	ret    

f01006d6 <getchar>:

int
getchar(void)
{
f01006d6:	55                   	push   %ebp
f01006d7:	89 e5                	mov    %esp,%ebp
f01006d9:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006dc:	e8 69 fe ff ff       	call   f010054a <cons_getc>
f01006e1:	85 c0                	test   %eax,%eax
f01006e3:	74 f7                	je     f01006dc <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006e5:	c9                   	leave  
f01006e6:	c3                   	ret    

f01006e7 <iscons>:

int
iscons(int fdnum)
{
f01006e7:	55                   	push   %ebp
f01006e8:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01006ef:	5d                   	pop    %ebp
f01006f0:	c3                   	ret    

f01006f1 <__x86.get_pc_thunk.ax>:
f01006f1:	8b 04 24             	mov    (%esp),%eax
f01006f4:	c3                   	ret    

f01006f5 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006f5:	55                   	push   %ebp
f01006f6:	89 e5                	mov    %esp,%ebp
f01006f8:	56                   	push   %esi
f01006f9:	53                   	push   %ebx
f01006fa:	e8 50 fa ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01006ff:	81 c3 09 3c 01 00    	add    $0x13c09,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100705:	83 ec 04             	sub    $0x4,%esp
f0100708:	8d 83 18 e7 fe ff    	lea    -0x118e8(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 36 e7 fe ff    	lea    -0x118ca(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 3b e7 fe ff    	lea    -0x118c5(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 ae 10 00 00       	call   f01017d0 <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 a4 e7 fe ff    	lea    -0x1185c(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 44 e7 fe ff    	lea    -0x118bc(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 97 10 00 00       	call   f01017d0 <cprintf>
	return 0;
}
f0100739:	b8 00 00 00 00       	mov    $0x0,%eax
f010073e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100741:	5b                   	pop    %ebx
f0100742:	5e                   	pop    %esi
f0100743:	5d                   	pop    %ebp
f0100744:	c3                   	ret    

f0100745 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100745:	55                   	push   %ebp
f0100746:	89 e5                	mov    %esp,%ebp
f0100748:	57                   	push   %edi
f0100749:	56                   	push   %esi
f010074a:	53                   	push   %ebx
f010074b:	83 ec 18             	sub    $0x18,%esp
f010074e:	e8 fc f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100753:	81 c3 b5 3b 01 00    	add    $0x13bb5,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100759:	8d 83 4d e7 fe ff    	lea    -0x118b3(%ebx),%eax
f010075f:	50                   	push   %eax
f0100760:	e8 6b 10 00 00       	call   f01017d0 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100765:	83 c4 08             	add    $0x8,%esp
f0100768:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010076e:	8d 83 cc e7 fe ff    	lea    -0x11834(%ebx),%eax
f0100774:	50                   	push   %eax
f0100775:	e8 56 10 00 00       	call   f01017d0 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010077a:	83 c4 0c             	add    $0xc,%esp
f010077d:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100783:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100789:	50                   	push   %eax
f010078a:	57                   	push   %edi
f010078b:	8d 83 f4 e7 fe ff    	lea    -0x1180c(%ebx),%eax
f0100791:	50                   	push   %eax
f0100792:	e8 39 10 00 00       	call   f01017d0 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100797:	83 c4 0c             	add    $0xc,%esp
f010079a:	c7 c0 99 27 10 f0    	mov    $0xf0102799,%eax
f01007a0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007a6:	52                   	push   %edx
f01007a7:	50                   	push   %eax
f01007a8:	8d 83 18 e8 fe ff    	lea    -0x117e8(%ebx),%eax
f01007ae:	50                   	push   %eax
f01007af:	e8 1c 10 00 00       	call   f01017d0 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007b4:	83 c4 0c             	add    $0xc,%esp
f01007b7:	c7 c0 60 60 11 f0    	mov    $0xf0116060,%eax
f01007bd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007c3:	52                   	push   %edx
f01007c4:	50                   	push   %eax
f01007c5:	8d 83 3c e8 fe ff    	lea    -0x117c4(%ebx),%eax
f01007cb:	50                   	push   %eax
f01007cc:	e8 ff 0f 00 00       	call   f01017d0 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007d1:	83 c4 0c             	add    $0xc,%esp
f01007d4:	c7 c6 c0 66 11 f0    	mov    $0xf01166c0,%esi
f01007da:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007e0:	50                   	push   %eax
f01007e1:	56                   	push   %esi
f01007e2:	8d 83 60 e8 fe ff    	lea    -0x117a0(%ebx),%eax
f01007e8:	50                   	push   %eax
f01007e9:	e8 e2 0f 00 00       	call   f01017d0 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007ee:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007f1:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f01007f7:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007f9:	c1 fe 0a             	sar    $0xa,%esi
f01007fc:	56                   	push   %esi
f01007fd:	8d 83 84 e8 fe ff    	lea    -0x1177c(%ebx),%eax
f0100803:	50                   	push   %eax
f0100804:	e8 c7 0f 00 00       	call   f01017d0 <cprintf>
	return 0;
}
f0100809:	b8 00 00 00 00       	mov    $0x0,%eax
f010080e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100811:	5b                   	pop    %ebx
f0100812:	5e                   	pop    %esi
f0100813:	5f                   	pop    %edi
f0100814:	5d                   	pop    %ebp
f0100815:	c3                   	ret    

f0100816 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100816:	55                   	push   %ebp
f0100817:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100819:	b8 00 00 00 00       	mov    $0x0,%eax
f010081e:	5d                   	pop    %ebp
f010081f:	c3                   	ret    

f0100820 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100820:	55                   	push   %ebp
f0100821:	89 e5                	mov    %esp,%ebp
f0100823:	57                   	push   %edi
f0100824:	56                   	push   %esi
f0100825:	53                   	push   %ebx
f0100826:	83 ec 68             	sub    $0x68,%esp
f0100829:	e8 21 f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010082e:	81 c3 da 3a 01 00    	add    $0x13ada,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100834:	8d 83 b0 e8 fe ff    	lea    -0x11750(%ebx),%eax
f010083a:	50                   	push   %eax
f010083b:	e8 90 0f 00 00       	call   f01017d0 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100840:	8d 83 d4 e8 fe ff    	lea    -0x1172c(%ebx),%eax
f0100846:	89 04 24             	mov    %eax,(%esp)
f0100849:	e8 82 0f 00 00       	call   f01017d0 <cprintf>
f010084e:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100851:	8d bb 6a e7 fe ff    	lea    -0x11896(%ebx),%edi
f0100857:	eb 4a                	jmp    f01008a3 <monitor+0x83>
f0100859:	83 ec 08             	sub    $0x8,%esp
f010085c:	0f be c0             	movsbl %al,%eax
f010085f:	50                   	push   %eax
f0100860:	57                   	push   %edi
f0100861:	e8 be 1a 00 00       	call   f0102324 <strchr>
f0100866:	83 c4 10             	add    $0x10,%esp
f0100869:	85 c0                	test   %eax,%eax
f010086b:	74 08                	je     f0100875 <monitor+0x55>
			*buf++ = 0;
f010086d:	c6 06 00             	movb   $0x0,(%esi)
f0100870:	8d 76 01             	lea    0x1(%esi),%esi
f0100873:	eb 79                	jmp    f01008ee <monitor+0xce>
		if (*buf == 0)
f0100875:	80 3e 00             	cmpb   $0x0,(%esi)
f0100878:	74 7f                	je     f01008f9 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f010087a:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f010087e:	74 0f                	je     f010088f <monitor+0x6f>
		argv[argc++] = buf;
f0100880:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100883:	8d 48 01             	lea    0x1(%eax),%ecx
f0100886:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f0100889:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f010088d:	eb 44                	jmp    f01008d3 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010088f:	83 ec 08             	sub    $0x8,%esp
f0100892:	6a 10                	push   $0x10
f0100894:	8d 83 6f e7 fe ff    	lea    -0x11891(%ebx),%eax
f010089a:	50                   	push   %eax
f010089b:	e8 30 0f 00 00       	call   f01017d0 <cprintf>
f01008a0:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01008a3:	8d 83 66 e7 fe ff    	lea    -0x1189a(%ebx),%eax
f01008a9:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01008ac:	83 ec 0c             	sub    $0xc,%esp
f01008af:	ff 75 a4             	pushl  -0x5c(%ebp)
f01008b2:	e8 35 18 00 00       	call   f01020ec <readline>
f01008b7:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01008b9:	83 c4 10             	add    $0x10,%esp
f01008bc:	85 c0                	test   %eax,%eax
f01008be:	74 ec                	je     f01008ac <monitor+0x8c>
	argv[argc] = 0;
f01008c0:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01008c7:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f01008ce:	eb 1e                	jmp    f01008ee <monitor+0xce>
			buf++;
f01008d0:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d3:	0f b6 06             	movzbl (%esi),%eax
f01008d6:	84 c0                	test   %al,%al
f01008d8:	74 14                	je     f01008ee <monitor+0xce>
f01008da:	83 ec 08             	sub    $0x8,%esp
f01008dd:	0f be c0             	movsbl %al,%eax
f01008e0:	50                   	push   %eax
f01008e1:	57                   	push   %edi
f01008e2:	e8 3d 1a 00 00       	call   f0102324 <strchr>
f01008e7:	83 c4 10             	add    $0x10,%esp
f01008ea:	85 c0                	test   %eax,%eax
f01008ec:	74 e2                	je     f01008d0 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f01008ee:	0f b6 06             	movzbl (%esi),%eax
f01008f1:	84 c0                	test   %al,%al
f01008f3:	0f 85 60 ff ff ff    	jne    f0100859 <monitor+0x39>
	argv[argc] = 0;
f01008f9:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01008fc:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100903:	00 
	if (argc == 0)
f0100904:	85 c0                	test   %eax,%eax
f0100906:	74 9b                	je     f01008a3 <monitor+0x83>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100908:	83 ec 08             	sub    $0x8,%esp
f010090b:	8d 83 36 e7 fe ff    	lea    -0x118ca(%ebx),%eax
f0100911:	50                   	push   %eax
f0100912:	ff 75 a8             	pushl  -0x58(%ebp)
f0100915:	e8 ac 19 00 00       	call   f01022c6 <strcmp>
f010091a:	83 c4 10             	add    $0x10,%esp
f010091d:	85 c0                	test   %eax,%eax
f010091f:	74 38                	je     f0100959 <monitor+0x139>
f0100921:	83 ec 08             	sub    $0x8,%esp
f0100924:	8d 83 44 e7 fe ff    	lea    -0x118bc(%ebx),%eax
f010092a:	50                   	push   %eax
f010092b:	ff 75 a8             	pushl  -0x58(%ebp)
f010092e:	e8 93 19 00 00       	call   f01022c6 <strcmp>
f0100933:	83 c4 10             	add    $0x10,%esp
f0100936:	85 c0                	test   %eax,%eax
f0100938:	74 1a                	je     f0100954 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f010093a:	83 ec 08             	sub    $0x8,%esp
f010093d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100940:	8d 83 8c e7 fe ff    	lea    -0x11874(%ebx),%eax
f0100946:	50                   	push   %eax
f0100947:	e8 84 0e 00 00       	call   f01017d0 <cprintf>
f010094c:	83 c4 10             	add    $0x10,%esp
f010094f:	e9 4f ff ff ff       	jmp    f01008a3 <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100954:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f0100959:	83 ec 04             	sub    $0x4,%esp
f010095c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010095f:	ff 75 08             	pushl  0x8(%ebp)
f0100962:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100965:	52                   	push   %edx
f0100966:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100969:	ff 94 83 10 1d 00 00 	call   *0x1d10(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100970:	83 c4 10             	add    $0x10,%esp
f0100973:	85 c0                	test   %eax,%eax
f0100975:	0f 89 28 ff ff ff    	jns    f01008a3 <monitor+0x83>
				break;
	}
}
f010097b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010097e:	5b                   	pop    %ebx
f010097f:	5e                   	pop    %esi
f0100980:	5f                   	pop    %edi
f0100981:	5d                   	pop    %ebp
f0100982:	c3                   	ret    

f0100983 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100983:	55                   	push   %ebp
f0100984:	89 e5                	mov    %esp,%ebp
f0100986:	e8 b6 0d 00 00       	call   f0101741 <__x86.get_pc_thunk.cx>
f010098b:	81 c1 7d 39 01 00    	add    $0x1397d,%ecx
f0100991:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree)
f0100993:	83 b9 90 1f 00 00 00 	cmpl   $0x0,0x1f90(%ecx)
f010099a:	74 20                	je     f01009bc <boot_alloc+0x39>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n == 0)
f010099c:	85 d2                	test   %edx,%edx
f010099e:	74 34                	je     f01009d4 <boot_alloc+0x51>
	{
		return nextfree;
	}
	else if (n > 0)
	{
		result = nextfree;
f01009a0:	8b 81 90 1f 00 00    	mov    0x1f90(%ecx),%eax
		nextfree += ROUNDUP(n, PGSIZE);
f01009a6:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f01009ac:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009b2:	01 c2                	add    %eax,%edx
f01009b4:	89 91 90 1f 00 00    	mov    %edx,0x1f90(%ecx)
		return result;
	}
	return NULL;
}
f01009ba:	5d                   	pop    %ebp
f01009bb:	c3                   	ret    
		nextfree = ROUNDUP((char *)end, PGSIZE);
f01009bc:	c7 c0 c0 66 11 f0    	mov    $0xf01166c0,%eax
f01009c2:	05 ff 0f 00 00       	add    $0xfff,%eax
f01009c7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009cc:	89 81 90 1f 00 00    	mov    %eax,0x1f90(%ecx)
f01009d2:	eb c8                	jmp    f010099c <boot_alloc+0x19>
		return nextfree;
f01009d4:	8b 81 90 1f 00 00    	mov    0x1f90(%ecx),%eax
f01009da:	eb de                	jmp    f01009ba <boot_alloc+0x37>

f01009dc <nvram_read>:
{
f01009dc:	55                   	push   %ebp
f01009dd:	89 e5                	mov    %esp,%ebp
f01009df:	57                   	push   %edi
f01009e0:	56                   	push   %esi
f01009e1:	53                   	push   %ebx
f01009e2:	83 ec 18             	sub    $0x18,%esp
f01009e5:	e8 65 f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01009ea:	81 c3 1e 39 01 00    	add    $0x1391e,%ebx
f01009f0:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009f2:	50                   	push   %eax
f01009f3:	e8 51 0d 00 00       	call   f0101749 <mc146818_read>
f01009f8:	89 c6                	mov    %eax,%esi
f01009fa:	83 c7 01             	add    $0x1,%edi
f01009fd:	89 3c 24             	mov    %edi,(%esp)
f0100a00:	e8 44 0d 00 00       	call   f0101749 <mc146818_read>
f0100a05:	c1 e0 08             	shl    $0x8,%eax
f0100a08:	09 f0                	or     %esi,%eax
}
f0100a0a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a0d:	5b                   	pop    %ebx
f0100a0e:	5e                   	pop    %esi
f0100a0f:	5f                   	pop    %edi
f0100a10:	5d                   	pop    %ebp
f0100a11:	c3                   	ret    

f0100a12 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100a12:	55                   	push   %ebp
f0100a13:	89 e5                	mov    %esp,%ebp
f0100a15:	53                   	push   %ebx
f0100a16:	83 ec 04             	sub    $0x4,%esp
f0100a19:	e8 1f 0d 00 00       	call   f010173d <__x86.get_pc_thunk.dx>
f0100a1e:	81 c2 ea 38 01 00    	add    $0x138ea,%edx
	return (pp - pages) << PGSHIFT;
f0100a24:	c7 c1 d0 66 11 f0    	mov    $0xf01166d0,%ecx
f0100a2a:	2b 01                	sub    (%ecx),%eax
f0100a2c:	c1 f8 03             	sar    $0x3,%eax
f0100a2f:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100a32:	89 c1                	mov    %eax,%ecx
f0100a34:	c1 e9 0c             	shr    $0xc,%ecx
f0100a37:	c7 c3 c8 66 11 f0    	mov    $0xf01166c8,%ebx
f0100a3d:	39 0b                	cmp    %ecx,(%ebx)
f0100a3f:	76 0a                	jbe    f0100a4b <page2kva+0x39>
	return (void *)(pa + KERNBASE);
f0100a41:	2d 00 00 00 10       	sub    $0x10000000,%eax
	return KADDR(page2pa(pp));
}
f0100a46:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a49:	c9                   	leave  
f0100a4a:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a4b:	50                   	push   %eax
f0100a4c:	8d 82 fc e8 fe ff    	lea    -0x11704(%edx),%eax
f0100a52:	50                   	push   %eax
f0100a53:	6a 52                	push   $0x52
f0100a55:	8d 82 64 eb fe ff    	lea    -0x1149c(%edx),%eax
f0100a5b:	50                   	push   %eax
f0100a5c:	89 d3                	mov    %edx,%ebx
f0100a5e:	e8 36 f6 ff ff       	call   f0100099 <_panic>

f0100a63 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a63:	55                   	push   %ebp
f0100a64:	89 e5                	mov    %esp,%ebp
f0100a66:	56                   	push   %esi
f0100a67:	53                   	push   %ebx
f0100a68:	e8 d4 0c 00 00       	call   f0101741 <__x86.get_pc_thunk.cx>
f0100a6d:	81 c1 9b 38 01 00    	add    $0x1389b,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a73:	89 d3                	mov    %edx,%ebx
f0100a75:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100a78:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100a7b:	a8 01                	test   $0x1,%al
f0100a7d:	74 5a                	je     f0100ad9 <check_va2pa+0x76>
		return ~0;
	p = (pte_t *)KADDR(PTE_ADDR(*pgdir));
f0100a7f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0100a84:	89 c6                	mov    %eax,%esi
f0100a86:	c1 ee 0c             	shr    $0xc,%esi
f0100a89:	c7 c3 c8 66 11 f0    	mov    $0xf01166c8,%ebx
f0100a8f:	3b 33                	cmp    (%ebx),%esi
f0100a91:	73 2b                	jae    f0100abe <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100a93:	c1 ea 0c             	shr    $0xc,%edx
f0100a96:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a9c:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100aa3:	89 c2                	mov    %eax,%edx
f0100aa5:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100aa8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100aad:	85 d2                	test   %edx,%edx
f0100aaf:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100ab4:	0f 44 c2             	cmove  %edx,%eax
}
f0100ab7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100aba:	5b                   	pop    %ebx
f0100abb:	5e                   	pop    %esi
f0100abc:	5d                   	pop    %ebp
f0100abd:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100abe:	50                   	push   %eax
f0100abf:	8d 81 fc e8 fe ff    	lea    -0x11704(%ecx),%eax
f0100ac5:	50                   	push   %eax
f0100ac6:	68 bf 02 00 00       	push   $0x2bf
f0100acb:	8d 81 72 eb fe ff    	lea    -0x1148e(%ecx),%eax
f0100ad1:	50                   	push   %eax
f0100ad2:	89 cb                	mov    %ecx,%ebx
f0100ad4:	e8 c0 f5 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100ad9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ade:	eb d7                	jmp    f0100ab7 <check_va2pa+0x54>

f0100ae0 <page_init>:
{
f0100ae0:	55                   	push   %ebp
f0100ae1:	89 e5                	mov    %esp,%ebp
f0100ae3:	57                   	push   %edi
f0100ae4:	56                   	push   %esi
f0100ae5:	53                   	push   %ebx
f0100ae6:	83 ec 1c             	sub    $0x1c,%esp
f0100ae9:	e8 57 0c 00 00       	call   f0101745 <__x86.get_pc_thunk.di>
f0100aee:	81 c7 1a 38 01 00    	add    $0x1381a,%edi
f0100af4:	89 7d e4             	mov    %edi,-0x1c(%ebp)
	pages[0].pp_ref = 1;
f0100af7:	c7 c0 d0 66 11 f0    	mov    $0xf01166d0,%eax
f0100afd:	8b 00                	mov    (%eax),%eax
f0100aff:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	for (i = 1; i < npages_basemem; i++)
f0100b05:	8b 87 98 1f 00 00    	mov    0x1f98(%edi),%eax
f0100b0b:	8b b7 94 1f 00 00    	mov    0x1f94(%edi),%esi
f0100b11:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100b16:	ba 01 00 00 00       	mov    $0x1,%edx
		pages[i].pp_ref = 0;
f0100b1b:	c7 c7 d0 66 11 f0    	mov    $0xf01166d0,%edi
	for (i = 1; i < npages_basemem; i++)
f0100b21:	eb 1f                	jmp    f0100b42 <page_init+0x62>
		pages[i].pp_ref = 0;
f0100b23:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f0100b2a:	89 cb                	mov    %ecx,%ebx
f0100b2c:	03 1f                	add    (%edi),%ebx
f0100b2e:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f0100b34:	89 33                	mov    %esi,(%ebx)
	for (i = 1; i < npages_basemem; i++)
f0100b36:	83 c2 01             	add    $0x1,%edx
		page_free_list = &pages[i];
f0100b39:	89 ce                	mov    %ecx,%esi
f0100b3b:	03 37                	add    (%edi),%esi
f0100b3d:	b9 01 00 00 00       	mov    $0x1,%ecx
	for (i = 1; i < npages_basemem; i++)
f0100b42:	39 d0                	cmp    %edx,%eax
f0100b44:	77 dd                	ja     f0100b23 <page_init+0x43>
f0100b46:	84 c9                	test   %cl,%cl
f0100b48:	75 0d                	jne    f0100b57 <page_init+0x77>
		pages[i].pp_ref = 1;
f0100b4a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b4d:	c7 c2 d0 66 11 f0    	mov    $0xf01166d0,%edx
f0100b53:	8b 12                	mov    (%edx),%edx
f0100b55:	eb 15                	jmp    f0100b6c <page_init+0x8c>
f0100b57:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b5a:	89 b7 94 1f 00 00    	mov    %esi,0x1f94(%edi)
f0100b60:	eb e8                	jmp    f0100b4a <page_init+0x6a>
f0100b62:	66 c7 44 c2 04 01 00 	movw   $0x1,0x4(%edx,%eax,8)
	for (i = npages_basemem; i < EXTPHYSMEM / PGSIZE; i++)
f0100b69:	83 c0 01             	add    $0x1,%eax
f0100b6c:	3d ff 00 00 00       	cmp    $0xff,%eax
f0100b71:	76 ef                	jbe    f0100b62 <page_init+0x82>
	physaddr_t first_free_addr = PADDR(boot_alloc(0));
f0100b73:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b78:	e8 06 fe ff ff       	call   f0100983 <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f0100b7d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100b82:	76 1a                	jbe    f0100b9e <page_init+0xbe>
	return (physaddr_t)kva - KERNBASE;
f0100b84:	05 00 00 00 10       	add    $0x10000000,%eax
	size_t first_free_page = first_free_addr / PGSIZE;
f0100b89:	c1 e8 0c             	shr    $0xc,%eax
		pages[i].pp_ref = 1;
f0100b8c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b8f:	c7 c2 d0 66 11 f0    	mov    $0xf01166d0,%edx
f0100b95:	8b 0a                	mov    (%edx),%ecx
	for (i = EXTPHYSMEM / PGSIZE; i < first_free_page; i++)
f0100b97:	ba 00 01 00 00       	mov    $0x100,%edx
f0100b9c:	eb 26                	jmp    f0100bc4 <page_init+0xe4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b9e:	50                   	push   %eax
f0100b9f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100ba2:	8d 83 20 e9 fe ff    	lea    -0x116e0(%ebx),%eax
f0100ba8:	50                   	push   %eax
f0100ba9:	68 1e 01 00 00       	push   $0x11e
f0100bae:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0100bb4:	50                   	push   %eax
f0100bb5:	e8 df f4 ff ff       	call   f0100099 <_panic>
		pages[i].pp_ref = 1;
f0100bba:	66 c7 44 d1 04 01 00 	movw   $0x1,0x4(%ecx,%edx,8)
	for (i = EXTPHYSMEM / PGSIZE; i < first_free_page; i++)
f0100bc1:	83 c2 01             	add    $0x1,%edx
f0100bc4:	39 c2                	cmp    %eax,%edx
f0100bc6:	72 f2                	jb     f0100bba <page_init+0xda>
f0100bc8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100bcb:	8b 9e 94 1f 00 00    	mov    0x1f94(%esi),%ebx
f0100bd1:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100bd8:	b9 00 00 00 00       	mov    $0x0,%ecx
	for (i = first_free_page; i < npages; i++)
f0100bdd:	c7 c7 c8 66 11 f0    	mov    $0xf01166c8,%edi
		pages[i].pp_ref = 0;
f0100be3:	c7 c6 d0 66 11 f0    	mov    $0xf01166d0,%esi
f0100be9:	eb 1b                	jmp    f0100c06 <page_init+0x126>
f0100beb:	89 d1                	mov    %edx,%ecx
f0100bed:	03 0e                	add    (%esi),%ecx
f0100bef:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100bf5:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100bf7:	89 d3                	mov    %edx,%ebx
f0100bf9:	03 1e                	add    (%esi),%ebx
	for (i = first_free_page; i < npages; i++)
f0100bfb:	83 c0 01             	add    $0x1,%eax
f0100bfe:	83 c2 08             	add    $0x8,%edx
f0100c01:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100c06:	39 07                	cmp    %eax,(%edi)
f0100c08:	77 e1                	ja     f0100beb <page_init+0x10b>
f0100c0a:	84 c9                	test   %cl,%cl
f0100c0c:	75 08                	jne    f0100c16 <page_init+0x136>
}
f0100c0e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c11:	5b                   	pop    %ebx
f0100c12:	5e                   	pop    %esi
f0100c13:	5f                   	pop    %edi
f0100c14:	5d                   	pop    %ebp
f0100c15:	c3                   	ret    
f0100c16:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c19:	89 98 94 1f 00 00    	mov    %ebx,0x1f94(%eax)
f0100c1f:	eb ed                	jmp    f0100c0e <page_init+0x12e>

f0100c21 <page_alloc>:
{
f0100c21:	55                   	push   %ebp
f0100c22:	89 e5                	mov    %esp,%ebp
f0100c24:	56                   	push   %esi
f0100c25:	53                   	push   %ebx
f0100c26:	e8 24 f5 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100c2b:	81 c3 dd 36 01 00    	add    $0x136dd,%ebx
	if (!page_free_list)
f0100c31:	8b b3 94 1f 00 00    	mov    0x1f94(%ebx),%esi
f0100c37:	85 f6                	test   %esi,%esi
f0100c39:	74 14                	je     f0100c4f <page_alloc+0x2e>
	page_free_list = page_free_list->pp_link;// update free list pointer
f0100c3b:	8b 06                	mov    (%esi),%eax
f0100c3d:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	pp->pp_link = NULL; // set to NULL according to notes
f0100c43:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if (alloc_flags & ALLOC_ZERO)
f0100c49:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100c4d:	75 09                	jne    f0100c58 <page_alloc+0x37>
}
f0100c4f:	89 f0                	mov    %esi,%eax
f0100c51:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100c54:	5b                   	pop    %ebx
f0100c55:	5e                   	pop    %esi
f0100c56:	5d                   	pop    %ebp
f0100c57:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f0100c58:	c7 c0 d0 66 11 f0    	mov    $0xf01166d0,%eax
f0100c5e:	89 f2                	mov    %esi,%edx
f0100c60:	2b 10                	sub    (%eax),%edx
f0100c62:	89 d0                	mov    %edx,%eax
f0100c64:	c1 f8 03             	sar    $0x3,%eax
f0100c67:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100c6a:	89 c1                	mov    %eax,%ecx
f0100c6c:	c1 e9 0c             	shr    $0xc,%ecx
f0100c6f:	c7 c2 c8 66 11 f0    	mov    $0xf01166c8,%edx
f0100c75:	3b 0a                	cmp    (%edx),%ecx
f0100c77:	73 1a                	jae    f0100c93 <page_alloc+0x72>
		memset(va, '\0', PGSIZE);
f0100c79:	83 ec 04             	sub    $0x4,%esp
f0100c7c:	68 00 10 00 00       	push   $0x1000
f0100c81:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100c83:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c88:	50                   	push   %eax
f0100c89:	e8 d3 16 00 00       	call   f0102361 <memset>
f0100c8e:	83 c4 10             	add    $0x10,%esp
f0100c91:	eb bc                	jmp    f0100c4f <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c93:	50                   	push   %eax
f0100c94:	8d 83 fc e8 fe ff    	lea    -0x11704(%ebx),%eax
f0100c9a:	50                   	push   %eax
f0100c9b:	6a 52                	push   $0x52
f0100c9d:	8d 83 64 eb fe ff    	lea    -0x1149c(%ebx),%eax
f0100ca3:	50                   	push   %eax
f0100ca4:	e8 f0 f3 ff ff       	call   f0100099 <_panic>

f0100ca9 <page_free>:
{
f0100ca9:	55                   	push   %ebp
f0100caa:	89 e5                	mov    %esp,%ebp
f0100cac:	53                   	push   %ebx
f0100cad:	83 ec 04             	sub    $0x4,%esp
f0100cb0:	e8 9a f4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100cb5:	81 c3 53 36 01 00    	add    $0x13653,%ebx
f0100cbb:	8b 45 08             	mov    0x8(%ebp),%eax
	if(pp->pp_link || pp->pp_ref) {
f0100cbe:	83 38 00             	cmpl   $0x0,(%eax)
f0100cc1:	75 1a                	jne    f0100cdd <page_free+0x34>
f0100cc3:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100cc8:	75 13                	jne    f0100cdd <page_free+0x34>
	pp->pp_link = page_free_list;
f0100cca:	8b 8b 94 1f 00 00    	mov    0x1f94(%ebx),%ecx
f0100cd0:	89 08                	mov    %ecx,(%eax)
    page_free_list = pp;
f0100cd2:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
}
f0100cd8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100cdb:	c9                   	leave  
f0100cdc:	c3                   	ret    
        panic("pp->pp_ref is nonzero or pp->pp_link is not NULL\n");
f0100cdd:	83 ec 04             	sub    $0x4,%esp
f0100ce0:	8d 83 44 e9 fe ff    	lea    -0x116bc(%ebx),%eax
f0100ce6:	50                   	push   %eax
f0100ce7:	68 5c 01 00 00       	push   $0x15c
f0100cec:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0100cf2:	50                   	push   %eax
f0100cf3:	e8 a1 f3 ff ff       	call   f0100099 <_panic>

f0100cf8 <mem_init>:
{
f0100cf8:	55                   	push   %ebp
f0100cf9:	89 e5                	mov    %esp,%ebp
f0100cfb:	57                   	push   %edi
f0100cfc:	56                   	push   %esi
f0100cfd:	53                   	push   %ebx
f0100cfe:	83 ec 3c             	sub    $0x3c,%esp
f0100d01:	e8 49 f4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100d06:	81 c3 02 36 01 00    	add    $0x13602,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f0100d0c:	b8 15 00 00 00       	mov    $0x15,%eax
f0100d11:	e8 c6 fc ff ff       	call   f01009dc <nvram_read>
f0100d16:	89 c7                	mov    %eax,%edi
	extmem = nvram_read(NVRAM_EXTLO);
f0100d18:	b8 17 00 00 00       	mov    $0x17,%eax
f0100d1d:	e8 ba fc ff ff       	call   f01009dc <nvram_read>
f0100d22:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100d24:	b8 34 00 00 00       	mov    $0x34,%eax
f0100d29:	e8 ae fc ff ff       	call   f01009dc <nvram_read>
f0100d2e:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0100d31:	85 c0                	test   %eax,%eax
f0100d33:	75 0e                	jne    f0100d43 <mem_init+0x4b>
		totalmem = basemem;
f0100d35:	89 f8                	mov    %edi,%eax
	else if (extmem)
f0100d37:	85 f6                	test   %esi,%esi
f0100d39:	74 0d                	je     f0100d48 <mem_init+0x50>
		totalmem = 1 * 1024 + extmem;
f0100d3b:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100d41:	eb 05                	jmp    f0100d48 <mem_init+0x50>
		totalmem = 16 * 1024 + ext16mem;
f0100d43:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f0100d48:	89 c1                	mov    %eax,%ecx
f0100d4a:	c1 e9 02             	shr    $0x2,%ecx
f0100d4d:	c7 c2 c8 66 11 f0    	mov    $0xf01166c8,%edx
f0100d53:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f0100d55:	89 fa                	mov    %edi,%edx
f0100d57:	c1 ea 02             	shr    $0x2,%edx
f0100d5a:	89 93 98 1f 00 00    	mov    %edx,0x1f98(%ebx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100d60:	89 c2                	mov    %eax,%edx
f0100d62:	29 fa                	sub    %edi,%edx
f0100d64:	52                   	push   %edx
f0100d65:	57                   	push   %edi
f0100d66:	50                   	push   %eax
f0100d67:	8d 83 78 e9 fe ff    	lea    -0x11688(%ebx),%eax
f0100d6d:	50                   	push   %eax
f0100d6e:	e8 5d 0a 00 00       	call   f01017d0 <cprintf>
	kern_pgdir = (pde_t *)boot_alloc(PGSIZE);
f0100d73:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100d78:	e8 06 fc ff ff       	call   f0100983 <boot_alloc>
f0100d7d:	c7 c6 cc 66 11 f0    	mov    $0xf01166cc,%esi
f0100d83:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f0100d85:	83 c4 0c             	add    $0xc,%esp
f0100d88:	68 00 10 00 00       	push   $0x1000
f0100d8d:	6a 00                	push   $0x0
f0100d8f:	50                   	push   %eax
f0100d90:	e8 cc 15 00 00       	call   f0102361 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100d95:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0100d97:	83 c4 10             	add    $0x10,%esp
f0100d9a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d9f:	77 19                	ja     f0100dba <mem_init+0xc2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100da1:	50                   	push   %eax
f0100da2:	8d 83 20 e9 fe ff    	lea    -0x116e0(%ebx),%eax
f0100da8:	50                   	push   %eax
f0100da9:	68 95 00 00 00       	push   $0x95
f0100dae:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0100db4:	50                   	push   %eax
f0100db5:	e8 df f2 ff ff       	call   f0100099 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100dba:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100dc0:	83 ca 05             	or     $0x5,%edx
f0100dc3:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f0100dc9:	c7 c6 c8 66 11 f0    	mov    $0xf01166c8,%esi
f0100dcf:	8b 06                	mov    (%esi),%eax
f0100dd1:	c1 e0 03             	shl    $0x3,%eax
f0100dd4:	e8 aa fb ff ff       	call   f0100983 <boot_alloc>
f0100dd9:	c7 c2 d0 66 11 f0    	mov    $0xf01166d0,%edx
f0100ddf:	89 02                	mov    %eax,(%edx)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0100de1:	83 ec 04             	sub    $0x4,%esp
f0100de4:	8b 16                	mov    (%esi),%edx
f0100de6:	c1 e2 03             	shl    $0x3,%edx
f0100de9:	52                   	push   %edx
f0100dea:	6a 00                	push   $0x0
f0100dec:	50                   	push   %eax
f0100ded:	e8 6f 15 00 00       	call   f0102361 <memset>
	page_init();
f0100df2:	e8 e9 fc ff ff       	call   f0100ae0 <page_init>
	if (!page_free_list)
f0100df7:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f0100dfd:	83 c4 10             	add    $0x10,%esp
f0100e00:	85 c0                	test   %eax,%eax
f0100e02:	74 5d                	je     f0100e61 <mem_init+0x169>
		struct PageInfo **tp[2] = {&pp1, &pp2};
f0100e04:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e07:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e0a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e0d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100e10:	c7 c1 d0 66 11 f0    	mov    $0xf01166d0,%ecx
f0100e16:	89 c2                	mov    %eax,%edx
f0100e18:	2b 11                	sub    (%ecx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100e1a:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100e20:	0f 95 c2             	setne  %dl
f0100e23:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100e26:	8b 74 95 e0          	mov    -0x20(%ebp,%edx,4),%esi
f0100e2a:	89 06                	mov    %eax,(%esi)
			tp[pagetype] = &pp->pp_link;
f0100e2c:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link)
f0100e30:	8b 00                	mov    (%eax),%eax
f0100e32:	85 c0                	test   %eax,%eax
f0100e34:	75 e0                	jne    f0100e16 <mem_init+0x11e>
		*tp[1] = 0;
f0100e36:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e39:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100e3f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e42:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e45:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100e47:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0100e4a:	89 b3 94 1f 00 00    	mov    %esi,0x1f94(%ebx)
f0100e50:	c7 c7 d0 66 11 f0    	mov    $0xf01166d0,%edi
	if (PGNUM(pa) >= npages)
f0100e56:	c7 c0 c8 66 11 f0    	mov    $0xf01166c8,%eax
f0100e5c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100e5f:	eb 33                	jmp    f0100e94 <mem_init+0x19c>
		panic("'page_free_list' is a null pointer!");
f0100e61:	83 ec 04             	sub    $0x4,%esp
f0100e64:	8d 83 b4 e9 fe ff    	lea    -0x1164c(%ebx),%eax
f0100e6a:	50                   	push   %eax
f0100e6b:	68 fa 01 00 00       	push   $0x1fa
f0100e70:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0100e76:	50                   	push   %eax
f0100e77:	e8 1d f2 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e7c:	52                   	push   %edx
f0100e7d:	8d 83 fc e8 fe ff    	lea    -0x11704(%ebx),%eax
f0100e83:	50                   	push   %eax
f0100e84:	6a 52                	push   $0x52
f0100e86:	8d 83 64 eb fe ff    	lea    -0x1149c(%ebx),%eax
f0100e8c:	50                   	push   %eax
f0100e8d:	e8 07 f2 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100e92:	8b 36                	mov    (%esi),%esi
f0100e94:	85 f6                	test   %esi,%esi
f0100e96:	74 3d                	je     f0100ed5 <mem_init+0x1dd>
	return (pp - pages) << PGSHIFT;
f0100e98:	89 f0                	mov    %esi,%eax
f0100e9a:	2b 07                	sub    (%edi),%eax
f0100e9c:	c1 f8 03             	sar    $0x3,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100e9f:	89 c2                	mov    %eax,%edx
f0100ea1:	c1 e2 0c             	shl    $0xc,%edx
f0100ea4:	a9 00 fc 0f 00       	test   $0xffc00,%eax
f0100ea9:	75 e7                	jne    f0100e92 <mem_init+0x19a>
	if (PGNUM(pa) >= npages)
f0100eab:	89 d0                	mov    %edx,%eax
f0100ead:	c1 e8 0c             	shr    $0xc,%eax
f0100eb0:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100eb3:	3b 01                	cmp    (%ecx),%eax
f0100eb5:	73 c5                	jae    f0100e7c <mem_init+0x184>
			memset(page2kva(pp), 0x97, 128);
f0100eb7:	83 ec 04             	sub    $0x4,%esp
f0100eba:	68 80 00 00 00       	push   $0x80
f0100ebf:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100ec4:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100eca:	52                   	push   %edx
f0100ecb:	e8 91 14 00 00       	call   f0102361 <memset>
f0100ed0:	83 c4 10             	add    $0x10,%esp
f0100ed3:	eb bd                	jmp    f0100e92 <mem_init+0x19a>
	first_free_page = (char *)boot_alloc(0);
f0100ed5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eda:	e8 a4 fa ff ff       	call   f0100983 <boot_alloc>
f0100edf:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ee2:	8b 93 94 1f 00 00    	mov    0x1f94(%ebx),%edx
		assert(pp >= pages);
f0100ee8:	c7 c0 d0 66 11 f0    	mov    $0xf01166d0,%eax
f0100eee:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100ef0:	c7 c0 c8 66 11 f0    	mov    $0xf01166c8,%eax
f0100ef6:	8b 00                	mov    (%eax),%eax
f0100ef8:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100efb:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100efe:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100f01:	89 4d d0             	mov    %ecx,-0x30(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100f04:	bf 00 00 00 00       	mov    $0x0,%edi
f0100f09:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0100f0c:	e9 f3 00 00 00       	jmp    f0101004 <mem_init+0x30c>
		assert(pp >= pages);
f0100f11:	8d 83 7e eb fe ff    	lea    -0x11482(%ebx),%eax
f0100f17:	50                   	push   %eax
f0100f18:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f0100f1e:	50                   	push   %eax
f0100f1f:	68 17 02 00 00       	push   $0x217
f0100f24:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0100f2a:	50                   	push   %eax
f0100f2b:	e8 69 f1 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100f30:	8d 83 9f eb fe ff    	lea    -0x11461(%ebx),%eax
f0100f36:	50                   	push   %eax
f0100f37:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f0100f3d:	50                   	push   %eax
f0100f3e:	68 18 02 00 00       	push   $0x218
f0100f43:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0100f49:	50                   	push   %eax
f0100f4a:	e8 4a f1 ff ff       	call   f0100099 <_panic>
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100f4f:	8d 83 d8 e9 fe ff    	lea    -0x11628(%ebx),%eax
f0100f55:	50                   	push   %eax
f0100f56:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f0100f5c:	50                   	push   %eax
f0100f5d:	68 19 02 00 00       	push   $0x219
f0100f62:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0100f68:	50                   	push   %eax
f0100f69:	e8 2b f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100f6e:	8d 83 b3 eb fe ff    	lea    -0x1144d(%ebx),%eax
f0100f74:	50                   	push   %eax
f0100f75:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f0100f7b:	50                   	push   %eax
f0100f7c:	68 1c 02 00 00       	push   $0x21c
f0100f81:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0100f87:	50                   	push   %eax
f0100f88:	e8 0c f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100f8d:	8d 83 c4 eb fe ff    	lea    -0x1143c(%ebx),%eax
f0100f93:	50                   	push   %eax
f0100f94:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f0100f9a:	50                   	push   %eax
f0100f9b:	68 1d 02 00 00       	push   $0x21d
f0100fa0:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0100fa6:	50                   	push   %eax
f0100fa7:	e8 ed f0 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100fac:	8d 83 08 ea fe ff    	lea    -0x115f8(%ebx),%eax
f0100fb2:	50                   	push   %eax
f0100fb3:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f0100fb9:	50                   	push   %eax
f0100fba:	68 1e 02 00 00       	push   $0x21e
f0100fbf:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0100fc5:	50                   	push   %eax
f0100fc6:	e8 ce f0 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100fcb:	8d 83 dd eb fe ff    	lea    -0x11423(%ebx),%eax
f0100fd1:	50                   	push   %eax
f0100fd2:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f0100fd8:	50                   	push   %eax
f0100fd9:	68 1f 02 00 00       	push   $0x21f
f0100fde:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0100fe4:	50                   	push   %eax
f0100fe5:	e8 af f0 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100fea:	89 c6                	mov    %eax,%esi
f0100fec:	c1 ee 0c             	shr    $0xc,%esi
f0100fef:	39 75 c4             	cmp    %esi,-0x3c(%ebp)
f0100ff2:	76 71                	jbe    f0101065 <mem_init+0x36d>
	return (void *)(pa + KERNBASE);
f0100ff4:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *)page2kva(pp) >= first_free_page);
f0100ff9:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100ffc:	77 7d                	ja     f010107b <mem_init+0x383>
			++nfree_extmem;
f0100ffe:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101002:	8b 12                	mov    (%edx),%edx
f0101004:	85 d2                	test   %edx,%edx
f0101006:	0f 84 8e 00 00 00    	je     f010109a <mem_init+0x3a2>
		assert(pp >= pages);
f010100c:	39 d1                	cmp    %edx,%ecx
f010100e:	0f 87 fd fe ff ff    	ja     f0100f11 <mem_init+0x219>
		assert(pp < pages + npages);
f0101014:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0101017:	0f 83 13 ff ff ff    	jae    f0100f30 <mem_init+0x238>
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f010101d:	89 d0                	mov    %edx,%eax
f010101f:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101022:	a8 07                	test   $0x7,%al
f0101024:	0f 85 25 ff ff ff    	jne    f0100f4f <mem_init+0x257>
	return (pp - pages) << PGSHIFT;
f010102a:	c1 f8 03             	sar    $0x3,%eax
f010102d:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0101030:	85 c0                	test   %eax,%eax
f0101032:	0f 84 36 ff ff ff    	je     f0100f6e <mem_init+0x276>
		assert(page2pa(pp) != IOPHYSMEM);
f0101038:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f010103d:	0f 84 4a ff ff ff    	je     f0100f8d <mem_init+0x295>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0101043:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101048:	0f 84 5e ff ff ff    	je     f0100fac <mem_init+0x2b4>
		assert(page2pa(pp) != EXTPHYSMEM);
f010104e:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0101053:	0f 84 72 ff ff ff    	je     f0100fcb <mem_init+0x2d3>
		assert(page2pa(pp) < EXTPHYSMEM || (char *)page2kva(pp) >= first_free_page);
f0101059:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f010105e:	77 8a                	ja     f0100fea <mem_init+0x2f2>
			++nfree_basemem;
f0101060:	83 c7 01             	add    $0x1,%edi
f0101063:	eb 9d                	jmp    f0101002 <mem_init+0x30a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101065:	50                   	push   %eax
f0101066:	8d 83 fc e8 fe ff    	lea    -0x11704(%ebx),%eax
f010106c:	50                   	push   %eax
f010106d:	6a 52                	push   $0x52
f010106f:	8d 83 64 eb fe ff    	lea    -0x1149c(%ebx),%eax
f0101075:	50                   	push   %eax
f0101076:	e8 1e f0 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *)page2kva(pp) >= first_free_page);
f010107b:	8d 83 2c ea fe ff    	lea    -0x115d4(%ebx),%eax
f0101081:	50                   	push   %eax
f0101082:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f0101088:	50                   	push   %eax
f0101089:	68 20 02 00 00       	push   $0x220
f010108e:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0101094:	50                   	push   %eax
f0101095:	e8 ff ef ff ff       	call   f0100099 <_panic>
f010109a:	8b 75 cc             	mov    -0x34(%ebp),%esi
	assert(nfree_basemem > 0);
f010109d:	85 ff                	test   %edi,%edi
f010109f:	7e 2e                	jle    f01010cf <mem_init+0x3d7>
	assert(nfree_extmem > 0);
f01010a1:	85 f6                	test   %esi,%esi
f01010a3:	7e 49                	jle    f01010ee <mem_init+0x3f6>
	cprintf("check_page_free_list() succeeded!\n");
f01010a5:	83 ec 0c             	sub    $0xc,%esp
f01010a8:	8d 83 70 ea fe ff    	lea    -0x11590(%ebx),%eax
f01010ae:	50                   	push   %eax
f01010af:	e8 1c 07 00 00       	call   f01017d0 <cprintf>
	if (!pages)
f01010b4:	83 c4 10             	add    $0x10,%esp
f01010b7:	c7 c0 d0 66 11 f0    	mov    $0xf01166d0,%eax
f01010bd:	83 38 00             	cmpl   $0x0,(%eax)
f01010c0:	74 4b                	je     f010110d <mem_init+0x415>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01010c2:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f01010c8:	be 00 00 00 00       	mov    $0x0,%esi
f01010cd:	eb 5e                	jmp    f010112d <mem_init+0x435>
	assert(nfree_basemem > 0);
f01010cf:	8d 83 f7 eb fe ff    	lea    -0x11409(%ebx),%eax
f01010d5:	50                   	push   %eax
f01010d6:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f01010dc:	50                   	push   %eax
f01010dd:	68 28 02 00 00       	push   $0x228
f01010e2:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f01010e8:	50                   	push   %eax
f01010e9:	e8 ab ef ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f01010ee:	8d 83 09 ec fe ff    	lea    -0x113f7(%ebx),%eax
f01010f4:	50                   	push   %eax
f01010f5:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f01010fb:	50                   	push   %eax
f01010fc:	68 29 02 00 00       	push   $0x229
f0101101:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0101107:	50                   	push   %eax
f0101108:	e8 8c ef ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f010110d:	83 ec 04             	sub    $0x4,%esp
f0101110:	8d 83 1a ec fe ff    	lea    -0x113e6(%ebx),%eax
f0101116:	50                   	push   %eax
f0101117:	68 3c 02 00 00       	push   $0x23c
f010111c:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0101122:	50                   	push   %eax
f0101123:	e8 71 ef ff ff       	call   f0100099 <_panic>
		++nfree;
f0101128:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010112b:	8b 00                	mov    (%eax),%eax
f010112d:	85 c0                	test   %eax,%eax
f010112f:	75 f7                	jne    f0101128 <mem_init+0x430>
	assert((pp0 = page_alloc(0)));
f0101131:	83 ec 0c             	sub    $0xc,%esp
f0101134:	6a 00                	push   $0x0
f0101136:	e8 e6 fa ff ff       	call   f0100c21 <page_alloc>
f010113b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010113e:	83 c4 10             	add    $0x10,%esp
f0101141:	85 c0                	test   %eax,%eax
f0101143:	0f 84 e7 01 00 00    	je     f0101330 <mem_init+0x638>
	assert((pp1 = page_alloc(0)));
f0101149:	83 ec 0c             	sub    $0xc,%esp
f010114c:	6a 00                	push   $0x0
f010114e:	e8 ce fa ff ff       	call   f0100c21 <page_alloc>
f0101153:	89 c7                	mov    %eax,%edi
f0101155:	83 c4 10             	add    $0x10,%esp
f0101158:	85 c0                	test   %eax,%eax
f010115a:	0f 84 ef 01 00 00    	je     f010134f <mem_init+0x657>
	assert((pp2 = page_alloc(0)));
f0101160:	83 ec 0c             	sub    $0xc,%esp
f0101163:	6a 00                	push   $0x0
f0101165:	e8 b7 fa ff ff       	call   f0100c21 <page_alloc>
f010116a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010116d:	83 c4 10             	add    $0x10,%esp
f0101170:	85 c0                	test   %eax,%eax
f0101172:	0f 84 f6 01 00 00    	je     f010136e <mem_init+0x676>
	assert(pp1 && pp1 != pp0);
f0101178:	39 7d d4             	cmp    %edi,-0x2c(%ebp)
f010117b:	0f 84 0c 02 00 00    	je     f010138d <mem_init+0x695>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101181:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101184:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101187:	0f 84 1f 02 00 00    	je     f01013ac <mem_init+0x6b4>
f010118d:	39 c7                	cmp    %eax,%edi
f010118f:	0f 84 17 02 00 00    	je     f01013ac <mem_init+0x6b4>
	return (pp - pages) << PGSHIFT;
f0101195:	c7 c0 d0 66 11 f0    	mov    $0xf01166d0,%eax
f010119b:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages * PGSIZE);
f010119d:	c7 c0 c8 66 11 f0    	mov    $0xf01166c8,%eax
f01011a3:	8b 10                	mov    (%eax),%edx
f01011a5:	c1 e2 0c             	shl    $0xc,%edx
f01011a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011ab:	29 c8                	sub    %ecx,%eax
f01011ad:	c1 f8 03             	sar    $0x3,%eax
f01011b0:	c1 e0 0c             	shl    $0xc,%eax
f01011b3:	39 d0                	cmp    %edx,%eax
f01011b5:	0f 83 10 02 00 00    	jae    f01013cb <mem_init+0x6d3>
f01011bb:	89 f8                	mov    %edi,%eax
f01011bd:	29 c8                	sub    %ecx,%eax
f01011bf:	c1 f8 03             	sar    $0x3,%eax
f01011c2:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages * PGSIZE);
f01011c5:	39 c2                	cmp    %eax,%edx
f01011c7:	0f 86 1d 02 00 00    	jbe    f01013ea <mem_init+0x6f2>
f01011cd:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01011d0:	29 c8                	sub    %ecx,%eax
f01011d2:	c1 f8 03             	sar    $0x3,%eax
f01011d5:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages * PGSIZE);
f01011d8:	39 c2                	cmp    %eax,%edx
f01011da:	0f 86 29 02 00 00    	jbe    f0101409 <mem_init+0x711>
	fl = page_free_list;
f01011e0:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f01011e6:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f01011e9:	c7 83 94 1f 00 00 00 	movl   $0x0,0x1f94(%ebx)
f01011f0:	00 00 00 
	assert(!page_alloc(0));
f01011f3:	83 ec 0c             	sub    $0xc,%esp
f01011f6:	6a 00                	push   $0x0
f01011f8:	e8 24 fa ff ff       	call   f0100c21 <page_alloc>
f01011fd:	83 c4 10             	add    $0x10,%esp
f0101200:	85 c0                	test   %eax,%eax
f0101202:	0f 85 20 02 00 00    	jne    f0101428 <mem_init+0x730>
	page_free(pp0);
f0101208:	83 ec 0c             	sub    $0xc,%esp
f010120b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010120e:	e8 96 fa ff ff       	call   f0100ca9 <page_free>
	page_free(pp1);
f0101213:	89 3c 24             	mov    %edi,(%esp)
f0101216:	e8 8e fa ff ff       	call   f0100ca9 <page_free>
	page_free(pp2);
f010121b:	83 c4 04             	add    $0x4,%esp
f010121e:	ff 75 d0             	pushl  -0x30(%ebp)
f0101221:	e8 83 fa ff ff       	call   f0100ca9 <page_free>
	assert((pp0 = page_alloc(0)));
f0101226:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010122d:	e8 ef f9 ff ff       	call   f0100c21 <page_alloc>
f0101232:	89 c7                	mov    %eax,%edi
f0101234:	83 c4 10             	add    $0x10,%esp
f0101237:	85 c0                	test   %eax,%eax
f0101239:	0f 84 08 02 00 00    	je     f0101447 <mem_init+0x74f>
	assert((pp1 = page_alloc(0)));
f010123f:	83 ec 0c             	sub    $0xc,%esp
f0101242:	6a 00                	push   $0x0
f0101244:	e8 d8 f9 ff ff       	call   f0100c21 <page_alloc>
f0101249:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010124c:	83 c4 10             	add    $0x10,%esp
f010124f:	85 c0                	test   %eax,%eax
f0101251:	0f 84 0f 02 00 00    	je     f0101466 <mem_init+0x76e>
	assert((pp2 = page_alloc(0)));
f0101257:	83 ec 0c             	sub    $0xc,%esp
f010125a:	6a 00                	push   $0x0
f010125c:	e8 c0 f9 ff ff       	call   f0100c21 <page_alloc>
f0101261:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101264:	83 c4 10             	add    $0x10,%esp
f0101267:	85 c0                	test   %eax,%eax
f0101269:	0f 84 16 02 00 00    	je     f0101485 <mem_init+0x78d>
	assert(pp1 && pp1 != pp0);
f010126f:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101272:	0f 84 2c 02 00 00    	je     f01014a4 <mem_init+0x7ac>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101278:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010127b:	39 c7                	cmp    %eax,%edi
f010127d:	0f 84 40 02 00 00    	je     f01014c3 <mem_init+0x7cb>
f0101283:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101286:	0f 84 37 02 00 00    	je     f01014c3 <mem_init+0x7cb>
	assert(!page_alloc(0));
f010128c:	83 ec 0c             	sub    $0xc,%esp
f010128f:	6a 00                	push   $0x0
f0101291:	e8 8b f9 ff ff       	call   f0100c21 <page_alloc>
f0101296:	83 c4 10             	add    $0x10,%esp
f0101299:	85 c0                	test   %eax,%eax
f010129b:	0f 85 41 02 00 00    	jne    f01014e2 <mem_init+0x7ea>
	memset(page2kva(pp0), 1, PGSIZE);
f01012a1:	89 f8                	mov    %edi,%eax
f01012a3:	e8 6a f7 ff ff       	call   f0100a12 <page2kva>
f01012a8:	83 ec 04             	sub    $0x4,%esp
f01012ab:	68 00 10 00 00       	push   $0x1000
f01012b0:	6a 01                	push   $0x1
f01012b2:	50                   	push   %eax
f01012b3:	e8 a9 10 00 00       	call   f0102361 <memset>
	page_free(pp0);
f01012b8:	89 3c 24             	mov    %edi,(%esp)
f01012bb:	e8 e9 f9 ff ff       	call   f0100ca9 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01012c0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01012c7:	e8 55 f9 ff ff       	call   f0100c21 <page_alloc>
f01012cc:	83 c4 10             	add    $0x10,%esp
f01012cf:	85 c0                	test   %eax,%eax
f01012d1:	0f 84 2a 02 00 00    	je     f0101501 <mem_init+0x809>
	assert(pp && pp0 == pp);
f01012d7:	39 c7                	cmp    %eax,%edi
f01012d9:	0f 85 41 02 00 00    	jne    f0101520 <mem_init+0x828>
	c = page2kva(pp);
f01012df:	e8 2e f7 ff ff       	call   f0100a12 <page2kva>
f01012e4:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
		assert(c[i] == 0);
f01012ea:	80 38 00             	cmpb   $0x0,(%eax)
f01012ed:	0f 85 4c 02 00 00    	jne    f010153f <mem_init+0x847>
f01012f3:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01012f6:	39 c2                	cmp    %eax,%edx
f01012f8:	75 f0                	jne    f01012ea <mem_init+0x5f2>
	page_free_list = fl;
f01012fa:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01012fd:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	page_free(pp0);
f0101303:	83 ec 0c             	sub    $0xc,%esp
f0101306:	57                   	push   %edi
f0101307:	e8 9d f9 ff ff       	call   f0100ca9 <page_free>
	page_free(pp1);
f010130c:	83 c4 04             	add    $0x4,%esp
f010130f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101312:	e8 92 f9 ff ff       	call   f0100ca9 <page_free>
	page_free(pp2);
f0101317:	83 c4 04             	add    $0x4,%esp
f010131a:	ff 75 d0             	pushl  -0x30(%ebp)
f010131d:	e8 87 f9 ff ff       	call   f0100ca9 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101322:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f0101328:	83 c4 10             	add    $0x10,%esp
f010132b:	e9 33 02 00 00       	jmp    f0101563 <mem_init+0x86b>
	assert((pp0 = page_alloc(0)));
f0101330:	8d 83 35 ec fe ff    	lea    -0x113cb(%ebx),%eax
f0101336:	50                   	push   %eax
f0101337:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f010133d:	50                   	push   %eax
f010133e:	68 44 02 00 00       	push   $0x244
f0101343:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0101349:	50                   	push   %eax
f010134a:	e8 4a ed ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010134f:	8d 83 4b ec fe ff    	lea    -0x113b5(%ebx),%eax
f0101355:	50                   	push   %eax
f0101356:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f010135c:	50                   	push   %eax
f010135d:	68 45 02 00 00       	push   $0x245
f0101362:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0101368:	50                   	push   %eax
f0101369:	e8 2b ed ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010136e:	8d 83 61 ec fe ff    	lea    -0x1139f(%ebx),%eax
f0101374:	50                   	push   %eax
f0101375:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f010137b:	50                   	push   %eax
f010137c:	68 46 02 00 00       	push   $0x246
f0101381:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0101387:	50                   	push   %eax
f0101388:	e8 0c ed ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f010138d:	8d 83 77 ec fe ff    	lea    -0x11389(%ebx),%eax
f0101393:	50                   	push   %eax
f0101394:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f010139a:	50                   	push   %eax
f010139b:	68 49 02 00 00       	push   $0x249
f01013a0:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f01013a6:	50                   	push   %eax
f01013a7:	e8 ed ec ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013ac:	8d 83 94 ea fe ff    	lea    -0x1156c(%ebx),%eax
f01013b2:	50                   	push   %eax
f01013b3:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f01013b9:	50                   	push   %eax
f01013ba:	68 4a 02 00 00       	push   $0x24a
f01013bf:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f01013c5:	50                   	push   %eax
f01013c6:	e8 ce ec ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages * PGSIZE);
f01013cb:	8d 83 b4 ea fe ff    	lea    -0x1154c(%ebx),%eax
f01013d1:	50                   	push   %eax
f01013d2:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f01013d8:	50                   	push   %eax
f01013d9:	68 4b 02 00 00       	push   $0x24b
f01013de:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f01013e4:	50                   	push   %eax
f01013e5:	e8 af ec ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages * PGSIZE);
f01013ea:	8d 83 d4 ea fe ff    	lea    -0x1152c(%ebx),%eax
f01013f0:	50                   	push   %eax
f01013f1:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f01013f7:	50                   	push   %eax
f01013f8:	68 4c 02 00 00       	push   $0x24c
f01013fd:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0101403:	50                   	push   %eax
f0101404:	e8 90 ec ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages * PGSIZE);
f0101409:	8d 83 f4 ea fe ff    	lea    -0x1150c(%ebx),%eax
f010140f:	50                   	push   %eax
f0101410:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f0101416:	50                   	push   %eax
f0101417:	68 4d 02 00 00       	push   $0x24d
f010141c:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0101422:	50                   	push   %eax
f0101423:	e8 71 ec ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101428:	8d 83 89 ec fe ff    	lea    -0x11377(%ebx),%eax
f010142e:	50                   	push   %eax
f010142f:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f0101435:	50                   	push   %eax
f0101436:	68 54 02 00 00       	push   $0x254
f010143b:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0101441:	50                   	push   %eax
f0101442:	e8 52 ec ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0101447:	8d 83 35 ec fe ff    	lea    -0x113cb(%ebx),%eax
f010144d:	50                   	push   %eax
f010144e:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f0101454:	50                   	push   %eax
f0101455:	68 5b 02 00 00       	push   $0x25b
f010145a:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0101460:	50                   	push   %eax
f0101461:	e8 33 ec ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101466:	8d 83 4b ec fe ff    	lea    -0x113b5(%ebx),%eax
f010146c:	50                   	push   %eax
f010146d:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f0101473:	50                   	push   %eax
f0101474:	68 5c 02 00 00       	push   $0x25c
f0101479:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f010147f:	50                   	push   %eax
f0101480:	e8 14 ec ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0101485:	8d 83 61 ec fe ff    	lea    -0x1139f(%ebx),%eax
f010148b:	50                   	push   %eax
f010148c:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f0101492:	50                   	push   %eax
f0101493:	68 5d 02 00 00       	push   $0x25d
f0101498:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f010149e:	50                   	push   %eax
f010149f:	e8 f5 eb ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01014a4:	8d 83 77 ec fe ff    	lea    -0x11389(%ebx),%eax
f01014aa:	50                   	push   %eax
f01014ab:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f01014b1:	50                   	push   %eax
f01014b2:	68 5f 02 00 00       	push   $0x25f
f01014b7:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f01014bd:	50                   	push   %eax
f01014be:	e8 d6 eb ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014c3:	8d 83 94 ea fe ff    	lea    -0x1156c(%ebx),%eax
f01014c9:	50                   	push   %eax
f01014ca:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f01014d0:	50                   	push   %eax
f01014d1:	68 60 02 00 00       	push   $0x260
f01014d6:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f01014dc:	50                   	push   %eax
f01014dd:	e8 b7 eb ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01014e2:	8d 83 89 ec fe ff    	lea    -0x11377(%ebx),%eax
f01014e8:	50                   	push   %eax
f01014e9:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f01014ef:	50                   	push   %eax
f01014f0:	68 61 02 00 00       	push   $0x261
f01014f5:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f01014fb:	50                   	push   %eax
f01014fc:	e8 98 eb ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101501:	8d 83 98 ec fe ff    	lea    -0x11368(%ebx),%eax
f0101507:	50                   	push   %eax
f0101508:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f010150e:	50                   	push   %eax
f010150f:	68 66 02 00 00       	push   $0x266
f0101514:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f010151a:	50                   	push   %eax
f010151b:	e8 79 eb ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f0101520:	8d 83 b6 ec fe ff    	lea    -0x1134a(%ebx),%eax
f0101526:	50                   	push   %eax
f0101527:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f010152d:	50                   	push   %eax
f010152e:	68 67 02 00 00       	push   $0x267
f0101533:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0101539:	50                   	push   %eax
f010153a:	e8 5a eb ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f010153f:	8d 83 c6 ec fe ff    	lea    -0x1133a(%ebx),%eax
f0101545:	50                   	push   %eax
f0101546:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f010154c:	50                   	push   %eax
f010154d:	68 6a 02 00 00       	push   $0x26a
f0101552:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0101558:	50                   	push   %eax
f0101559:	e8 3b eb ff ff       	call   f0100099 <_panic>
		--nfree;
f010155e:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101561:	8b 00                	mov    (%eax),%eax
f0101563:	85 c0                	test   %eax,%eax
f0101565:	75 f7                	jne    f010155e <mem_init+0x866>
	assert(nfree == 0);
f0101567:	85 f6                	test   %esi,%esi
f0101569:	0f 85 83 00 00 00    	jne    f01015f2 <mem_init+0x8fa>
	cprintf("check_page_alloc() succeeded!\n");
f010156f:	83 ec 0c             	sub    $0xc,%esp
f0101572:	8d 83 14 eb fe ff    	lea    -0x114ec(%ebx),%eax
f0101578:	50                   	push   %eax
f0101579:	e8 52 02 00 00       	call   f01017d0 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010157e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101585:	e8 97 f6 ff ff       	call   f0100c21 <page_alloc>
f010158a:	89 c7                	mov    %eax,%edi
f010158c:	83 c4 10             	add    $0x10,%esp
f010158f:	85 c0                	test   %eax,%eax
f0101591:	74 7e                	je     f0101611 <mem_init+0x919>
	assert((pp1 = page_alloc(0)));
f0101593:	83 ec 0c             	sub    $0xc,%esp
f0101596:	6a 00                	push   $0x0
f0101598:	e8 84 f6 ff ff       	call   f0100c21 <page_alloc>
f010159d:	89 c6                	mov    %eax,%esi
f010159f:	83 c4 10             	add    $0x10,%esp
f01015a2:	85 c0                	test   %eax,%eax
f01015a4:	0f 84 86 00 00 00    	je     f0101630 <mem_init+0x938>
	assert((pp2 = page_alloc(0)));
f01015aa:	83 ec 0c             	sub    $0xc,%esp
f01015ad:	6a 00                	push   $0x0
f01015af:	e8 6d f6 ff ff       	call   f0100c21 <page_alloc>
f01015b4:	83 c4 10             	add    $0x10,%esp
f01015b7:	85 c0                	test   %eax,%eax
f01015b9:	0f 84 90 00 00 00    	je     f010164f <mem_init+0x957>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015bf:	39 f7                	cmp    %esi,%edi
f01015c1:	0f 84 a7 00 00 00    	je     f010166e <mem_init+0x976>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015c7:	39 c7                	cmp    %eax,%edi
f01015c9:	74 08                	je     f01015d3 <mem_init+0x8db>
f01015cb:	39 c6                	cmp    %eax,%esi
f01015cd:	0f 85 ba 00 00 00    	jne    f010168d <mem_init+0x995>
f01015d3:	8d 83 94 ea fe ff    	lea    -0x1156c(%ebx),%eax
f01015d9:	50                   	push   %eax
f01015da:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f01015e0:	50                   	push   %eax
f01015e1:	68 d8 02 00 00       	push   $0x2d8
f01015e6:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f01015ec:	50                   	push   %eax
f01015ed:	e8 a7 ea ff ff       	call   f0100099 <_panic>
	assert(nfree == 0);
f01015f2:	8d 83 d0 ec fe ff    	lea    -0x11330(%ebx),%eax
f01015f8:	50                   	push   %eax
f01015f9:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f01015ff:	50                   	push   %eax
f0101600:	68 77 02 00 00       	push   $0x277
f0101605:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f010160b:	50                   	push   %eax
f010160c:	e8 88 ea ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0101611:	8d 83 35 ec fe ff    	lea    -0x113cb(%ebx),%eax
f0101617:	50                   	push   %eax
f0101618:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f010161e:	50                   	push   %eax
f010161f:	68 d2 02 00 00       	push   $0x2d2
f0101624:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f010162a:	50                   	push   %eax
f010162b:	e8 69 ea ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101630:	8d 83 4b ec fe ff    	lea    -0x113b5(%ebx),%eax
f0101636:	50                   	push   %eax
f0101637:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f010163d:	50                   	push   %eax
f010163e:	68 d3 02 00 00       	push   $0x2d3
f0101643:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0101649:	50                   	push   %eax
f010164a:	e8 4a ea ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010164f:	8d 83 61 ec fe ff    	lea    -0x1139f(%ebx),%eax
f0101655:	50                   	push   %eax
f0101656:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f010165c:	50                   	push   %eax
f010165d:	68 d4 02 00 00       	push   $0x2d4
f0101662:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0101668:	50                   	push   %eax
f0101669:	e8 2b ea ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f010166e:	8d 83 77 ec fe ff    	lea    -0x11389(%ebx),%eax
f0101674:	50                   	push   %eax
f0101675:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f010167b:	50                   	push   %eax
f010167c:	68 d7 02 00 00       	push   $0x2d7
f0101681:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f0101687:	50                   	push   %eax
f0101688:	e8 0c ea ff ff       	call   f0100099 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f010168d:	c7 83 94 1f 00 00 00 	movl   $0x0,0x1f94(%ebx)
f0101694:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101697:	83 ec 0c             	sub    $0xc,%esp
f010169a:	6a 00                	push   $0x0
f010169c:	e8 80 f5 ff ff       	call   f0100c21 <page_alloc>
f01016a1:	83 c4 10             	add    $0x10,%esp
f01016a4:	85 c0                	test   %eax,%eax
f01016a6:	74 1f                	je     f01016c7 <mem_init+0x9cf>
f01016a8:	8d 83 89 ec fe ff    	lea    -0x11377(%ebx),%eax
f01016ae:	50                   	push   %eax
f01016af:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f01016b5:	50                   	push   %eax
f01016b6:	68 df 02 00 00       	push   $0x2df
f01016bb:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f01016c1:	50                   	push   %eax
f01016c2:	e8 d2 e9 ff ff       	call   f0100099 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *)0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016c7:	8d 83 34 eb fe ff    	lea    -0x114cc(%ebx),%eax
f01016cd:	50                   	push   %eax
f01016ce:	8d 83 8a eb fe ff    	lea    -0x11476(%ebx),%eax
f01016d4:	50                   	push   %eax
f01016d5:	68 e5 02 00 00       	push   $0x2e5
f01016da:	8d 83 72 eb fe ff    	lea    -0x1148e(%ebx),%eax
f01016e0:	50                   	push   %eax
f01016e1:	e8 b3 e9 ff ff       	call   f0100099 <_panic>

f01016e6 <page_decref>:
{
f01016e6:	55                   	push   %ebp
f01016e7:	89 e5                	mov    %esp,%ebp
f01016e9:	83 ec 08             	sub    $0x8,%esp
f01016ec:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f01016ef:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01016f3:	83 e8 01             	sub    $0x1,%eax
f01016f6:	66 89 42 04          	mov    %ax,0x4(%edx)
f01016fa:	66 85 c0             	test   %ax,%ax
f01016fd:	74 02                	je     f0101701 <page_decref+0x1b>
}
f01016ff:	c9                   	leave  
f0101700:	c3                   	ret    
		page_free(pp);
f0101701:	83 ec 0c             	sub    $0xc,%esp
f0101704:	52                   	push   %edx
f0101705:	e8 9f f5 ff ff       	call   f0100ca9 <page_free>
f010170a:	83 c4 10             	add    $0x10,%esp
}
f010170d:	eb f0                	jmp    f01016ff <page_decref+0x19>

f010170f <pgdir_walk>:
{
f010170f:	55                   	push   %ebp
f0101710:	89 e5                	mov    %esp,%ebp
}
f0101712:	b8 00 00 00 00       	mov    $0x0,%eax
f0101717:	5d                   	pop    %ebp
f0101718:	c3                   	ret    

f0101719 <page_insert>:
{
f0101719:	55                   	push   %ebp
f010171a:	89 e5                	mov    %esp,%ebp
}
f010171c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101721:	5d                   	pop    %ebp
f0101722:	c3                   	ret    

f0101723 <page_lookup>:
{
f0101723:	55                   	push   %ebp
f0101724:	89 e5                	mov    %esp,%ebp
}
f0101726:	b8 00 00 00 00       	mov    $0x0,%eax
f010172b:	5d                   	pop    %ebp
f010172c:	c3                   	ret    

f010172d <page_remove>:
{
f010172d:	55                   	push   %ebp
f010172e:	89 e5                	mov    %esp,%ebp
}
f0101730:	5d                   	pop    %ebp
f0101731:	c3                   	ret    

f0101732 <tlb_invalidate>:
{
f0101732:	55                   	push   %ebp
f0101733:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101735:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101738:	0f 01 38             	invlpg (%eax)
}
f010173b:	5d                   	pop    %ebp
f010173c:	c3                   	ret    

f010173d <__x86.get_pc_thunk.dx>:
f010173d:	8b 14 24             	mov    (%esp),%edx
f0101740:	c3                   	ret    

f0101741 <__x86.get_pc_thunk.cx>:
f0101741:	8b 0c 24             	mov    (%esp),%ecx
f0101744:	c3                   	ret    

f0101745 <__x86.get_pc_thunk.di>:
f0101745:	8b 3c 24             	mov    (%esp),%edi
f0101748:	c3                   	ret    

f0101749 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0101749:	55                   	push   %ebp
f010174a:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010174c:	8b 45 08             	mov    0x8(%ebp),%eax
f010174f:	ba 70 00 00 00       	mov    $0x70,%edx
f0101754:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0101755:	ba 71 00 00 00       	mov    $0x71,%edx
f010175a:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010175b:	0f b6 c0             	movzbl %al,%eax
}
f010175e:	5d                   	pop    %ebp
f010175f:	c3                   	ret    

f0101760 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0101760:	55                   	push   %ebp
f0101761:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0101763:	8b 45 08             	mov    0x8(%ebp),%eax
f0101766:	ba 70 00 00 00       	mov    $0x70,%edx
f010176b:	ee                   	out    %al,(%dx)
f010176c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010176f:	ba 71 00 00 00       	mov    $0x71,%edx
f0101774:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0101775:	5d                   	pop    %ebp
f0101776:	c3                   	ret    

f0101777 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0101777:	55                   	push   %ebp
f0101778:	89 e5                	mov    %esp,%ebp
f010177a:	53                   	push   %ebx
f010177b:	83 ec 10             	sub    $0x10,%esp
f010177e:	e8 cc e9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101783:	81 c3 85 2b 01 00    	add    $0x12b85,%ebx
	cputchar(ch);
f0101789:	ff 75 08             	pushl  0x8(%ebp)
f010178c:	e8 35 ef ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f0101791:	83 c4 10             	add    $0x10,%esp
f0101794:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101797:	c9                   	leave  
f0101798:	c3                   	ret    

f0101799 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101799:	55                   	push   %ebp
f010179a:	89 e5                	mov    %esp,%ebp
f010179c:	53                   	push   %ebx
f010179d:	83 ec 14             	sub    $0x14,%esp
f01017a0:	e8 aa e9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01017a5:	81 c3 63 2b 01 00    	add    $0x12b63,%ebx
	int cnt = 0;
f01017ab:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01017b2:	ff 75 0c             	pushl  0xc(%ebp)
f01017b5:	ff 75 08             	pushl  0x8(%ebp)
f01017b8:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01017bb:	50                   	push   %eax
f01017bc:	8d 83 6f d4 fe ff    	lea    -0x12b91(%ebx),%eax
f01017c2:	50                   	push   %eax
f01017c3:	e8 18 04 00 00       	call   f0101be0 <vprintfmt>
	return cnt;
}
f01017c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01017cb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01017ce:	c9                   	leave  
f01017cf:	c3                   	ret    

f01017d0 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01017d0:	55                   	push   %ebp
f01017d1:	89 e5                	mov    %esp,%ebp
f01017d3:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01017d6:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01017d9:	50                   	push   %eax
f01017da:	ff 75 08             	pushl  0x8(%ebp)
f01017dd:	e8 b7 ff ff ff       	call   f0101799 <vcprintf>
	va_end(ap);

	return cnt;
}
f01017e2:	c9                   	leave  
f01017e3:	c3                   	ret    

f01017e4 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01017e4:	55                   	push   %ebp
f01017e5:	89 e5                	mov    %esp,%ebp
f01017e7:	57                   	push   %edi
f01017e8:	56                   	push   %esi
f01017e9:	53                   	push   %ebx
f01017ea:	83 ec 14             	sub    $0x14,%esp
f01017ed:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01017f0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01017f3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01017f6:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01017f9:	8b 32                	mov    (%edx),%esi
f01017fb:	8b 01                	mov    (%ecx),%eax
f01017fd:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101800:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0101807:	eb 2f                	jmp    f0101838 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0101809:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f010180c:	39 c6                	cmp    %eax,%esi
f010180e:	7f 49                	jg     f0101859 <stab_binsearch+0x75>
f0101810:	0f b6 0a             	movzbl (%edx),%ecx
f0101813:	83 ea 0c             	sub    $0xc,%edx
f0101816:	39 f9                	cmp    %edi,%ecx
f0101818:	75 ef                	jne    f0101809 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010181a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010181d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101820:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0101824:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0101827:	73 35                	jae    f010185e <stab_binsearch+0x7a>
			*region_left = m;
f0101829:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010182c:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f010182e:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0101831:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0101838:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f010183b:	7f 4e                	jg     f010188b <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f010183d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101840:	01 f0                	add    %esi,%eax
f0101842:	89 c3                	mov    %eax,%ebx
f0101844:	c1 eb 1f             	shr    $0x1f,%ebx
f0101847:	01 c3                	add    %eax,%ebx
f0101849:	d1 fb                	sar    %ebx
f010184b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010184e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101851:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0101855:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0101857:	eb b3                	jmp    f010180c <stab_binsearch+0x28>
			l = true_m + 1;
f0101859:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f010185c:	eb da                	jmp    f0101838 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f010185e:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0101861:	76 14                	jbe    f0101877 <stab_binsearch+0x93>
			*region_right = m - 1;
f0101863:	83 e8 01             	sub    $0x1,%eax
f0101866:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101869:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010186c:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f010186e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0101875:	eb c1                	jmp    f0101838 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0101877:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010187a:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010187c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0101880:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0101882:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0101889:	eb ad                	jmp    f0101838 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f010188b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010188f:	74 16                	je     f01018a7 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101891:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101894:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101896:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101899:	8b 0e                	mov    (%esi),%ecx
f010189b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010189e:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01018a1:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f01018a5:	eb 12                	jmp    f01018b9 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f01018a7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01018aa:	8b 00                	mov    (%eax),%eax
f01018ac:	83 e8 01             	sub    $0x1,%eax
f01018af:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01018b2:	89 07                	mov    %eax,(%edi)
f01018b4:	eb 16                	jmp    f01018cc <stab_binsearch+0xe8>
		     l--)
f01018b6:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f01018b9:	39 c1                	cmp    %eax,%ecx
f01018bb:	7d 0a                	jge    f01018c7 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f01018bd:	0f b6 1a             	movzbl (%edx),%ebx
f01018c0:	83 ea 0c             	sub    $0xc,%edx
f01018c3:	39 fb                	cmp    %edi,%ebx
f01018c5:	75 ef                	jne    f01018b6 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f01018c7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01018ca:	89 07                	mov    %eax,(%edi)
	}
}
f01018cc:	83 c4 14             	add    $0x14,%esp
f01018cf:	5b                   	pop    %ebx
f01018d0:	5e                   	pop    %esi
f01018d1:	5f                   	pop    %edi
f01018d2:	5d                   	pop    %ebp
f01018d3:	c3                   	ret    

f01018d4 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01018d4:	55                   	push   %ebp
f01018d5:	89 e5                	mov    %esp,%ebp
f01018d7:	57                   	push   %edi
f01018d8:	56                   	push   %esi
f01018d9:	53                   	push   %ebx
f01018da:	83 ec 2c             	sub    $0x2c,%esp
f01018dd:	e8 5f fe ff ff       	call   f0101741 <__x86.get_pc_thunk.cx>
f01018e2:	81 c1 26 2a 01 00    	add    $0x12a26,%ecx
f01018e8:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01018eb:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01018ee:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01018f1:	8d 81 db ec fe ff    	lea    -0x11325(%ecx),%eax
f01018f7:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f01018f9:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0101900:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0101903:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f010190a:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f010190d:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101914:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f010191a:	0f 86 f4 00 00 00    	jbe    f0101a14 <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101920:	c7 c0 b1 83 10 f0    	mov    $0xf01083b1,%eax
f0101926:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f010192c:	0f 86 88 01 00 00    	jbe    f0101aba <debuginfo_eip+0x1e6>
f0101932:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101935:	c7 c0 fd a0 10 f0    	mov    $0xf010a0fd,%eax
f010193b:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f010193f:	0f 85 7c 01 00 00    	jne    f0101ac1 <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0101945:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010194c:	c7 c0 fc 31 10 f0    	mov    $0xf01031fc,%eax
f0101952:	c7 c2 b0 83 10 f0    	mov    $0xf01083b0,%edx
f0101958:	29 c2                	sub    %eax,%edx
f010195a:	c1 fa 02             	sar    $0x2,%edx
f010195d:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0101963:	83 ea 01             	sub    $0x1,%edx
f0101966:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0101969:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010196c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010196f:	83 ec 08             	sub    $0x8,%esp
f0101972:	53                   	push   %ebx
f0101973:	6a 64                	push   $0x64
f0101975:	e8 6a fe ff ff       	call   f01017e4 <stab_binsearch>
	if (lfile == 0)
f010197a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010197d:	83 c4 10             	add    $0x10,%esp
f0101980:	85 c0                	test   %eax,%eax
f0101982:	0f 84 40 01 00 00    	je     f0101ac8 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0101988:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010198b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010198e:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101991:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0101994:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101997:	83 ec 08             	sub    $0x8,%esp
f010199a:	53                   	push   %ebx
f010199b:	6a 24                	push   $0x24
f010199d:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01019a0:	c7 c0 fc 31 10 f0    	mov    $0xf01031fc,%eax
f01019a6:	e8 39 fe ff ff       	call   f01017e4 <stab_binsearch>

	if (lfun <= rfun) {
f01019ab:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01019ae:	83 c4 10             	add    $0x10,%esp
f01019b1:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f01019b4:	7f 79                	jg     f0101a2f <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01019b6:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01019b9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019bc:	c7 c2 fc 31 10 f0    	mov    $0xf01031fc,%edx
f01019c2:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f01019c5:	8b 11                	mov    (%ecx),%edx
f01019c7:	c7 c0 fd a0 10 f0    	mov    $0xf010a0fd,%eax
f01019cd:	81 e8 b1 83 10 f0    	sub    $0xf01083b1,%eax
f01019d3:	39 c2                	cmp    %eax,%edx
f01019d5:	73 09                	jae    f01019e0 <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01019d7:	81 c2 b1 83 10 f0    	add    $0xf01083b1,%edx
f01019dd:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01019e0:	8b 41 08             	mov    0x8(%ecx),%eax
f01019e3:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01019e6:	83 ec 08             	sub    $0x8,%esp
f01019e9:	6a 3a                	push   $0x3a
f01019eb:	ff 77 08             	pushl  0x8(%edi)
f01019ee:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019f1:	e8 4f 09 00 00       	call   f0102345 <strfind>
f01019f6:	2b 47 08             	sub    0x8(%edi),%eax
f01019f9:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01019fc:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01019ff:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0101a02:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a05:	c7 c2 fc 31 10 f0    	mov    $0xf01031fc,%edx
f0101a0b:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f0101a0f:	83 c4 10             	add    $0x10,%esp
f0101a12:	eb 29                	jmp    f0101a3d <debuginfo_eip+0x169>
  	        panic("User address");
f0101a14:	83 ec 04             	sub    $0x4,%esp
f0101a17:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a1a:	8d 83 e5 ec fe ff    	lea    -0x1131b(%ebx),%eax
f0101a20:	50                   	push   %eax
f0101a21:	6a 7f                	push   $0x7f
f0101a23:	8d 83 f2 ec fe ff    	lea    -0x1130e(%ebx),%eax
f0101a29:	50                   	push   %eax
f0101a2a:	e8 6a e6 ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f0101a2f:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0101a32:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101a35:	eb af                	jmp    f01019e6 <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0101a37:	83 ee 01             	sub    $0x1,%esi
f0101a3a:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0101a3d:	39 f3                	cmp    %esi,%ebx
f0101a3f:	7f 3a                	jg     f0101a7b <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f0101a41:	0f b6 10             	movzbl (%eax),%edx
f0101a44:	80 fa 84             	cmp    $0x84,%dl
f0101a47:	74 0b                	je     f0101a54 <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101a49:	80 fa 64             	cmp    $0x64,%dl
f0101a4c:	75 e9                	jne    f0101a37 <debuginfo_eip+0x163>
f0101a4e:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0101a52:	74 e3                	je     f0101a37 <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101a54:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0101a57:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a5a:	c7 c0 fc 31 10 f0    	mov    $0xf01031fc,%eax
f0101a60:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0101a63:	c7 c0 fd a0 10 f0    	mov    $0xf010a0fd,%eax
f0101a69:	81 e8 b1 83 10 f0    	sub    $0xf01083b1,%eax
f0101a6f:	39 c2                	cmp    %eax,%edx
f0101a71:	73 08                	jae    f0101a7b <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101a73:	81 c2 b1 83 10 f0    	add    $0xf01083b1,%edx
f0101a79:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101a7b:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101a7e:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101a81:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0101a86:	39 cb                	cmp    %ecx,%ebx
f0101a88:	7d 4a                	jge    f0101ad4 <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0101a8a:	8d 53 01             	lea    0x1(%ebx),%edx
f0101a8d:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f0101a90:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a93:	c7 c0 fc 31 10 f0    	mov    $0xf01031fc,%eax
f0101a99:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0101a9d:	eb 07                	jmp    f0101aa6 <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f0101a9f:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0101aa3:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0101aa6:	39 d1                	cmp    %edx,%ecx
f0101aa8:	74 25                	je     f0101acf <debuginfo_eip+0x1fb>
f0101aaa:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101aad:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0101ab1:	74 ec                	je     f0101a9f <debuginfo_eip+0x1cb>
	return 0;
f0101ab3:	b8 00 00 00 00       	mov    $0x0,%eax
f0101ab8:	eb 1a                	jmp    f0101ad4 <debuginfo_eip+0x200>
		return -1;
f0101aba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101abf:	eb 13                	jmp    f0101ad4 <debuginfo_eip+0x200>
f0101ac1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101ac6:	eb 0c                	jmp    f0101ad4 <debuginfo_eip+0x200>
		return -1;
f0101ac8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101acd:	eb 05                	jmp    f0101ad4 <debuginfo_eip+0x200>
	return 0;
f0101acf:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101ad4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101ad7:	5b                   	pop    %ebx
f0101ad8:	5e                   	pop    %esi
f0101ad9:	5f                   	pop    %edi
f0101ada:	5d                   	pop    %ebp
f0101adb:	c3                   	ret    

f0101adc <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101adc:	55                   	push   %ebp
f0101add:	89 e5                	mov    %esp,%ebp
f0101adf:	57                   	push   %edi
f0101ae0:	56                   	push   %esi
f0101ae1:	53                   	push   %ebx
f0101ae2:	83 ec 2c             	sub    $0x2c,%esp
f0101ae5:	e8 57 fc ff ff       	call   f0101741 <__x86.get_pc_thunk.cx>
f0101aea:	81 c1 1e 28 01 00    	add    $0x1281e,%ecx
f0101af0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101af3:	89 c7                	mov    %eax,%edi
f0101af5:	89 d6                	mov    %edx,%esi
f0101af7:	8b 45 08             	mov    0x8(%ebp),%eax
f0101afa:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101afd:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101b00:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101b03:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101b06:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101b0b:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0101b0e:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0101b11:	39 d3                	cmp    %edx,%ebx
f0101b13:	72 09                	jb     f0101b1e <printnum+0x42>
f0101b15:	39 45 10             	cmp    %eax,0x10(%ebp)
f0101b18:	0f 87 83 00 00 00    	ja     f0101ba1 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101b1e:	83 ec 0c             	sub    $0xc,%esp
f0101b21:	ff 75 18             	pushl  0x18(%ebp)
f0101b24:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b27:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0101b2a:	53                   	push   %ebx
f0101b2b:	ff 75 10             	pushl  0x10(%ebp)
f0101b2e:	83 ec 08             	sub    $0x8,%esp
f0101b31:	ff 75 dc             	pushl  -0x24(%ebp)
f0101b34:	ff 75 d8             	pushl  -0x28(%ebp)
f0101b37:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b3a:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b3d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101b40:	e8 1b 0a 00 00       	call   f0102560 <__udivdi3>
f0101b45:	83 c4 18             	add    $0x18,%esp
f0101b48:	52                   	push   %edx
f0101b49:	50                   	push   %eax
f0101b4a:	89 f2                	mov    %esi,%edx
f0101b4c:	89 f8                	mov    %edi,%eax
f0101b4e:	e8 89 ff ff ff       	call   f0101adc <printnum>
f0101b53:	83 c4 20             	add    $0x20,%esp
f0101b56:	eb 13                	jmp    f0101b6b <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101b58:	83 ec 08             	sub    $0x8,%esp
f0101b5b:	56                   	push   %esi
f0101b5c:	ff 75 18             	pushl  0x18(%ebp)
f0101b5f:	ff d7                	call   *%edi
f0101b61:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0101b64:	83 eb 01             	sub    $0x1,%ebx
f0101b67:	85 db                	test   %ebx,%ebx
f0101b69:	7f ed                	jg     f0101b58 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101b6b:	83 ec 08             	sub    $0x8,%esp
f0101b6e:	56                   	push   %esi
f0101b6f:	83 ec 04             	sub    $0x4,%esp
f0101b72:	ff 75 dc             	pushl  -0x24(%ebp)
f0101b75:	ff 75 d8             	pushl  -0x28(%ebp)
f0101b78:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b7b:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b7e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101b81:	89 f3                	mov    %esi,%ebx
f0101b83:	e8 f8 0a 00 00       	call   f0102680 <__umoddi3>
f0101b88:	83 c4 14             	add    $0x14,%esp
f0101b8b:	0f be 84 06 00 ed fe 	movsbl -0x11300(%esi,%eax,1),%eax
f0101b92:	ff 
f0101b93:	50                   	push   %eax
f0101b94:	ff d7                	call   *%edi
}
f0101b96:	83 c4 10             	add    $0x10,%esp
f0101b99:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101b9c:	5b                   	pop    %ebx
f0101b9d:	5e                   	pop    %esi
f0101b9e:	5f                   	pop    %edi
f0101b9f:	5d                   	pop    %ebp
f0101ba0:	c3                   	ret    
f0101ba1:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0101ba4:	eb be                	jmp    f0101b64 <printnum+0x88>

f0101ba6 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101ba6:	55                   	push   %ebp
f0101ba7:	89 e5                	mov    %esp,%ebp
f0101ba9:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101bac:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101bb0:	8b 10                	mov    (%eax),%edx
f0101bb2:	3b 50 04             	cmp    0x4(%eax),%edx
f0101bb5:	73 0a                	jae    f0101bc1 <sprintputch+0x1b>
		*b->buf++ = ch;
f0101bb7:	8d 4a 01             	lea    0x1(%edx),%ecx
f0101bba:	89 08                	mov    %ecx,(%eax)
f0101bbc:	8b 45 08             	mov    0x8(%ebp),%eax
f0101bbf:	88 02                	mov    %al,(%edx)
}
f0101bc1:	5d                   	pop    %ebp
f0101bc2:	c3                   	ret    

f0101bc3 <printfmt>:
{
f0101bc3:	55                   	push   %ebp
f0101bc4:	89 e5                	mov    %esp,%ebp
f0101bc6:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0101bc9:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101bcc:	50                   	push   %eax
f0101bcd:	ff 75 10             	pushl  0x10(%ebp)
f0101bd0:	ff 75 0c             	pushl  0xc(%ebp)
f0101bd3:	ff 75 08             	pushl  0x8(%ebp)
f0101bd6:	e8 05 00 00 00       	call   f0101be0 <vprintfmt>
}
f0101bdb:	83 c4 10             	add    $0x10,%esp
f0101bde:	c9                   	leave  
f0101bdf:	c3                   	ret    

f0101be0 <vprintfmt>:
{
f0101be0:	55                   	push   %ebp
f0101be1:	89 e5                	mov    %esp,%ebp
f0101be3:	57                   	push   %edi
f0101be4:	56                   	push   %esi
f0101be5:	53                   	push   %ebx
f0101be6:	83 ec 2c             	sub    $0x2c,%esp
f0101be9:	e8 61 e5 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101bee:	81 c3 1a 27 01 00    	add    $0x1271a,%ebx
f0101bf4:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101bf7:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101bfa:	e9 c3 03 00 00       	jmp    f0101fc2 <.L35+0x48>
		padc = ' ';
f0101bff:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0101c03:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0101c0a:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f0101c11:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0101c18:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101c1d:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101c20:	8d 47 01             	lea    0x1(%edi),%eax
f0101c23:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101c26:	0f b6 17             	movzbl (%edi),%edx
f0101c29:	8d 42 dd             	lea    -0x23(%edx),%eax
f0101c2c:	3c 55                	cmp    $0x55,%al
f0101c2e:	0f 87 16 04 00 00    	ja     f010204a <.L22>
f0101c34:	0f b6 c0             	movzbl %al,%eax
f0101c37:	89 d9                	mov    %ebx,%ecx
f0101c39:	03 8c 83 8c ed fe ff 	add    -0x11274(%ebx,%eax,4),%ecx
f0101c40:	ff e1                	jmp    *%ecx

f0101c42 <.L69>:
f0101c42:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0101c45:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0101c49:	eb d5                	jmp    f0101c20 <vprintfmt+0x40>

f0101c4b <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0101c4b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0101c4e:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0101c52:	eb cc                	jmp    f0101c20 <vprintfmt+0x40>

f0101c54 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0101c54:	0f b6 d2             	movzbl %dl,%edx
f0101c57:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0101c5a:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0101c5f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101c62:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0101c66:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0101c69:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0101c6c:	83 f9 09             	cmp    $0x9,%ecx
f0101c6f:	77 55                	ja     f0101cc6 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0101c71:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0101c74:	eb e9                	jmp    f0101c5f <.L29+0xb>

f0101c76 <.L26>:
			precision = va_arg(ap, int);
f0101c76:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c79:	8b 00                	mov    (%eax),%eax
f0101c7b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c7e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c81:	8d 40 04             	lea    0x4(%eax),%eax
f0101c84:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101c87:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0101c8a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101c8e:	79 90                	jns    f0101c20 <vprintfmt+0x40>
				width = precision, precision = -1;
f0101c90:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101c93:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101c96:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0101c9d:	eb 81                	jmp    f0101c20 <vprintfmt+0x40>

f0101c9f <.L27>:
f0101c9f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101ca2:	85 c0                	test   %eax,%eax
f0101ca4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ca9:	0f 49 d0             	cmovns %eax,%edx
f0101cac:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101caf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101cb2:	e9 69 ff ff ff       	jmp    f0101c20 <vprintfmt+0x40>

f0101cb7 <.L23>:
f0101cb7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0101cba:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101cc1:	e9 5a ff ff ff       	jmp    f0101c20 <vprintfmt+0x40>
f0101cc6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101cc9:	eb bf                	jmp    f0101c8a <.L26+0x14>

f0101ccb <.L33>:
			lflag++;
f0101ccb:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101ccf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0101cd2:	e9 49 ff ff ff       	jmp    f0101c20 <vprintfmt+0x40>

f0101cd7 <.L30>:
			putch(va_arg(ap, int), putdat);
f0101cd7:	8b 45 14             	mov    0x14(%ebp),%eax
f0101cda:	8d 78 04             	lea    0x4(%eax),%edi
f0101cdd:	83 ec 08             	sub    $0x8,%esp
f0101ce0:	56                   	push   %esi
f0101ce1:	ff 30                	pushl  (%eax)
f0101ce3:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101ce6:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0101ce9:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0101cec:	e9 ce 02 00 00       	jmp    f0101fbf <.L35+0x45>

f0101cf1 <.L32>:
			err = va_arg(ap, int);
f0101cf1:	8b 45 14             	mov    0x14(%ebp),%eax
f0101cf4:	8d 78 04             	lea    0x4(%eax),%edi
f0101cf7:	8b 00                	mov    (%eax),%eax
f0101cf9:	99                   	cltd   
f0101cfa:	31 d0                	xor    %edx,%eax
f0101cfc:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101cfe:	83 f8 06             	cmp    $0x6,%eax
f0101d01:	7f 27                	jg     f0101d2a <.L32+0x39>
f0101d03:	8b 94 83 20 1d 00 00 	mov    0x1d20(%ebx,%eax,4),%edx
f0101d0a:	85 d2                	test   %edx,%edx
f0101d0c:	74 1c                	je     f0101d2a <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0101d0e:	52                   	push   %edx
f0101d0f:	8d 83 9c eb fe ff    	lea    -0x11464(%ebx),%eax
f0101d15:	50                   	push   %eax
f0101d16:	56                   	push   %esi
f0101d17:	ff 75 08             	pushl  0x8(%ebp)
f0101d1a:	e8 a4 fe ff ff       	call   f0101bc3 <printfmt>
f0101d1f:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0101d22:	89 7d 14             	mov    %edi,0x14(%ebp)
f0101d25:	e9 95 02 00 00       	jmp    f0101fbf <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0101d2a:	50                   	push   %eax
f0101d2b:	8d 83 18 ed fe ff    	lea    -0x112e8(%ebx),%eax
f0101d31:	50                   	push   %eax
f0101d32:	56                   	push   %esi
f0101d33:	ff 75 08             	pushl  0x8(%ebp)
f0101d36:	e8 88 fe ff ff       	call   f0101bc3 <printfmt>
f0101d3b:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0101d3e:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0101d41:	e9 79 02 00 00       	jmp    f0101fbf <.L35+0x45>

f0101d46 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0101d46:	8b 45 14             	mov    0x14(%ebp),%eax
f0101d49:	83 c0 04             	add    $0x4,%eax
f0101d4c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101d4f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101d52:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101d54:	85 ff                	test   %edi,%edi
f0101d56:	8d 83 11 ed fe ff    	lea    -0x112ef(%ebx),%eax
f0101d5c:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101d5f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101d63:	0f 8e b5 00 00 00    	jle    f0101e1e <.L36+0xd8>
f0101d69:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101d6d:	75 08                	jne    f0101d77 <.L36+0x31>
f0101d6f:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101d72:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101d75:	eb 6d                	jmp    f0101de4 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101d77:	83 ec 08             	sub    $0x8,%esp
f0101d7a:	ff 75 cc             	pushl  -0x34(%ebp)
f0101d7d:	57                   	push   %edi
f0101d7e:	e8 7e 04 00 00       	call   f0102201 <strnlen>
f0101d83:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101d86:	29 c2                	sub    %eax,%edx
f0101d88:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0101d8b:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101d8e:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101d92:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101d95:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101d98:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101d9a:	eb 10                	jmp    f0101dac <.L36+0x66>
					putch(padc, putdat);
f0101d9c:	83 ec 08             	sub    $0x8,%esp
f0101d9f:	56                   	push   %esi
f0101da0:	ff 75 e0             	pushl  -0x20(%ebp)
f0101da3:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101da6:	83 ef 01             	sub    $0x1,%edi
f0101da9:	83 c4 10             	add    $0x10,%esp
f0101dac:	85 ff                	test   %edi,%edi
f0101dae:	7f ec                	jg     f0101d9c <.L36+0x56>
f0101db0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101db3:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0101db6:	85 d2                	test   %edx,%edx
f0101db8:	b8 00 00 00 00       	mov    $0x0,%eax
f0101dbd:	0f 49 c2             	cmovns %edx,%eax
f0101dc0:	29 c2                	sub    %eax,%edx
f0101dc2:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101dc5:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101dc8:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101dcb:	eb 17                	jmp    f0101de4 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0101dcd:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101dd1:	75 30                	jne    f0101e03 <.L36+0xbd>
					putch(ch, putdat);
f0101dd3:	83 ec 08             	sub    $0x8,%esp
f0101dd6:	ff 75 0c             	pushl  0xc(%ebp)
f0101dd9:	50                   	push   %eax
f0101dda:	ff 55 08             	call   *0x8(%ebp)
f0101ddd:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101de0:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101de4:	83 c7 01             	add    $0x1,%edi
f0101de7:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101deb:	0f be c2             	movsbl %dl,%eax
f0101dee:	85 c0                	test   %eax,%eax
f0101df0:	74 52                	je     f0101e44 <.L36+0xfe>
f0101df2:	85 f6                	test   %esi,%esi
f0101df4:	78 d7                	js     f0101dcd <.L36+0x87>
f0101df6:	83 ee 01             	sub    $0x1,%esi
f0101df9:	79 d2                	jns    f0101dcd <.L36+0x87>
f0101dfb:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101dfe:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101e01:	eb 32                	jmp    f0101e35 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f0101e03:	0f be d2             	movsbl %dl,%edx
f0101e06:	83 ea 20             	sub    $0x20,%edx
f0101e09:	83 fa 5e             	cmp    $0x5e,%edx
f0101e0c:	76 c5                	jbe    f0101dd3 <.L36+0x8d>
					putch('?', putdat);
f0101e0e:	83 ec 08             	sub    $0x8,%esp
f0101e11:	ff 75 0c             	pushl  0xc(%ebp)
f0101e14:	6a 3f                	push   $0x3f
f0101e16:	ff 55 08             	call   *0x8(%ebp)
f0101e19:	83 c4 10             	add    $0x10,%esp
f0101e1c:	eb c2                	jmp    f0101de0 <.L36+0x9a>
f0101e1e:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101e21:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101e24:	eb be                	jmp    f0101de4 <.L36+0x9e>
				putch(' ', putdat);
f0101e26:	83 ec 08             	sub    $0x8,%esp
f0101e29:	56                   	push   %esi
f0101e2a:	6a 20                	push   $0x20
f0101e2c:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f0101e2f:	83 ef 01             	sub    $0x1,%edi
f0101e32:	83 c4 10             	add    $0x10,%esp
f0101e35:	85 ff                	test   %edi,%edi
f0101e37:	7f ed                	jg     f0101e26 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0101e39:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e3c:	89 45 14             	mov    %eax,0x14(%ebp)
f0101e3f:	e9 7b 01 00 00       	jmp    f0101fbf <.L35+0x45>
f0101e44:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101e47:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101e4a:	eb e9                	jmp    f0101e35 <.L36+0xef>

f0101e4c <.L31>:
f0101e4c:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101e4f:	83 f9 01             	cmp    $0x1,%ecx
f0101e52:	7e 40                	jle    f0101e94 <.L31+0x48>
		return va_arg(*ap, long long);
f0101e54:	8b 45 14             	mov    0x14(%ebp),%eax
f0101e57:	8b 50 04             	mov    0x4(%eax),%edx
f0101e5a:	8b 00                	mov    (%eax),%eax
f0101e5c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101e5f:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101e62:	8b 45 14             	mov    0x14(%ebp),%eax
f0101e65:	8d 40 08             	lea    0x8(%eax),%eax
f0101e68:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101e6b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101e6f:	79 55                	jns    f0101ec6 <.L31+0x7a>
				putch('-', putdat);
f0101e71:	83 ec 08             	sub    $0x8,%esp
f0101e74:	56                   	push   %esi
f0101e75:	6a 2d                	push   $0x2d
f0101e77:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101e7a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101e7d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101e80:	f7 da                	neg    %edx
f0101e82:	83 d1 00             	adc    $0x0,%ecx
f0101e85:	f7 d9                	neg    %ecx
f0101e87:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101e8a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101e8f:	e9 10 01 00 00       	jmp    f0101fa4 <.L35+0x2a>
	else if (lflag)
f0101e94:	85 c9                	test   %ecx,%ecx
f0101e96:	75 17                	jne    f0101eaf <.L31+0x63>
		return va_arg(*ap, int);
f0101e98:	8b 45 14             	mov    0x14(%ebp),%eax
f0101e9b:	8b 00                	mov    (%eax),%eax
f0101e9d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101ea0:	99                   	cltd   
f0101ea1:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101ea4:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ea7:	8d 40 04             	lea    0x4(%eax),%eax
f0101eaa:	89 45 14             	mov    %eax,0x14(%ebp)
f0101ead:	eb bc                	jmp    f0101e6b <.L31+0x1f>
		return va_arg(*ap, long);
f0101eaf:	8b 45 14             	mov    0x14(%ebp),%eax
f0101eb2:	8b 00                	mov    (%eax),%eax
f0101eb4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101eb7:	99                   	cltd   
f0101eb8:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101ebb:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ebe:	8d 40 04             	lea    0x4(%eax),%eax
f0101ec1:	89 45 14             	mov    %eax,0x14(%ebp)
f0101ec4:	eb a5                	jmp    f0101e6b <.L31+0x1f>
			num = getint(&ap, lflag);
f0101ec6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101ec9:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101ecc:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101ed1:	e9 ce 00 00 00       	jmp    f0101fa4 <.L35+0x2a>

f0101ed6 <.L37>:
f0101ed6:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101ed9:	83 f9 01             	cmp    $0x1,%ecx
f0101edc:	7e 18                	jle    f0101ef6 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f0101ede:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ee1:	8b 10                	mov    (%eax),%edx
f0101ee3:	8b 48 04             	mov    0x4(%eax),%ecx
f0101ee6:	8d 40 08             	lea    0x8(%eax),%eax
f0101ee9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101eec:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101ef1:	e9 ae 00 00 00       	jmp    f0101fa4 <.L35+0x2a>
	else if (lflag)
f0101ef6:	85 c9                	test   %ecx,%ecx
f0101ef8:	75 1a                	jne    f0101f14 <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f0101efa:	8b 45 14             	mov    0x14(%ebp),%eax
f0101efd:	8b 10                	mov    (%eax),%edx
f0101eff:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101f04:	8d 40 04             	lea    0x4(%eax),%eax
f0101f07:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101f0a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101f0f:	e9 90 00 00 00       	jmp    f0101fa4 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101f14:	8b 45 14             	mov    0x14(%ebp),%eax
f0101f17:	8b 10                	mov    (%eax),%edx
f0101f19:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101f1e:	8d 40 04             	lea    0x4(%eax),%eax
f0101f21:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101f24:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101f29:	eb 79                	jmp    f0101fa4 <.L35+0x2a>

f0101f2b <.L34>:
f0101f2b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101f2e:	83 f9 01             	cmp    $0x1,%ecx
f0101f31:	7e 15                	jle    f0101f48 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f0101f33:	8b 45 14             	mov    0x14(%ebp),%eax
f0101f36:	8b 10                	mov    (%eax),%edx
f0101f38:	8b 48 04             	mov    0x4(%eax),%ecx
f0101f3b:	8d 40 08             	lea    0x8(%eax),%eax
f0101f3e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0101f41:	b8 08 00 00 00       	mov    $0x8,%eax
f0101f46:	eb 5c                	jmp    f0101fa4 <.L35+0x2a>
	else if (lflag)
f0101f48:	85 c9                	test   %ecx,%ecx
f0101f4a:	75 17                	jne    f0101f63 <.L34+0x38>
		return va_arg(*ap, unsigned int);
f0101f4c:	8b 45 14             	mov    0x14(%ebp),%eax
f0101f4f:	8b 10                	mov    (%eax),%edx
f0101f51:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101f56:	8d 40 04             	lea    0x4(%eax),%eax
f0101f59:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0101f5c:	b8 08 00 00 00       	mov    $0x8,%eax
f0101f61:	eb 41                	jmp    f0101fa4 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101f63:	8b 45 14             	mov    0x14(%ebp),%eax
f0101f66:	8b 10                	mov    (%eax),%edx
f0101f68:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101f6d:	8d 40 04             	lea    0x4(%eax),%eax
f0101f70:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0101f73:	b8 08 00 00 00       	mov    $0x8,%eax
f0101f78:	eb 2a                	jmp    f0101fa4 <.L35+0x2a>

f0101f7a <.L35>:
			putch('0', putdat);
f0101f7a:	83 ec 08             	sub    $0x8,%esp
f0101f7d:	56                   	push   %esi
f0101f7e:	6a 30                	push   $0x30
f0101f80:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101f83:	83 c4 08             	add    $0x8,%esp
f0101f86:	56                   	push   %esi
f0101f87:	6a 78                	push   $0x78
f0101f89:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0101f8c:	8b 45 14             	mov    0x14(%ebp),%eax
f0101f8f:	8b 10                	mov    (%eax),%edx
f0101f91:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0101f96:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101f99:	8d 40 04             	lea    0x4(%eax),%eax
f0101f9c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101f9f:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0101fa4:	83 ec 0c             	sub    $0xc,%esp
f0101fa7:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101fab:	57                   	push   %edi
f0101fac:	ff 75 e0             	pushl  -0x20(%ebp)
f0101faf:	50                   	push   %eax
f0101fb0:	51                   	push   %ecx
f0101fb1:	52                   	push   %edx
f0101fb2:	89 f2                	mov    %esi,%edx
f0101fb4:	8b 45 08             	mov    0x8(%ebp),%eax
f0101fb7:	e8 20 fb ff ff       	call   f0101adc <printnum>
			break;
f0101fbc:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0101fbf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101fc2:	83 c7 01             	add    $0x1,%edi
f0101fc5:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101fc9:	83 f8 25             	cmp    $0x25,%eax
f0101fcc:	0f 84 2d fc ff ff    	je     f0101bff <vprintfmt+0x1f>
			if (ch == '\0')
f0101fd2:	85 c0                	test   %eax,%eax
f0101fd4:	0f 84 91 00 00 00    	je     f010206b <.L22+0x21>
			putch(ch, putdat);
f0101fda:	83 ec 08             	sub    $0x8,%esp
f0101fdd:	56                   	push   %esi
f0101fde:	50                   	push   %eax
f0101fdf:	ff 55 08             	call   *0x8(%ebp)
f0101fe2:	83 c4 10             	add    $0x10,%esp
f0101fe5:	eb db                	jmp    f0101fc2 <.L35+0x48>

f0101fe7 <.L38>:
f0101fe7:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101fea:	83 f9 01             	cmp    $0x1,%ecx
f0101fed:	7e 15                	jle    f0102004 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0101fef:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ff2:	8b 10                	mov    (%eax),%edx
f0101ff4:	8b 48 04             	mov    0x4(%eax),%ecx
f0101ff7:	8d 40 08             	lea    0x8(%eax),%eax
f0101ffa:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101ffd:	b8 10 00 00 00       	mov    $0x10,%eax
f0102002:	eb a0                	jmp    f0101fa4 <.L35+0x2a>
	else if (lflag)
f0102004:	85 c9                	test   %ecx,%ecx
f0102006:	75 17                	jne    f010201f <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0102008:	8b 45 14             	mov    0x14(%ebp),%eax
f010200b:	8b 10                	mov    (%eax),%edx
f010200d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102012:	8d 40 04             	lea    0x4(%eax),%eax
f0102015:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102018:	b8 10 00 00 00       	mov    $0x10,%eax
f010201d:	eb 85                	jmp    f0101fa4 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010201f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102022:	8b 10                	mov    (%eax),%edx
f0102024:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102029:	8d 40 04             	lea    0x4(%eax),%eax
f010202c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010202f:	b8 10 00 00 00       	mov    $0x10,%eax
f0102034:	e9 6b ff ff ff       	jmp    f0101fa4 <.L35+0x2a>

f0102039 <.L25>:
			putch(ch, putdat);
f0102039:	83 ec 08             	sub    $0x8,%esp
f010203c:	56                   	push   %esi
f010203d:	6a 25                	push   $0x25
f010203f:	ff 55 08             	call   *0x8(%ebp)
			break;
f0102042:	83 c4 10             	add    $0x10,%esp
f0102045:	e9 75 ff ff ff       	jmp    f0101fbf <.L35+0x45>

f010204a <.L22>:
			putch('%', putdat);
f010204a:	83 ec 08             	sub    $0x8,%esp
f010204d:	56                   	push   %esi
f010204e:	6a 25                	push   $0x25
f0102050:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102053:	83 c4 10             	add    $0x10,%esp
f0102056:	89 f8                	mov    %edi,%eax
f0102058:	eb 03                	jmp    f010205d <.L22+0x13>
f010205a:	83 e8 01             	sub    $0x1,%eax
f010205d:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0102061:	75 f7                	jne    f010205a <.L22+0x10>
f0102063:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102066:	e9 54 ff ff ff       	jmp    f0101fbf <.L35+0x45>
}
f010206b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010206e:	5b                   	pop    %ebx
f010206f:	5e                   	pop    %esi
f0102070:	5f                   	pop    %edi
f0102071:	5d                   	pop    %ebp
f0102072:	c3                   	ret    

f0102073 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102073:	55                   	push   %ebp
f0102074:	89 e5                	mov    %esp,%ebp
f0102076:	53                   	push   %ebx
f0102077:	83 ec 14             	sub    $0x14,%esp
f010207a:	e8 d0 e0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010207f:	81 c3 89 22 01 00    	add    $0x12289,%ebx
f0102085:	8b 45 08             	mov    0x8(%ebp),%eax
f0102088:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010208b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010208e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102092:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102095:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010209c:	85 c0                	test   %eax,%eax
f010209e:	74 2b                	je     f01020cb <vsnprintf+0x58>
f01020a0:	85 d2                	test   %edx,%edx
f01020a2:	7e 27                	jle    f01020cb <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01020a4:	ff 75 14             	pushl  0x14(%ebp)
f01020a7:	ff 75 10             	pushl  0x10(%ebp)
f01020aa:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01020ad:	50                   	push   %eax
f01020ae:	8d 83 9e d8 fe ff    	lea    -0x12762(%ebx),%eax
f01020b4:	50                   	push   %eax
f01020b5:	e8 26 fb ff ff       	call   f0101be0 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01020ba:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01020bd:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01020c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01020c3:	83 c4 10             	add    $0x10,%esp
}
f01020c6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01020c9:	c9                   	leave  
f01020ca:	c3                   	ret    
		return -E_INVAL;
f01020cb:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01020d0:	eb f4                	jmp    f01020c6 <vsnprintf+0x53>

f01020d2 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01020d2:	55                   	push   %ebp
f01020d3:	89 e5                	mov    %esp,%ebp
f01020d5:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01020d8:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01020db:	50                   	push   %eax
f01020dc:	ff 75 10             	pushl  0x10(%ebp)
f01020df:	ff 75 0c             	pushl  0xc(%ebp)
f01020e2:	ff 75 08             	pushl  0x8(%ebp)
f01020e5:	e8 89 ff ff ff       	call   f0102073 <vsnprintf>
	va_end(ap);

	return rc;
}
f01020ea:	c9                   	leave  
f01020eb:	c3                   	ret    

f01020ec <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01020ec:	55                   	push   %ebp
f01020ed:	89 e5                	mov    %esp,%ebp
f01020ef:	57                   	push   %edi
f01020f0:	56                   	push   %esi
f01020f1:	53                   	push   %ebx
f01020f2:	83 ec 1c             	sub    $0x1c,%esp
f01020f5:	e8 55 e0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01020fa:	81 c3 0e 22 01 00    	add    $0x1220e,%ebx
f0102100:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102103:	85 c0                	test   %eax,%eax
f0102105:	74 13                	je     f010211a <readline+0x2e>
		cprintf("%s", prompt);
f0102107:	83 ec 08             	sub    $0x8,%esp
f010210a:	50                   	push   %eax
f010210b:	8d 83 9c eb fe ff    	lea    -0x11464(%ebx),%eax
f0102111:	50                   	push   %eax
f0102112:	e8 b9 f6 ff ff       	call   f01017d0 <cprintf>
f0102117:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010211a:	83 ec 0c             	sub    $0xc,%esp
f010211d:	6a 00                	push   $0x0
f010211f:	e8 c3 e5 ff ff       	call   f01006e7 <iscons>
f0102124:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102127:	83 c4 10             	add    $0x10,%esp
	i = 0;
f010212a:	bf 00 00 00 00       	mov    $0x0,%edi
f010212f:	eb 46                	jmp    f0102177 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0102131:	83 ec 08             	sub    $0x8,%esp
f0102134:	50                   	push   %eax
f0102135:	8d 83 e4 ee fe ff    	lea    -0x1111c(%ebx),%eax
f010213b:	50                   	push   %eax
f010213c:	e8 8f f6 ff ff       	call   f01017d0 <cprintf>
			return NULL;
f0102141:	83 c4 10             	add    $0x10,%esp
f0102144:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0102149:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010214c:	5b                   	pop    %ebx
f010214d:	5e                   	pop    %esi
f010214e:	5f                   	pop    %edi
f010214f:	5d                   	pop    %ebp
f0102150:	c3                   	ret    
			if (echoing)
f0102151:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0102155:	75 05                	jne    f010215c <readline+0x70>
			i--;
f0102157:	83 ef 01             	sub    $0x1,%edi
f010215a:	eb 1b                	jmp    f0102177 <readline+0x8b>
				cputchar('\b');
f010215c:	83 ec 0c             	sub    $0xc,%esp
f010215f:	6a 08                	push   $0x8
f0102161:	e8 60 e5 ff ff       	call   f01006c6 <cputchar>
f0102166:	83 c4 10             	add    $0x10,%esp
f0102169:	eb ec                	jmp    f0102157 <readline+0x6b>
			buf[i++] = c;
f010216b:	89 f0                	mov    %esi,%eax
f010216d:	88 84 3b b8 1f 00 00 	mov    %al,0x1fb8(%ebx,%edi,1)
f0102174:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0102177:	e8 5a e5 ff ff       	call   f01006d6 <getchar>
f010217c:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f010217e:	85 c0                	test   %eax,%eax
f0102180:	78 af                	js     f0102131 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102182:	83 f8 08             	cmp    $0x8,%eax
f0102185:	0f 94 c2             	sete   %dl
f0102188:	83 f8 7f             	cmp    $0x7f,%eax
f010218b:	0f 94 c0             	sete   %al
f010218e:	08 c2                	or     %al,%dl
f0102190:	74 04                	je     f0102196 <readline+0xaa>
f0102192:	85 ff                	test   %edi,%edi
f0102194:	7f bb                	jg     f0102151 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102196:	83 fe 1f             	cmp    $0x1f,%esi
f0102199:	7e 1c                	jle    f01021b7 <readline+0xcb>
f010219b:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f01021a1:	7f 14                	jg     f01021b7 <readline+0xcb>
			if (echoing)
f01021a3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01021a7:	74 c2                	je     f010216b <readline+0x7f>
				cputchar(c);
f01021a9:	83 ec 0c             	sub    $0xc,%esp
f01021ac:	56                   	push   %esi
f01021ad:	e8 14 e5 ff ff       	call   f01006c6 <cputchar>
f01021b2:	83 c4 10             	add    $0x10,%esp
f01021b5:	eb b4                	jmp    f010216b <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f01021b7:	83 fe 0a             	cmp    $0xa,%esi
f01021ba:	74 05                	je     f01021c1 <readline+0xd5>
f01021bc:	83 fe 0d             	cmp    $0xd,%esi
f01021bf:	75 b6                	jne    f0102177 <readline+0x8b>
			if (echoing)
f01021c1:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01021c5:	75 13                	jne    f01021da <readline+0xee>
			buf[i] = 0;
f01021c7:	c6 84 3b b8 1f 00 00 	movb   $0x0,0x1fb8(%ebx,%edi,1)
f01021ce:	00 
			return buf;
f01021cf:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f01021d5:	e9 6f ff ff ff       	jmp    f0102149 <readline+0x5d>
				cputchar('\n');
f01021da:	83 ec 0c             	sub    $0xc,%esp
f01021dd:	6a 0a                	push   $0xa
f01021df:	e8 e2 e4 ff ff       	call   f01006c6 <cputchar>
f01021e4:	83 c4 10             	add    $0x10,%esp
f01021e7:	eb de                	jmp    f01021c7 <readline+0xdb>

f01021e9 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01021e9:	55                   	push   %ebp
f01021ea:	89 e5                	mov    %esp,%ebp
f01021ec:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01021ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01021f4:	eb 03                	jmp    f01021f9 <strlen+0x10>
		n++;
f01021f6:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01021f9:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01021fd:	75 f7                	jne    f01021f6 <strlen+0xd>
	return n;
}
f01021ff:	5d                   	pop    %ebp
f0102200:	c3                   	ret    

f0102201 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102201:	55                   	push   %ebp
f0102202:	89 e5                	mov    %esp,%ebp
f0102204:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102207:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010220a:	b8 00 00 00 00       	mov    $0x0,%eax
f010220f:	eb 03                	jmp    f0102214 <strnlen+0x13>
		n++;
f0102211:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102214:	39 d0                	cmp    %edx,%eax
f0102216:	74 06                	je     f010221e <strnlen+0x1d>
f0102218:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010221c:	75 f3                	jne    f0102211 <strnlen+0x10>
	return n;
}
f010221e:	5d                   	pop    %ebp
f010221f:	c3                   	ret    

f0102220 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102220:	55                   	push   %ebp
f0102221:	89 e5                	mov    %esp,%ebp
f0102223:	53                   	push   %ebx
f0102224:	8b 45 08             	mov    0x8(%ebp),%eax
f0102227:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010222a:	89 c2                	mov    %eax,%edx
f010222c:	83 c1 01             	add    $0x1,%ecx
f010222f:	83 c2 01             	add    $0x1,%edx
f0102232:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0102236:	88 5a ff             	mov    %bl,-0x1(%edx)
f0102239:	84 db                	test   %bl,%bl
f010223b:	75 ef                	jne    f010222c <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010223d:	5b                   	pop    %ebx
f010223e:	5d                   	pop    %ebp
f010223f:	c3                   	ret    

f0102240 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0102240:	55                   	push   %ebp
f0102241:	89 e5                	mov    %esp,%ebp
f0102243:	53                   	push   %ebx
f0102244:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0102247:	53                   	push   %ebx
f0102248:	e8 9c ff ff ff       	call   f01021e9 <strlen>
f010224d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0102250:	ff 75 0c             	pushl  0xc(%ebp)
f0102253:	01 d8                	add    %ebx,%eax
f0102255:	50                   	push   %eax
f0102256:	e8 c5 ff ff ff       	call   f0102220 <strcpy>
	return dst;
}
f010225b:	89 d8                	mov    %ebx,%eax
f010225d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102260:	c9                   	leave  
f0102261:	c3                   	ret    

f0102262 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102262:	55                   	push   %ebp
f0102263:	89 e5                	mov    %esp,%ebp
f0102265:	56                   	push   %esi
f0102266:	53                   	push   %ebx
f0102267:	8b 75 08             	mov    0x8(%ebp),%esi
f010226a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010226d:	89 f3                	mov    %esi,%ebx
f010226f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102272:	89 f2                	mov    %esi,%edx
f0102274:	eb 0f                	jmp    f0102285 <strncpy+0x23>
		*dst++ = *src;
f0102276:	83 c2 01             	add    $0x1,%edx
f0102279:	0f b6 01             	movzbl (%ecx),%eax
f010227c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010227f:	80 39 01             	cmpb   $0x1,(%ecx)
f0102282:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0102285:	39 da                	cmp    %ebx,%edx
f0102287:	75 ed                	jne    f0102276 <strncpy+0x14>
	}
	return ret;
}
f0102289:	89 f0                	mov    %esi,%eax
f010228b:	5b                   	pop    %ebx
f010228c:	5e                   	pop    %esi
f010228d:	5d                   	pop    %ebp
f010228e:	c3                   	ret    

f010228f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010228f:	55                   	push   %ebp
f0102290:	89 e5                	mov    %esp,%ebp
f0102292:	56                   	push   %esi
f0102293:	53                   	push   %ebx
f0102294:	8b 75 08             	mov    0x8(%ebp),%esi
f0102297:	8b 55 0c             	mov    0xc(%ebp),%edx
f010229a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010229d:	89 f0                	mov    %esi,%eax
f010229f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01022a3:	85 c9                	test   %ecx,%ecx
f01022a5:	75 0b                	jne    f01022b2 <strlcpy+0x23>
f01022a7:	eb 17                	jmp    f01022c0 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01022a9:	83 c2 01             	add    $0x1,%edx
f01022ac:	83 c0 01             	add    $0x1,%eax
f01022af:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f01022b2:	39 d8                	cmp    %ebx,%eax
f01022b4:	74 07                	je     f01022bd <strlcpy+0x2e>
f01022b6:	0f b6 0a             	movzbl (%edx),%ecx
f01022b9:	84 c9                	test   %cl,%cl
f01022bb:	75 ec                	jne    f01022a9 <strlcpy+0x1a>
		*dst = '\0';
f01022bd:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01022c0:	29 f0                	sub    %esi,%eax
}
f01022c2:	5b                   	pop    %ebx
f01022c3:	5e                   	pop    %esi
f01022c4:	5d                   	pop    %ebp
f01022c5:	c3                   	ret    

f01022c6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01022c6:	55                   	push   %ebp
f01022c7:	89 e5                	mov    %esp,%ebp
f01022c9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01022cc:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01022cf:	eb 06                	jmp    f01022d7 <strcmp+0x11>
		p++, q++;
f01022d1:	83 c1 01             	add    $0x1,%ecx
f01022d4:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01022d7:	0f b6 01             	movzbl (%ecx),%eax
f01022da:	84 c0                	test   %al,%al
f01022dc:	74 04                	je     f01022e2 <strcmp+0x1c>
f01022de:	3a 02                	cmp    (%edx),%al
f01022e0:	74 ef                	je     f01022d1 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01022e2:	0f b6 c0             	movzbl %al,%eax
f01022e5:	0f b6 12             	movzbl (%edx),%edx
f01022e8:	29 d0                	sub    %edx,%eax
}
f01022ea:	5d                   	pop    %ebp
f01022eb:	c3                   	ret    

f01022ec <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01022ec:	55                   	push   %ebp
f01022ed:	89 e5                	mov    %esp,%ebp
f01022ef:	53                   	push   %ebx
f01022f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01022f3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01022f6:	89 c3                	mov    %eax,%ebx
f01022f8:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01022fb:	eb 06                	jmp    f0102303 <strncmp+0x17>
		n--, p++, q++;
f01022fd:	83 c0 01             	add    $0x1,%eax
f0102300:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0102303:	39 d8                	cmp    %ebx,%eax
f0102305:	74 16                	je     f010231d <strncmp+0x31>
f0102307:	0f b6 08             	movzbl (%eax),%ecx
f010230a:	84 c9                	test   %cl,%cl
f010230c:	74 04                	je     f0102312 <strncmp+0x26>
f010230e:	3a 0a                	cmp    (%edx),%cl
f0102310:	74 eb                	je     f01022fd <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0102312:	0f b6 00             	movzbl (%eax),%eax
f0102315:	0f b6 12             	movzbl (%edx),%edx
f0102318:	29 d0                	sub    %edx,%eax
}
f010231a:	5b                   	pop    %ebx
f010231b:	5d                   	pop    %ebp
f010231c:	c3                   	ret    
		return 0;
f010231d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102322:	eb f6                	jmp    f010231a <strncmp+0x2e>

f0102324 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0102324:	55                   	push   %ebp
f0102325:	89 e5                	mov    %esp,%ebp
f0102327:	8b 45 08             	mov    0x8(%ebp),%eax
f010232a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010232e:	0f b6 10             	movzbl (%eax),%edx
f0102331:	84 d2                	test   %dl,%dl
f0102333:	74 09                	je     f010233e <strchr+0x1a>
		if (*s == c)
f0102335:	38 ca                	cmp    %cl,%dl
f0102337:	74 0a                	je     f0102343 <strchr+0x1f>
	for (; *s; s++)
f0102339:	83 c0 01             	add    $0x1,%eax
f010233c:	eb f0                	jmp    f010232e <strchr+0xa>
			return (char *) s;
	return 0;
f010233e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102343:	5d                   	pop    %ebp
f0102344:	c3                   	ret    

f0102345 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0102345:	55                   	push   %ebp
f0102346:	89 e5                	mov    %esp,%ebp
f0102348:	8b 45 08             	mov    0x8(%ebp),%eax
f010234b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010234f:	eb 03                	jmp    f0102354 <strfind+0xf>
f0102351:	83 c0 01             	add    $0x1,%eax
f0102354:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0102357:	38 ca                	cmp    %cl,%dl
f0102359:	74 04                	je     f010235f <strfind+0x1a>
f010235b:	84 d2                	test   %dl,%dl
f010235d:	75 f2                	jne    f0102351 <strfind+0xc>
			break;
	return (char *) s;
}
f010235f:	5d                   	pop    %ebp
f0102360:	c3                   	ret    

f0102361 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0102361:	55                   	push   %ebp
f0102362:	89 e5                	mov    %esp,%ebp
f0102364:	57                   	push   %edi
f0102365:	56                   	push   %esi
f0102366:	53                   	push   %ebx
f0102367:	8b 7d 08             	mov    0x8(%ebp),%edi
f010236a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010236d:	85 c9                	test   %ecx,%ecx
f010236f:	74 13                	je     f0102384 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0102371:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0102377:	75 05                	jne    f010237e <memset+0x1d>
f0102379:	f6 c1 03             	test   $0x3,%cl
f010237c:	74 0d                	je     f010238b <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010237e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102381:	fc                   	cld    
f0102382:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0102384:	89 f8                	mov    %edi,%eax
f0102386:	5b                   	pop    %ebx
f0102387:	5e                   	pop    %esi
f0102388:	5f                   	pop    %edi
f0102389:	5d                   	pop    %ebp
f010238a:	c3                   	ret    
		c &= 0xFF;
f010238b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010238f:	89 d3                	mov    %edx,%ebx
f0102391:	c1 e3 08             	shl    $0x8,%ebx
f0102394:	89 d0                	mov    %edx,%eax
f0102396:	c1 e0 18             	shl    $0x18,%eax
f0102399:	89 d6                	mov    %edx,%esi
f010239b:	c1 e6 10             	shl    $0x10,%esi
f010239e:	09 f0                	or     %esi,%eax
f01023a0:	09 c2                	or     %eax,%edx
f01023a2:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f01023a4:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01023a7:	89 d0                	mov    %edx,%eax
f01023a9:	fc                   	cld    
f01023aa:	f3 ab                	rep stos %eax,%es:(%edi)
f01023ac:	eb d6                	jmp    f0102384 <memset+0x23>

f01023ae <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01023ae:	55                   	push   %ebp
f01023af:	89 e5                	mov    %esp,%ebp
f01023b1:	57                   	push   %edi
f01023b2:	56                   	push   %esi
f01023b3:	8b 45 08             	mov    0x8(%ebp),%eax
f01023b6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01023b9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01023bc:	39 c6                	cmp    %eax,%esi
f01023be:	73 35                	jae    f01023f5 <memmove+0x47>
f01023c0:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01023c3:	39 c2                	cmp    %eax,%edx
f01023c5:	76 2e                	jbe    f01023f5 <memmove+0x47>
		s += n;
		d += n;
f01023c7:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01023ca:	89 d6                	mov    %edx,%esi
f01023cc:	09 fe                	or     %edi,%esi
f01023ce:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01023d4:	74 0c                	je     f01023e2 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01023d6:	83 ef 01             	sub    $0x1,%edi
f01023d9:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01023dc:	fd                   	std    
f01023dd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01023df:	fc                   	cld    
f01023e0:	eb 21                	jmp    f0102403 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01023e2:	f6 c1 03             	test   $0x3,%cl
f01023e5:	75 ef                	jne    f01023d6 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01023e7:	83 ef 04             	sub    $0x4,%edi
f01023ea:	8d 72 fc             	lea    -0x4(%edx),%esi
f01023ed:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01023f0:	fd                   	std    
f01023f1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01023f3:	eb ea                	jmp    f01023df <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01023f5:	89 f2                	mov    %esi,%edx
f01023f7:	09 c2                	or     %eax,%edx
f01023f9:	f6 c2 03             	test   $0x3,%dl
f01023fc:	74 09                	je     f0102407 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01023fe:	89 c7                	mov    %eax,%edi
f0102400:	fc                   	cld    
f0102401:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0102403:	5e                   	pop    %esi
f0102404:	5f                   	pop    %edi
f0102405:	5d                   	pop    %ebp
f0102406:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102407:	f6 c1 03             	test   $0x3,%cl
f010240a:	75 f2                	jne    f01023fe <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010240c:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f010240f:	89 c7                	mov    %eax,%edi
f0102411:	fc                   	cld    
f0102412:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102414:	eb ed                	jmp    f0102403 <memmove+0x55>

f0102416 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0102416:	55                   	push   %ebp
f0102417:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0102419:	ff 75 10             	pushl  0x10(%ebp)
f010241c:	ff 75 0c             	pushl  0xc(%ebp)
f010241f:	ff 75 08             	pushl  0x8(%ebp)
f0102422:	e8 87 ff ff ff       	call   f01023ae <memmove>
}
f0102427:	c9                   	leave  
f0102428:	c3                   	ret    

f0102429 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0102429:	55                   	push   %ebp
f010242a:	89 e5                	mov    %esp,%ebp
f010242c:	56                   	push   %esi
f010242d:	53                   	push   %ebx
f010242e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102431:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102434:	89 c6                	mov    %eax,%esi
f0102436:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102439:	39 f0                	cmp    %esi,%eax
f010243b:	74 1c                	je     f0102459 <memcmp+0x30>
		if (*s1 != *s2)
f010243d:	0f b6 08             	movzbl (%eax),%ecx
f0102440:	0f b6 1a             	movzbl (%edx),%ebx
f0102443:	38 d9                	cmp    %bl,%cl
f0102445:	75 08                	jne    f010244f <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0102447:	83 c0 01             	add    $0x1,%eax
f010244a:	83 c2 01             	add    $0x1,%edx
f010244d:	eb ea                	jmp    f0102439 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f010244f:	0f b6 c1             	movzbl %cl,%eax
f0102452:	0f b6 db             	movzbl %bl,%ebx
f0102455:	29 d8                	sub    %ebx,%eax
f0102457:	eb 05                	jmp    f010245e <memcmp+0x35>
	}

	return 0;
f0102459:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010245e:	5b                   	pop    %ebx
f010245f:	5e                   	pop    %esi
f0102460:	5d                   	pop    %ebp
f0102461:	c3                   	ret    

f0102462 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0102462:	55                   	push   %ebp
f0102463:	89 e5                	mov    %esp,%ebp
f0102465:	8b 45 08             	mov    0x8(%ebp),%eax
f0102468:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010246b:	89 c2                	mov    %eax,%edx
f010246d:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0102470:	39 d0                	cmp    %edx,%eax
f0102472:	73 09                	jae    f010247d <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0102474:	38 08                	cmp    %cl,(%eax)
f0102476:	74 05                	je     f010247d <memfind+0x1b>
	for (; s < ends; s++)
f0102478:	83 c0 01             	add    $0x1,%eax
f010247b:	eb f3                	jmp    f0102470 <memfind+0xe>
			break;
	return (void *) s;
}
f010247d:	5d                   	pop    %ebp
f010247e:	c3                   	ret    

f010247f <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010247f:	55                   	push   %ebp
f0102480:	89 e5                	mov    %esp,%ebp
f0102482:	57                   	push   %edi
f0102483:	56                   	push   %esi
f0102484:	53                   	push   %ebx
f0102485:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102488:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010248b:	eb 03                	jmp    f0102490 <strtol+0x11>
		s++;
f010248d:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0102490:	0f b6 01             	movzbl (%ecx),%eax
f0102493:	3c 20                	cmp    $0x20,%al
f0102495:	74 f6                	je     f010248d <strtol+0xe>
f0102497:	3c 09                	cmp    $0x9,%al
f0102499:	74 f2                	je     f010248d <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f010249b:	3c 2b                	cmp    $0x2b,%al
f010249d:	74 2e                	je     f01024cd <strtol+0x4e>
	int neg = 0;
f010249f:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01024a4:	3c 2d                	cmp    $0x2d,%al
f01024a6:	74 2f                	je     f01024d7 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01024a8:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01024ae:	75 05                	jne    f01024b5 <strtol+0x36>
f01024b0:	80 39 30             	cmpb   $0x30,(%ecx)
f01024b3:	74 2c                	je     f01024e1 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01024b5:	85 db                	test   %ebx,%ebx
f01024b7:	75 0a                	jne    f01024c3 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01024b9:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f01024be:	80 39 30             	cmpb   $0x30,(%ecx)
f01024c1:	74 28                	je     f01024eb <strtol+0x6c>
		base = 10;
f01024c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01024c8:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01024cb:	eb 50                	jmp    f010251d <strtol+0x9e>
		s++;
f01024cd:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f01024d0:	bf 00 00 00 00       	mov    $0x0,%edi
f01024d5:	eb d1                	jmp    f01024a8 <strtol+0x29>
		s++, neg = 1;
f01024d7:	83 c1 01             	add    $0x1,%ecx
f01024da:	bf 01 00 00 00       	mov    $0x1,%edi
f01024df:	eb c7                	jmp    f01024a8 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01024e1:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01024e5:	74 0e                	je     f01024f5 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01024e7:	85 db                	test   %ebx,%ebx
f01024e9:	75 d8                	jne    f01024c3 <strtol+0x44>
		s++, base = 8;
f01024eb:	83 c1 01             	add    $0x1,%ecx
f01024ee:	bb 08 00 00 00       	mov    $0x8,%ebx
f01024f3:	eb ce                	jmp    f01024c3 <strtol+0x44>
		s += 2, base = 16;
f01024f5:	83 c1 02             	add    $0x2,%ecx
f01024f8:	bb 10 00 00 00       	mov    $0x10,%ebx
f01024fd:	eb c4                	jmp    f01024c3 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01024ff:	8d 72 9f             	lea    -0x61(%edx),%esi
f0102502:	89 f3                	mov    %esi,%ebx
f0102504:	80 fb 19             	cmp    $0x19,%bl
f0102507:	77 29                	ja     f0102532 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0102509:	0f be d2             	movsbl %dl,%edx
f010250c:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010250f:	3b 55 10             	cmp    0x10(%ebp),%edx
f0102512:	7d 30                	jge    f0102544 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0102514:	83 c1 01             	add    $0x1,%ecx
f0102517:	0f af 45 10          	imul   0x10(%ebp),%eax
f010251b:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f010251d:	0f b6 11             	movzbl (%ecx),%edx
f0102520:	8d 72 d0             	lea    -0x30(%edx),%esi
f0102523:	89 f3                	mov    %esi,%ebx
f0102525:	80 fb 09             	cmp    $0x9,%bl
f0102528:	77 d5                	ja     f01024ff <strtol+0x80>
			dig = *s - '0';
f010252a:	0f be d2             	movsbl %dl,%edx
f010252d:	83 ea 30             	sub    $0x30,%edx
f0102530:	eb dd                	jmp    f010250f <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0102532:	8d 72 bf             	lea    -0x41(%edx),%esi
f0102535:	89 f3                	mov    %esi,%ebx
f0102537:	80 fb 19             	cmp    $0x19,%bl
f010253a:	77 08                	ja     f0102544 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010253c:	0f be d2             	movsbl %dl,%edx
f010253f:	83 ea 37             	sub    $0x37,%edx
f0102542:	eb cb                	jmp    f010250f <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0102544:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0102548:	74 05                	je     f010254f <strtol+0xd0>
		*endptr = (char *) s;
f010254a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010254d:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f010254f:	89 c2                	mov    %eax,%edx
f0102551:	f7 da                	neg    %edx
f0102553:	85 ff                	test   %edi,%edi
f0102555:	0f 45 c2             	cmovne %edx,%eax
}
f0102558:	5b                   	pop    %ebx
f0102559:	5e                   	pop    %esi
f010255a:	5f                   	pop    %edi
f010255b:	5d                   	pop    %ebp
f010255c:	c3                   	ret    
f010255d:	66 90                	xchg   %ax,%ax
f010255f:	90                   	nop

f0102560 <__udivdi3>:
f0102560:	55                   	push   %ebp
f0102561:	57                   	push   %edi
f0102562:	56                   	push   %esi
f0102563:	53                   	push   %ebx
f0102564:	83 ec 1c             	sub    $0x1c,%esp
f0102567:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010256b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010256f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0102573:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0102577:	85 d2                	test   %edx,%edx
f0102579:	75 35                	jne    f01025b0 <__udivdi3+0x50>
f010257b:	39 f3                	cmp    %esi,%ebx
f010257d:	0f 87 bd 00 00 00    	ja     f0102640 <__udivdi3+0xe0>
f0102583:	85 db                	test   %ebx,%ebx
f0102585:	89 d9                	mov    %ebx,%ecx
f0102587:	75 0b                	jne    f0102594 <__udivdi3+0x34>
f0102589:	b8 01 00 00 00       	mov    $0x1,%eax
f010258e:	31 d2                	xor    %edx,%edx
f0102590:	f7 f3                	div    %ebx
f0102592:	89 c1                	mov    %eax,%ecx
f0102594:	31 d2                	xor    %edx,%edx
f0102596:	89 f0                	mov    %esi,%eax
f0102598:	f7 f1                	div    %ecx
f010259a:	89 c6                	mov    %eax,%esi
f010259c:	89 e8                	mov    %ebp,%eax
f010259e:	89 f7                	mov    %esi,%edi
f01025a0:	f7 f1                	div    %ecx
f01025a2:	89 fa                	mov    %edi,%edx
f01025a4:	83 c4 1c             	add    $0x1c,%esp
f01025a7:	5b                   	pop    %ebx
f01025a8:	5e                   	pop    %esi
f01025a9:	5f                   	pop    %edi
f01025aa:	5d                   	pop    %ebp
f01025ab:	c3                   	ret    
f01025ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01025b0:	39 f2                	cmp    %esi,%edx
f01025b2:	77 7c                	ja     f0102630 <__udivdi3+0xd0>
f01025b4:	0f bd fa             	bsr    %edx,%edi
f01025b7:	83 f7 1f             	xor    $0x1f,%edi
f01025ba:	0f 84 98 00 00 00    	je     f0102658 <__udivdi3+0xf8>
f01025c0:	89 f9                	mov    %edi,%ecx
f01025c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01025c7:	29 f8                	sub    %edi,%eax
f01025c9:	d3 e2                	shl    %cl,%edx
f01025cb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01025cf:	89 c1                	mov    %eax,%ecx
f01025d1:	89 da                	mov    %ebx,%edx
f01025d3:	d3 ea                	shr    %cl,%edx
f01025d5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01025d9:	09 d1                	or     %edx,%ecx
f01025db:	89 f2                	mov    %esi,%edx
f01025dd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01025e1:	89 f9                	mov    %edi,%ecx
f01025e3:	d3 e3                	shl    %cl,%ebx
f01025e5:	89 c1                	mov    %eax,%ecx
f01025e7:	d3 ea                	shr    %cl,%edx
f01025e9:	89 f9                	mov    %edi,%ecx
f01025eb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01025ef:	d3 e6                	shl    %cl,%esi
f01025f1:	89 eb                	mov    %ebp,%ebx
f01025f3:	89 c1                	mov    %eax,%ecx
f01025f5:	d3 eb                	shr    %cl,%ebx
f01025f7:	09 de                	or     %ebx,%esi
f01025f9:	89 f0                	mov    %esi,%eax
f01025fb:	f7 74 24 08          	divl   0x8(%esp)
f01025ff:	89 d6                	mov    %edx,%esi
f0102601:	89 c3                	mov    %eax,%ebx
f0102603:	f7 64 24 0c          	mull   0xc(%esp)
f0102607:	39 d6                	cmp    %edx,%esi
f0102609:	72 0c                	jb     f0102617 <__udivdi3+0xb7>
f010260b:	89 f9                	mov    %edi,%ecx
f010260d:	d3 e5                	shl    %cl,%ebp
f010260f:	39 c5                	cmp    %eax,%ebp
f0102611:	73 5d                	jae    f0102670 <__udivdi3+0x110>
f0102613:	39 d6                	cmp    %edx,%esi
f0102615:	75 59                	jne    f0102670 <__udivdi3+0x110>
f0102617:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010261a:	31 ff                	xor    %edi,%edi
f010261c:	89 fa                	mov    %edi,%edx
f010261e:	83 c4 1c             	add    $0x1c,%esp
f0102621:	5b                   	pop    %ebx
f0102622:	5e                   	pop    %esi
f0102623:	5f                   	pop    %edi
f0102624:	5d                   	pop    %ebp
f0102625:	c3                   	ret    
f0102626:	8d 76 00             	lea    0x0(%esi),%esi
f0102629:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0102630:	31 ff                	xor    %edi,%edi
f0102632:	31 c0                	xor    %eax,%eax
f0102634:	89 fa                	mov    %edi,%edx
f0102636:	83 c4 1c             	add    $0x1c,%esp
f0102639:	5b                   	pop    %ebx
f010263a:	5e                   	pop    %esi
f010263b:	5f                   	pop    %edi
f010263c:	5d                   	pop    %ebp
f010263d:	c3                   	ret    
f010263e:	66 90                	xchg   %ax,%ax
f0102640:	31 ff                	xor    %edi,%edi
f0102642:	89 e8                	mov    %ebp,%eax
f0102644:	89 f2                	mov    %esi,%edx
f0102646:	f7 f3                	div    %ebx
f0102648:	89 fa                	mov    %edi,%edx
f010264a:	83 c4 1c             	add    $0x1c,%esp
f010264d:	5b                   	pop    %ebx
f010264e:	5e                   	pop    %esi
f010264f:	5f                   	pop    %edi
f0102650:	5d                   	pop    %ebp
f0102651:	c3                   	ret    
f0102652:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102658:	39 f2                	cmp    %esi,%edx
f010265a:	72 06                	jb     f0102662 <__udivdi3+0x102>
f010265c:	31 c0                	xor    %eax,%eax
f010265e:	39 eb                	cmp    %ebp,%ebx
f0102660:	77 d2                	ja     f0102634 <__udivdi3+0xd4>
f0102662:	b8 01 00 00 00       	mov    $0x1,%eax
f0102667:	eb cb                	jmp    f0102634 <__udivdi3+0xd4>
f0102669:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102670:	89 d8                	mov    %ebx,%eax
f0102672:	31 ff                	xor    %edi,%edi
f0102674:	eb be                	jmp    f0102634 <__udivdi3+0xd4>
f0102676:	66 90                	xchg   %ax,%ax
f0102678:	66 90                	xchg   %ax,%ax
f010267a:	66 90                	xchg   %ax,%ax
f010267c:	66 90                	xchg   %ax,%ax
f010267e:	66 90                	xchg   %ax,%ax

f0102680 <__umoddi3>:
f0102680:	55                   	push   %ebp
f0102681:	57                   	push   %edi
f0102682:	56                   	push   %esi
f0102683:	53                   	push   %ebx
f0102684:	83 ec 1c             	sub    $0x1c,%esp
f0102687:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010268b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010268f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0102693:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102697:	85 ed                	test   %ebp,%ebp
f0102699:	89 f0                	mov    %esi,%eax
f010269b:	89 da                	mov    %ebx,%edx
f010269d:	75 19                	jne    f01026b8 <__umoddi3+0x38>
f010269f:	39 df                	cmp    %ebx,%edi
f01026a1:	0f 86 b1 00 00 00    	jbe    f0102758 <__umoddi3+0xd8>
f01026a7:	f7 f7                	div    %edi
f01026a9:	89 d0                	mov    %edx,%eax
f01026ab:	31 d2                	xor    %edx,%edx
f01026ad:	83 c4 1c             	add    $0x1c,%esp
f01026b0:	5b                   	pop    %ebx
f01026b1:	5e                   	pop    %esi
f01026b2:	5f                   	pop    %edi
f01026b3:	5d                   	pop    %ebp
f01026b4:	c3                   	ret    
f01026b5:	8d 76 00             	lea    0x0(%esi),%esi
f01026b8:	39 dd                	cmp    %ebx,%ebp
f01026ba:	77 f1                	ja     f01026ad <__umoddi3+0x2d>
f01026bc:	0f bd cd             	bsr    %ebp,%ecx
f01026bf:	83 f1 1f             	xor    $0x1f,%ecx
f01026c2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01026c6:	0f 84 b4 00 00 00    	je     f0102780 <__umoddi3+0x100>
f01026cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01026d1:	89 c2                	mov    %eax,%edx
f01026d3:	8b 44 24 04          	mov    0x4(%esp),%eax
f01026d7:	29 c2                	sub    %eax,%edx
f01026d9:	89 c1                	mov    %eax,%ecx
f01026db:	89 f8                	mov    %edi,%eax
f01026dd:	d3 e5                	shl    %cl,%ebp
f01026df:	89 d1                	mov    %edx,%ecx
f01026e1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01026e5:	d3 e8                	shr    %cl,%eax
f01026e7:	09 c5                	or     %eax,%ebp
f01026e9:	8b 44 24 04          	mov    0x4(%esp),%eax
f01026ed:	89 c1                	mov    %eax,%ecx
f01026ef:	d3 e7                	shl    %cl,%edi
f01026f1:	89 d1                	mov    %edx,%ecx
f01026f3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01026f7:	89 df                	mov    %ebx,%edi
f01026f9:	d3 ef                	shr    %cl,%edi
f01026fb:	89 c1                	mov    %eax,%ecx
f01026fd:	89 f0                	mov    %esi,%eax
f01026ff:	d3 e3                	shl    %cl,%ebx
f0102701:	89 d1                	mov    %edx,%ecx
f0102703:	89 fa                	mov    %edi,%edx
f0102705:	d3 e8                	shr    %cl,%eax
f0102707:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010270c:	09 d8                	or     %ebx,%eax
f010270e:	f7 f5                	div    %ebp
f0102710:	d3 e6                	shl    %cl,%esi
f0102712:	89 d1                	mov    %edx,%ecx
f0102714:	f7 64 24 08          	mull   0x8(%esp)
f0102718:	39 d1                	cmp    %edx,%ecx
f010271a:	89 c3                	mov    %eax,%ebx
f010271c:	89 d7                	mov    %edx,%edi
f010271e:	72 06                	jb     f0102726 <__umoddi3+0xa6>
f0102720:	75 0e                	jne    f0102730 <__umoddi3+0xb0>
f0102722:	39 c6                	cmp    %eax,%esi
f0102724:	73 0a                	jae    f0102730 <__umoddi3+0xb0>
f0102726:	2b 44 24 08          	sub    0x8(%esp),%eax
f010272a:	19 ea                	sbb    %ebp,%edx
f010272c:	89 d7                	mov    %edx,%edi
f010272e:	89 c3                	mov    %eax,%ebx
f0102730:	89 ca                	mov    %ecx,%edx
f0102732:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0102737:	29 de                	sub    %ebx,%esi
f0102739:	19 fa                	sbb    %edi,%edx
f010273b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010273f:	89 d0                	mov    %edx,%eax
f0102741:	d3 e0                	shl    %cl,%eax
f0102743:	89 d9                	mov    %ebx,%ecx
f0102745:	d3 ee                	shr    %cl,%esi
f0102747:	d3 ea                	shr    %cl,%edx
f0102749:	09 f0                	or     %esi,%eax
f010274b:	83 c4 1c             	add    $0x1c,%esp
f010274e:	5b                   	pop    %ebx
f010274f:	5e                   	pop    %esi
f0102750:	5f                   	pop    %edi
f0102751:	5d                   	pop    %ebp
f0102752:	c3                   	ret    
f0102753:	90                   	nop
f0102754:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102758:	85 ff                	test   %edi,%edi
f010275a:	89 f9                	mov    %edi,%ecx
f010275c:	75 0b                	jne    f0102769 <__umoddi3+0xe9>
f010275e:	b8 01 00 00 00       	mov    $0x1,%eax
f0102763:	31 d2                	xor    %edx,%edx
f0102765:	f7 f7                	div    %edi
f0102767:	89 c1                	mov    %eax,%ecx
f0102769:	89 d8                	mov    %ebx,%eax
f010276b:	31 d2                	xor    %edx,%edx
f010276d:	f7 f1                	div    %ecx
f010276f:	89 f0                	mov    %esi,%eax
f0102771:	f7 f1                	div    %ecx
f0102773:	e9 31 ff ff ff       	jmp    f01026a9 <__umoddi3+0x29>
f0102778:	90                   	nop
f0102779:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102780:	39 dd                	cmp    %ebx,%ebp
f0102782:	72 08                	jb     f010278c <__umoddi3+0x10c>
f0102784:	39 f7                	cmp    %esi,%edi
f0102786:	0f 87 21 ff ff ff    	ja     f01026ad <__umoddi3+0x2d>
f010278c:	89 da                	mov    %ebx,%edx
f010278e:	89 f0                	mov    %esi,%eax
f0102790:	29 f8                	sub    %edi,%eax
f0102792:	19 ea                	sbb    %ebp,%edx
f0102794:	e9 14 ff ff ff       	jmp    f01026ad <__umoddi3+0x2d>
