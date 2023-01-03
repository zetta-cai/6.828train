
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
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
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
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

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
f010004c:	81 c3 c0 72 01 00    	add    $0x172c0,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 60 90 11 f0    	mov    $0xf0119060,%edx
f0100058:	c7 c0 c0 96 11 f0    	mov    $0xf01196c0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 35 3c 00 00       	call   f0103c9e <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 d4 cd fe ff    	lea    -0x1322c(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 8b 30 00 00       	call   f010310d <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 e2 12 00 00       	call   f0101369 <mem_init>
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
f01000a7:	81 c3 65 72 01 00    	add    $0x17265,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 c4 96 11 f0    	mov    $0xf01196c4,%eax
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
f01000da:	8d 83 ef cd fe ff    	lea    -0x13211(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 27 30 00 00       	call   f010310d <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 e6 2f 00 00       	call   f01030d6 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 fa dc fe ff    	lea    -0x12306(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 0f 30 00 00       	call   f010310d <cprintf>
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
f010010d:	81 c3 ff 71 01 00    	add    $0x171ff,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 07 ce fe ff    	lea    -0x131f9(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 e2 2f 00 00       	call   f010310d <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 9f 2f 00 00       	call   f01030d6 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 fa dc fe ff    	lea    -0x12306(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 c8 2f 00 00       	call   f010310d <cprintf>
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
f010017c:	81 c3 90 71 01 00    	add    $0x17190,%ebx
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
f010018f:	8b 8b 78 1f 00 00    	mov    0x1f78(%ebx),%ecx
f0100195:	8d 51 01             	lea    0x1(%ecx),%edx
f0100198:	89 93 78 1f 00 00    	mov    %edx,0x1f78(%ebx)
f010019e:	88 84 0b 74 1d 00 00 	mov    %al,0x1d74(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001a5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001ab:	75 d7                	jne    f0100184 <cons_intr+0x12>
			cons.wpos = 0;
f01001ad:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
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
f01001c7:	81 c3 45 71 01 00    	add    $0x17145,%ebx
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
f01001fb:	8b 8b 54 1d 00 00    	mov    0x1d54(%ebx),%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x57>
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 8b 54 1d 00 00    	mov    %ecx,0x1d54(%ebx)
	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
f0100217:	0f b6 84 13 54 cf fe 	movzbl -0x130ac(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 54 1d 00 00    	or     0x1d54(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 54 ce fe 	movzbl -0x131ac(%ebx,%edx,1),%ecx
f010022c:	ff 
f010022d:	31 c8                	xor    %ecx,%eax
f010022f:	89 83 54 1d 00 00    	mov    %eax,0x1d54(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100235:	89 c1                	mov    %eax,%ecx
f0100237:	83 e1 03             	and    $0x3,%ecx
f010023a:	8b 8c 8b f4 1c 00 00 	mov    0x1cf4(%ebx,%ecx,4),%ecx
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
f010026a:	8d 83 21 ce fe ff    	lea    -0x131df(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 97 2e 00 00       	call   f010310d <cprintf>
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
f0100286:	83 8b 54 1d 00 00 40 	orl    $0x40,0x1d54(%ebx)
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
f010029b:	8b 8b 54 1d 00 00    	mov    0x1d54(%ebx),%ecx
f01002a1:	89 ce                	mov    %ecx,%esi
f01002a3:	83 e6 40             	and    $0x40,%esi
f01002a6:	83 e0 7f             	and    $0x7f,%eax
f01002a9:	85 f6                	test   %esi,%esi
f01002ab:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002ae:	0f b6 d2             	movzbl %dl,%edx
f01002b1:	0f b6 84 13 54 cf fe 	movzbl -0x130ac(%ebx,%edx,1),%eax
f01002b8:	ff 
f01002b9:	83 c8 40             	or     $0x40,%eax
f01002bc:	0f b6 c0             	movzbl %al,%eax
f01002bf:	f7 d0                	not    %eax
f01002c1:	21 c8                	and    %ecx,%eax
f01002c3:	89 83 54 1d 00 00    	mov    %eax,0x1d54(%ebx)
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
f01002fd:	81 c3 0f 70 01 00    	add    $0x1700f,%ebx
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
f01003bc:	0f b7 83 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%eax
f01003c3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c9:	c1 e8 16             	shr    $0x16,%eax
f01003cc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003cf:	c1 e0 04             	shl    $0x4,%eax
f01003d2:	66 89 83 7c 1f 00 00 	mov    %ax,0x1f7c(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003d9:	66 81 bb 7c 1f 00 00 	cmpw   $0x7cf,0x1f7c(%ebx)
f01003e0:	cf 07 
f01003e2:	0f 87 d4 00 00 00    	ja     f01004bc <cons_putc+0x1cd>
	outb(addr_6845, 14);
f01003e8:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f01003ee:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003f3:	89 ca                	mov    %ecx,%edx
f01003f5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003f6:	0f b7 9b 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%ebx
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
f0100423:	0f b7 83 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%eax
f010042a:	66 85 c0             	test   %ax,%ax
f010042d:	74 b9                	je     f01003e8 <cons_putc+0xf9>
			crt_pos--;
f010042f:	83 e8 01             	sub    $0x1,%eax
f0100432:	66 89 83 7c 1f 00 00 	mov    %ax,0x1f7c(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100440:	b2 00                	mov    $0x0,%dl
f0100442:	83 ca 20             	or     $0x20,%edx
f0100445:	8b 8b 80 1f 00 00    	mov    0x1f80(%ebx),%ecx
f010044b:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010044f:	eb 88                	jmp    f01003d9 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100451:	66 83 83 7c 1f 00 00 	addw   $0x50,0x1f7c(%ebx)
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
f0100495:	0f b7 83 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%eax
f010049c:	8d 50 01             	lea    0x1(%eax),%edx
f010049f:	66 89 93 7c 1f 00 00 	mov    %dx,0x1f7c(%ebx)
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	8b 93 80 1f 00 00    	mov    0x1f80(%ebx),%edx
f01004af:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004b3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b7:	e9 1d ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004bc:	8b 83 80 1f 00 00    	mov    0x1f80(%ebx),%eax
f01004c2:	83 ec 04             	sub    $0x4,%esp
f01004c5:	68 00 0f 00 00       	push   $0xf00
f01004ca:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004d0:	52                   	push   %edx
f01004d1:	50                   	push   %eax
f01004d2:	e8 14 38 00 00       	call   f0103ceb <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004d7:	8b 93 80 1f 00 00    	mov    0x1f80(%ebx),%edx
f01004dd:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004e3:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004e9:	83 c4 10             	add    $0x10,%esp
f01004ec:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004f1:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004f4:	39 d0                	cmp    %edx,%eax
f01004f6:	75 f4                	jne    f01004ec <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f01004f8:	66 83 ab 7c 1f 00 00 	subw   $0x50,0x1f7c(%ebx)
f01004ff:	50 
f0100500:	e9 e3 fe ff ff       	jmp    f01003e8 <cons_putc+0xf9>

f0100505 <serial_intr>:
{
f0100505:	e8 e7 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010050a:	05 02 6e 01 00       	add    $0x16e02,%eax
	if (serial_exists)
f010050f:	80 b8 88 1f 00 00 00 	cmpb   $0x0,0x1f88(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 47 8e fe ff    	lea    -0x171b9(%eax),%eax
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
f0100538:	05 d4 6d 01 00       	add    $0x16dd4,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b1 8e fe ff    	lea    -0x1714f(%eax),%eax
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
f0100556:	81 c3 b6 6d 01 00    	add    $0x16db6,%ebx
	serial_intr();
f010055c:	e8 a4 ff ff ff       	call   f0100505 <serial_intr>
	kbd_intr();
f0100561:	e8 c7 ff ff ff       	call   f010052d <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100566:	8b 93 74 1f 00 00    	mov    0x1f74(%ebx),%edx
	return 0;
f010056c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100571:	3b 93 78 1f 00 00    	cmp    0x1f78(%ebx),%edx
f0100577:	74 19                	je     f0100592 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100579:	8d 4a 01             	lea    0x1(%edx),%ecx
f010057c:	89 8b 74 1f 00 00    	mov    %ecx,0x1f74(%ebx)
f0100582:	0f b6 84 13 74 1d 00 	movzbl 0x1d74(%ebx,%edx,1),%eax
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
f0100598:	c7 83 74 1f 00 00 00 	movl   $0x0,0x1f74(%ebx)
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
f01005b2:	81 c3 5a 6d 01 00    	add    $0x16d5a,%ebx
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
f01005d9:	c7 83 84 1f 00 00 b4 	movl   $0x3b4,0x1f84(%ebx)
f01005e0:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005e3:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f01005ea:	8b bb 84 1f 00 00    	mov    0x1f84(%ebx),%edi
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
f0100612:	89 bb 80 1f 00 00    	mov    %edi,0x1f80(%ebx)
	pos |= inb(addr_6845 + 1);
f0100618:	0f b6 c0             	movzbl %al,%eax
f010061b:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010061d:	66 89 b3 7c 1f 00 00 	mov    %si,0x1f7c(%ebx)
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
f0100675:	0f 95 83 88 1f 00 00 	setne  0x1f88(%ebx)
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
f010069c:	c7 83 84 1f 00 00 d4 	movl   $0x3d4,0x1f84(%ebx)
f01006a3:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a6:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006ad:	e9 38 ff ff ff       	jmp    f01005ea <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006b2:	83 ec 0c             	sub    $0xc,%esp
f01006b5:	8d 83 2d ce fe ff    	lea    -0x131d3(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 4c 2a 00 00       	call   f010310d <cprintf>
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
f01006ff:	81 c3 0d 6c 01 00    	add    $0x16c0d,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100705:	83 ec 04             	sub    $0x4,%esp
f0100708:	8d 83 54 d0 fe ff    	lea    -0x12fac(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 72 d0 fe ff    	lea    -0x12f8e(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 77 d0 fe ff    	lea    -0x12f89(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 eb 29 00 00       	call   f010310d <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 e0 d0 fe ff    	lea    -0x12f20(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 80 d0 fe ff    	lea    -0x12f80(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 d4 29 00 00       	call   f010310d <cprintf>
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
f0100753:	81 c3 b9 6b 01 00    	add    $0x16bb9,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100759:	8d 83 89 d0 fe ff    	lea    -0x12f77(%ebx),%eax
f010075f:	50                   	push   %eax
f0100760:	e8 a8 29 00 00       	call   f010310d <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100765:	83 c4 08             	add    $0x8,%esp
f0100768:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f010076e:	8d 83 08 d1 fe ff    	lea    -0x12ef8(%ebx),%eax
f0100774:	50                   	push   %eax
f0100775:	e8 93 29 00 00       	call   f010310d <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010077a:	83 c4 0c             	add    $0xc,%esp
f010077d:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100783:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100789:	50                   	push   %eax
f010078a:	57                   	push   %edi
f010078b:	8d 83 30 d1 fe ff    	lea    -0x12ed0(%ebx),%eax
f0100791:	50                   	push   %eax
f0100792:	e8 76 29 00 00       	call   f010310d <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100797:	83 c4 0c             	add    $0xc,%esp
f010079a:	c7 c0 d9 40 10 f0    	mov    $0xf01040d9,%eax
f01007a0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007a6:	52                   	push   %edx
f01007a7:	50                   	push   %eax
f01007a8:	8d 83 54 d1 fe ff    	lea    -0x12eac(%ebx),%eax
f01007ae:	50                   	push   %eax
f01007af:	e8 59 29 00 00       	call   f010310d <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007b4:	83 c4 0c             	add    $0xc,%esp
f01007b7:	c7 c0 60 90 11 f0    	mov    $0xf0119060,%eax
f01007bd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007c3:	52                   	push   %edx
f01007c4:	50                   	push   %eax
f01007c5:	8d 83 78 d1 fe ff    	lea    -0x12e88(%ebx),%eax
f01007cb:	50                   	push   %eax
f01007cc:	e8 3c 29 00 00       	call   f010310d <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007d1:	83 c4 0c             	add    $0xc,%esp
f01007d4:	c7 c6 c0 96 11 f0    	mov    $0xf01196c0,%esi
f01007da:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007e0:	50                   	push   %eax
f01007e1:	56                   	push   %esi
f01007e2:	8d 83 9c d1 fe ff    	lea    -0x12e64(%ebx),%eax
f01007e8:	50                   	push   %eax
f01007e9:	e8 1f 29 00 00       	call   f010310d <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007ee:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007f1:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f01007f7:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007f9:	c1 fe 0a             	sar    $0xa,%esi
f01007fc:	56                   	push   %esi
f01007fd:	8d 83 c0 d1 fe ff    	lea    -0x12e40(%ebx),%eax
f0100803:	50                   	push   %eax
f0100804:	e8 04 29 00 00       	call   f010310d <cprintf>
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
f010082e:	81 c3 de 6a 01 00    	add    $0x16ade,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100834:	8d 83 ec d1 fe ff    	lea    -0x12e14(%ebx),%eax
f010083a:	50                   	push   %eax
f010083b:	e8 cd 28 00 00       	call   f010310d <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100840:	8d 83 10 d2 fe ff    	lea    -0x12df0(%ebx),%eax
f0100846:	89 04 24             	mov    %eax,(%esp)
f0100849:	e8 bf 28 00 00       	call   f010310d <cprintf>
f010084e:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100851:	8d bb a6 d0 fe ff    	lea    -0x12f5a(%ebx),%edi
f0100857:	eb 4a                	jmp    f01008a3 <monitor+0x83>
f0100859:	83 ec 08             	sub    $0x8,%esp
f010085c:	0f be c0             	movsbl %al,%eax
f010085f:	50                   	push   %eax
f0100860:	57                   	push   %edi
f0100861:	e8 fb 33 00 00       	call   f0103c61 <strchr>
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
f0100894:	8d 83 ab d0 fe ff    	lea    -0x12f55(%ebx),%eax
f010089a:	50                   	push   %eax
f010089b:	e8 6d 28 00 00       	call   f010310d <cprintf>
f01008a0:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01008a3:	8d 83 a2 d0 fe ff    	lea    -0x12f5e(%ebx),%eax
f01008a9:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01008ac:	83 ec 0c             	sub    $0xc,%esp
f01008af:	ff 75 a4             	pushl  -0x5c(%ebp)
f01008b2:	e8 72 31 00 00       	call   f0103a29 <readline>
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
f01008e2:	e8 7a 33 00 00       	call   f0103c61 <strchr>
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
f010090b:	8d 83 72 d0 fe ff    	lea    -0x12f8e(%ebx),%eax
f0100911:	50                   	push   %eax
f0100912:	ff 75 a8             	pushl  -0x58(%ebp)
f0100915:	e8 e9 32 00 00       	call   f0103c03 <strcmp>
f010091a:	83 c4 10             	add    $0x10,%esp
f010091d:	85 c0                	test   %eax,%eax
f010091f:	74 38                	je     f0100959 <monitor+0x139>
f0100921:	83 ec 08             	sub    $0x8,%esp
f0100924:	8d 83 80 d0 fe ff    	lea    -0x12f80(%ebx),%eax
f010092a:	50                   	push   %eax
f010092b:	ff 75 a8             	pushl  -0x58(%ebp)
f010092e:	e8 d0 32 00 00       	call   f0103c03 <strcmp>
f0100933:	83 c4 10             	add    $0x10,%esp
f0100936:	85 c0                	test   %eax,%eax
f0100938:	74 1a                	je     f0100954 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f010093a:	83 ec 08             	sub    $0x8,%esp
f010093d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100940:	8d 83 c8 d0 fe ff    	lea    -0x12f38(%ebx),%eax
f0100946:	50                   	push   %eax
f0100947:	e8 c1 27 00 00       	call   f010310d <cprintf>
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
f0100969:	ff 94 83 0c 1d 00 00 	call   *0x1d0c(%ebx,%eax,4)
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

f0100983 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100983:	55                   	push   %ebp
f0100984:	89 e5                	mov    %esp,%ebp
f0100986:	57                   	push   %edi
f0100987:	56                   	push   %esi
f0100988:	53                   	push   %ebx
f0100989:	83 ec 18             	sub    $0x18,%esp
f010098c:	e8 be f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100991:	81 c3 7b 69 01 00    	add    $0x1697b,%ebx
f0100997:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100999:	50                   	push   %eax
f010099a:	e8 e7 26 00 00       	call   f0103086 <mc146818_read>
f010099f:	89 c6                	mov    %eax,%esi
f01009a1:	83 c7 01             	add    $0x1,%edi
f01009a4:	89 3c 24             	mov    %edi,(%esp)
f01009a7:	e8 da 26 00 00       	call   f0103086 <mc146818_read>
f01009ac:	c1 e0 08             	shl    $0x8,%eax
f01009af:	09 f0                	or     %esi,%eax
}
f01009b1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009b4:	5b                   	pop    %ebx
f01009b5:	5e                   	pop    %esi
f01009b6:	5f                   	pop    %edi
f01009b7:	5d                   	pop    %ebp
f01009b8:	c3                   	ret    

f01009b9 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009b9:	55                   	push   %ebp
f01009ba:	89 e5                	mov    %esp,%ebp
f01009bc:	53                   	push   %ebx
f01009bd:	83 ec 04             	sub    $0x4,%esp
f01009c0:	e8 8a f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01009c5:	81 c3 47 69 01 00    	add    $0x16947,%ebx
f01009cb:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree)
f01009cd:	83 bb 8c 1f 00 00 00 	cmpl   $0x0,0x1f8c(%ebx)
f01009d4:	74 2b                	je     f0100a01 <boot_alloc+0x48>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n == 0)
f01009d6:	85 d2                	test   %edx,%edx
f01009d8:	74 3f                	je     f0100a19 <boot_alloc+0x60>
	{
		return nextfree;
	}

	// note before update
	result = nextfree;
f01009da:	8b 83 8c 1f 00 00    	mov    0x1f8c(%ebx),%eax
	nextfree = ROUNDUP(n, PGSIZE) + nextfree;
f01009e0:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f01009e6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009ec:	01 c2                	add    %eax,%edx
f01009ee:	89 93 8c 1f 00 00    	mov    %edx,0x1f8c(%ebx)

	// out of memory panic
	if (nextfree > (char *)0xf0400000)
f01009f4:	81 fa 00 00 40 f0    	cmp    $0xf0400000,%edx
f01009fa:	77 25                	ja     f0100a21 <boot_alloc+0x68>
		nextfree = result; // reset static data
		return NULL;
	}

	return result;
}
f01009fc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01009ff:	c9                   	leave  
f0100a00:	c3                   	ret    
		nextfree = ROUNDUP((char *)end, PGSIZE);
f0100a01:	c7 c0 c0 96 11 f0    	mov    $0xf01196c0,%eax
f0100a07:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100a0c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a11:	89 83 8c 1f 00 00    	mov    %eax,0x1f8c(%ebx)
f0100a17:	eb bd                	jmp    f01009d6 <boot_alloc+0x1d>
		return nextfree;
f0100a19:	8b 83 8c 1f 00 00    	mov    0x1f8c(%ebx),%eax
f0100a1f:	eb db                	jmp    f01009fc <boot_alloc+0x43>
		panic("boot_alloc: out of memory, nothing changed, returning NULL...\n");
f0100a21:	83 ec 04             	sub    $0x4,%esp
f0100a24:	8d 83 38 d2 fe ff    	lea    -0x12dc8(%ebx),%eax
f0100a2a:	50                   	push   %eax
f0100a2b:	6a 74                	push   $0x74
f0100a2d:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0100a33:	50                   	push   %eax
f0100a34:	e8 60 f6 ff ff       	call   f0100099 <_panic>

f0100a39 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a39:	55                   	push   %ebp
f0100a3a:	89 e5                	mov    %esp,%ebp
f0100a3c:	56                   	push   %esi
f0100a3d:	53                   	push   %ebx
f0100a3e:	e8 3b 26 00 00       	call   f010307e <__x86.get_pc_thunk.cx>
f0100a43:	81 c1 c9 68 01 00    	add    $0x168c9,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a49:	89 d3                	mov    %edx,%ebx
f0100a4b:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100a4e:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100a51:	a8 01                	test   $0x1,%al
f0100a53:	74 5a                	je     f0100aaf <check_va2pa+0x76>
		return ~0;
	p = (pte_t *)KADDR(PTE_ADDR(*pgdir));
f0100a55:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a5a:	89 c6                	mov    %eax,%esi
f0100a5c:	c1 ee 0c             	shr    $0xc,%esi
f0100a5f:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f0100a65:	3b 33                	cmp    (%ebx),%esi
f0100a67:	73 2b                	jae    f0100a94 <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100a69:	c1 ea 0c             	shr    $0xc,%edx
f0100a6c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a72:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a79:	89 c2                	mov    %eax,%edx
f0100a7b:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a7e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a83:	85 d2                	test   %edx,%edx
f0100a85:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a8a:	0f 44 c2             	cmove  %edx,%eax
}
f0100a8d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a90:	5b                   	pop    %ebx
f0100a91:	5e                   	pop    %esi
f0100a92:	5d                   	pop    %ebp
f0100a93:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a94:	50                   	push   %eax
f0100a95:	8d 81 78 d2 fe ff    	lea    -0x12d88(%ecx),%eax
f0100a9b:	50                   	push   %eax
f0100a9c:	68 16 03 00 00       	push   $0x316
f0100aa1:	8d 81 a0 da fe ff    	lea    -0x12560(%ecx),%eax
f0100aa7:	50                   	push   %eax
f0100aa8:	89 cb                	mov    %ecx,%ebx
f0100aaa:	e8 ea f5 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100aaf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ab4:	eb d7                	jmp    f0100a8d <check_va2pa+0x54>

f0100ab6 <check_page_free_list>:
{
f0100ab6:	55                   	push   %ebp
f0100ab7:	89 e5                	mov    %esp,%ebp
f0100ab9:	57                   	push   %edi
f0100aba:	56                   	push   %esi
f0100abb:	53                   	push   %ebx
f0100abc:	83 ec 3c             	sub    $0x3c,%esp
f0100abf:	e8 be 25 00 00       	call   f0103082 <__x86.get_pc_thunk.di>
f0100ac4:	81 c7 48 68 01 00    	add    $0x16848,%edi
f0100aca:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100acd:	84 c0                	test   %al,%al
f0100acf:	0f 85 dd 02 00 00    	jne    f0100db2 <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100ad5:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100ad8:	83 b8 90 1f 00 00 00 	cmpl   $0x0,0x1f90(%eax)
f0100adf:	74 0c                	je     f0100aed <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ae1:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100ae8:	e9 2f 03 00 00       	jmp    f0100e1c <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100aed:	83 ec 04             	sub    $0x4,%esp
f0100af0:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100af3:	8d 83 9c d2 fe ff    	lea    -0x12d64(%ebx),%eax
f0100af9:	50                   	push   %eax
f0100afa:	68 51 02 00 00       	push   $0x251
f0100aff:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0100b05:	50                   	push   %eax
f0100b06:	e8 8e f5 ff ff       	call   f0100099 <_panic>
f0100b0b:	50                   	push   %eax
f0100b0c:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100b0f:	8d 83 78 d2 fe ff    	lea    -0x12d88(%ebx),%eax
f0100b15:	50                   	push   %eax
f0100b16:	6a 52                	push   $0x52
f0100b18:	8d 83 ac da fe ff    	lea    -0x12554(%ebx),%eax
f0100b1e:	50                   	push   %eax
f0100b1f:	e8 75 f5 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b24:	8b 36                	mov    (%esi),%esi
f0100b26:	85 f6                	test   %esi,%esi
f0100b28:	74 40                	je     f0100b6a <check_page_free_list+0xb4>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b2a:	89 f0                	mov    %esi,%eax
f0100b2c:	2b 07                	sub    (%edi),%eax
f0100b2e:	c1 f8 03             	sar    $0x3,%eax
f0100b31:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b34:	89 c2                	mov    %eax,%edx
f0100b36:	c1 ea 16             	shr    $0x16,%edx
f0100b39:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100b3c:	73 e6                	jae    f0100b24 <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100b3e:	89 c2                	mov    %eax,%edx
f0100b40:	c1 ea 0c             	shr    $0xc,%edx
f0100b43:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100b46:	3b 11                	cmp    (%ecx),%edx
f0100b48:	73 c1                	jae    f0100b0b <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100b4a:	83 ec 04             	sub    $0x4,%esp
f0100b4d:	68 80 00 00 00       	push   $0x80
f0100b52:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100b57:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b5c:	50                   	push   %eax
f0100b5d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100b60:	e8 39 31 00 00       	call   f0103c9e <memset>
f0100b65:	83 c4 10             	add    $0x10,%esp
f0100b68:	eb ba                	jmp    f0100b24 <check_page_free_list+0x6e>
	first_free_page = (char *)boot_alloc(0);
f0100b6a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b6f:	e8 45 fe ff ff       	call   f01009b9 <boot_alloc>
f0100b74:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b77:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100b7a:	8b 97 90 1f 00 00    	mov    0x1f90(%edi),%edx
		assert(pp >= pages);
f0100b80:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100b86:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100b88:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100b8e:	8b 00                	mov    (%eax),%eax
f0100b90:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100b93:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100b96:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b99:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b9e:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ba1:	e9 08 01 00 00       	jmp    f0100cae <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0100ba6:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ba9:	8d 83 ba da fe ff    	lea    -0x12546(%ebx),%eax
f0100baf:	50                   	push   %eax
f0100bb0:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0100bb6:	50                   	push   %eax
f0100bb7:	68 6e 02 00 00       	push   $0x26e
f0100bbc:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0100bc2:	50                   	push   %eax
f0100bc3:	e8 d1 f4 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100bc8:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bcb:	8d 83 db da fe ff    	lea    -0x12525(%ebx),%eax
f0100bd1:	50                   	push   %eax
f0100bd2:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0100bd8:	50                   	push   %eax
f0100bd9:	68 6f 02 00 00       	push   $0x26f
f0100bde:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0100be4:	50                   	push   %eax
f0100be5:	e8 af f4 ff ff       	call   f0100099 <_panic>
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100bea:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bed:	8d 83 c0 d2 fe ff    	lea    -0x12d40(%ebx),%eax
f0100bf3:	50                   	push   %eax
f0100bf4:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0100bfa:	50                   	push   %eax
f0100bfb:	68 70 02 00 00       	push   $0x270
f0100c00:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0100c06:	50                   	push   %eax
f0100c07:	e8 8d f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100c0c:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c0f:	8d 83 ef da fe ff    	lea    -0x12511(%ebx),%eax
f0100c15:	50                   	push   %eax
f0100c16:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0100c1c:	50                   	push   %eax
f0100c1d:	68 73 02 00 00       	push   $0x273
f0100c22:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0100c28:	50                   	push   %eax
f0100c29:	e8 6b f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c2e:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c31:	8d 83 00 db fe ff    	lea    -0x12500(%ebx),%eax
f0100c37:	50                   	push   %eax
f0100c38:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0100c3e:	50                   	push   %eax
f0100c3f:	68 74 02 00 00       	push   $0x274
f0100c44:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0100c4a:	50                   	push   %eax
f0100c4b:	e8 49 f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c50:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c53:	8d 83 f0 d2 fe ff    	lea    -0x12d10(%ebx),%eax
f0100c59:	50                   	push   %eax
f0100c5a:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0100c60:	50                   	push   %eax
f0100c61:	68 75 02 00 00       	push   $0x275
f0100c66:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0100c6c:	50                   	push   %eax
f0100c6d:	e8 27 f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c72:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c75:	8d 83 19 db fe ff    	lea    -0x124e7(%ebx),%eax
f0100c7b:	50                   	push   %eax
f0100c7c:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0100c82:	50                   	push   %eax
f0100c83:	68 76 02 00 00       	push   $0x276
f0100c88:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0100c8e:	50                   	push   %eax
f0100c8f:	e8 05 f4 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100c94:	89 c6                	mov    %eax,%esi
f0100c96:	c1 ee 0c             	shr    $0xc,%esi
f0100c99:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0100c9c:	76 70                	jbe    f0100d0e <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0100c9e:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *)page2kva(pp) >= first_free_page);
f0100ca3:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100ca6:	77 7f                	ja     f0100d27 <check_page_free_list+0x271>
			++nfree_extmem;
f0100ca8:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100cac:	8b 12                	mov    (%edx),%edx
f0100cae:	85 d2                	test   %edx,%edx
f0100cb0:	0f 84 93 00 00 00    	je     f0100d49 <check_page_free_list+0x293>
		assert(pp >= pages);
f0100cb6:	39 d1                	cmp    %edx,%ecx
f0100cb8:	0f 87 e8 fe ff ff    	ja     f0100ba6 <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0100cbe:	39 d3                	cmp    %edx,%ebx
f0100cc0:	0f 86 02 ff ff ff    	jbe    f0100bc8 <check_page_free_list+0x112>
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100cc6:	89 d0                	mov    %edx,%eax
f0100cc8:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100ccb:	a8 07                	test   $0x7,%al
f0100ccd:	0f 85 17 ff ff ff    	jne    f0100bea <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0100cd3:	c1 f8 03             	sar    $0x3,%eax
f0100cd6:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100cd9:	85 c0                	test   %eax,%eax
f0100cdb:	0f 84 2b ff ff ff    	je     f0100c0c <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ce1:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ce6:	0f 84 42 ff ff ff    	je     f0100c2e <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cec:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cf1:	0f 84 59 ff ff ff    	je     f0100c50 <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cf7:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cfc:	0f 84 70 ff ff ff    	je     f0100c72 <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *)page2kva(pp) >= first_free_page);
f0100d02:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d07:	77 8b                	ja     f0100c94 <check_page_free_list+0x1de>
			++nfree_basemem;
f0100d09:	83 c7 01             	add    $0x1,%edi
f0100d0c:	eb 9e                	jmp    f0100cac <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d0e:	50                   	push   %eax
f0100d0f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d12:	8d 83 78 d2 fe ff    	lea    -0x12d88(%ebx),%eax
f0100d18:	50                   	push   %eax
f0100d19:	6a 52                	push   $0x52
f0100d1b:	8d 83 ac da fe ff    	lea    -0x12554(%ebx),%eax
f0100d21:	50                   	push   %eax
f0100d22:	e8 72 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *)page2kva(pp) >= first_free_page);
f0100d27:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d2a:	8d 83 14 d3 fe ff    	lea    -0x12cec(%ebx),%eax
f0100d30:	50                   	push   %eax
f0100d31:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0100d37:	50                   	push   %eax
f0100d38:	68 77 02 00 00       	push   $0x277
f0100d3d:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0100d43:	50                   	push   %eax
f0100d44:	e8 50 f3 ff ff       	call   f0100099 <_panic>
f0100d49:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f0100d4c:	85 ff                	test   %edi,%edi
f0100d4e:	7e 1e                	jle    f0100d6e <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f0100d50:	85 f6                	test   %esi,%esi
f0100d52:	7e 3c                	jle    f0100d90 <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f0100d54:	83 ec 0c             	sub    $0xc,%esp
f0100d57:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d5a:	8d 83 58 d3 fe ff    	lea    -0x12ca8(%ebx),%eax
f0100d60:	50                   	push   %eax
f0100d61:	e8 a7 23 00 00       	call   f010310d <cprintf>
}
f0100d66:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d69:	5b                   	pop    %ebx
f0100d6a:	5e                   	pop    %esi
f0100d6b:	5f                   	pop    %edi
f0100d6c:	5d                   	pop    %ebp
f0100d6d:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100d6e:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d71:	8d 83 33 db fe ff    	lea    -0x124cd(%ebx),%eax
f0100d77:	50                   	push   %eax
f0100d78:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0100d7e:	50                   	push   %eax
f0100d7f:	68 7f 02 00 00       	push   $0x27f
f0100d84:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0100d8a:	50                   	push   %eax
f0100d8b:	e8 09 f3 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100d90:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d93:	8d 83 45 db fe ff    	lea    -0x124bb(%ebx),%eax
f0100d99:	50                   	push   %eax
f0100d9a:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0100da0:	50                   	push   %eax
f0100da1:	68 80 02 00 00       	push   $0x280
f0100da6:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0100dac:	50                   	push   %eax
f0100dad:	e8 e7 f2 ff ff       	call   f0100099 <_panic>
	if (!page_free_list)
f0100db2:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100db5:	8b 80 90 1f 00 00    	mov    0x1f90(%eax),%eax
f0100dbb:	85 c0                	test   %eax,%eax
f0100dbd:	0f 84 2a fd ff ff    	je     f0100aed <check_page_free_list+0x37>
		struct PageInfo **tp[2] = {&pp1, &pp2};
f0100dc3:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100dc6:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100dc9:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100dcc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100dcf:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100dd2:	c7 c3 d0 96 11 f0    	mov    $0xf01196d0,%ebx
f0100dd8:	89 c2                	mov    %eax,%edx
f0100dda:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ddc:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100de2:	0f 95 c2             	setne  %dl
f0100de5:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100de8:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100dec:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100dee:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link)
f0100df2:	8b 00                	mov    (%eax),%eax
f0100df4:	85 c0                	test   %eax,%eax
f0100df6:	75 e0                	jne    f0100dd8 <check_page_free_list+0x322>
		*tp[1] = 0;
f0100df8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dfb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100e01:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e04:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e07:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100e09:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e0c:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100e0f:	89 87 90 1f 00 00    	mov    %eax,0x1f90(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e15:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100e1c:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100e1f:	8b b0 90 1f 00 00    	mov    0x1f90(%eax),%esi
f0100e25:	c7 c7 d0 96 11 f0    	mov    $0xf01196d0,%edi
	if (PGNUM(pa) >= npages)
f0100e2b:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100e31:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e34:	e9 ed fc ff ff       	jmp    f0100b26 <check_page_free_list+0x70>

f0100e39 <page_init>:
{
f0100e39:	55                   	push   %ebp
f0100e3a:	89 e5                	mov    %esp,%ebp
f0100e3c:	57                   	push   %edi
f0100e3d:	56                   	push   %esi
f0100e3e:	53                   	push   %ebx
f0100e3f:	83 ec 1c             	sub    $0x1c,%esp
f0100e42:	e8 3b 22 00 00       	call   f0103082 <__x86.get_pc_thunk.di>
f0100e47:	81 c7 c5 64 01 00    	add    $0x164c5,%edi
f0100e4d:	89 7d e4             	mov    %edi,-0x1c(%ebp)
	pages[0].pp_ref = 1;
f0100e50:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100e56:	8b 00                	mov    (%eax),%eax
f0100e58:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	for (i = 1; i < npages_basemem; i++)
f0100e5e:	8b 87 94 1f 00 00    	mov    0x1f94(%edi),%eax
f0100e64:	8b b7 90 1f 00 00    	mov    0x1f90(%edi),%esi
f0100e6a:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e6f:	ba 01 00 00 00       	mov    $0x1,%edx
		pages[i].pp_ref = 0;
f0100e74:	c7 c7 d0 96 11 f0    	mov    $0xf01196d0,%edi
	for (i = 1; i < npages_basemem; i++)
f0100e7a:	eb 1f                	jmp    f0100e9b <page_init+0x62>
		pages[i].pp_ref = 0;
f0100e7c:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f0100e83:	89 cb                	mov    %ecx,%ebx
f0100e85:	03 1f                	add    (%edi),%ebx
f0100e87:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f0100e8d:	89 33                	mov    %esi,(%ebx)
	for (i = 1; i < npages_basemem; i++)
f0100e8f:	83 c2 01             	add    $0x1,%edx
		page_free_list = &pages[i];
f0100e92:	89 ce                	mov    %ecx,%esi
f0100e94:	03 37                	add    (%edi),%esi
f0100e96:	b9 01 00 00 00       	mov    $0x1,%ecx
	for (i = 1; i < npages_basemem; i++)
f0100e9b:	39 d0                	cmp    %edx,%eax
f0100e9d:	77 dd                	ja     f0100e7c <page_init+0x43>
f0100e9f:	84 c9                	test   %cl,%cl
f0100ea1:	75 0d                	jne    f0100eb0 <page_init+0x77>
		pages[i].pp_ref = 1;
f0100ea3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ea6:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0100eac:	8b 12                	mov    (%edx),%edx
f0100eae:	eb 15                	jmp    f0100ec5 <page_init+0x8c>
f0100eb0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100eb3:	89 b7 90 1f 00 00    	mov    %esi,0x1f90(%edi)
f0100eb9:	eb e8                	jmp    f0100ea3 <page_init+0x6a>
f0100ebb:	66 c7 44 c2 04 01 00 	movw   $0x1,0x4(%edx,%eax,8)
	for (i = npages_basemem; i < EXTPHYSMEM / PGSIZE; i++)
f0100ec2:	83 c0 01             	add    $0x1,%eax
f0100ec5:	3d ff 00 00 00       	cmp    $0xff,%eax
f0100eca:	76 ef                	jbe    f0100ebb <page_init+0x82>
	physaddr_t first_free_addr = PADDR(boot_alloc(0));
f0100ecc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ed1:	e8 e3 fa ff ff       	call   f01009b9 <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f0100ed6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100edb:	76 1a                	jbe    f0100ef7 <page_init+0xbe>
	return (physaddr_t)kva - KERNBASE;
f0100edd:	05 00 00 00 10       	add    $0x10000000,%eax
	size_t first_free_page = first_free_addr / PGSIZE;
f0100ee2:	c1 e8 0c             	shr    $0xc,%eax
		pages[i].pp_ref = 1;
f0100ee5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ee8:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0100eee:	8b 0a                	mov    (%edx),%ecx
	for (i = EXTPHYSMEM / PGSIZE; i < first_free_page; i++)
f0100ef0:	ba 00 01 00 00       	mov    $0x100,%edx
f0100ef5:	eb 26                	jmp    f0100f1d <page_init+0xe4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ef7:	50                   	push   %eax
f0100ef8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100efb:	8d 83 7c d3 fe ff    	lea    -0x12c84(%ebx),%eax
f0100f01:	50                   	push   %eax
f0100f02:	68 2b 01 00 00       	push   $0x12b
f0100f07:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0100f0d:	50                   	push   %eax
f0100f0e:	e8 86 f1 ff ff       	call   f0100099 <_panic>
		pages[i].pp_ref = 1;
f0100f13:	66 c7 44 d1 04 01 00 	movw   $0x1,0x4(%ecx,%edx,8)
	for (i = EXTPHYSMEM / PGSIZE; i < first_free_page; i++)
f0100f1a:	83 c2 01             	add    $0x1,%edx
f0100f1d:	39 c2                	cmp    %eax,%edx
f0100f1f:	72 f2                	jb     f0100f13 <page_init+0xda>
f0100f21:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100f24:	8b 9e 90 1f 00 00    	mov    0x1f90(%esi),%ebx
f0100f2a:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100f31:	b9 00 00 00 00       	mov    $0x0,%ecx
	for (i = first_free_page; i < npages; i++)
f0100f36:	c7 c7 c8 96 11 f0    	mov    $0xf01196c8,%edi
		pages[i].pp_ref = 0;
f0100f3c:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
f0100f42:	eb 1b                	jmp    f0100f5f <page_init+0x126>
f0100f44:	89 d1                	mov    %edx,%ecx
f0100f46:	03 0e                	add    (%esi),%ecx
f0100f48:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100f4e:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100f50:	89 d3                	mov    %edx,%ebx
f0100f52:	03 1e                	add    (%esi),%ebx
	for (i = first_free_page; i < npages; i++)
f0100f54:	83 c0 01             	add    $0x1,%eax
f0100f57:	83 c2 08             	add    $0x8,%edx
f0100f5a:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100f5f:	39 07                	cmp    %eax,(%edi)
f0100f61:	77 e1                	ja     f0100f44 <page_init+0x10b>
f0100f63:	84 c9                	test   %cl,%cl
f0100f65:	75 08                	jne    f0100f6f <page_init+0x136>
}
f0100f67:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f6a:	5b                   	pop    %ebx
f0100f6b:	5e                   	pop    %esi
f0100f6c:	5f                   	pop    %edi
f0100f6d:	5d                   	pop    %ebp
f0100f6e:	c3                   	ret    
f0100f6f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f72:	89 98 90 1f 00 00    	mov    %ebx,0x1f90(%eax)
f0100f78:	eb ed                	jmp    f0100f67 <page_init+0x12e>

f0100f7a <page_alloc>:
{
f0100f7a:	55                   	push   %ebp
f0100f7b:	89 e5                	mov    %esp,%ebp
f0100f7d:	56                   	push   %esi
f0100f7e:	53                   	push   %ebx
f0100f7f:	e8 cb f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100f84:	81 c3 88 63 01 00    	add    $0x16388,%ebx
	if (!page_free_list)
f0100f8a:	8b b3 90 1f 00 00    	mov    0x1f90(%ebx),%esi
f0100f90:	85 f6                	test   %esi,%esi
f0100f92:	74 14                	je     f0100fa8 <page_alloc+0x2e>
	page_free_list = page_free_list->pp_link; // update free list pointer
f0100f94:	8b 06                	mov    (%esi),%eax
f0100f96:	89 83 90 1f 00 00    	mov    %eax,0x1f90(%ebx)
	pp->pp_link = NULL;						  // set to NULL according to notes
f0100f9c:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if (alloc_flags & ALLOC_ZERO)
f0100fa2:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100fa6:	75 09                	jne    f0100fb1 <page_alloc+0x37>
}
f0100fa8:	89 f0                	mov    %esi,%eax
f0100faa:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100fad:	5b                   	pop    %ebx
f0100fae:	5e                   	pop    %esi
f0100faf:	5d                   	pop    %ebp
f0100fb0:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f0100fb1:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100fb7:	89 f2                	mov    %esi,%edx
f0100fb9:	2b 10                	sub    (%eax),%edx
f0100fbb:	89 d0                	mov    %edx,%eax
f0100fbd:	c1 f8 03             	sar    $0x3,%eax
f0100fc0:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100fc3:	89 c1                	mov    %eax,%ecx
f0100fc5:	c1 e9 0c             	shr    $0xc,%ecx
f0100fc8:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0100fce:	3b 0a                	cmp    (%edx),%ecx
f0100fd0:	73 1a                	jae    f0100fec <page_alloc+0x72>
		memset(va, '\0', PGSIZE);
f0100fd2:	83 ec 04             	sub    $0x4,%esp
f0100fd5:	68 00 10 00 00       	push   $0x1000
f0100fda:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100fdc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fe1:	50                   	push   %eax
f0100fe2:	e8 b7 2c 00 00       	call   f0103c9e <memset>
f0100fe7:	83 c4 10             	add    $0x10,%esp
f0100fea:	eb bc                	jmp    f0100fa8 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fec:	50                   	push   %eax
f0100fed:	8d 83 78 d2 fe ff    	lea    -0x12d88(%ebx),%eax
f0100ff3:	50                   	push   %eax
f0100ff4:	6a 52                	push   $0x52
f0100ff6:	8d 83 ac da fe ff    	lea    -0x12554(%ebx),%eax
f0100ffc:	50                   	push   %eax
f0100ffd:	e8 97 f0 ff ff       	call   f0100099 <_panic>

f0101002 <page_free>:
{
f0101002:	55                   	push   %ebp
f0101003:	89 e5                	mov    %esp,%ebp
f0101005:	53                   	push   %ebx
f0101006:	83 ec 04             	sub    $0x4,%esp
f0101009:	e8 41 f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010100e:	81 c3 fe 62 01 00    	add    $0x162fe,%ebx
f0101014:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_link || pp->pp_ref)
f0101017:	83 38 00             	cmpl   $0x0,(%eax)
f010101a:	75 1a                	jne    f0101036 <page_free+0x34>
f010101c:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101021:	75 13                	jne    f0101036 <page_free+0x34>
	pp->pp_link = page_free_list;
f0101023:	8b 8b 90 1f 00 00    	mov    0x1f90(%ebx),%ecx
f0101029:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f010102b:	89 83 90 1f 00 00    	mov    %eax,0x1f90(%ebx)
}
f0101031:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101034:	c9                   	leave  
f0101035:	c3                   	ret    
		panic("pp->pp_ref is nonzero or pp->pp_link is not NULL\n");
f0101036:	83 ec 04             	sub    $0x4,%esp
f0101039:	8d 83 a0 d3 fe ff    	lea    -0x12c60(%ebx),%eax
f010103f:	50                   	push   %eax
f0101040:	68 6a 01 00 00       	push   $0x16a
f0101045:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010104b:	50                   	push   %eax
f010104c:	e8 48 f0 ff ff       	call   f0100099 <_panic>

f0101051 <page_decref>:
{
f0101051:	55                   	push   %ebp
f0101052:	89 e5                	mov    %esp,%ebp
f0101054:	83 ec 08             	sub    $0x8,%esp
f0101057:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f010105a:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010105e:	83 e8 01             	sub    $0x1,%eax
f0101061:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101065:	66 85 c0             	test   %ax,%ax
f0101068:	74 02                	je     f010106c <page_decref+0x1b>
}
f010106a:	c9                   	leave  
f010106b:	c3                   	ret    
		page_free(pp);
f010106c:	83 ec 0c             	sub    $0xc,%esp
f010106f:	52                   	push   %edx
f0101070:	e8 8d ff ff ff       	call   f0101002 <page_free>
f0101075:	83 c4 10             	add    $0x10,%esp
}
f0101078:	eb f0                	jmp    f010106a <page_decref+0x19>

f010107a <pgdir_walk>:
{
f010107a:	55                   	push   %ebp
f010107b:	89 e5                	mov    %esp,%ebp
f010107d:	57                   	push   %edi
f010107e:	56                   	push   %esi
f010107f:	53                   	push   %ebx
f0101080:	83 ec 1c             	sub    $0x1c,%esp
f0101083:	e8 c7 f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101088:	81 c3 84 62 01 00    	add    $0x16284,%ebx
f010108e:	8b 75 0c             	mov    0xc(%ebp),%esi
	uint32_t ptx = PTX(va); // 页表项索引
f0101091:	89 f0                	mov    %esi,%eax
f0101093:	c1 e8 0c             	shr    $0xc,%eax
f0101096:	25 ff 03 00 00       	and    $0x3ff,%eax
f010109b:	89 c7                	mov    %eax,%edi
	uint32_t pdx = PDX(va); // 页目录项索引
f010109d:	c1 ee 16             	shr    $0x16,%esi
	pde = &pgdir[pdx]; // 获取页目录项
f01010a0:	c1 e6 02             	shl    $0x2,%esi
f01010a3:	03 75 08             	add    0x8(%ebp),%esi
	if (*pde & PTE_P)
f01010a6:	8b 16                	mov    (%esi),%edx
f01010a8:	f6 c2 01             	test   $0x1,%dl
f01010ab:	74 3f                	je     f01010ec <pgdir_walk+0x72>
		pte = (KADDR(PTE_ADDR(*pde)));
f01010ad:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f01010b3:	89 d0                	mov    %edx,%eax
f01010b5:	c1 e8 0c             	shr    $0xc,%eax
f01010b8:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f01010be:	39 01                	cmp    %eax,(%ecx)
f01010c0:	76 11                	jbe    f01010d3 <pgdir_walk+0x59>
	return (void *)(pa + KERNBASE);
f01010c2:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
	return &pte[ptx];
f01010c8:	8d 04 ba             	lea    (%edx,%edi,4),%eax
}
f01010cb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010ce:	5b                   	pop    %ebx
f01010cf:	5e                   	pop    %esi
f01010d0:	5f                   	pop    %edi
f01010d1:	5d                   	pop    %ebp
f01010d2:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010d3:	52                   	push   %edx
f01010d4:	8d 83 78 d2 fe ff    	lea    -0x12d88(%ebx),%eax
f01010da:	50                   	push   %eax
f01010db:	68 a1 01 00 00       	push   $0x1a1
f01010e0:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01010e6:	50                   	push   %eax
f01010e7:	e8 ad ef ff ff       	call   f0100099 <_panic>
		if (!create)
f01010ec:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01010f0:	0f 84 8e 00 00 00    	je     f0101184 <pgdir_walk+0x10a>
		if (!(pp = page_alloc(ALLOC_ZERO)))
f01010f6:	83 ec 0c             	sub    $0xc,%esp
f01010f9:	6a 01                	push   $0x1
f01010fb:	e8 7a fe ff ff       	call   f0100f7a <page_alloc>
f0101100:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101103:	83 c4 10             	add    $0x10,%esp
f0101106:	85 c0                	test   %eax,%eax
f0101108:	0f 84 80 00 00 00    	je     f010118e <pgdir_walk+0x114>
	return (pp - pages) << PGSHIFT;
f010110e:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101114:	89 c1                	mov    %eax,%ecx
f0101116:	2b 0a                	sub    (%edx),%ecx
f0101118:	c1 f9 03             	sar    $0x3,%ecx
f010111b:	c1 e1 0c             	shl    $0xc,%ecx
	if (PGNUM(pa) >= npages)
f010111e:	89 ca                	mov    %ecx,%edx
f0101120:	c1 ea 0c             	shr    $0xc,%edx
f0101123:	89 d0                	mov    %edx,%eax
f0101125:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f010112b:	3b 02                	cmp    (%edx),%eax
f010112d:	73 26                	jae    f0101155 <pgdir_walk+0xdb>
	return (void *)(pa + KERNBASE);
f010112f:	8d 91 00 00 00 f0    	lea    -0x10000000(%ecx),%edx
f0101135:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101138:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		pp->pp_ref++;
f010113b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010113e:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	if ((uint32_t)kva < KERNBASE)
f0101143:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0101149:	76 20                	jbe    f010116b <pgdir_walk+0xf1>
		*pde = PADDR(pte) | (PTE_P | PTE_W | PTE_U); // 设置页目录项
f010114b:	83 c9 07             	or     $0x7,%ecx
f010114e:	89 0e                	mov    %ecx,(%esi)
f0101150:	e9 73 ff ff ff       	jmp    f01010c8 <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101155:	51                   	push   %ecx
f0101156:	8d 83 78 d2 fe ff    	lea    -0x12d88(%ebx),%eax
f010115c:	50                   	push   %eax
f010115d:	6a 52                	push   $0x52
f010115f:	8d 83 ac da fe ff    	lea    -0x12554(%ebx),%eax
f0101165:	50                   	push   %eax
f0101166:	e8 2e ef ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010116b:	52                   	push   %edx
f010116c:	8d 83 7c d3 fe ff    	lea    -0x12c84(%ebx),%eax
f0101172:	50                   	push   %eax
f0101173:	68 b2 01 00 00       	push   $0x1b2
f0101178:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010117e:	50                   	push   %eax
f010117f:	e8 15 ef ff ff       	call   f0100099 <_panic>
			return NULL;
f0101184:	b8 00 00 00 00       	mov    $0x0,%eax
f0101189:	e9 3d ff ff ff       	jmp    f01010cb <pgdir_walk+0x51>
			return NULL;
f010118e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101193:	e9 33 ff ff ff       	jmp    f01010cb <pgdir_walk+0x51>

f0101198 <boot_map_region>:
{
f0101198:	55                   	push   %ebp
f0101199:	89 e5                	mov    %esp,%ebp
f010119b:	57                   	push   %edi
f010119c:	56                   	push   %esi
f010119d:	53                   	push   %ebx
f010119e:	83 ec 1c             	sub    $0x1c,%esp
f01011a1:	e8 dc 1e 00 00       	call   f0103082 <__x86.get_pc_thunk.di>
f01011a6:	81 c7 66 61 01 00    	add    $0x16166,%edi
f01011ac:	89 7d d8             	mov    %edi,-0x28(%ebp)
f01011af:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01011b2:	8b 45 08             	mov    0x8(%ebp),%eax
	size_t pgs = PAGE_ALIGN(size) >> PGSHIFT;// 计算总共有多少页
f01011b5:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f01011bb:	c1 e9 0c             	shr    $0xc,%ecx
f01011be:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for (int i = 0; i < pgs; i++, pa += PGSIZE, va += PGSIZE)// 更新pa和va，进行下一轮循环
f01011c1:	89 c3                	mov    %eax,%ebx
f01011c3:	be 00 00 00 00       	mov    $0x0,%esi
		pte_t *pte = pgdir_walk(pgdir, (void *)va, 1);// 获取va对应的PTE的地址 create if not exists
f01011c8:	89 d7                	mov    %edx,%edi
f01011ca:	29 c7                	sub    %eax,%edi
		*pte = pa | PTE_P | perm;// 修改va对应的PTE的值
f01011cc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011cf:	83 c8 01             	or     $0x1,%eax
f01011d2:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for (int i = 0; i < pgs; i++, pa += PGSIZE, va += PGSIZE)// 更新pa和va，进行下一轮循环
f01011d5:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f01011d8:	74 48                	je     f0101222 <boot_map_region+0x8a>
		pte_t *pte = pgdir_walk(pgdir, (void *)va, 1);// 获取va对应的PTE的地址 create if not exists
f01011da:	83 ec 04             	sub    $0x4,%esp
f01011dd:	6a 01                	push   $0x1
f01011df:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f01011e2:	50                   	push   %eax
f01011e3:	ff 75 e0             	pushl  -0x20(%ebp)
f01011e6:	e8 8f fe ff ff       	call   f010107a <pgdir_walk>
		if (pte == NULL)
f01011eb:	83 c4 10             	add    $0x10,%esp
f01011ee:	85 c0                	test   %eax,%eax
f01011f0:	74 12                	je     f0101204 <boot_map_region+0x6c>
		*pte = pa | PTE_P | perm;// 修改va对应的PTE的值
f01011f2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01011f5:	09 da                	or     %ebx,%edx
f01011f7:	89 10                	mov    %edx,(%eax)
	for (int i = 0; i < pgs; i++, pa += PGSIZE, va += PGSIZE)// 更新pa和va，进行下一轮循环
f01011f9:	83 c6 01             	add    $0x1,%esi
f01011fc:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101202:	eb d1                	jmp    f01011d5 <boot_map_region+0x3d>
			panic("boot_map_region(): out of memory\n");
f0101204:	83 ec 04             	sub    $0x4,%esp
f0101207:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010120a:	8d 83 d4 d3 fe ff    	lea    -0x12c2c(%ebx),%eax
f0101210:	50                   	push   %eax
f0101211:	68 cc 01 00 00       	push   $0x1cc
f0101216:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010121c:	50                   	push   %eax
f010121d:	e8 77 ee ff ff       	call   f0100099 <_panic>
}
f0101222:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101225:	5b                   	pop    %ebx
f0101226:	5e                   	pop    %esi
f0101227:	5f                   	pop    %edi
f0101228:	5d                   	pop    %ebp
f0101229:	c3                   	ret    

f010122a <page_lookup>:
{
f010122a:	55                   	push   %ebp
f010122b:	89 e5                	mov    %esp,%ebp
f010122d:	56                   	push   %esi
f010122e:	53                   	push   %ebx
f010122f:	e8 1b ef ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101234:	81 c3 d8 60 01 00    	add    $0x160d8,%ebx
f010123a:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f010123d:	83 ec 04             	sub    $0x4,%esp
f0101240:	6a 00                	push   $0x0
f0101242:	ff 75 0c             	pushl  0xc(%ebp)
f0101245:	ff 75 08             	pushl  0x8(%ebp)
f0101248:	e8 2d fe ff ff       	call   f010107a <pgdir_walk>
	if (pte == NULL) // no page mapped at va
f010124d:	83 c4 10             	add    $0x10,%esp
f0101250:	85 c0                	test   %eax,%eax
f0101252:	74 44                	je     f0101298 <page_lookup+0x6e>
	if (!(*pte & PTE_P)) // 考虑页表项是否存在
f0101254:	f6 00 01             	testb  $0x1,(%eax)
f0101257:	74 46                	je     f010129f <page_lookup+0x75>
	if (pte_store)
f0101259:	85 f6                	test   %esi,%esi
f010125b:	74 02                	je     f010125f <page_lookup+0x35>
		*pte_store = pte;
f010125d:	89 06                	mov    %eax,(%esi)
f010125f:	8b 00                	mov    (%eax),%eax
f0101261:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101264:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f010126a:	39 02                	cmp    %eax,(%edx)
f010126c:	76 12                	jbe    f0101280 <page_lookup+0x56>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f010126e:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101274:	8b 12                	mov    (%edx),%edx
f0101276:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f0101279:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010127c:	5b                   	pop    %ebx
f010127d:	5e                   	pop    %esi
f010127e:	5d                   	pop    %ebp
f010127f:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0101280:	83 ec 04             	sub    $0x4,%esp
f0101283:	8d 83 f8 d3 fe ff    	lea    -0x12c08(%ebx),%eax
f0101289:	50                   	push   %eax
f010128a:	6a 4b                	push   $0x4b
f010128c:	8d 83 ac da fe ff    	lea    -0x12554(%ebx),%eax
f0101292:	50                   	push   %eax
f0101293:	e8 01 ee ff ff       	call   f0100099 <_panic>
		return NULL;
f0101298:	b8 00 00 00 00       	mov    $0x0,%eax
f010129d:	eb da                	jmp    f0101279 <page_lookup+0x4f>
		return NULL;
f010129f:	b8 00 00 00 00       	mov    $0x0,%eax
f01012a4:	eb d3                	jmp    f0101279 <page_lookup+0x4f>

f01012a6 <page_remove>:
{
f01012a6:	55                   	push   %ebp
f01012a7:	89 e5                	mov    %esp,%ebp
f01012a9:	53                   	push   %ebx
f01012aa:	83 ec 18             	sub    $0x18,%esp
f01012ad:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *pageInfo = page_lookup(pgdir, va, &pte); // PageInfo
f01012b0:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01012b3:	50                   	push   %eax
f01012b4:	53                   	push   %ebx
f01012b5:	ff 75 08             	pushl  0x8(%ebp)
f01012b8:	e8 6d ff ff ff       	call   f010122a <page_lookup>
	if (pageInfo == NULL)
f01012bd:	83 c4 10             	add    $0x10,%esp
f01012c0:	85 c0                	test   %eax,%eax
f01012c2:	75 05                	jne    f01012c9 <page_remove+0x23>
}
f01012c4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012c7:	c9                   	leave  
f01012c8:	c3                   	ret    
	page_decref(pageInfo); // 减少引用，如果为0，free
f01012c9:	83 ec 0c             	sub    $0xc,%esp
f01012cc:	50                   	push   %eax
f01012cd:	e8 7f fd ff ff       	call   f0101051 <page_decref>
	*pte = 0;			   // set pte not present
f01012d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012d5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01012db:	0f 01 3b             	invlpg (%ebx)
f01012de:	83 c4 10             	add    $0x10,%esp
f01012e1:	eb e1                	jmp    f01012c4 <page_remove+0x1e>

f01012e3 <page_insert>:
{
f01012e3:	55                   	push   %ebp
f01012e4:	89 e5                	mov    %esp,%ebp
f01012e6:	57                   	push   %edi
f01012e7:	56                   	push   %esi
f01012e8:	53                   	push   %ebx
f01012e9:	83 ec 10             	sub    $0x10,%esp
f01012ec:	e8 91 1d 00 00       	call   f0103082 <__x86.get_pc_thunk.di>
f01012f1:	81 c7 1b 60 01 00    	add    $0x1601b,%edi
f01012f7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f01012fa:	6a 01                	push   $0x1
f01012fc:	ff 75 10             	pushl  0x10(%ebp)
f01012ff:	53                   	push   %ebx
f0101300:	e8 75 fd ff ff       	call   f010107a <pgdir_walk>
	if (!pte)
f0101305:	83 c4 10             	add    $0x10,%esp
f0101308:	85 c0                	test   %eax,%eax
f010130a:	74 56                	je     f0101362 <page_insert+0x7f>
f010130c:	89 c6                	mov    %eax,%esi
	pp->pp_ref++;
f010130e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101311:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	if ((*pte) & PTE_P) // If this virtual address is already mapped. 先删掉
f0101316:	f6 06 01             	testb  $0x1,(%esi)
f0101319:	75 36                	jne    f0101351 <page_insert+0x6e>
	return (pp - pages) << PGSHIFT;
f010131b:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101321:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101324:	2b 08                	sub    (%eax),%ecx
f0101326:	89 c8                	mov    %ecx,%eax
f0101328:	c1 f8 03             	sar    $0x3,%eax
f010132b:	c1 e0 0c             	shl    $0xc,%eax
	*pte = (page2pa(pp) | perm | PTE_P);
f010132e:	8b 55 14             	mov    0x14(%ebp),%edx
f0101331:	83 ca 01             	or     $0x1,%edx
f0101334:	09 d0                	or     %edx,%eax
f0101336:	89 06                	mov    %eax,(%esi)
	pgdir[PDX(va)] |= perm; // Remember this step!
f0101338:	8b 45 10             	mov    0x10(%ebp),%eax
f010133b:	c1 e8 16             	shr    $0x16,%eax
f010133e:	8b 7d 14             	mov    0x14(%ebp),%edi
f0101341:	09 3c 83             	or     %edi,(%ebx,%eax,4)
	return 0;
f0101344:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101349:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010134c:	5b                   	pop    %ebx
f010134d:	5e                   	pop    %esi
f010134e:	5f                   	pop    %edi
f010134f:	5d                   	pop    %ebp
f0101350:	c3                   	ret    
		page_remove(pgdir, va);
f0101351:	83 ec 08             	sub    $0x8,%esp
f0101354:	ff 75 10             	pushl  0x10(%ebp)
f0101357:	53                   	push   %ebx
f0101358:	e8 49 ff ff ff       	call   f01012a6 <page_remove>
f010135d:	83 c4 10             	add    $0x10,%esp
f0101360:	eb b9                	jmp    f010131b <page_insert+0x38>
		return -E_NO_MEM; // 错误是负数
f0101362:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0101367:	eb e0                	jmp    f0101349 <page_insert+0x66>

f0101369 <mem_init>:
{
f0101369:	55                   	push   %ebp
f010136a:	89 e5                	mov    %esp,%ebp
f010136c:	57                   	push   %edi
f010136d:	56                   	push   %esi
f010136e:	53                   	push   %ebx
f010136f:	83 ec 3c             	sub    $0x3c,%esp
f0101372:	e8 7a f3 ff ff       	call   f01006f1 <__x86.get_pc_thunk.ax>
f0101377:	05 95 5f 01 00       	add    $0x15f95,%eax
f010137c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f010137f:	b8 15 00 00 00       	mov    $0x15,%eax
f0101384:	e8 fa f5 ff ff       	call   f0100983 <nvram_read>
f0101389:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010138b:	b8 17 00 00 00       	mov    $0x17,%eax
f0101390:	e8 ee f5 ff ff       	call   f0100983 <nvram_read>
f0101395:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101397:	b8 34 00 00 00       	mov    $0x34,%eax
f010139c:	e8 e2 f5 ff ff       	call   f0100983 <nvram_read>
f01013a1:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f01013a4:	85 c0                	test   %eax,%eax
f01013a6:	0f 85 cd 00 00 00    	jne    f0101479 <mem_init+0x110>
		totalmem = 1 * 1024 + extmem;
f01013ac:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01013b2:	85 f6                	test   %esi,%esi
f01013b4:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f01013b7:	89 c1                	mov    %eax,%ecx
f01013b9:	c1 e9 02             	shr    $0x2,%ecx
f01013bc:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01013bf:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f01013c5:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f01013c7:	89 da                	mov    %ebx,%edx
f01013c9:	c1 ea 02             	shr    $0x2,%edx
f01013cc:	89 97 94 1f 00 00    	mov    %edx,0x1f94(%edi)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013d2:	89 c2                	mov    %eax,%edx
f01013d4:	29 da                	sub    %ebx,%edx
f01013d6:	52                   	push   %edx
f01013d7:	53                   	push   %ebx
f01013d8:	50                   	push   %eax
f01013d9:	8d 87 18 d4 fe ff    	lea    -0x12be8(%edi),%eax
f01013df:	50                   	push   %eax
f01013e0:	89 fb                	mov    %edi,%ebx
f01013e2:	e8 26 1d 00 00       	call   f010310d <cprintf>
	kern_pgdir = (pde_t *)boot_alloc(PGSIZE);
f01013e7:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013ec:	e8 c8 f5 ff ff       	call   f01009b9 <boot_alloc>
f01013f1:	c7 c6 cc 96 11 f0    	mov    $0xf01196cc,%esi
f01013f7:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f01013f9:	83 c4 0c             	add    $0xc,%esp
f01013fc:	68 00 10 00 00       	push   $0x1000
f0101401:	6a 00                	push   $0x0
f0101403:	50                   	push   %eax
f0101404:	e8 95 28 00 00       	call   f0103c9e <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101409:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f010140b:	83 c4 10             	add    $0x10,%esp
f010140e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101413:	76 6e                	jbe    f0101483 <mem_init+0x11a>
	return (physaddr_t)kva - KERNBASE;
f0101415:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010141b:	83 ca 05             	or     $0x5,%edx
f010141e:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f0101424:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101427:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f010142d:	8b 03                	mov    (%ebx),%eax
f010142f:	c1 e0 03             	shl    $0x3,%eax
f0101432:	e8 82 f5 ff ff       	call   f01009b9 <boot_alloc>
f0101437:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
f010143d:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010143f:	83 ec 04             	sub    $0x4,%esp
f0101442:	8b 13                	mov    (%ebx),%edx
f0101444:	c1 e2 03             	shl    $0x3,%edx
f0101447:	52                   	push   %edx
f0101448:	6a 00                	push   $0x0
f010144a:	50                   	push   %eax
f010144b:	89 fb                	mov    %edi,%ebx
f010144d:	e8 4c 28 00 00       	call   f0103c9e <memset>
	page_init();
f0101452:	e8 e2 f9 ff ff       	call   f0100e39 <page_init>
	check_page_free_list(1);
f0101457:	b8 01 00 00 00       	mov    $0x1,%eax
f010145c:	e8 55 f6 ff ff       	call   f0100ab6 <check_page_free_list>
	if (!pages)
f0101461:	83 c4 10             	add    $0x10,%esp
f0101464:	83 3e 00             	cmpl   $0x0,(%esi)
f0101467:	74 36                	je     f010149f <mem_init+0x136>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101469:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010146c:	8b 80 90 1f 00 00    	mov    0x1f90(%eax),%eax
f0101472:	be 00 00 00 00       	mov    $0x0,%esi
f0101477:	eb 49                	jmp    f01014c2 <mem_init+0x159>
		totalmem = 16 * 1024 + ext16mem;
f0101479:	05 00 40 00 00       	add    $0x4000,%eax
f010147e:	e9 34 ff ff ff       	jmp    f01013b7 <mem_init+0x4e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101483:	50                   	push   %eax
f0101484:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101487:	8d 83 7c d3 fe ff    	lea    -0x12c84(%ebx),%eax
f010148d:	50                   	push   %eax
f010148e:	68 9c 00 00 00       	push   $0x9c
f0101493:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0101499:	50                   	push   %eax
f010149a:	e8 fa eb ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f010149f:	83 ec 04             	sub    $0x4,%esp
f01014a2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01014a5:	8d 83 56 db fe ff    	lea    -0x124aa(%ebx),%eax
f01014ab:	50                   	push   %eax
f01014ac:	68 93 02 00 00       	push   $0x293
f01014b1:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01014b7:	50                   	push   %eax
f01014b8:	e8 dc eb ff ff       	call   f0100099 <_panic>
		++nfree;
f01014bd:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014c0:	8b 00                	mov    (%eax),%eax
f01014c2:	85 c0                	test   %eax,%eax
f01014c4:	75 f7                	jne    f01014bd <mem_init+0x154>
	assert((pp0 = page_alloc(0)));
f01014c6:	83 ec 0c             	sub    $0xc,%esp
f01014c9:	6a 00                	push   $0x0
f01014cb:	e8 aa fa ff ff       	call   f0100f7a <page_alloc>
f01014d0:	89 c3                	mov    %eax,%ebx
f01014d2:	83 c4 10             	add    $0x10,%esp
f01014d5:	85 c0                	test   %eax,%eax
f01014d7:	0f 84 3b 02 00 00    	je     f0101718 <mem_init+0x3af>
	assert((pp1 = page_alloc(0)));
f01014dd:	83 ec 0c             	sub    $0xc,%esp
f01014e0:	6a 00                	push   $0x0
f01014e2:	e8 93 fa ff ff       	call   f0100f7a <page_alloc>
f01014e7:	89 c7                	mov    %eax,%edi
f01014e9:	83 c4 10             	add    $0x10,%esp
f01014ec:	85 c0                	test   %eax,%eax
f01014ee:	0f 84 46 02 00 00    	je     f010173a <mem_init+0x3d1>
	assert((pp2 = page_alloc(0)));
f01014f4:	83 ec 0c             	sub    $0xc,%esp
f01014f7:	6a 00                	push   $0x0
f01014f9:	e8 7c fa ff ff       	call   f0100f7a <page_alloc>
f01014fe:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101501:	83 c4 10             	add    $0x10,%esp
f0101504:	85 c0                	test   %eax,%eax
f0101506:	0f 84 50 02 00 00    	je     f010175c <mem_init+0x3f3>
	assert(pp1 && pp1 != pp0);
f010150c:	39 fb                	cmp    %edi,%ebx
f010150e:	0f 84 6a 02 00 00    	je     f010177e <mem_init+0x415>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101514:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101517:	39 c7                	cmp    %eax,%edi
f0101519:	0f 84 81 02 00 00    	je     f01017a0 <mem_init+0x437>
f010151f:	39 c3                	cmp    %eax,%ebx
f0101521:	0f 84 79 02 00 00    	je     f01017a0 <mem_init+0x437>
	return (pp - pages) << PGSHIFT;
f0101527:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010152a:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101530:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages * PGSIZE);
f0101532:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0101538:	8b 10                	mov    (%eax),%edx
f010153a:	c1 e2 0c             	shl    $0xc,%edx
f010153d:	89 d8                	mov    %ebx,%eax
f010153f:	29 c8                	sub    %ecx,%eax
f0101541:	c1 f8 03             	sar    $0x3,%eax
f0101544:	c1 e0 0c             	shl    $0xc,%eax
f0101547:	39 d0                	cmp    %edx,%eax
f0101549:	0f 83 73 02 00 00    	jae    f01017c2 <mem_init+0x459>
f010154f:	89 f8                	mov    %edi,%eax
f0101551:	29 c8                	sub    %ecx,%eax
f0101553:	c1 f8 03             	sar    $0x3,%eax
f0101556:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages * PGSIZE);
f0101559:	39 c2                	cmp    %eax,%edx
f010155b:	0f 86 83 02 00 00    	jbe    f01017e4 <mem_init+0x47b>
f0101561:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101564:	29 c8                	sub    %ecx,%eax
f0101566:	c1 f8 03             	sar    $0x3,%eax
f0101569:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages * PGSIZE);
f010156c:	39 c2                	cmp    %eax,%edx
f010156e:	0f 86 92 02 00 00    	jbe    f0101806 <mem_init+0x49d>
	fl = page_free_list;
f0101574:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101577:	8b 88 90 1f 00 00    	mov    0x1f90(%eax),%ecx
f010157d:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101580:	c7 80 90 1f 00 00 00 	movl   $0x0,0x1f90(%eax)
f0101587:	00 00 00 
	assert(!page_alloc(0));
f010158a:	83 ec 0c             	sub    $0xc,%esp
f010158d:	6a 00                	push   $0x0
f010158f:	e8 e6 f9 ff ff       	call   f0100f7a <page_alloc>
f0101594:	83 c4 10             	add    $0x10,%esp
f0101597:	85 c0                	test   %eax,%eax
f0101599:	0f 85 89 02 00 00    	jne    f0101828 <mem_init+0x4bf>
	page_free(pp0);
f010159f:	83 ec 0c             	sub    $0xc,%esp
f01015a2:	53                   	push   %ebx
f01015a3:	e8 5a fa ff ff       	call   f0101002 <page_free>
	page_free(pp1);
f01015a8:	89 3c 24             	mov    %edi,(%esp)
f01015ab:	e8 52 fa ff ff       	call   f0101002 <page_free>
	page_free(pp2);
f01015b0:	83 c4 04             	add    $0x4,%esp
f01015b3:	ff 75 d0             	pushl  -0x30(%ebp)
f01015b6:	e8 47 fa ff ff       	call   f0101002 <page_free>
	assert((pp0 = page_alloc(0)));
f01015bb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015c2:	e8 b3 f9 ff ff       	call   f0100f7a <page_alloc>
f01015c7:	89 c7                	mov    %eax,%edi
f01015c9:	83 c4 10             	add    $0x10,%esp
f01015cc:	85 c0                	test   %eax,%eax
f01015ce:	0f 84 76 02 00 00    	je     f010184a <mem_init+0x4e1>
	assert((pp1 = page_alloc(0)));
f01015d4:	83 ec 0c             	sub    $0xc,%esp
f01015d7:	6a 00                	push   $0x0
f01015d9:	e8 9c f9 ff ff       	call   f0100f7a <page_alloc>
f01015de:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01015e1:	83 c4 10             	add    $0x10,%esp
f01015e4:	85 c0                	test   %eax,%eax
f01015e6:	0f 84 80 02 00 00    	je     f010186c <mem_init+0x503>
	assert((pp2 = page_alloc(0)));
f01015ec:	83 ec 0c             	sub    $0xc,%esp
f01015ef:	6a 00                	push   $0x0
f01015f1:	e8 84 f9 ff ff       	call   f0100f7a <page_alloc>
f01015f6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01015f9:	83 c4 10             	add    $0x10,%esp
f01015fc:	85 c0                	test   %eax,%eax
f01015fe:	0f 84 8a 02 00 00    	je     f010188e <mem_init+0x525>
	assert(pp1 && pp1 != pp0);
f0101604:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f0101607:	0f 84 a3 02 00 00    	je     f01018b0 <mem_init+0x547>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010160d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101610:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101613:	0f 84 b9 02 00 00    	je     f01018d2 <mem_init+0x569>
f0101619:	39 c7                	cmp    %eax,%edi
f010161b:	0f 84 b1 02 00 00    	je     f01018d2 <mem_init+0x569>
	assert(!page_alloc(0));
f0101621:	83 ec 0c             	sub    $0xc,%esp
f0101624:	6a 00                	push   $0x0
f0101626:	e8 4f f9 ff ff       	call   f0100f7a <page_alloc>
f010162b:	83 c4 10             	add    $0x10,%esp
f010162e:	85 c0                	test   %eax,%eax
f0101630:	0f 85 be 02 00 00    	jne    f01018f4 <mem_init+0x58b>
f0101636:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101639:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010163f:	89 f9                	mov    %edi,%ecx
f0101641:	2b 08                	sub    (%eax),%ecx
f0101643:	89 c8                	mov    %ecx,%eax
f0101645:	c1 f8 03             	sar    $0x3,%eax
f0101648:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010164b:	89 c1                	mov    %eax,%ecx
f010164d:	c1 e9 0c             	shr    $0xc,%ecx
f0101650:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0101656:	3b 0a                	cmp    (%edx),%ecx
f0101658:	0f 83 b8 02 00 00    	jae    f0101916 <mem_init+0x5ad>
	memset(page2kva(pp0), 1, PGSIZE);
f010165e:	83 ec 04             	sub    $0x4,%esp
f0101661:	68 00 10 00 00       	push   $0x1000
f0101666:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101668:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010166d:	50                   	push   %eax
f010166e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101671:	e8 28 26 00 00       	call   f0103c9e <memset>
	page_free(pp0);
f0101676:	89 3c 24             	mov    %edi,(%esp)
f0101679:	e8 84 f9 ff ff       	call   f0101002 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010167e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101685:	e8 f0 f8 ff ff       	call   f0100f7a <page_alloc>
f010168a:	83 c4 10             	add    $0x10,%esp
f010168d:	85 c0                	test   %eax,%eax
f010168f:	0f 84 97 02 00 00    	je     f010192c <mem_init+0x5c3>
	assert(pp && pp0 == pp);
f0101695:	39 c7                	cmp    %eax,%edi
f0101697:	0f 85 b1 02 00 00    	jne    f010194e <mem_init+0x5e5>
	return (pp - pages) << PGSHIFT;
f010169d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016a0:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01016a6:	89 fa                	mov    %edi,%edx
f01016a8:	2b 10                	sub    (%eax),%edx
f01016aa:	c1 fa 03             	sar    $0x3,%edx
f01016ad:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01016b0:	89 d1                	mov    %edx,%ecx
f01016b2:	c1 e9 0c             	shr    $0xc,%ecx
f01016b5:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f01016bb:	3b 08                	cmp    (%eax),%ecx
f01016bd:	0f 83 ad 02 00 00    	jae    f0101970 <mem_init+0x607>
	return (void *)(pa + KERNBASE);
f01016c3:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f01016c9:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01016cf:	80 38 00             	cmpb   $0x0,(%eax)
f01016d2:	0f 85 ae 02 00 00    	jne    f0101986 <mem_init+0x61d>
f01016d8:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01016db:	39 d0                	cmp    %edx,%eax
f01016dd:	75 f0                	jne    f01016cf <mem_init+0x366>
	page_free_list = fl;
f01016df:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016e2:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01016e5:	89 8b 90 1f 00 00    	mov    %ecx,0x1f90(%ebx)
	page_free(pp0);
f01016eb:	83 ec 0c             	sub    $0xc,%esp
f01016ee:	57                   	push   %edi
f01016ef:	e8 0e f9 ff ff       	call   f0101002 <page_free>
	page_free(pp1);
f01016f4:	83 c4 04             	add    $0x4,%esp
f01016f7:	ff 75 d0             	pushl  -0x30(%ebp)
f01016fa:	e8 03 f9 ff ff       	call   f0101002 <page_free>
	page_free(pp2);
f01016ff:	83 c4 04             	add    $0x4,%esp
f0101702:	ff 75 cc             	pushl  -0x34(%ebp)
f0101705:	e8 f8 f8 ff ff       	call   f0101002 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010170a:	8b 83 90 1f 00 00    	mov    0x1f90(%ebx),%eax
f0101710:	83 c4 10             	add    $0x10,%esp
f0101713:	e9 95 02 00 00       	jmp    f01019ad <mem_init+0x644>
	assert((pp0 = page_alloc(0)));
f0101718:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010171b:	8d 83 71 db fe ff    	lea    -0x1248f(%ebx),%eax
f0101721:	50                   	push   %eax
f0101722:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0101728:	50                   	push   %eax
f0101729:	68 9b 02 00 00       	push   $0x29b
f010172e:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0101734:	50                   	push   %eax
f0101735:	e8 5f e9 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010173a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010173d:	8d 83 87 db fe ff    	lea    -0x12479(%ebx),%eax
f0101743:	50                   	push   %eax
f0101744:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010174a:	50                   	push   %eax
f010174b:	68 9c 02 00 00       	push   $0x29c
f0101750:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0101756:	50                   	push   %eax
f0101757:	e8 3d e9 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010175c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010175f:	8d 83 9d db fe ff    	lea    -0x12463(%ebx),%eax
f0101765:	50                   	push   %eax
f0101766:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010176c:	50                   	push   %eax
f010176d:	68 9d 02 00 00       	push   $0x29d
f0101772:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0101778:	50                   	push   %eax
f0101779:	e8 1b e9 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f010177e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101781:	8d 83 b3 db fe ff    	lea    -0x1244d(%ebx),%eax
f0101787:	50                   	push   %eax
f0101788:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010178e:	50                   	push   %eax
f010178f:	68 a0 02 00 00       	push   $0x2a0
f0101794:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010179a:	50                   	push   %eax
f010179b:	e8 f9 e8 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017a0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017a3:	8d 83 54 d4 fe ff    	lea    -0x12bac(%ebx),%eax
f01017a9:	50                   	push   %eax
f01017aa:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01017b0:	50                   	push   %eax
f01017b1:	68 a1 02 00 00       	push   $0x2a1
f01017b6:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01017bc:	50                   	push   %eax
f01017bd:	e8 d7 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages * PGSIZE);
f01017c2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017c5:	8d 83 74 d4 fe ff    	lea    -0x12b8c(%ebx),%eax
f01017cb:	50                   	push   %eax
f01017cc:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01017d2:	50                   	push   %eax
f01017d3:	68 a2 02 00 00       	push   $0x2a2
f01017d8:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01017de:	50                   	push   %eax
f01017df:	e8 b5 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages * PGSIZE);
f01017e4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017e7:	8d 83 94 d4 fe ff    	lea    -0x12b6c(%ebx),%eax
f01017ed:	50                   	push   %eax
f01017ee:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01017f4:	50                   	push   %eax
f01017f5:	68 a3 02 00 00       	push   $0x2a3
f01017fa:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0101800:	50                   	push   %eax
f0101801:	e8 93 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages * PGSIZE);
f0101806:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101809:	8d 83 b4 d4 fe ff    	lea    -0x12b4c(%ebx),%eax
f010180f:	50                   	push   %eax
f0101810:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0101816:	50                   	push   %eax
f0101817:	68 a4 02 00 00       	push   $0x2a4
f010181c:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0101822:	50                   	push   %eax
f0101823:	e8 71 e8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101828:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010182b:	8d 83 c5 db fe ff    	lea    -0x1243b(%ebx),%eax
f0101831:	50                   	push   %eax
f0101832:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0101838:	50                   	push   %eax
f0101839:	68 ab 02 00 00       	push   $0x2ab
f010183e:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0101844:	50                   	push   %eax
f0101845:	e8 4f e8 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f010184a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010184d:	8d 83 71 db fe ff    	lea    -0x1248f(%ebx),%eax
f0101853:	50                   	push   %eax
f0101854:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010185a:	50                   	push   %eax
f010185b:	68 b2 02 00 00       	push   $0x2b2
f0101860:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0101866:	50                   	push   %eax
f0101867:	e8 2d e8 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010186c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010186f:	8d 83 87 db fe ff    	lea    -0x12479(%ebx),%eax
f0101875:	50                   	push   %eax
f0101876:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010187c:	50                   	push   %eax
f010187d:	68 b3 02 00 00       	push   $0x2b3
f0101882:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0101888:	50                   	push   %eax
f0101889:	e8 0b e8 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010188e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101891:	8d 83 9d db fe ff    	lea    -0x12463(%ebx),%eax
f0101897:	50                   	push   %eax
f0101898:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010189e:	50                   	push   %eax
f010189f:	68 b4 02 00 00       	push   $0x2b4
f01018a4:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01018aa:	50                   	push   %eax
f01018ab:	e8 e9 e7 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01018b0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018b3:	8d 83 b3 db fe ff    	lea    -0x1244d(%ebx),%eax
f01018b9:	50                   	push   %eax
f01018ba:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01018c0:	50                   	push   %eax
f01018c1:	68 b6 02 00 00       	push   $0x2b6
f01018c6:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01018cc:	50                   	push   %eax
f01018cd:	e8 c7 e7 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018d2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018d5:	8d 83 54 d4 fe ff    	lea    -0x12bac(%ebx),%eax
f01018db:	50                   	push   %eax
f01018dc:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01018e2:	50                   	push   %eax
f01018e3:	68 b7 02 00 00       	push   $0x2b7
f01018e8:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01018ee:	50                   	push   %eax
f01018ef:	e8 a5 e7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01018f4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018f7:	8d 83 c5 db fe ff    	lea    -0x1243b(%ebx),%eax
f01018fd:	50                   	push   %eax
f01018fe:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0101904:	50                   	push   %eax
f0101905:	68 b8 02 00 00       	push   $0x2b8
f010190a:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0101910:	50                   	push   %eax
f0101911:	e8 83 e7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101916:	50                   	push   %eax
f0101917:	8d 83 78 d2 fe ff    	lea    -0x12d88(%ebx),%eax
f010191d:	50                   	push   %eax
f010191e:	6a 52                	push   $0x52
f0101920:	8d 83 ac da fe ff    	lea    -0x12554(%ebx),%eax
f0101926:	50                   	push   %eax
f0101927:	e8 6d e7 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010192c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010192f:	8d 83 d4 db fe ff    	lea    -0x1242c(%ebx),%eax
f0101935:	50                   	push   %eax
f0101936:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010193c:	50                   	push   %eax
f010193d:	68 bd 02 00 00       	push   $0x2bd
f0101942:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0101948:	50                   	push   %eax
f0101949:	e8 4b e7 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f010194e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101951:	8d 83 f2 db fe ff    	lea    -0x1240e(%ebx),%eax
f0101957:	50                   	push   %eax
f0101958:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010195e:	50                   	push   %eax
f010195f:	68 be 02 00 00       	push   $0x2be
f0101964:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010196a:	50                   	push   %eax
f010196b:	e8 29 e7 ff ff       	call   f0100099 <_panic>
f0101970:	52                   	push   %edx
f0101971:	8d 83 78 d2 fe ff    	lea    -0x12d88(%ebx),%eax
f0101977:	50                   	push   %eax
f0101978:	6a 52                	push   $0x52
f010197a:	8d 83 ac da fe ff    	lea    -0x12554(%ebx),%eax
f0101980:	50                   	push   %eax
f0101981:	e8 13 e7 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f0101986:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101989:	8d 83 02 dc fe ff    	lea    -0x123fe(%ebx),%eax
f010198f:	50                   	push   %eax
f0101990:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0101996:	50                   	push   %eax
f0101997:	68 c1 02 00 00       	push   $0x2c1
f010199c:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01019a2:	50                   	push   %eax
f01019a3:	e8 f1 e6 ff ff       	call   f0100099 <_panic>
		--nfree;
f01019a8:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01019ab:	8b 00                	mov    (%eax),%eax
f01019ad:	85 c0                	test   %eax,%eax
f01019af:	75 f7                	jne    f01019a8 <mem_init+0x63f>
	assert(nfree == 0);
f01019b1:	85 f6                	test   %esi,%esi
f01019b3:	0f 85 5b 08 00 00    	jne    f0102214 <mem_init+0xeab>
	cprintf("check_page_alloc() succeeded!\n");
f01019b9:	83 ec 0c             	sub    $0xc,%esp
f01019bc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019bf:	8d 83 d4 d4 fe ff    	lea    -0x12b2c(%ebx),%eax
f01019c5:	50                   	push   %eax
f01019c6:	e8 42 17 00 00       	call   f010310d <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01019cb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019d2:	e8 a3 f5 ff ff       	call   f0100f7a <page_alloc>
f01019d7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01019da:	83 c4 10             	add    $0x10,%esp
f01019dd:	85 c0                	test   %eax,%eax
f01019df:	0f 84 51 08 00 00    	je     f0102236 <mem_init+0xecd>
	assert((pp1 = page_alloc(0)));
f01019e5:	83 ec 0c             	sub    $0xc,%esp
f01019e8:	6a 00                	push   $0x0
f01019ea:	e8 8b f5 ff ff       	call   f0100f7a <page_alloc>
f01019ef:	89 c7                	mov    %eax,%edi
f01019f1:	83 c4 10             	add    $0x10,%esp
f01019f4:	85 c0                	test   %eax,%eax
f01019f6:	0f 84 5c 08 00 00    	je     f0102258 <mem_init+0xeef>
	assert((pp2 = page_alloc(0)));
f01019fc:	83 ec 0c             	sub    $0xc,%esp
f01019ff:	6a 00                	push   $0x0
f0101a01:	e8 74 f5 ff ff       	call   f0100f7a <page_alloc>
f0101a06:	89 c6                	mov    %eax,%esi
f0101a08:	83 c4 10             	add    $0x10,%esp
f0101a0b:	85 c0                	test   %eax,%eax
f0101a0d:	0f 84 67 08 00 00    	je     f010227a <mem_init+0xf11>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a13:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0101a16:	0f 84 80 08 00 00    	je     f010229c <mem_init+0xf33>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a1c:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101a1f:	0f 84 99 08 00 00    	je     f01022be <mem_init+0xf55>
f0101a25:	39 c7                	cmp    %eax,%edi
f0101a27:	0f 84 91 08 00 00    	je     f01022be <mem_init+0xf55>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a2d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a30:	8b 88 90 1f 00 00    	mov    0x1f90(%eax),%ecx
f0101a36:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101a39:	c7 80 90 1f 00 00 00 	movl   $0x0,0x1f90(%eax)
f0101a40:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a43:	83 ec 0c             	sub    $0xc,%esp
f0101a46:	6a 00                	push   $0x0
f0101a48:	e8 2d f5 ff ff       	call   f0100f7a <page_alloc>
f0101a4d:	83 c4 10             	add    $0x10,%esp
f0101a50:	85 c0                	test   %eax,%eax
f0101a52:	0f 85 88 08 00 00    	jne    f01022e0 <mem_init+0xf77>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *)0x0, &ptep) == NULL);
f0101a58:	83 ec 04             	sub    $0x4,%esp
f0101a5b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a5e:	50                   	push   %eax
f0101a5f:	6a 00                	push   $0x0
f0101a61:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a64:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a6a:	ff 30                	pushl  (%eax)
f0101a6c:	e8 b9 f7 ff ff       	call   f010122a <page_lookup>
f0101a71:	83 c4 10             	add    $0x10,%esp
f0101a74:	85 c0                	test   %eax,%eax
f0101a76:	0f 85 86 08 00 00    	jne    f0102302 <mem_init+0xf99>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a7c:	6a 02                	push   $0x2
f0101a7e:	6a 00                	push   $0x0
f0101a80:	57                   	push   %edi
f0101a81:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a84:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a8a:	ff 30                	pushl  (%eax)
f0101a8c:	e8 52 f8 ff ff       	call   f01012e3 <page_insert>
f0101a91:	83 c4 10             	add    $0x10,%esp
f0101a94:	85 c0                	test   %eax,%eax
f0101a96:	0f 89 88 08 00 00    	jns    f0102324 <mem_init+0xfbb>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a9c:	83 ec 0c             	sub    $0xc,%esp
f0101a9f:	ff 75 d0             	pushl  -0x30(%ebp)
f0101aa2:	e8 5b f5 ff ff       	call   f0101002 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101aa7:	6a 02                	push   $0x2
f0101aa9:	6a 00                	push   $0x0
f0101aab:	57                   	push   %edi
f0101aac:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101aaf:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ab5:	ff 30                	pushl  (%eax)
f0101ab7:	e8 27 f8 ff ff       	call   f01012e3 <page_insert>
f0101abc:	83 c4 20             	add    $0x20,%esp
f0101abf:	85 c0                	test   %eax,%eax
f0101ac1:	0f 85 7f 08 00 00    	jne    f0102346 <mem_init+0xfdd>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ac7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101aca:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ad0:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101ad2:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101ad8:	8b 08                	mov    (%eax),%ecx
f0101ada:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101add:	8b 13                	mov    (%ebx),%edx
f0101adf:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ae5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101ae8:	29 c8                	sub    %ecx,%eax
f0101aea:	c1 f8 03             	sar    $0x3,%eax
f0101aed:	c1 e0 0c             	shl    $0xc,%eax
f0101af0:	39 c2                	cmp    %eax,%edx
f0101af2:	0f 85 70 08 00 00    	jne    f0102368 <mem_init+0xfff>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101af8:	ba 00 00 00 00       	mov    $0x0,%edx
f0101afd:	89 d8                	mov    %ebx,%eax
f0101aff:	e8 35 ef ff ff       	call   f0100a39 <check_va2pa>
f0101b04:	89 fa                	mov    %edi,%edx
f0101b06:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b09:	c1 fa 03             	sar    $0x3,%edx
f0101b0c:	c1 e2 0c             	shl    $0xc,%edx
f0101b0f:	39 d0                	cmp    %edx,%eax
f0101b11:	0f 85 73 08 00 00    	jne    f010238a <mem_init+0x1021>
	assert(pp1->pp_ref == 1);
f0101b17:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101b1c:	0f 85 8a 08 00 00    	jne    f01023ac <mem_init+0x1043>
	assert(pp0->pp_ref == 1);
f0101b22:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b25:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b2a:	0f 85 9e 08 00 00    	jne    f01023ce <mem_init+0x1065>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101b30:	6a 02                	push   $0x2
f0101b32:	68 00 10 00 00       	push   $0x1000
f0101b37:	56                   	push   %esi
f0101b38:	53                   	push   %ebx
f0101b39:	e8 a5 f7 ff ff       	call   f01012e3 <page_insert>
f0101b3e:	83 c4 10             	add    $0x10,%esp
f0101b41:	85 c0                	test   %eax,%eax
f0101b43:	0f 85 a7 08 00 00    	jne    f01023f0 <mem_init+0x1087>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b49:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b4e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b51:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b57:	8b 00                	mov    (%eax),%eax
f0101b59:	e8 db ee ff ff       	call   f0100a39 <check_va2pa>
f0101b5e:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101b64:	89 f1                	mov    %esi,%ecx
f0101b66:	2b 0a                	sub    (%edx),%ecx
f0101b68:	89 ca                	mov    %ecx,%edx
f0101b6a:	c1 fa 03             	sar    $0x3,%edx
f0101b6d:	c1 e2 0c             	shl    $0xc,%edx
f0101b70:	39 d0                	cmp    %edx,%eax
f0101b72:	0f 85 9a 08 00 00    	jne    f0102412 <mem_init+0x10a9>
	assert(pp2->pp_ref == 1);
f0101b78:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b7d:	0f 85 b1 08 00 00    	jne    f0102434 <mem_init+0x10cb>

	// should be no free memory
	assert(!page_alloc(0));
f0101b83:	83 ec 0c             	sub    $0xc,%esp
f0101b86:	6a 00                	push   $0x0
f0101b88:	e8 ed f3 ff ff       	call   f0100f7a <page_alloc>
f0101b8d:	83 c4 10             	add    $0x10,%esp
f0101b90:	85 c0                	test   %eax,%eax
f0101b92:	0f 85 be 08 00 00    	jne    f0102456 <mem_init+0x10ed>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101b98:	6a 02                	push   $0x2
f0101b9a:	68 00 10 00 00       	push   $0x1000
f0101b9f:	56                   	push   %esi
f0101ba0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ba3:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ba9:	ff 30                	pushl  (%eax)
f0101bab:	e8 33 f7 ff ff       	call   f01012e3 <page_insert>
f0101bb0:	83 c4 10             	add    $0x10,%esp
f0101bb3:	85 c0                	test   %eax,%eax
f0101bb5:	0f 85 bd 08 00 00    	jne    f0102478 <mem_init+0x110f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bbb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bc0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101bc3:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101bc9:	8b 00                	mov    (%eax),%eax
f0101bcb:	e8 69 ee ff ff       	call   f0100a39 <check_va2pa>
f0101bd0:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101bd6:	89 f1                	mov    %esi,%ecx
f0101bd8:	2b 0a                	sub    (%edx),%ecx
f0101bda:	89 ca                	mov    %ecx,%edx
f0101bdc:	c1 fa 03             	sar    $0x3,%edx
f0101bdf:	c1 e2 0c             	shl    $0xc,%edx
f0101be2:	39 d0                	cmp    %edx,%eax
f0101be4:	0f 85 b0 08 00 00    	jne    f010249a <mem_init+0x1131>
	assert(pp2->pp_ref == 1);
f0101bea:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bef:	0f 85 c7 08 00 00    	jne    f01024bc <mem_init+0x1153>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101bf5:	83 ec 0c             	sub    $0xc,%esp
f0101bf8:	6a 00                	push   $0x0
f0101bfa:	e8 7b f3 ff ff       	call   f0100f7a <page_alloc>
f0101bff:	83 c4 10             	add    $0x10,%esp
f0101c02:	85 c0                	test   %eax,%eax
f0101c04:	0f 85 d4 08 00 00    	jne    f01024de <mem_init+0x1175>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c0a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c0d:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c13:	8b 10                	mov    (%eax),%edx
f0101c15:	8b 02                	mov    (%edx),%eax
f0101c17:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101c1c:	89 c3                	mov    %eax,%ebx
f0101c1e:	c1 eb 0c             	shr    $0xc,%ebx
f0101c21:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f0101c27:	3b 19                	cmp    (%ecx),%ebx
f0101c29:	0f 83 d1 08 00 00    	jae    f0102500 <mem_init+0x1197>
	return (void *)(pa + KERNBASE);
f0101c2f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c34:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) == ptep + PTX(PGSIZE));
f0101c37:	83 ec 04             	sub    $0x4,%esp
f0101c3a:	6a 00                	push   $0x0
f0101c3c:	68 00 10 00 00       	push   $0x1000
f0101c41:	52                   	push   %edx
f0101c42:	e8 33 f4 ff ff       	call   f010107a <pgdir_walk>
f0101c47:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c4a:	8d 51 04             	lea    0x4(%ecx),%edx
f0101c4d:	83 c4 10             	add    $0x10,%esp
f0101c50:	39 d0                	cmp    %edx,%eax
f0101c52:	0f 85 c4 08 00 00    	jne    f010251c <mem_init+0x11b3>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W | PTE_U) == 0);
f0101c58:	6a 06                	push   $0x6
f0101c5a:	68 00 10 00 00       	push   $0x1000
f0101c5f:	56                   	push   %esi
f0101c60:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c63:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c69:	ff 30                	pushl  (%eax)
f0101c6b:	e8 73 f6 ff ff       	call   f01012e3 <page_insert>
f0101c70:	83 c4 10             	add    $0x10,%esp
f0101c73:	85 c0                	test   %eax,%eax
f0101c75:	0f 85 c3 08 00 00    	jne    f010253e <mem_init+0x11d5>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c7b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c7e:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c84:	8b 18                	mov    (%eax),%ebx
f0101c86:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c8b:	89 d8                	mov    %ebx,%eax
f0101c8d:	e8 a7 ed ff ff       	call   f0100a39 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101c92:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c95:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101c9b:	89 f1                	mov    %esi,%ecx
f0101c9d:	2b 0a                	sub    (%edx),%ecx
f0101c9f:	89 ca                	mov    %ecx,%edx
f0101ca1:	c1 fa 03             	sar    $0x3,%edx
f0101ca4:	c1 e2 0c             	shl    $0xc,%edx
f0101ca7:	39 d0                	cmp    %edx,%eax
f0101ca9:	0f 85 b1 08 00 00    	jne    f0102560 <mem_init+0x11f7>
	assert(pp2->pp_ref == 1);
f0101caf:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cb4:	0f 85 c8 08 00 00    	jne    f0102582 <mem_init+0x1219>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U);
f0101cba:	83 ec 04             	sub    $0x4,%esp
f0101cbd:	6a 00                	push   $0x0
f0101cbf:	68 00 10 00 00       	push   $0x1000
f0101cc4:	53                   	push   %ebx
f0101cc5:	e8 b0 f3 ff ff       	call   f010107a <pgdir_walk>
f0101cca:	83 c4 10             	add    $0x10,%esp
f0101ccd:	f6 00 04             	testb  $0x4,(%eax)
f0101cd0:	0f 84 ce 08 00 00    	je     f01025a4 <mem_init+0x123b>
	assert(kern_pgdir[0] & PTE_U);
f0101cd6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cd9:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101cdf:	8b 00                	mov    (%eax),%eax
f0101ce1:	f6 00 04             	testb  $0x4,(%eax)
f0101ce4:	0f 84 dc 08 00 00    	je     f01025c6 <mem_init+0x125d>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101cea:	6a 02                	push   $0x2
f0101cec:	68 00 10 00 00       	push   $0x1000
f0101cf1:	56                   	push   %esi
f0101cf2:	50                   	push   %eax
f0101cf3:	e8 eb f5 ff ff       	call   f01012e3 <page_insert>
f0101cf8:	83 c4 10             	add    $0x10,%esp
f0101cfb:	85 c0                	test   %eax,%eax
f0101cfd:	0f 85 e5 08 00 00    	jne    f01025e8 <mem_init+0x127f>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_W);
f0101d03:	83 ec 04             	sub    $0x4,%esp
f0101d06:	6a 00                	push   $0x0
f0101d08:	68 00 10 00 00       	push   $0x1000
f0101d0d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d10:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d16:	ff 30                	pushl  (%eax)
f0101d18:	e8 5d f3 ff ff       	call   f010107a <pgdir_walk>
f0101d1d:	83 c4 10             	add    $0x10,%esp
f0101d20:	f6 00 02             	testb  $0x2,(%eax)
f0101d23:	0f 84 e1 08 00 00    	je     f010260a <mem_init+0x12a1>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0101d29:	83 ec 04             	sub    $0x4,%esp
f0101d2c:	6a 00                	push   $0x0
f0101d2e:	68 00 10 00 00       	push   $0x1000
f0101d33:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d36:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d3c:	ff 30                	pushl  (%eax)
f0101d3e:	e8 37 f3 ff ff       	call   f010107a <pgdir_walk>
f0101d43:	83 c4 10             	add    $0x10,%esp
f0101d46:	f6 00 04             	testb  $0x4,(%eax)
f0101d49:	0f 85 dd 08 00 00    	jne    f010262c <mem_init+0x12c3>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void *)PTSIZE, PTE_W) < 0);
f0101d4f:	6a 02                	push   $0x2
f0101d51:	68 00 00 40 00       	push   $0x400000
f0101d56:	ff 75 d0             	pushl  -0x30(%ebp)
f0101d59:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d5c:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d62:	ff 30                	pushl  (%eax)
f0101d64:	e8 7a f5 ff ff       	call   f01012e3 <page_insert>
f0101d69:	83 c4 10             	add    $0x10,%esp
f0101d6c:	85 c0                	test   %eax,%eax
f0101d6e:	0f 89 da 08 00 00    	jns    f010264e <mem_init+0x12e5>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W) == 0);
f0101d74:	6a 02                	push   $0x2
f0101d76:	68 00 10 00 00       	push   $0x1000
f0101d7b:	57                   	push   %edi
f0101d7c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d7f:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d85:	ff 30                	pushl  (%eax)
f0101d87:	e8 57 f5 ff ff       	call   f01012e3 <page_insert>
f0101d8c:	83 c4 10             	add    $0x10,%esp
f0101d8f:	85 c0                	test   %eax,%eax
f0101d91:	0f 85 d9 08 00 00    	jne    f0102670 <mem_init+0x1307>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0101d97:	83 ec 04             	sub    $0x4,%esp
f0101d9a:	6a 00                	push   $0x0
f0101d9c:	68 00 10 00 00       	push   $0x1000
f0101da1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101da4:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101daa:	ff 30                	pushl  (%eax)
f0101dac:	e8 c9 f2 ff ff       	call   f010107a <pgdir_walk>
f0101db1:	83 c4 10             	add    $0x10,%esp
f0101db4:	f6 00 04             	testb  $0x4,(%eax)
f0101db7:	0f 85 d5 08 00 00    	jne    f0102692 <mem_init+0x1329>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101dbd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dc0:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101dc6:	8b 18                	mov    (%eax),%ebx
f0101dc8:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dcd:	89 d8                	mov    %ebx,%eax
f0101dcf:	e8 65 ec ff ff       	call   f0100a39 <check_va2pa>
f0101dd4:	89 c2                	mov    %eax,%edx
f0101dd6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101dd9:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ddc:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101de2:	89 f9                	mov    %edi,%ecx
f0101de4:	2b 08                	sub    (%eax),%ecx
f0101de6:	89 c8                	mov    %ecx,%eax
f0101de8:	c1 f8 03             	sar    $0x3,%eax
f0101deb:	c1 e0 0c             	shl    $0xc,%eax
f0101dee:	39 c2                	cmp    %eax,%edx
f0101df0:	0f 85 be 08 00 00    	jne    f01026b4 <mem_init+0x134b>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101df6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dfb:	89 d8                	mov    %ebx,%eax
f0101dfd:	e8 37 ec ff ff       	call   f0100a39 <check_va2pa>
f0101e02:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101e05:	0f 85 cb 08 00 00    	jne    f01026d6 <mem_init+0x136d>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e0b:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101e10:	0f 85 e2 08 00 00    	jne    f01026f8 <mem_init+0x138f>
	assert(pp2->pp_ref == 0);
f0101e16:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e1b:	0f 85 f9 08 00 00    	jne    f010271a <mem_init+0x13b1>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e21:	83 ec 0c             	sub    $0xc,%esp
f0101e24:	6a 00                	push   $0x0
f0101e26:	e8 4f f1 ff ff       	call   f0100f7a <page_alloc>
f0101e2b:	83 c4 10             	add    $0x10,%esp
f0101e2e:	39 c6                	cmp    %eax,%esi
f0101e30:	0f 85 06 09 00 00    	jne    f010273c <mem_init+0x13d3>
f0101e36:	85 c0                	test   %eax,%eax
f0101e38:	0f 84 fe 08 00 00    	je     f010273c <mem_init+0x13d3>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e3e:	83 ec 08             	sub    $0x8,%esp
f0101e41:	6a 00                	push   $0x0
f0101e43:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e46:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101e4c:	ff 33                	pushl  (%ebx)
f0101e4e:	e8 53 f4 ff ff       	call   f01012a6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e53:	8b 1b                	mov    (%ebx),%ebx
f0101e55:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e5a:	89 d8                	mov    %ebx,%eax
f0101e5c:	e8 d8 eb ff ff       	call   f0100a39 <check_va2pa>
f0101e61:	83 c4 10             	add    $0x10,%esp
f0101e64:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e67:	0f 85 f1 08 00 00    	jne    f010275e <mem_init+0x13f5>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e6d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e72:	89 d8                	mov    %ebx,%eax
f0101e74:	e8 c0 eb ff ff       	call   f0100a39 <check_va2pa>
f0101e79:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e7c:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101e82:	89 f9                	mov    %edi,%ecx
f0101e84:	2b 0a                	sub    (%edx),%ecx
f0101e86:	89 ca                	mov    %ecx,%edx
f0101e88:	c1 fa 03             	sar    $0x3,%edx
f0101e8b:	c1 e2 0c             	shl    $0xc,%edx
f0101e8e:	39 d0                	cmp    %edx,%eax
f0101e90:	0f 85 ea 08 00 00    	jne    f0102780 <mem_init+0x1417>
	assert(pp1->pp_ref == 1);
f0101e96:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101e9b:	0f 85 01 09 00 00    	jne    f01027a2 <mem_init+0x1439>
	assert(pp2->pp_ref == 0);
f0101ea1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ea6:	0f 85 18 09 00 00    	jne    f01027c4 <mem_init+0x145b>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, 0) == 0);
f0101eac:	6a 00                	push   $0x0
f0101eae:	68 00 10 00 00       	push   $0x1000
f0101eb3:	57                   	push   %edi
f0101eb4:	53                   	push   %ebx
f0101eb5:	e8 29 f4 ff ff       	call   f01012e3 <page_insert>
f0101eba:	83 c4 10             	add    $0x10,%esp
f0101ebd:	85 c0                	test   %eax,%eax
f0101ebf:	0f 85 21 09 00 00    	jne    f01027e6 <mem_init+0x147d>
	assert(pp1->pp_ref);
f0101ec5:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101eca:	0f 84 38 09 00 00    	je     f0102808 <mem_init+0x149f>
	assert(pp1->pp_link == NULL);
f0101ed0:	83 3f 00             	cmpl   $0x0,(%edi)
f0101ed3:	0f 85 51 09 00 00    	jne    f010282a <mem_init+0x14c1>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void *)PGSIZE);
f0101ed9:	83 ec 08             	sub    $0x8,%esp
f0101edc:	68 00 10 00 00       	push   $0x1000
f0101ee1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ee4:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101eea:	ff 33                	pushl  (%ebx)
f0101eec:	e8 b5 f3 ff ff       	call   f01012a6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101ef1:	8b 1b                	mov    (%ebx),%ebx
f0101ef3:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ef8:	89 d8                	mov    %ebx,%eax
f0101efa:	e8 3a eb ff ff       	call   f0100a39 <check_va2pa>
f0101eff:	83 c4 10             	add    $0x10,%esp
f0101f02:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f05:	0f 85 41 09 00 00    	jne    f010284c <mem_init+0x14e3>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f0b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f10:	89 d8                	mov    %ebx,%eax
f0101f12:	e8 22 eb ff ff       	call   f0100a39 <check_va2pa>
f0101f17:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f1a:	0f 85 4e 09 00 00    	jne    f010286e <mem_init+0x1505>
	assert(pp1->pp_ref == 0);
f0101f20:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101f25:	0f 85 65 09 00 00    	jne    f0102890 <mem_init+0x1527>
	assert(pp2->pp_ref == 0);
f0101f2b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f30:	0f 85 7c 09 00 00    	jne    f01028b2 <mem_init+0x1549>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f36:	83 ec 0c             	sub    $0xc,%esp
f0101f39:	6a 00                	push   $0x0
f0101f3b:	e8 3a f0 ff ff       	call   f0100f7a <page_alloc>
f0101f40:	83 c4 10             	add    $0x10,%esp
f0101f43:	85 c0                	test   %eax,%eax
f0101f45:	0f 84 89 09 00 00    	je     f01028d4 <mem_init+0x156b>
f0101f4b:	39 c7                	cmp    %eax,%edi
f0101f4d:	0f 85 81 09 00 00    	jne    f01028d4 <mem_init+0x156b>

	// should be no free memory
	assert(!page_alloc(0));
f0101f53:	83 ec 0c             	sub    $0xc,%esp
f0101f56:	6a 00                	push   $0x0
f0101f58:	e8 1d f0 ff ff       	call   f0100f7a <page_alloc>
f0101f5d:	83 c4 10             	add    $0x10,%esp
f0101f60:	85 c0                	test   %eax,%eax
f0101f62:	0f 85 8e 09 00 00    	jne    f01028f6 <mem_init+0x158d>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f68:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101f6b:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101f71:	8b 08                	mov    (%eax),%ecx
f0101f73:	8b 11                	mov    (%ecx),%edx
f0101f75:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f7b:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101f81:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101f84:	2b 18                	sub    (%eax),%ebx
f0101f86:	89 d8                	mov    %ebx,%eax
f0101f88:	c1 f8 03             	sar    $0x3,%eax
f0101f8b:	c1 e0 0c             	shl    $0xc,%eax
f0101f8e:	39 c2                	cmp    %eax,%edx
f0101f90:	0f 85 82 09 00 00    	jne    f0102918 <mem_init+0x15af>
	kern_pgdir[0] = 0;
f0101f96:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f9c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f9f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101fa4:	0f 85 90 09 00 00    	jne    f010293a <mem_init+0x15d1>
	pp0->pp_ref = 0;
f0101faa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101fad:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101fb3:	83 ec 0c             	sub    $0xc,%esp
f0101fb6:	50                   	push   %eax
f0101fb7:	e8 46 f0 ff ff       	call   f0101002 <page_free>
	va = (void *)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101fbc:	83 c4 0c             	add    $0xc,%esp
f0101fbf:	6a 01                	push   $0x1
f0101fc1:	68 00 10 40 00       	push   $0x401000
f0101fc6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fc9:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101fcf:	ff 33                	pushl  (%ebx)
f0101fd1:	e8 a4 f0 ff ff       	call   f010107a <pgdir_walk>
f0101fd6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fd9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fdc:	8b 1b                	mov    (%ebx),%ebx
f0101fde:	8b 53 04             	mov    0x4(%ebx),%edx
f0101fe1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101fe7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101fea:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f0101ff0:	8b 09                	mov    (%ecx),%ecx
f0101ff2:	89 d0                	mov    %edx,%eax
f0101ff4:	c1 e8 0c             	shr    $0xc,%eax
f0101ff7:	83 c4 10             	add    $0x10,%esp
f0101ffa:	39 c8                	cmp    %ecx,%eax
f0101ffc:	0f 83 5a 09 00 00    	jae    f010295c <mem_init+0x15f3>
	assert(ptep == ptep1 + PTX(va));
f0102002:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102008:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f010200b:	0f 85 67 09 00 00    	jne    f0102978 <mem_init+0x160f>
	kern_pgdir[PDX(va)] = 0;
f0102011:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0102018:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f010201b:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0102021:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102024:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010202a:	2b 18                	sub    (%eax),%ebx
f010202c:	89 d8                	mov    %ebx,%eax
f010202e:	c1 f8 03             	sar    $0x3,%eax
f0102031:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102034:	89 c2                	mov    %eax,%edx
f0102036:	c1 ea 0c             	shr    $0xc,%edx
f0102039:	39 d1                	cmp    %edx,%ecx
f010203b:	0f 86 59 09 00 00    	jbe    f010299a <mem_init+0x1631>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102041:	83 ec 04             	sub    $0x4,%esp
f0102044:	68 00 10 00 00       	push   $0x1000
f0102049:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f010204e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102053:	50                   	push   %eax
f0102054:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102057:	e8 42 1c 00 00       	call   f0103c9e <memset>
	page_free(pp0);
f010205c:	83 c4 04             	add    $0x4,%esp
f010205f:	ff 75 d0             	pushl  -0x30(%ebp)
f0102062:	e8 9b ef ff ff       	call   f0101002 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102067:	83 c4 0c             	add    $0xc,%esp
f010206a:	6a 01                	push   $0x1
f010206c:	6a 00                	push   $0x0
f010206e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102071:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102077:	ff 30                	pushl  (%eax)
f0102079:	e8 fc ef ff ff       	call   f010107a <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f010207e:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102084:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0102087:	2b 10                	sub    (%eax),%edx
f0102089:	c1 fa 03             	sar    $0x3,%edx
f010208c:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010208f:	89 d1                	mov    %edx,%ecx
f0102091:	c1 e9 0c             	shr    $0xc,%ecx
f0102094:	83 c4 10             	add    $0x10,%esp
f0102097:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f010209d:	3b 08                	cmp    (%eax),%ecx
f010209f:	0f 83 0e 09 00 00    	jae    f01029b3 <mem_init+0x164a>
	return (void *)(pa + KERNBASE);
f01020a5:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *)page2kva(pp0);
f01020ab:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020ae:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for (i = 0; i < NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020b4:	f6 00 01             	testb  $0x1,(%eax)
f01020b7:	0f 85 0f 09 00 00    	jne    f01029cc <mem_init+0x1663>
f01020bd:	83 c0 04             	add    $0x4,%eax
	for (i = 0; i < NPTENTRIES; i++)
f01020c0:	39 d0                	cmp    %edx,%eax
f01020c2:	75 f0                	jne    f01020b4 <mem_init+0xd4b>
	kern_pgdir[0] = 0;
f01020c4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01020c7:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f01020cd:	8b 00                	mov    (%eax),%eax
f01020cf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020d5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01020d8:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020de:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01020e1:	89 93 90 1f 00 00    	mov    %edx,0x1f90(%ebx)

	// free the pages we took
	page_free(pp0);
f01020e7:	83 ec 0c             	sub    $0xc,%esp
f01020ea:	50                   	push   %eax
f01020eb:	e8 12 ef ff ff       	call   f0101002 <page_free>
	page_free(pp1);
f01020f0:	89 3c 24             	mov    %edi,(%esp)
f01020f3:	e8 0a ef ff ff       	call   f0101002 <page_free>
	page_free(pp2);
f01020f8:	89 34 24             	mov    %esi,(%esp)
f01020fb:	e8 02 ef ff ff       	call   f0101002 <page_free>

	cprintf("check_page() succeeded!\n");
f0102100:	8d 83 e3 dc fe ff    	lea    -0x1231d(%ebx),%eax
f0102106:	89 04 24             	mov    %eax,(%esp)
f0102109:	e8 ff 0f 00 00       	call   f010310d <cprintf>
	boot_map_region(kern_pgdir, UPAGES, npages * sizeof(struct PageInfo), PADDR(pages), PTE_U);
f010210e:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102114:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102116:	83 c4 10             	add    $0x10,%esp
f0102119:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010211e:	0f 86 ca 08 00 00    	jbe    f01029ee <mem_init+0x1685>
f0102124:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102127:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f010212d:	8b 0a                	mov    (%edx),%ecx
f010212f:	c1 e1 03             	shl    $0x3,%ecx
f0102132:	83 ec 08             	sub    $0x8,%esp
f0102135:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102137:	05 00 00 00 10       	add    $0x10000000,%eax
f010213c:	50                   	push   %eax
f010213d:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102142:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102148:	8b 00                	mov    (%eax),%eax
f010214a:	e8 49 f0 ff ff       	call   f0101198 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f010214f:	c7 c0 00 e0 10 f0    	mov    $0xf010e000,%eax
f0102155:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102158:	83 c4 10             	add    $0x10,%esp
f010215b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102160:	0f 86 a4 08 00 00    	jbe    f0102a0a <mem_init+0x16a1>
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102166:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102169:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f010216f:	83 ec 08             	sub    $0x8,%esp
f0102172:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f0102174:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102177:	05 00 00 00 10       	add    $0x10000000,%eax
f010217c:	50                   	push   %eax
f010217d:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102182:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102187:	8b 03                	mov    (%ebx),%eax
f0102189:	e8 0a f0 ff ff       	call   f0101198 <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f010218e:	83 c4 08             	add    $0x8,%esp
f0102191:	6a 02                	push   $0x2
f0102193:	6a 00                	push   $0x0
f0102195:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010219a:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010219f:	8b 03                	mov    (%ebx),%eax
f01021a1:	e8 f2 ef ff ff       	call   f0101198 <boot_map_region>
	pgdir = kern_pgdir;
f01021a6:	8b 33                	mov    (%ebx),%esi
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
f01021a8:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f01021ae:	8b 00                	mov    (%eax),%eax
f01021b0:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01021b3:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021ba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021bf:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021c2:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01021c8:	8b 00                	mov    (%eax),%eax
f01021ca:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01021cd:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01021d0:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f01021d6:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f01021d9:	bf 00 00 00 00       	mov    $0x0,%edi
f01021de:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f01021e1:	0f 86 84 08 00 00    	jbe    f0102a6b <mem_init+0x1702>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021e7:	8d 97 00 00 00 ef    	lea    -0x11000000(%edi),%edx
f01021ed:	89 f0                	mov    %esi,%eax
f01021ef:	e8 45 e8 ff ff       	call   f0100a39 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f01021f4:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f01021fb:	0f 86 2a 08 00 00    	jbe    f0102a2b <mem_init+0x16c2>
f0102201:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102204:	39 c2                	cmp    %eax,%edx
f0102206:	0f 85 3d 08 00 00    	jne    f0102a49 <mem_init+0x16e0>
	for (i = 0; i < n; i += PGSIZE)
f010220c:	81 c7 00 10 00 00    	add    $0x1000,%edi
f0102212:	eb ca                	jmp    f01021de <mem_init+0xe75>
	assert(nfree == 0);
f0102214:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102217:	8d 83 0c dc fe ff    	lea    -0x123f4(%ebx),%eax
f010221d:	50                   	push   %eax
f010221e:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102224:	50                   	push   %eax
f0102225:	68 ce 02 00 00       	push   $0x2ce
f010222a:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102230:	50                   	push   %eax
f0102231:	e8 63 de ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102236:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102239:	8d 83 71 db fe ff    	lea    -0x1248f(%ebx),%eax
f010223f:	50                   	push   %eax
f0102240:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102246:	50                   	push   %eax
f0102247:	68 29 03 00 00       	push   $0x329
f010224c:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102252:	50                   	push   %eax
f0102253:	e8 41 de ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102258:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010225b:	8d 83 87 db fe ff    	lea    -0x12479(%ebx),%eax
f0102261:	50                   	push   %eax
f0102262:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102268:	50                   	push   %eax
f0102269:	68 2a 03 00 00       	push   $0x32a
f010226e:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102274:	50                   	push   %eax
f0102275:	e8 1f de ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010227a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010227d:	8d 83 9d db fe ff    	lea    -0x12463(%ebx),%eax
f0102283:	50                   	push   %eax
f0102284:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010228a:	50                   	push   %eax
f010228b:	68 2b 03 00 00       	push   $0x32b
f0102290:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102296:	50                   	push   %eax
f0102297:	e8 fd dd ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f010229c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010229f:	8d 83 b3 db fe ff    	lea    -0x1244d(%ebx),%eax
f01022a5:	50                   	push   %eax
f01022a6:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01022ac:	50                   	push   %eax
f01022ad:	68 2e 03 00 00       	push   $0x32e
f01022b2:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01022b8:	50                   	push   %eax
f01022b9:	e8 db dd ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01022be:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022c1:	8d 83 54 d4 fe ff    	lea    -0x12bac(%ebx),%eax
f01022c7:	50                   	push   %eax
f01022c8:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01022ce:	50                   	push   %eax
f01022cf:	68 2f 03 00 00       	push   $0x32f
f01022d4:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01022da:	50                   	push   %eax
f01022db:	e8 b9 dd ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01022e0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022e3:	8d 83 c5 db fe ff    	lea    -0x1243b(%ebx),%eax
f01022e9:	50                   	push   %eax
f01022ea:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01022f0:	50                   	push   %eax
f01022f1:	68 36 03 00 00       	push   $0x336
f01022f6:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01022fc:	50                   	push   %eax
f01022fd:	e8 97 dd ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *)0x0, &ptep) == NULL);
f0102302:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102305:	8d 83 f4 d4 fe ff    	lea    -0x12b0c(%ebx),%eax
f010230b:	50                   	push   %eax
f010230c:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102312:	50                   	push   %eax
f0102313:	68 39 03 00 00       	push   $0x339
f0102318:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010231e:	50                   	push   %eax
f010231f:	e8 75 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102324:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102327:	8d 83 28 d5 fe ff    	lea    -0x12ad8(%ebx),%eax
f010232d:	50                   	push   %eax
f010232e:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102334:	50                   	push   %eax
f0102335:	68 3c 03 00 00       	push   $0x33c
f010233a:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102340:	50                   	push   %eax
f0102341:	e8 53 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102346:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102349:	8d 83 58 d5 fe ff    	lea    -0x12aa8(%ebx),%eax
f010234f:	50                   	push   %eax
f0102350:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102356:	50                   	push   %eax
f0102357:	68 40 03 00 00       	push   $0x340
f010235c:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102362:	50                   	push   %eax
f0102363:	e8 31 dd ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102368:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010236b:	8d 83 88 d5 fe ff    	lea    -0x12a78(%ebx),%eax
f0102371:	50                   	push   %eax
f0102372:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102378:	50                   	push   %eax
f0102379:	68 41 03 00 00       	push   $0x341
f010237e:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102384:	50                   	push   %eax
f0102385:	e8 0f dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010238a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010238d:	8d 83 b0 d5 fe ff    	lea    -0x12a50(%ebx),%eax
f0102393:	50                   	push   %eax
f0102394:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010239a:	50                   	push   %eax
f010239b:	68 42 03 00 00       	push   $0x342
f01023a0:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01023a6:	50                   	push   %eax
f01023a7:	e8 ed dc ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01023ac:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023af:	8d 83 17 dc fe ff    	lea    -0x123e9(%ebx),%eax
f01023b5:	50                   	push   %eax
f01023b6:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01023bc:	50                   	push   %eax
f01023bd:	68 43 03 00 00       	push   $0x343
f01023c2:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01023c8:	50                   	push   %eax
f01023c9:	e8 cb dc ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01023ce:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023d1:	8d 83 28 dc fe ff    	lea    -0x123d8(%ebx),%eax
f01023d7:	50                   	push   %eax
f01023d8:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01023de:	50                   	push   %eax
f01023df:	68 44 03 00 00       	push   $0x344
f01023e4:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01023ea:	50                   	push   %eax
f01023eb:	e8 a9 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f01023f0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023f3:	8d 83 e0 d5 fe ff    	lea    -0x12a20(%ebx),%eax
f01023f9:	50                   	push   %eax
f01023fa:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102400:	50                   	push   %eax
f0102401:	68 47 03 00 00       	push   $0x347
f0102406:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010240c:	50                   	push   %eax
f010240d:	e8 87 dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102412:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102415:	8d 83 1c d6 fe ff    	lea    -0x129e4(%ebx),%eax
f010241b:	50                   	push   %eax
f010241c:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102422:	50                   	push   %eax
f0102423:	68 48 03 00 00       	push   $0x348
f0102428:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010242e:	50                   	push   %eax
f010242f:	e8 65 dc ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102434:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102437:	8d 83 39 dc fe ff    	lea    -0x123c7(%ebx),%eax
f010243d:	50                   	push   %eax
f010243e:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102444:	50                   	push   %eax
f0102445:	68 49 03 00 00       	push   $0x349
f010244a:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102450:	50                   	push   %eax
f0102451:	e8 43 dc ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102456:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102459:	8d 83 c5 db fe ff    	lea    -0x1243b(%ebx),%eax
f010245f:	50                   	push   %eax
f0102460:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102466:	50                   	push   %eax
f0102467:	68 4c 03 00 00       	push   $0x34c
f010246c:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102472:	50                   	push   %eax
f0102473:	e8 21 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0102478:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010247b:	8d 83 e0 d5 fe ff    	lea    -0x12a20(%ebx),%eax
f0102481:	50                   	push   %eax
f0102482:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102488:	50                   	push   %eax
f0102489:	68 4f 03 00 00       	push   $0x34f
f010248e:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102494:	50                   	push   %eax
f0102495:	e8 ff db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010249a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010249d:	8d 83 1c d6 fe ff    	lea    -0x129e4(%ebx),%eax
f01024a3:	50                   	push   %eax
f01024a4:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01024aa:	50                   	push   %eax
f01024ab:	68 50 03 00 00       	push   $0x350
f01024b0:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01024b6:	50                   	push   %eax
f01024b7:	e8 dd db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01024bc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024bf:	8d 83 39 dc fe ff    	lea    -0x123c7(%ebx),%eax
f01024c5:	50                   	push   %eax
f01024c6:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01024cc:	50                   	push   %eax
f01024cd:	68 51 03 00 00       	push   $0x351
f01024d2:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01024d8:	50                   	push   %eax
f01024d9:	e8 bb db ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01024de:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024e1:	8d 83 c5 db fe ff    	lea    -0x1243b(%ebx),%eax
f01024e7:	50                   	push   %eax
f01024e8:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01024ee:	50                   	push   %eax
f01024ef:	68 55 03 00 00       	push   $0x355
f01024f4:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01024fa:	50                   	push   %eax
f01024fb:	e8 99 db ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102500:	50                   	push   %eax
f0102501:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102504:	8d 83 78 d2 fe ff    	lea    -0x12d88(%ebx),%eax
f010250a:	50                   	push   %eax
f010250b:	68 58 03 00 00       	push   $0x358
f0102510:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102516:	50                   	push   %eax
f0102517:	e8 7d db ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) == ptep + PTX(PGSIZE));
f010251c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010251f:	8d 83 4c d6 fe ff    	lea    -0x129b4(%ebx),%eax
f0102525:	50                   	push   %eax
f0102526:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010252c:	50                   	push   %eax
f010252d:	68 59 03 00 00       	push   $0x359
f0102532:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102538:	50                   	push   %eax
f0102539:	e8 5b db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W | PTE_U) == 0);
f010253e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102541:	8d 83 8c d6 fe ff    	lea    -0x12974(%ebx),%eax
f0102547:	50                   	push   %eax
f0102548:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010254e:	50                   	push   %eax
f010254f:	68 5c 03 00 00       	push   $0x35c
f0102554:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010255a:	50                   	push   %eax
f010255b:	e8 39 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102560:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102563:	8d 83 1c d6 fe ff    	lea    -0x129e4(%ebx),%eax
f0102569:	50                   	push   %eax
f010256a:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102570:	50                   	push   %eax
f0102571:	68 5d 03 00 00       	push   $0x35d
f0102576:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010257c:	50                   	push   %eax
f010257d:	e8 17 db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102582:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102585:	8d 83 39 dc fe ff    	lea    -0x123c7(%ebx),%eax
f010258b:	50                   	push   %eax
f010258c:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102592:	50                   	push   %eax
f0102593:	68 5e 03 00 00       	push   $0x35e
f0102598:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010259e:	50                   	push   %eax
f010259f:	e8 f5 da ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U);
f01025a4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025a7:	8d 83 d0 d6 fe ff    	lea    -0x12930(%ebx),%eax
f01025ad:	50                   	push   %eax
f01025ae:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01025b4:	50                   	push   %eax
f01025b5:	68 5f 03 00 00       	push   $0x35f
f01025ba:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01025c0:	50                   	push   %eax
f01025c1:	e8 d3 da ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01025c6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025c9:	8d 83 4a dc fe ff    	lea    -0x123b6(%ebx),%eax
f01025cf:	50                   	push   %eax
f01025d0:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01025d6:	50                   	push   %eax
f01025d7:	68 60 03 00 00       	push   $0x360
f01025dc:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01025e2:	50                   	push   %eax
f01025e3:	e8 b1 da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f01025e8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025eb:	8d 83 e0 d5 fe ff    	lea    -0x12a20(%ebx),%eax
f01025f1:	50                   	push   %eax
f01025f2:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01025f8:	50                   	push   %eax
f01025f9:	68 63 03 00 00       	push   $0x363
f01025fe:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102604:	50                   	push   %eax
f0102605:	e8 8f da ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_W);
f010260a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010260d:	8d 83 04 d7 fe ff    	lea    -0x128fc(%ebx),%eax
f0102613:	50                   	push   %eax
f0102614:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010261a:	50                   	push   %eax
f010261b:	68 64 03 00 00       	push   $0x364
f0102620:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102626:	50                   	push   %eax
f0102627:	e8 6d da ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f010262c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010262f:	8d 83 38 d7 fe ff    	lea    -0x128c8(%ebx),%eax
f0102635:	50                   	push   %eax
f0102636:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010263c:	50                   	push   %eax
f010263d:	68 65 03 00 00       	push   $0x365
f0102642:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102648:	50                   	push   %eax
f0102649:	e8 4b da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void *)PTSIZE, PTE_W) < 0);
f010264e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102651:	8d 83 70 d7 fe ff    	lea    -0x12890(%ebx),%eax
f0102657:	50                   	push   %eax
f0102658:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010265e:	50                   	push   %eax
f010265f:	68 68 03 00 00       	push   $0x368
f0102664:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010266a:	50                   	push   %eax
f010266b:	e8 29 da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W) == 0);
f0102670:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102673:	8d 83 a8 d7 fe ff    	lea    -0x12858(%ebx),%eax
f0102679:	50                   	push   %eax
f010267a:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102680:	50                   	push   %eax
f0102681:	68 6b 03 00 00       	push   $0x36b
f0102686:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010268c:	50                   	push   %eax
f010268d:	e8 07 da ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0102692:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102695:	8d 83 38 d7 fe ff    	lea    -0x128c8(%ebx),%eax
f010269b:	50                   	push   %eax
f010269c:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01026a2:	50                   	push   %eax
f01026a3:	68 6c 03 00 00       	push   $0x36c
f01026a8:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01026ae:	50                   	push   %eax
f01026af:	e8 e5 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01026b4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026b7:	8d 83 e4 d7 fe ff    	lea    -0x1281c(%ebx),%eax
f01026bd:	50                   	push   %eax
f01026be:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01026c4:	50                   	push   %eax
f01026c5:	68 6f 03 00 00       	push   $0x36f
f01026ca:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01026d0:	50                   	push   %eax
f01026d1:	e8 c3 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01026d6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026d9:	8d 83 10 d8 fe ff    	lea    -0x127f0(%ebx),%eax
f01026df:	50                   	push   %eax
f01026e0:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01026e6:	50                   	push   %eax
f01026e7:	68 70 03 00 00       	push   $0x370
f01026ec:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01026f2:	50                   	push   %eax
f01026f3:	e8 a1 d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f01026f8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026fb:	8d 83 60 dc fe ff    	lea    -0x123a0(%ebx),%eax
f0102701:	50                   	push   %eax
f0102702:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102708:	50                   	push   %eax
f0102709:	68 72 03 00 00       	push   $0x372
f010270e:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102714:	50                   	push   %eax
f0102715:	e8 7f d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f010271a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010271d:	8d 83 71 dc fe ff    	lea    -0x1238f(%ebx),%eax
f0102723:	50                   	push   %eax
f0102724:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010272a:	50                   	push   %eax
f010272b:	68 73 03 00 00       	push   $0x373
f0102730:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102736:	50                   	push   %eax
f0102737:	e8 5d d9 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f010273c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010273f:	8d 83 40 d8 fe ff    	lea    -0x127c0(%ebx),%eax
f0102745:	50                   	push   %eax
f0102746:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010274c:	50                   	push   %eax
f010274d:	68 76 03 00 00       	push   $0x376
f0102752:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102758:	50                   	push   %eax
f0102759:	e8 3b d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010275e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102761:	8d 83 64 d8 fe ff    	lea    -0x1279c(%ebx),%eax
f0102767:	50                   	push   %eax
f0102768:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010276e:	50                   	push   %eax
f010276f:	68 7a 03 00 00       	push   $0x37a
f0102774:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010277a:	50                   	push   %eax
f010277b:	e8 19 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102780:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102783:	8d 83 10 d8 fe ff    	lea    -0x127f0(%ebx),%eax
f0102789:	50                   	push   %eax
f010278a:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102790:	50                   	push   %eax
f0102791:	68 7b 03 00 00       	push   $0x37b
f0102796:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010279c:	50                   	push   %eax
f010279d:	e8 f7 d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01027a2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027a5:	8d 83 17 dc fe ff    	lea    -0x123e9(%ebx),%eax
f01027ab:	50                   	push   %eax
f01027ac:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01027b2:	50                   	push   %eax
f01027b3:	68 7c 03 00 00       	push   $0x37c
f01027b8:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01027be:	50                   	push   %eax
f01027bf:	e8 d5 d8 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01027c4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027c7:	8d 83 71 dc fe ff    	lea    -0x1238f(%ebx),%eax
f01027cd:	50                   	push   %eax
f01027ce:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01027d4:	50                   	push   %eax
f01027d5:	68 7d 03 00 00       	push   $0x37d
f01027da:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01027e0:	50                   	push   %eax
f01027e1:	e8 b3 d8 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, 0) == 0);
f01027e6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027e9:	8d 83 88 d8 fe ff    	lea    -0x12778(%ebx),%eax
f01027ef:	50                   	push   %eax
f01027f0:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01027f6:	50                   	push   %eax
f01027f7:	68 80 03 00 00       	push   $0x380
f01027fc:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102802:	50                   	push   %eax
f0102803:	e8 91 d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f0102808:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010280b:	8d 83 82 dc fe ff    	lea    -0x1237e(%ebx),%eax
f0102811:	50                   	push   %eax
f0102812:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102818:	50                   	push   %eax
f0102819:	68 81 03 00 00       	push   $0x381
f010281e:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102824:	50                   	push   %eax
f0102825:	e8 6f d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f010282a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010282d:	8d 83 8e dc fe ff    	lea    -0x12372(%ebx),%eax
f0102833:	50                   	push   %eax
f0102834:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010283a:	50                   	push   %eax
f010283b:	68 82 03 00 00       	push   $0x382
f0102840:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102846:	50                   	push   %eax
f0102847:	e8 4d d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010284c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010284f:	8d 83 64 d8 fe ff    	lea    -0x1279c(%ebx),%eax
f0102855:	50                   	push   %eax
f0102856:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010285c:	50                   	push   %eax
f010285d:	68 86 03 00 00       	push   $0x386
f0102862:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102868:	50                   	push   %eax
f0102869:	e8 2b d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010286e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102871:	8d 83 c0 d8 fe ff    	lea    -0x12740(%ebx),%eax
f0102877:	50                   	push   %eax
f0102878:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010287e:	50                   	push   %eax
f010287f:	68 87 03 00 00       	push   $0x387
f0102884:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010288a:	50                   	push   %eax
f010288b:	e8 09 d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102890:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102893:	8d 83 a3 dc fe ff    	lea    -0x1235d(%ebx),%eax
f0102899:	50                   	push   %eax
f010289a:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01028a0:	50                   	push   %eax
f01028a1:	68 88 03 00 00       	push   $0x388
f01028a6:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01028ac:	50                   	push   %eax
f01028ad:	e8 e7 d7 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01028b2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028b5:	8d 83 71 dc fe ff    	lea    -0x1238f(%ebx),%eax
f01028bb:	50                   	push   %eax
f01028bc:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01028c2:	50                   	push   %eax
f01028c3:	68 89 03 00 00       	push   $0x389
f01028c8:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01028ce:	50                   	push   %eax
f01028cf:	e8 c5 d7 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01028d4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028d7:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
f01028dd:	50                   	push   %eax
f01028de:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01028e4:	50                   	push   %eax
f01028e5:	68 8c 03 00 00       	push   $0x38c
f01028ea:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01028f0:	50                   	push   %eax
f01028f1:	e8 a3 d7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01028f6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028f9:	8d 83 c5 db fe ff    	lea    -0x1243b(%ebx),%eax
f01028ff:	50                   	push   %eax
f0102900:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102906:	50                   	push   %eax
f0102907:	68 8f 03 00 00       	push   $0x38f
f010290c:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102912:	50                   	push   %eax
f0102913:	e8 81 d7 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102918:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010291b:	8d 83 88 d5 fe ff    	lea    -0x12a78(%ebx),%eax
f0102921:	50                   	push   %eax
f0102922:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102928:	50                   	push   %eax
f0102929:	68 92 03 00 00       	push   $0x392
f010292e:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102934:	50                   	push   %eax
f0102935:	e8 5f d7 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f010293a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010293d:	8d 83 28 dc fe ff    	lea    -0x123d8(%ebx),%eax
f0102943:	50                   	push   %eax
f0102944:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010294a:	50                   	push   %eax
f010294b:	68 94 03 00 00       	push   $0x394
f0102950:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102956:	50                   	push   %eax
f0102957:	e8 3d d7 ff ff       	call   f0100099 <_panic>
f010295c:	52                   	push   %edx
f010295d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102960:	8d 83 78 d2 fe ff    	lea    -0x12d88(%ebx),%eax
f0102966:	50                   	push   %eax
f0102967:	68 9b 03 00 00       	push   $0x39b
f010296c:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102972:	50                   	push   %eax
f0102973:	e8 21 d7 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102978:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010297b:	8d 83 b4 dc fe ff    	lea    -0x1234c(%ebx),%eax
f0102981:	50                   	push   %eax
f0102982:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102988:	50                   	push   %eax
f0102989:	68 9c 03 00 00       	push   $0x39c
f010298e:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102994:	50                   	push   %eax
f0102995:	e8 ff d6 ff ff       	call   f0100099 <_panic>
f010299a:	50                   	push   %eax
f010299b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010299e:	8d 83 78 d2 fe ff    	lea    -0x12d88(%ebx),%eax
f01029a4:	50                   	push   %eax
f01029a5:	6a 52                	push   $0x52
f01029a7:	8d 83 ac da fe ff    	lea    -0x12554(%ebx),%eax
f01029ad:	50                   	push   %eax
f01029ae:	e8 e6 d6 ff ff       	call   f0100099 <_panic>
f01029b3:	52                   	push   %edx
f01029b4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029b7:	8d 83 78 d2 fe ff    	lea    -0x12d88(%ebx),%eax
f01029bd:	50                   	push   %eax
f01029be:	6a 52                	push   $0x52
f01029c0:	8d 83 ac da fe ff    	lea    -0x12554(%ebx),%eax
f01029c6:	50                   	push   %eax
f01029c7:	e8 cd d6 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f01029cc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029cf:	8d 83 cc dc fe ff    	lea    -0x12334(%ebx),%eax
f01029d5:	50                   	push   %eax
f01029d6:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f01029dc:	50                   	push   %eax
f01029dd:	68 a6 03 00 00       	push   $0x3a6
f01029e2:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f01029e8:	50                   	push   %eax
f01029e9:	e8 ab d6 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029ee:	50                   	push   %eax
f01029ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029f2:	8d 83 7c d3 fe ff    	lea    -0x12c84(%ebx),%eax
f01029f8:	50                   	push   %eax
f01029f9:	68 bf 00 00 00       	push   $0xbf
f01029fe:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102a04:	50                   	push   %eax
f0102a05:	e8 8f d6 ff ff       	call   f0100099 <_panic>
f0102a0a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a0d:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f0102a13:	8d 83 7c d3 fe ff    	lea    -0x12c84(%ebx),%eax
f0102a19:	50                   	push   %eax
f0102a1a:	68 cd 00 00 00       	push   $0xcd
f0102a1f:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102a25:	50                   	push   %eax
f0102a26:	e8 6e d6 ff ff       	call   f0100099 <_panic>
f0102a2b:	ff 75 c0             	pushl  -0x40(%ebp)
f0102a2e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a31:	8d 83 7c d3 fe ff    	lea    -0x12c84(%ebx),%eax
f0102a37:	50                   	push   %eax
f0102a38:	68 e6 02 00 00       	push   $0x2e6
f0102a3d:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102a43:	50                   	push   %eax
f0102a44:	e8 50 d6 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102a49:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a4c:	8d 83 0c d9 fe ff    	lea    -0x126f4(%ebx),%eax
f0102a52:	50                   	push   %eax
f0102a53:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102a59:	50                   	push   %eax
f0102a5a:	68 e6 02 00 00       	push   $0x2e6
f0102a5f:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102a65:	50                   	push   %eax
f0102a66:	e8 2e d6 ff ff       	call   f0100099 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a6b:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102a6e:	c1 e7 0c             	shl    $0xc,%edi
f0102a71:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a76:	eb 17                	jmp    f0102a8f <mem_init+0x1726>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a78:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102a7e:	89 f0                	mov    %esi,%eax
f0102a80:	e8 b4 df ff ff       	call   f0100a39 <check_va2pa>
f0102a85:	39 c3                	cmp    %eax,%ebx
f0102a87:	75 51                	jne    f0102ada <mem_init+0x1771>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a89:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102a8f:	39 fb                	cmp    %edi,%ebx
f0102a91:	72 e5                	jb     f0102a78 <mem_init+0x170f>
f0102a93:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102a98:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102a9b:	81 c7 00 80 00 20    	add    $0x20008000,%edi
f0102aa1:	89 da                	mov    %ebx,%edx
f0102aa3:	89 f0                	mov    %esi,%eax
f0102aa5:	e8 8f df ff ff       	call   f0100a39 <check_va2pa>
f0102aaa:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102aad:	39 c2                	cmp    %eax,%edx
f0102aaf:	75 4b                	jne    f0102afc <mem_init+0x1793>
f0102ab1:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102ab7:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102abd:	75 e2                	jne    f0102aa1 <mem_init+0x1738>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102abf:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102ac4:	89 f0                	mov    %esi,%eax
f0102ac6:	e8 6e df ff ff       	call   f0100a39 <check_va2pa>
f0102acb:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102ace:	75 4e                	jne    f0102b1e <mem_init+0x17b5>
	for (i = 0; i < NPDENTRIES; i++)
f0102ad0:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ad5:	e9 8f 00 00 00       	jmp    f0102b69 <mem_init+0x1800>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102ada:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102add:	8d 83 40 d9 fe ff    	lea    -0x126c0(%ebx),%eax
f0102ae3:	50                   	push   %eax
f0102ae4:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102aea:	50                   	push   %eax
f0102aeb:	68 ea 02 00 00       	push   $0x2ea
f0102af0:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102af6:	50                   	push   %eax
f0102af7:	e8 9d d5 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102afc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102aff:	8d 83 68 d9 fe ff    	lea    -0x12698(%ebx),%eax
f0102b05:	50                   	push   %eax
f0102b06:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102b0c:	50                   	push   %eax
f0102b0d:	68 ee 02 00 00       	push   $0x2ee
f0102b12:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102b18:	50                   	push   %eax
f0102b19:	e8 7b d5 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b1e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b21:	8d 83 b0 d9 fe ff    	lea    -0x12650(%ebx),%eax
f0102b27:	50                   	push   %eax
f0102b28:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102b2e:	50                   	push   %eax
f0102b2f:	68 ef 02 00 00       	push   $0x2ef
f0102b34:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102b3a:	50                   	push   %eax
f0102b3b:	e8 59 d5 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102b40:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102b44:	74 52                	je     f0102b98 <mem_init+0x182f>
	for (i = 0; i < NPDENTRIES; i++)
f0102b46:	83 c0 01             	add    $0x1,%eax
f0102b49:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102b4e:	0f 87 bb 00 00 00    	ja     f0102c0f <mem_init+0x18a6>
		switch (i)
f0102b54:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102b59:	72 0e                	jb     f0102b69 <mem_init+0x1800>
f0102b5b:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102b60:	76 de                	jbe    f0102b40 <mem_init+0x17d7>
f0102b62:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102b67:	74 d7                	je     f0102b40 <mem_init+0x17d7>
			if (i >= PDX(KERNBASE))
f0102b69:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102b6e:	77 4a                	ja     f0102bba <mem_init+0x1851>
				assert(pgdir[i] == 0);
f0102b70:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102b74:	74 d0                	je     f0102b46 <mem_init+0x17dd>
f0102b76:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b79:	8d 83 1e dd fe ff    	lea    -0x122e2(%ebx),%eax
f0102b7f:	50                   	push   %eax
f0102b80:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102b86:	50                   	push   %eax
f0102b87:	68 02 03 00 00       	push   $0x302
f0102b8c:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102b92:	50                   	push   %eax
f0102b93:	e8 01 d5 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102b98:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b9b:	8d 83 fc dc fe ff    	lea    -0x12304(%ebx),%eax
f0102ba1:	50                   	push   %eax
f0102ba2:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102ba8:	50                   	push   %eax
f0102ba9:	68 f9 02 00 00       	push   $0x2f9
f0102bae:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102bb4:	50                   	push   %eax
f0102bb5:	e8 df d4 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102bba:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102bbd:	f6 c2 01             	test   $0x1,%dl
f0102bc0:	74 2b                	je     f0102bed <mem_init+0x1884>
				assert(pgdir[i] & PTE_W);
f0102bc2:	f6 c2 02             	test   $0x2,%dl
f0102bc5:	0f 85 7b ff ff ff    	jne    f0102b46 <mem_init+0x17dd>
f0102bcb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bce:	8d 83 0d dd fe ff    	lea    -0x122f3(%ebx),%eax
f0102bd4:	50                   	push   %eax
f0102bd5:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102bdb:	50                   	push   %eax
f0102bdc:	68 ff 02 00 00       	push   $0x2ff
f0102be1:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102be7:	50                   	push   %eax
f0102be8:	e8 ac d4 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102bed:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bf0:	8d 83 fc dc fe ff    	lea    -0x12304(%ebx),%eax
f0102bf6:	50                   	push   %eax
f0102bf7:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102bfd:	50                   	push   %eax
f0102bfe:	68 fe 02 00 00       	push   $0x2fe
f0102c03:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102c09:	50                   	push   %eax
f0102c0a:	e8 8a d4 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102c0f:	83 ec 0c             	sub    $0xc,%esp
f0102c12:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c15:	8d 87 e0 d9 fe ff    	lea    -0x12620(%edi),%eax
f0102c1b:	50                   	push   %eax
f0102c1c:	89 fb                	mov    %edi,%ebx
f0102c1e:	e8 ea 04 00 00       	call   f010310d <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102c23:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102c29:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102c2b:	83 c4 10             	add    $0x10,%esp
f0102c2e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c33:	0f 86 44 02 00 00    	jbe    f0102e7d <mem_init+0x1b14>
	return (physaddr_t)kva - KERNBASE;
f0102c39:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102c3e:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102c41:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c46:	e8 6b de ff ff       	call   f0100ab6 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102c4b:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS | CR0_EM);
f0102c4e:	83 e0 f3             	and    $0xfffffff3,%eax
f0102c51:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102c56:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102c59:	83 ec 0c             	sub    $0xc,%esp
f0102c5c:	6a 00                	push   $0x0
f0102c5e:	e8 17 e3 ff ff       	call   f0100f7a <page_alloc>
f0102c63:	89 c6                	mov    %eax,%esi
f0102c65:	83 c4 10             	add    $0x10,%esp
f0102c68:	85 c0                	test   %eax,%eax
f0102c6a:	0f 84 29 02 00 00    	je     f0102e99 <mem_init+0x1b30>
	assert((pp1 = page_alloc(0)));
f0102c70:	83 ec 0c             	sub    $0xc,%esp
f0102c73:	6a 00                	push   $0x0
f0102c75:	e8 00 e3 ff ff       	call   f0100f7a <page_alloc>
f0102c7a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102c7d:	83 c4 10             	add    $0x10,%esp
f0102c80:	85 c0                	test   %eax,%eax
f0102c82:	0f 84 33 02 00 00    	je     f0102ebb <mem_init+0x1b52>
	assert((pp2 = page_alloc(0)));
f0102c88:	83 ec 0c             	sub    $0xc,%esp
f0102c8b:	6a 00                	push   $0x0
f0102c8d:	e8 e8 e2 ff ff       	call   f0100f7a <page_alloc>
f0102c92:	89 c7                	mov    %eax,%edi
f0102c94:	83 c4 10             	add    $0x10,%esp
f0102c97:	85 c0                	test   %eax,%eax
f0102c99:	0f 84 3e 02 00 00    	je     f0102edd <mem_init+0x1b74>
	page_free(pp0);
f0102c9f:	83 ec 0c             	sub    $0xc,%esp
f0102ca2:	56                   	push   %esi
f0102ca3:	e8 5a e3 ff ff       	call   f0101002 <page_free>
	return (pp - pages) << PGSHIFT;
f0102ca8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cab:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102cb1:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102cb4:	2b 08                	sub    (%eax),%ecx
f0102cb6:	89 c8                	mov    %ecx,%eax
f0102cb8:	c1 f8 03             	sar    $0x3,%eax
f0102cbb:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102cbe:	89 c1                	mov    %eax,%ecx
f0102cc0:	c1 e9 0c             	shr    $0xc,%ecx
f0102cc3:	83 c4 10             	add    $0x10,%esp
f0102cc6:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102ccc:	3b 0a                	cmp    (%edx),%ecx
f0102cce:	0f 83 2b 02 00 00    	jae    f0102eff <mem_init+0x1b96>
	memset(page2kva(pp1), 1, PGSIZE);
f0102cd4:	83 ec 04             	sub    $0x4,%esp
f0102cd7:	68 00 10 00 00       	push   $0x1000
f0102cdc:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102cde:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102ce3:	50                   	push   %eax
f0102ce4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ce7:	e8 b2 0f 00 00       	call   f0103c9e <memset>
	return (pp - pages) << PGSHIFT;
f0102cec:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cef:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102cf5:	89 f9                	mov    %edi,%ecx
f0102cf7:	2b 08                	sub    (%eax),%ecx
f0102cf9:	89 c8                	mov    %ecx,%eax
f0102cfb:	c1 f8 03             	sar    $0x3,%eax
f0102cfe:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102d01:	89 c1                	mov    %eax,%ecx
f0102d03:	c1 e9 0c             	shr    $0xc,%ecx
f0102d06:	83 c4 10             	add    $0x10,%esp
f0102d09:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102d0f:	3b 0a                	cmp    (%edx),%ecx
f0102d11:	0f 83 fe 01 00 00    	jae    f0102f15 <mem_init+0x1bac>
	memset(page2kva(pp2), 2, PGSIZE);
f0102d17:	83 ec 04             	sub    $0x4,%esp
f0102d1a:	68 00 10 00 00       	push   $0x1000
f0102d1f:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102d21:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102d26:	50                   	push   %eax
f0102d27:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d2a:	e8 6f 0f 00 00       	call   f0103c9e <memset>
	page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W);
f0102d2f:	6a 02                	push   $0x2
f0102d31:	68 00 10 00 00       	push   $0x1000
f0102d36:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102d39:	53                   	push   %ebx
f0102d3a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d3d:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102d43:	ff 30                	pushl  (%eax)
f0102d45:	e8 99 e5 ff ff       	call   f01012e3 <page_insert>
	assert(pp1->pp_ref == 1);
f0102d4a:	83 c4 20             	add    $0x20,%esp
f0102d4d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d52:	0f 85 d3 01 00 00    	jne    f0102f2b <mem_init+0x1bc2>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d58:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102d5f:	01 01 01 
f0102d62:	0f 85 e5 01 00 00    	jne    f0102f4d <mem_init+0x1be4>
	page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W);
f0102d68:	6a 02                	push   $0x2
f0102d6a:	68 00 10 00 00       	push   $0x1000
f0102d6f:	57                   	push   %edi
f0102d70:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d73:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102d79:	ff 30                	pushl  (%eax)
f0102d7b:	e8 63 e5 ff ff       	call   f01012e3 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d80:	83 c4 10             	add    $0x10,%esp
f0102d83:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d8a:	02 02 02 
f0102d8d:	0f 85 dc 01 00 00    	jne    f0102f6f <mem_init+0x1c06>
	assert(pp2->pp_ref == 1);
f0102d93:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102d98:	0f 85 f3 01 00 00    	jne    f0102f91 <mem_init+0x1c28>
	assert(pp1->pp_ref == 0);
f0102d9e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102da1:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102da6:	0f 85 07 02 00 00    	jne    f0102fb3 <mem_init+0x1c4a>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102dac:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102db3:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102db6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102db9:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102dbf:	89 f9                	mov    %edi,%ecx
f0102dc1:	2b 08                	sub    (%eax),%ecx
f0102dc3:	89 c8                	mov    %ecx,%eax
f0102dc5:	c1 f8 03             	sar    $0x3,%eax
f0102dc8:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102dcb:	89 c1                	mov    %eax,%ecx
f0102dcd:	c1 e9 0c             	shr    $0xc,%ecx
f0102dd0:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102dd6:	3b 0a                	cmp    (%edx),%ecx
f0102dd8:	0f 83 f7 01 00 00    	jae    f0102fd5 <mem_init+0x1c6c>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102dde:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102de5:	03 03 03 
f0102de8:	0f 85 fd 01 00 00    	jne    f0102feb <mem_init+0x1c82>
	page_remove(kern_pgdir, (void *)PGSIZE);
f0102dee:	83 ec 08             	sub    $0x8,%esp
f0102df1:	68 00 10 00 00       	push   $0x1000
f0102df6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102df9:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102dff:	ff 30                	pushl  (%eax)
f0102e01:	e8 a0 e4 ff ff       	call   f01012a6 <page_remove>
	assert(pp2->pp_ref == 0);
f0102e06:	83 c4 10             	add    $0x10,%esp
f0102e09:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102e0e:	0f 85 f9 01 00 00    	jne    f010300d <mem_init+0x1ca4>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102e14:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102e17:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102e1d:	8b 08                	mov    (%eax),%ecx
f0102e1f:	8b 11                	mov    (%ecx),%edx
f0102e21:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102e27:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102e2d:	89 f7                	mov    %esi,%edi
f0102e2f:	2b 38                	sub    (%eax),%edi
f0102e31:	89 f8                	mov    %edi,%eax
f0102e33:	c1 f8 03             	sar    $0x3,%eax
f0102e36:	c1 e0 0c             	shl    $0xc,%eax
f0102e39:	39 c2                	cmp    %eax,%edx
f0102e3b:	0f 85 ee 01 00 00    	jne    f010302f <mem_init+0x1cc6>
	kern_pgdir[0] = 0;
f0102e41:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102e47:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102e4c:	0f 85 ff 01 00 00    	jne    f0103051 <mem_init+0x1ce8>
	pp0->pp_ref = 0;
f0102e52:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102e58:	83 ec 0c             	sub    $0xc,%esp
f0102e5b:	56                   	push   %esi
f0102e5c:	e8 a1 e1 ff ff       	call   f0101002 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e61:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e64:	8d 83 74 da fe ff    	lea    -0x1258c(%ebx),%eax
f0102e6a:	89 04 24             	mov    %eax,(%esp)
f0102e6d:	e8 9b 02 00 00       	call   f010310d <cprintf>
}
f0102e72:	83 c4 10             	add    $0x10,%esp
f0102e75:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e78:	5b                   	pop    %ebx
f0102e79:	5e                   	pop    %esi
f0102e7a:	5f                   	pop    %edi
f0102e7b:	5d                   	pop    %ebp
f0102e7c:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e7d:	50                   	push   %eax
f0102e7e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e81:	8d 83 7c d3 fe ff    	lea    -0x12c84(%ebx),%eax
f0102e87:	50                   	push   %eax
f0102e88:	68 e4 00 00 00       	push   $0xe4
f0102e8d:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102e93:	50                   	push   %eax
f0102e94:	e8 00 d2 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102e99:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e9c:	8d 83 71 db fe ff    	lea    -0x1248f(%ebx),%eax
f0102ea2:	50                   	push   %eax
f0102ea3:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102ea9:	50                   	push   %eax
f0102eaa:	68 c1 03 00 00       	push   $0x3c1
f0102eaf:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102eb5:	50                   	push   %eax
f0102eb6:	e8 de d1 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102ebb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ebe:	8d 83 87 db fe ff    	lea    -0x12479(%ebx),%eax
f0102ec4:	50                   	push   %eax
f0102ec5:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102ecb:	50                   	push   %eax
f0102ecc:	68 c2 03 00 00       	push   $0x3c2
f0102ed1:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102ed7:	50                   	push   %eax
f0102ed8:	e8 bc d1 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102edd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ee0:	8d 83 9d db fe ff    	lea    -0x12463(%ebx),%eax
f0102ee6:	50                   	push   %eax
f0102ee7:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102eed:	50                   	push   %eax
f0102eee:	68 c3 03 00 00       	push   $0x3c3
f0102ef3:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102ef9:	50                   	push   %eax
f0102efa:	e8 9a d1 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102eff:	50                   	push   %eax
f0102f00:	8d 83 78 d2 fe ff    	lea    -0x12d88(%ebx),%eax
f0102f06:	50                   	push   %eax
f0102f07:	6a 52                	push   $0x52
f0102f09:	8d 83 ac da fe ff    	lea    -0x12554(%ebx),%eax
f0102f0f:	50                   	push   %eax
f0102f10:	e8 84 d1 ff ff       	call   f0100099 <_panic>
f0102f15:	50                   	push   %eax
f0102f16:	8d 83 78 d2 fe ff    	lea    -0x12d88(%ebx),%eax
f0102f1c:	50                   	push   %eax
f0102f1d:	6a 52                	push   $0x52
f0102f1f:	8d 83 ac da fe ff    	lea    -0x12554(%ebx),%eax
f0102f25:	50                   	push   %eax
f0102f26:	e8 6e d1 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102f2b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f2e:	8d 83 17 dc fe ff    	lea    -0x123e9(%ebx),%eax
f0102f34:	50                   	push   %eax
f0102f35:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102f3b:	50                   	push   %eax
f0102f3c:	68 c8 03 00 00       	push   $0x3c8
f0102f41:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102f47:	50                   	push   %eax
f0102f48:	e8 4c d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102f4d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f50:	8d 83 00 da fe ff    	lea    -0x12600(%ebx),%eax
f0102f56:	50                   	push   %eax
f0102f57:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102f5d:	50                   	push   %eax
f0102f5e:	68 c9 03 00 00       	push   $0x3c9
f0102f63:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102f69:	50                   	push   %eax
f0102f6a:	e8 2a d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102f6f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f72:	8d 83 24 da fe ff    	lea    -0x125dc(%ebx),%eax
f0102f78:	50                   	push   %eax
f0102f79:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102f7f:	50                   	push   %eax
f0102f80:	68 cb 03 00 00       	push   $0x3cb
f0102f85:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102f8b:	50                   	push   %eax
f0102f8c:	e8 08 d1 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102f91:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f94:	8d 83 39 dc fe ff    	lea    -0x123c7(%ebx),%eax
f0102f9a:	50                   	push   %eax
f0102f9b:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102fa1:	50                   	push   %eax
f0102fa2:	68 cc 03 00 00       	push   $0x3cc
f0102fa7:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102fad:	50                   	push   %eax
f0102fae:	e8 e6 d0 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102fb3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fb6:	8d 83 a3 dc fe ff    	lea    -0x1235d(%ebx),%eax
f0102fbc:	50                   	push   %eax
f0102fbd:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102fc3:	50                   	push   %eax
f0102fc4:	68 cd 03 00 00       	push   $0x3cd
f0102fc9:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0102fcf:	50                   	push   %eax
f0102fd0:	e8 c4 d0 ff ff       	call   f0100099 <_panic>
f0102fd5:	50                   	push   %eax
f0102fd6:	8d 83 78 d2 fe ff    	lea    -0x12d88(%ebx),%eax
f0102fdc:	50                   	push   %eax
f0102fdd:	6a 52                	push   $0x52
f0102fdf:	8d 83 ac da fe ff    	lea    -0x12554(%ebx),%eax
f0102fe5:	50                   	push   %eax
f0102fe6:	e8 ae d0 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102feb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fee:	8d 83 48 da fe ff    	lea    -0x125b8(%ebx),%eax
f0102ff4:	50                   	push   %eax
f0102ff5:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0102ffb:	50                   	push   %eax
f0102ffc:	68 cf 03 00 00       	push   $0x3cf
f0103001:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0103007:	50                   	push   %eax
f0103008:	e8 8c d0 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f010300d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103010:	8d 83 71 dc fe ff    	lea    -0x1238f(%ebx),%eax
f0103016:	50                   	push   %eax
f0103017:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010301d:	50                   	push   %eax
f010301e:	68 d1 03 00 00       	push   $0x3d1
f0103023:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f0103029:	50                   	push   %eax
f010302a:	e8 6a d0 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010302f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103032:	8d 83 88 d5 fe ff    	lea    -0x12a78(%ebx),%eax
f0103038:	50                   	push   %eax
f0103039:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f010303f:	50                   	push   %eax
f0103040:	68 d4 03 00 00       	push   $0x3d4
f0103045:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010304b:	50                   	push   %eax
f010304c:	e8 48 d0 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0103051:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103054:	8d 83 28 dc fe ff    	lea    -0x123d8(%ebx),%eax
f010305a:	50                   	push   %eax
f010305b:	8d 83 c6 da fe ff    	lea    -0x1253a(%ebx),%eax
f0103061:	50                   	push   %eax
f0103062:	68 d6 03 00 00       	push   $0x3d6
f0103067:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010306d:	50                   	push   %eax
f010306e:	e8 26 d0 ff ff       	call   f0100099 <_panic>

f0103073 <tlb_invalidate>:
{
f0103073:	55                   	push   %ebp
f0103074:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0103076:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103079:	0f 01 38             	invlpg (%eax)
}
f010307c:	5d                   	pop    %ebp
f010307d:	c3                   	ret    

f010307e <__x86.get_pc_thunk.cx>:
f010307e:	8b 0c 24             	mov    (%esp),%ecx
f0103081:	c3                   	ret    

f0103082 <__x86.get_pc_thunk.di>:
f0103082:	8b 3c 24             	mov    (%esp),%edi
f0103085:	c3                   	ret    

f0103086 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103086:	55                   	push   %ebp
f0103087:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103089:	8b 45 08             	mov    0x8(%ebp),%eax
f010308c:	ba 70 00 00 00       	mov    $0x70,%edx
f0103091:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103092:	ba 71 00 00 00       	mov    $0x71,%edx
f0103097:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103098:	0f b6 c0             	movzbl %al,%eax
}
f010309b:	5d                   	pop    %ebp
f010309c:	c3                   	ret    

f010309d <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010309d:	55                   	push   %ebp
f010309e:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01030a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01030a3:	ba 70 00 00 00       	mov    $0x70,%edx
f01030a8:	ee                   	out    %al,(%dx)
f01030a9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030ac:	ba 71 00 00 00       	mov    $0x71,%edx
f01030b1:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01030b2:	5d                   	pop    %ebp
f01030b3:	c3                   	ret    

f01030b4 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01030b4:	55                   	push   %ebp
f01030b5:	89 e5                	mov    %esp,%ebp
f01030b7:	53                   	push   %ebx
f01030b8:	83 ec 10             	sub    $0x10,%esp
f01030bb:	e8 8f d0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01030c0:	81 c3 4c 42 01 00    	add    $0x1424c,%ebx
	cputchar(ch);
f01030c6:	ff 75 08             	pushl  0x8(%ebp)
f01030c9:	e8 f8 d5 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f01030ce:	83 c4 10             	add    $0x10,%esp
f01030d1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030d4:	c9                   	leave  
f01030d5:	c3                   	ret    

f01030d6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01030d6:	55                   	push   %ebp
f01030d7:	89 e5                	mov    %esp,%ebp
f01030d9:	53                   	push   %ebx
f01030da:	83 ec 14             	sub    $0x14,%esp
f01030dd:	e8 6d d0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01030e2:	81 c3 2a 42 01 00    	add    $0x1422a,%ebx
	int cnt = 0;
f01030e8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01030ef:	ff 75 0c             	pushl  0xc(%ebp)
f01030f2:	ff 75 08             	pushl  0x8(%ebp)
f01030f5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01030f8:	50                   	push   %eax
f01030f9:	8d 83 a8 bd fe ff    	lea    -0x14258(%ebx),%eax
f01030ff:	50                   	push   %eax
f0103100:	e8 18 04 00 00       	call   f010351d <vprintfmt>
	return cnt;
}
f0103105:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103108:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010310b:	c9                   	leave  
f010310c:	c3                   	ret    

f010310d <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010310d:	55                   	push   %ebp
f010310e:	89 e5                	mov    %esp,%ebp
f0103110:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103113:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103116:	50                   	push   %eax
f0103117:	ff 75 08             	pushl  0x8(%ebp)
f010311a:	e8 b7 ff ff ff       	call   f01030d6 <vcprintf>
	va_end(ap);

	return cnt;
}
f010311f:	c9                   	leave  
f0103120:	c3                   	ret    

f0103121 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103121:	55                   	push   %ebp
f0103122:	89 e5                	mov    %esp,%ebp
f0103124:	57                   	push   %edi
f0103125:	56                   	push   %esi
f0103126:	53                   	push   %ebx
f0103127:	83 ec 14             	sub    $0x14,%esp
f010312a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010312d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103130:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103133:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103136:	8b 32                	mov    (%edx),%esi
f0103138:	8b 01                	mov    (%ecx),%eax
f010313a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010313d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103144:	eb 2f                	jmp    f0103175 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103146:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0103149:	39 c6                	cmp    %eax,%esi
f010314b:	7f 49                	jg     f0103196 <stab_binsearch+0x75>
f010314d:	0f b6 0a             	movzbl (%edx),%ecx
f0103150:	83 ea 0c             	sub    $0xc,%edx
f0103153:	39 f9                	cmp    %edi,%ecx
f0103155:	75 ef                	jne    f0103146 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103157:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010315a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010315d:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103161:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103164:	73 35                	jae    f010319b <stab_binsearch+0x7a>
			*region_left = m;
f0103166:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103169:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f010316b:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f010316e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0103175:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0103178:	7f 4e                	jg     f01031c8 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f010317a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010317d:	01 f0                	add    %esi,%eax
f010317f:	89 c3                	mov    %eax,%ebx
f0103181:	c1 eb 1f             	shr    $0x1f,%ebx
f0103184:	01 c3                	add    %eax,%ebx
f0103186:	d1 fb                	sar    %ebx
f0103188:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010318b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010318e:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0103192:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0103194:	eb b3                	jmp    f0103149 <stab_binsearch+0x28>
			l = true_m + 1;
f0103196:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0103199:	eb da                	jmp    f0103175 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f010319b:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010319e:	76 14                	jbe    f01031b4 <stab_binsearch+0x93>
			*region_right = m - 1;
f01031a0:	83 e8 01             	sub    $0x1,%eax
f01031a3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01031a6:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01031a9:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f01031ab:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01031b2:	eb c1                	jmp    f0103175 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01031b4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01031b7:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01031b9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01031bd:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f01031bf:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01031c6:	eb ad                	jmp    f0103175 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f01031c8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01031cc:	74 16                	je     f01031e4 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01031ce:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031d1:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01031d3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01031d6:	8b 0e                	mov    (%esi),%ecx
f01031d8:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01031db:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01031de:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f01031e2:	eb 12                	jmp    f01031f6 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f01031e4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031e7:	8b 00                	mov    (%eax),%eax
f01031e9:	83 e8 01             	sub    $0x1,%eax
f01031ec:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01031ef:	89 07                	mov    %eax,(%edi)
f01031f1:	eb 16                	jmp    f0103209 <stab_binsearch+0xe8>
		     l--)
f01031f3:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f01031f6:	39 c1                	cmp    %eax,%ecx
f01031f8:	7d 0a                	jge    f0103204 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f01031fa:	0f b6 1a             	movzbl (%edx),%ebx
f01031fd:	83 ea 0c             	sub    $0xc,%edx
f0103200:	39 fb                	cmp    %edi,%ebx
f0103202:	75 ef                	jne    f01031f3 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0103204:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103207:	89 07                	mov    %eax,(%edi)
	}
}
f0103209:	83 c4 14             	add    $0x14,%esp
f010320c:	5b                   	pop    %ebx
f010320d:	5e                   	pop    %esi
f010320e:	5f                   	pop    %edi
f010320f:	5d                   	pop    %ebp
f0103210:	c3                   	ret    

f0103211 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103211:	55                   	push   %ebp
f0103212:	89 e5                	mov    %esp,%ebp
f0103214:	57                   	push   %edi
f0103215:	56                   	push   %esi
f0103216:	53                   	push   %ebx
f0103217:	83 ec 2c             	sub    $0x2c,%esp
f010321a:	e8 5f fe ff ff       	call   f010307e <__x86.get_pc_thunk.cx>
f010321f:	81 c1 ed 40 01 00    	add    $0x140ed,%ecx
f0103225:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0103228:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010322b:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010322e:	8d 81 2c dd fe ff    	lea    -0x122d4(%ecx),%eax
f0103234:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0103236:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f010323d:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0103240:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0103247:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f010324a:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103251:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0103257:	0f 86 f4 00 00 00    	jbe    f0103351 <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010325d:	c7 c0 91 ba 10 f0    	mov    $0xf010ba91,%eax
f0103263:	39 81 f8 ff ff ff    	cmp    %eax,-0x8(%ecx)
f0103269:	0f 86 88 01 00 00    	jbe    f01033f7 <debuginfo_eip+0x1e6>
f010326f:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0103272:	c7 c0 b4 d8 10 f0    	mov    $0xf010d8b4,%eax
f0103278:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f010327c:	0f 85 7c 01 00 00    	jne    f01033fe <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103282:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103289:	c7 c0 50 52 10 f0    	mov    $0xf0105250,%eax
f010328f:	c7 c2 90 ba 10 f0    	mov    $0xf010ba90,%edx
f0103295:	29 c2                	sub    %eax,%edx
f0103297:	c1 fa 02             	sar    $0x2,%edx
f010329a:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01032a0:	83 ea 01             	sub    $0x1,%edx
f01032a3:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01032a6:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01032a9:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01032ac:	83 ec 08             	sub    $0x8,%esp
f01032af:	53                   	push   %ebx
f01032b0:	6a 64                	push   $0x64
f01032b2:	e8 6a fe ff ff       	call   f0103121 <stab_binsearch>
	if (lfile == 0)
f01032b7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032ba:	83 c4 10             	add    $0x10,%esp
f01032bd:	85 c0                	test   %eax,%eax
f01032bf:	0f 84 40 01 00 00    	je     f0103405 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01032c5:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01032c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032cb:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01032ce:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01032d1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01032d4:	83 ec 08             	sub    $0x8,%esp
f01032d7:	53                   	push   %ebx
f01032d8:	6a 24                	push   $0x24
f01032da:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01032dd:	c7 c0 50 52 10 f0    	mov    $0xf0105250,%eax
f01032e3:	e8 39 fe ff ff       	call   f0103121 <stab_binsearch>

	if (lfun <= rfun) {
f01032e8:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01032eb:	83 c4 10             	add    $0x10,%esp
f01032ee:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f01032f1:	7f 79                	jg     f010336c <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01032f3:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01032f6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01032f9:	c7 c2 50 52 10 f0    	mov    $0xf0105250,%edx
f01032ff:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0103302:	8b 11                	mov    (%ecx),%edx
f0103304:	c7 c0 b4 d8 10 f0    	mov    $0xf010d8b4,%eax
f010330a:	81 e8 91 ba 10 f0    	sub    $0xf010ba91,%eax
f0103310:	39 c2                	cmp    %eax,%edx
f0103312:	73 09                	jae    f010331d <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103314:	81 c2 91 ba 10 f0    	add    $0xf010ba91,%edx
f010331a:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010331d:	8b 41 08             	mov    0x8(%ecx),%eax
f0103320:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103323:	83 ec 08             	sub    $0x8,%esp
f0103326:	6a 3a                	push   $0x3a
f0103328:	ff 77 08             	pushl  0x8(%edi)
f010332b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010332e:	e8 4f 09 00 00       	call   f0103c82 <strfind>
f0103333:	2b 47 08             	sub    0x8(%edi),%eax
f0103336:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103339:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010333c:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010333f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103342:	c7 c2 50 52 10 f0    	mov    $0xf0105250,%edx
f0103348:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f010334c:	83 c4 10             	add    $0x10,%esp
f010334f:	eb 29                	jmp    f010337a <debuginfo_eip+0x169>
  	        panic("User address");
f0103351:	83 ec 04             	sub    $0x4,%esp
f0103354:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103357:	8d 83 36 dd fe ff    	lea    -0x122ca(%ebx),%eax
f010335d:	50                   	push   %eax
f010335e:	6a 7f                	push   $0x7f
f0103360:	8d 83 43 dd fe ff    	lea    -0x122bd(%ebx),%eax
f0103366:	50                   	push   %eax
f0103367:	e8 2d cd ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f010336c:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f010336f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103372:	eb af                	jmp    f0103323 <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103374:	83 ee 01             	sub    $0x1,%esi
f0103377:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f010337a:	39 f3                	cmp    %esi,%ebx
f010337c:	7f 3a                	jg     f01033b8 <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f010337e:	0f b6 10             	movzbl (%eax),%edx
f0103381:	80 fa 84             	cmp    $0x84,%dl
f0103384:	74 0b                	je     f0103391 <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103386:	80 fa 64             	cmp    $0x64,%dl
f0103389:	75 e9                	jne    f0103374 <debuginfo_eip+0x163>
f010338b:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f010338f:	74 e3                	je     f0103374 <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103391:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0103394:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103397:	c7 c0 50 52 10 f0    	mov    $0xf0105250,%eax
f010339d:	8b 14 90             	mov    (%eax,%edx,4),%edx
f01033a0:	c7 c0 b4 d8 10 f0    	mov    $0xf010d8b4,%eax
f01033a6:	81 e8 91 ba 10 f0    	sub    $0xf010ba91,%eax
f01033ac:	39 c2                	cmp    %eax,%edx
f01033ae:	73 08                	jae    f01033b8 <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01033b0:	81 c2 91 ba 10 f0    	add    $0xf010ba91,%edx
f01033b6:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01033b8:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01033bb:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01033be:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01033c3:	39 cb                	cmp    %ecx,%ebx
f01033c5:	7d 4a                	jge    f0103411 <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f01033c7:	8d 53 01             	lea    0x1(%ebx),%edx
f01033ca:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f01033cd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01033d0:	c7 c0 50 52 10 f0    	mov    $0xf0105250,%eax
f01033d6:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f01033da:	eb 07                	jmp    f01033e3 <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f01033dc:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f01033e0:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f01033e3:	39 d1                	cmp    %edx,%ecx
f01033e5:	74 25                	je     f010340c <debuginfo_eip+0x1fb>
f01033e7:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01033ea:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f01033ee:	74 ec                	je     f01033dc <debuginfo_eip+0x1cb>
	return 0;
f01033f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01033f5:	eb 1a                	jmp    f0103411 <debuginfo_eip+0x200>
		return -1;
f01033f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01033fc:	eb 13                	jmp    f0103411 <debuginfo_eip+0x200>
f01033fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103403:	eb 0c                	jmp    f0103411 <debuginfo_eip+0x200>
		return -1;
f0103405:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010340a:	eb 05                	jmp    f0103411 <debuginfo_eip+0x200>
	return 0;
f010340c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103411:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103414:	5b                   	pop    %ebx
f0103415:	5e                   	pop    %esi
f0103416:	5f                   	pop    %edi
f0103417:	5d                   	pop    %ebp
f0103418:	c3                   	ret    

f0103419 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103419:	55                   	push   %ebp
f010341a:	89 e5                	mov    %esp,%ebp
f010341c:	57                   	push   %edi
f010341d:	56                   	push   %esi
f010341e:	53                   	push   %ebx
f010341f:	83 ec 2c             	sub    $0x2c,%esp
f0103422:	e8 57 fc ff ff       	call   f010307e <__x86.get_pc_thunk.cx>
f0103427:	81 c1 e5 3e 01 00    	add    $0x13ee5,%ecx
f010342d:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0103430:	89 c7                	mov    %eax,%edi
f0103432:	89 d6                	mov    %edx,%esi
f0103434:	8b 45 08             	mov    0x8(%ebp),%eax
f0103437:	8b 55 0c             	mov    0xc(%ebp),%edx
f010343a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010343d:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103440:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103443:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103448:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f010344b:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010344e:	39 d3                	cmp    %edx,%ebx
f0103450:	72 09                	jb     f010345b <printnum+0x42>
f0103452:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103455:	0f 87 83 00 00 00    	ja     f01034de <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010345b:	83 ec 0c             	sub    $0xc,%esp
f010345e:	ff 75 18             	pushl  0x18(%ebp)
f0103461:	8b 45 14             	mov    0x14(%ebp),%eax
f0103464:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103467:	53                   	push   %ebx
f0103468:	ff 75 10             	pushl  0x10(%ebp)
f010346b:	83 ec 08             	sub    $0x8,%esp
f010346e:	ff 75 dc             	pushl  -0x24(%ebp)
f0103471:	ff 75 d8             	pushl  -0x28(%ebp)
f0103474:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103477:	ff 75 d0             	pushl  -0x30(%ebp)
f010347a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010347d:	e8 1e 0a 00 00       	call   f0103ea0 <__udivdi3>
f0103482:	83 c4 18             	add    $0x18,%esp
f0103485:	52                   	push   %edx
f0103486:	50                   	push   %eax
f0103487:	89 f2                	mov    %esi,%edx
f0103489:	89 f8                	mov    %edi,%eax
f010348b:	e8 89 ff ff ff       	call   f0103419 <printnum>
f0103490:	83 c4 20             	add    $0x20,%esp
f0103493:	eb 13                	jmp    f01034a8 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103495:	83 ec 08             	sub    $0x8,%esp
f0103498:	56                   	push   %esi
f0103499:	ff 75 18             	pushl  0x18(%ebp)
f010349c:	ff d7                	call   *%edi
f010349e:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f01034a1:	83 eb 01             	sub    $0x1,%ebx
f01034a4:	85 db                	test   %ebx,%ebx
f01034a6:	7f ed                	jg     f0103495 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01034a8:	83 ec 08             	sub    $0x8,%esp
f01034ab:	56                   	push   %esi
f01034ac:	83 ec 04             	sub    $0x4,%esp
f01034af:	ff 75 dc             	pushl  -0x24(%ebp)
f01034b2:	ff 75 d8             	pushl  -0x28(%ebp)
f01034b5:	ff 75 d4             	pushl  -0x2c(%ebp)
f01034b8:	ff 75 d0             	pushl  -0x30(%ebp)
f01034bb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01034be:	89 f3                	mov    %esi,%ebx
f01034c0:	e8 fb 0a 00 00       	call   f0103fc0 <__umoddi3>
f01034c5:	83 c4 14             	add    $0x14,%esp
f01034c8:	0f be 84 06 51 dd fe 	movsbl -0x122af(%esi,%eax,1),%eax
f01034cf:	ff 
f01034d0:	50                   	push   %eax
f01034d1:	ff d7                	call   *%edi
}
f01034d3:	83 c4 10             	add    $0x10,%esp
f01034d6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01034d9:	5b                   	pop    %ebx
f01034da:	5e                   	pop    %esi
f01034db:	5f                   	pop    %edi
f01034dc:	5d                   	pop    %ebp
f01034dd:	c3                   	ret    
f01034de:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01034e1:	eb be                	jmp    f01034a1 <printnum+0x88>

f01034e3 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01034e3:	55                   	push   %ebp
f01034e4:	89 e5                	mov    %esp,%ebp
f01034e6:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01034e9:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01034ed:	8b 10                	mov    (%eax),%edx
f01034ef:	3b 50 04             	cmp    0x4(%eax),%edx
f01034f2:	73 0a                	jae    f01034fe <sprintputch+0x1b>
		*b->buf++ = ch;
f01034f4:	8d 4a 01             	lea    0x1(%edx),%ecx
f01034f7:	89 08                	mov    %ecx,(%eax)
f01034f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01034fc:	88 02                	mov    %al,(%edx)
}
f01034fe:	5d                   	pop    %ebp
f01034ff:	c3                   	ret    

f0103500 <printfmt>:
{
f0103500:	55                   	push   %ebp
f0103501:	89 e5                	mov    %esp,%ebp
f0103503:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0103506:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103509:	50                   	push   %eax
f010350a:	ff 75 10             	pushl  0x10(%ebp)
f010350d:	ff 75 0c             	pushl  0xc(%ebp)
f0103510:	ff 75 08             	pushl  0x8(%ebp)
f0103513:	e8 05 00 00 00       	call   f010351d <vprintfmt>
}
f0103518:	83 c4 10             	add    $0x10,%esp
f010351b:	c9                   	leave  
f010351c:	c3                   	ret    

f010351d <vprintfmt>:
{
f010351d:	55                   	push   %ebp
f010351e:	89 e5                	mov    %esp,%ebp
f0103520:	57                   	push   %edi
f0103521:	56                   	push   %esi
f0103522:	53                   	push   %ebx
f0103523:	83 ec 2c             	sub    $0x2c,%esp
f0103526:	e8 24 cc ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010352b:	81 c3 e1 3d 01 00    	add    $0x13de1,%ebx
f0103531:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103534:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103537:	e9 c3 03 00 00       	jmp    f01038ff <.L35+0x48>
		padc = ' ';
f010353c:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0103540:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0103547:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f010354e:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0103555:	b9 00 00 00 00       	mov    $0x0,%ecx
f010355a:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010355d:	8d 47 01             	lea    0x1(%edi),%eax
f0103560:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103563:	0f b6 17             	movzbl (%edi),%edx
f0103566:	8d 42 dd             	lea    -0x23(%edx),%eax
f0103569:	3c 55                	cmp    $0x55,%al
f010356b:	0f 87 16 04 00 00    	ja     f0103987 <.L22>
f0103571:	0f b6 c0             	movzbl %al,%eax
f0103574:	89 d9                	mov    %ebx,%ecx
f0103576:	03 8c 83 dc dd fe ff 	add    -0x12224(%ebx,%eax,4),%ecx
f010357d:	ff e1                	jmp    *%ecx

f010357f <.L69>:
f010357f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0103582:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0103586:	eb d5                	jmp    f010355d <vprintfmt+0x40>

f0103588 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0103588:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f010358b:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010358f:	eb cc                	jmp    f010355d <vprintfmt+0x40>

f0103591 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0103591:	0f b6 d2             	movzbl %dl,%edx
f0103594:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0103597:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f010359c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010359f:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01035a3:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01035a6:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01035a9:	83 f9 09             	cmp    $0x9,%ecx
f01035ac:	77 55                	ja     f0103603 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f01035ae:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01035b1:	eb e9                	jmp    f010359c <.L29+0xb>

f01035b3 <.L26>:
			precision = va_arg(ap, int);
f01035b3:	8b 45 14             	mov    0x14(%ebp),%eax
f01035b6:	8b 00                	mov    (%eax),%eax
f01035b8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01035bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01035be:	8d 40 04             	lea    0x4(%eax),%eax
f01035c1:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01035c4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f01035c7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01035cb:	79 90                	jns    f010355d <vprintfmt+0x40>
				width = precision, precision = -1;
f01035cd:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01035d0:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01035d3:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f01035da:	eb 81                	jmp    f010355d <vprintfmt+0x40>

f01035dc <.L27>:
f01035dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01035df:	85 c0                	test   %eax,%eax
f01035e1:	ba 00 00 00 00       	mov    $0x0,%edx
f01035e6:	0f 49 d0             	cmovns %eax,%edx
f01035e9:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01035ec:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01035ef:	e9 69 ff ff ff       	jmp    f010355d <vprintfmt+0x40>

f01035f4 <.L23>:
f01035f4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f01035f7:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01035fe:	e9 5a ff ff ff       	jmp    f010355d <vprintfmt+0x40>
f0103603:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103606:	eb bf                	jmp    f01035c7 <.L26+0x14>

f0103608 <.L33>:
			lflag++;
f0103608:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010360c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f010360f:	e9 49 ff ff ff       	jmp    f010355d <vprintfmt+0x40>

f0103614 <.L30>:
			putch(va_arg(ap, int), putdat);
f0103614:	8b 45 14             	mov    0x14(%ebp),%eax
f0103617:	8d 78 04             	lea    0x4(%eax),%edi
f010361a:	83 ec 08             	sub    $0x8,%esp
f010361d:	56                   	push   %esi
f010361e:	ff 30                	pushl  (%eax)
f0103620:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103623:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0103626:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0103629:	e9 ce 02 00 00       	jmp    f01038fc <.L35+0x45>

f010362e <.L32>:
			err = va_arg(ap, int);
f010362e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103631:	8d 78 04             	lea    0x4(%eax),%edi
f0103634:	8b 00                	mov    (%eax),%eax
f0103636:	99                   	cltd   
f0103637:	31 d0                	xor    %edx,%eax
f0103639:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010363b:	83 f8 06             	cmp    $0x6,%eax
f010363e:	7f 27                	jg     f0103667 <.L32+0x39>
f0103640:	8b 94 83 1c 1d 00 00 	mov    0x1d1c(%ebx,%eax,4),%edx
f0103647:	85 d2                	test   %edx,%edx
f0103649:	74 1c                	je     f0103667 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f010364b:	52                   	push   %edx
f010364c:	8d 83 d8 da fe ff    	lea    -0x12528(%ebx),%eax
f0103652:	50                   	push   %eax
f0103653:	56                   	push   %esi
f0103654:	ff 75 08             	pushl  0x8(%ebp)
f0103657:	e8 a4 fe ff ff       	call   f0103500 <printfmt>
f010365c:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010365f:	89 7d 14             	mov    %edi,0x14(%ebp)
f0103662:	e9 95 02 00 00       	jmp    f01038fc <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0103667:	50                   	push   %eax
f0103668:	8d 83 69 dd fe ff    	lea    -0x12297(%ebx),%eax
f010366e:	50                   	push   %eax
f010366f:	56                   	push   %esi
f0103670:	ff 75 08             	pushl  0x8(%ebp)
f0103673:	e8 88 fe ff ff       	call   f0103500 <printfmt>
f0103678:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010367b:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010367e:	e9 79 02 00 00       	jmp    f01038fc <.L35+0x45>

f0103683 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0103683:	8b 45 14             	mov    0x14(%ebp),%eax
f0103686:	83 c0 04             	add    $0x4,%eax
f0103689:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010368c:	8b 45 14             	mov    0x14(%ebp),%eax
f010368f:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103691:	85 ff                	test   %edi,%edi
f0103693:	8d 83 62 dd fe ff    	lea    -0x1229e(%ebx),%eax
f0103699:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010369c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01036a0:	0f 8e b5 00 00 00    	jle    f010375b <.L36+0xd8>
f01036a6:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01036aa:	75 08                	jne    f01036b4 <.L36+0x31>
f01036ac:	89 75 0c             	mov    %esi,0xc(%ebp)
f01036af:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01036b2:	eb 6d                	jmp    f0103721 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f01036b4:	83 ec 08             	sub    $0x8,%esp
f01036b7:	ff 75 cc             	pushl  -0x34(%ebp)
f01036ba:	57                   	push   %edi
f01036bb:	e8 7e 04 00 00       	call   f0103b3e <strnlen>
f01036c0:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01036c3:	29 c2                	sub    %eax,%edx
f01036c5:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01036c8:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01036cb:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01036cf:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01036d2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01036d5:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f01036d7:	eb 10                	jmp    f01036e9 <.L36+0x66>
					putch(padc, putdat);
f01036d9:	83 ec 08             	sub    $0x8,%esp
f01036dc:	56                   	push   %esi
f01036dd:	ff 75 e0             	pushl  -0x20(%ebp)
f01036e0:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f01036e3:	83 ef 01             	sub    $0x1,%edi
f01036e6:	83 c4 10             	add    $0x10,%esp
f01036e9:	85 ff                	test   %edi,%edi
f01036eb:	7f ec                	jg     f01036d9 <.L36+0x56>
f01036ed:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01036f0:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01036f3:	85 d2                	test   %edx,%edx
f01036f5:	b8 00 00 00 00       	mov    $0x0,%eax
f01036fa:	0f 49 c2             	cmovns %edx,%eax
f01036fd:	29 c2                	sub    %eax,%edx
f01036ff:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0103702:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103705:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103708:	eb 17                	jmp    f0103721 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f010370a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010370e:	75 30                	jne    f0103740 <.L36+0xbd>
					putch(ch, putdat);
f0103710:	83 ec 08             	sub    $0x8,%esp
f0103713:	ff 75 0c             	pushl  0xc(%ebp)
f0103716:	50                   	push   %eax
f0103717:	ff 55 08             	call   *0x8(%ebp)
f010371a:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010371d:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0103721:	83 c7 01             	add    $0x1,%edi
f0103724:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0103728:	0f be c2             	movsbl %dl,%eax
f010372b:	85 c0                	test   %eax,%eax
f010372d:	74 52                	je     f0103781 <.L36+0xfe>
f010372f:	85 f6                	test   %esi,%esi
f0103731:	78 d7                	js     f010370a <.L36+0x87>
f0103733:	83 ee 01             	sub    $0x1,%esi
f0103736:	79 d2                	jns    f010370a <.L36+0x87>
f0103738:	8b 75 0c             	mov    0xc(%ebp),%esi
f010373b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010373e:	eb 32                	jmp    f0103772 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f0103740:	0f be d2             	movsbl %dl,%edx
f0103743:	83 ea 20             	sub    $0x20,%edx
f0103746:	83 fa 5e             	cmp    $0x5e,%edx
f0103749:	76 c5                	jbe    f0103710 <.L36+0x8d>
					putch('?', putdat);
f010374b:	83 ec 08             	sub    $0x8,%esp
f010374e:	ff 75 0c             	pushl  0xc(%ebp)
f0103751:	6a 3f                	push   $0x3f
f0103753:	ff 55 08             	call   *0x8(%ebp)
f0103756:	83 c4 10             	add    $0x10,%esp
f0103759:	eb c2                	jmp    f010371d <.L36+0x9a>
f010375b:	89 75 0c             	mov    %esi,0xc(%ebp)
f010375e:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103761:	eb be                	jmp    f0103721 <.L36+0x9e>
				putch(' ', putdat);
f0103763:	83 ec 08             	sub    $0x8,%esp
f0103766:	56                   	push   %esi
f0103767:	6a 20                	push   $0x20
f0103769:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f010376c:	83 ef 01             	sub    $0x1,%edi
f010376f:	83 c4 10             	add    $0x10,%esp
f0103772:	85 ff                	test   %edi,%edi
f0103774:	7f ed                	jg     f0103763 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0103776:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103779:	89 45 14             	mov    %eax,0x14(%ebp)
f010377c:	e9 7b 01 00 00       	jmp    f01038fc <.L35+0x45>
f0103781:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103784:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103787:	eb e9                	jmp    f0103772 <.L36+0xef>

f0103789 <.L31>:
f0103789:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010378c:	83 f9 01             	cmp    $0x1,%ecx
f010378f:	7e 40                	jle    f01037d1 <.L31+0x48>
		return va_arg(*ap, long long);
f0103791:	8b 45 14             	mov    0x14(%ebp),%eax
f0103794:	8b 50 04             	mov    0x4(%eax),%edx
f0103797:	8b 00                	mov    (%eax),%eax
f0103799:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010379c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010379f:	8b 45 14             	mov    0x14(%ebp),%eax
f01037a2:	8d 40 08             	lea    0x8(%eax),%eax
f01037a5:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01037a8:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01037ac:	79 55                	jns    f0103803 <.L31+0x7a>
				putch('-', putdat);
f01037ae:	83 ec 08             	sub    $0x8,%esp
f01037b1:	56                   	push   %esi
f01037b2:	6a 2d                	push   $0x2d
f01037b4:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01037b7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01037ba:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01037bd:	f7 da                	neg    %edx
f01037bf:	83 d1 00             	adc    $0x0,%ecx
f01037c2:	f7 d9                	neg    %ecx
f01037c4:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01037c7:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037cc:	e9 10 01 00 00       	jmp    f01038e1 <.L35+0x2a>
	else if (lflag)
f01037d1:	85 c9                	test   %ecx,%ecx
f01037d3:	75 17                	jne    f01037ec <.L31+0x63>
		return va_arg(*ap, int);
f01037d5:	8b 45 14             	mov    0x14(%ebp),%eax
f01037d8:	8b 00                	mov    (%eax),%eax
f01037da:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01037dd:	99                   	cltd   
f01037de:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01037e1:	8b 45 14             	mov    0x14(%ebp),%eax
f01037e4:	8d 40 04             	lea    0x4(%eax),%eax
f01037e7:	89 45 14             	mov    %eax,0x14(%ebp)
f01037ea:	eb bc                	jmp    f01037a8 <.L31+0x1f>
		return va_arg(*ap, long);
f01037ec:	8b 45 14             	mov    0x14(%ebp),%eax
f01037ef:	8b 00                	mov    (%eax),%eax
f01037f1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01037f4:	99                   	cltd   
f01037f5:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01037f8:	8b 45 14             	mov    0x14(%ebp),%eax
f01037fb:	8d 40 04             	lea    0x4(%eax),%eax
f01037fe:	89 45 14             	mov    %eax,0x14(%ebp)
f0103801:	eb a5                	jmp    f01037a8 <.L31+0x1f>
			num = getint(&ap, lflag);
f0103803:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103806:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0103809:	b8 0a 00 00 00       	mov    $0xa,%eax
f010380e:	e9 ce 00 00 00       	jmp    f01038e1 <.L35+0x2a>

f0103813 <.L37>:
f0103813:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103816:	83 f9 01             	cmp    $0x1,%ecx
f0103819:	7e 18                	jle    f0103833 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f010381b:	8b 45 14             	mov    0x14(%ebp),%eax
f010381e:	8b 10                	mov    (%eax),%edx
f0103820:	8b 48 04             	mov    0x4(%eax),%ecx
f0103823:	8d 40 08             	lea    0x8(%eax),%eax
f0103826:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103829:	b8 0a 00 00 00       	mov    $0xa,%eax
f010382e:	e9 ae 00 00 00       	jmp    f01038e1 <.L35+0x2a>
	else if (lflag)
f0103833:	85 c9                	test   %ecx,%ecx
f0103835:	75 1a                	jne    f0103851 <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f0103837:	8b 45 14             	mov    0x14(%ebp),%eax
f010383a:	8b 10                	mov    (%eax),%edx
f010383c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103841:	8d 40 04             	lea    0x4(%eax),%eax
f0103844:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103847:	b8 0a 00 00 00       	mov    $0xa,%eax
f010384c:	e9 90 00 00 00       	jmp    f01038e1 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103851:	8b 45 14             	mov    0x14(%ebp),%eax
f0103854:	8b 10                	mov    (%eax),%edx
f0103856:	b9 00 00 00 00       	mov    $0x0,%ecx
f010385b:	8d 40 04             	lea    0x4(%eax),%eax
f010385e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103861:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103866:	eb 79                	jmp    f01038e1 <.L35+0x2a>

f0103868 <.L34>:
f0103868:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010386b:	83 f9 01             	cmp    $0x1,%ecx
f010386e:	7e 15                	jle    f0103885 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f0103870:	8b 45 14             	mov    0x14(%ebp),%eax
f0103873:	8b 10                	mov    (%eax),%edx
f0103875:	8b 48 04             	mov    0x4(%eax),%ecx
f0103878:	8d 40 08             	lea    0x8(%eax),%eax
f010387b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010387e:	b8 08 00 00 00       	mov    $0x8,%eax
f0103883:	eb 5c                	jmp    f01038e1 <.L35+0x2a>
	else if (lflag)
f0103885:	85 c9                	test   %ecx,%ecx
f0103887:	75 17                	jne    f01038a0 <.L34+0x38>
		return va_arg(*ap, unsigned int);
f0103889:	8b 45 14             	mov    0x14(%ebp),%eax
f010388c:	8b 10                	mov    (%eax),%edx
f010388e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103893:	8d 40 04             	lea    0x4(%eax),%eax
f0103896:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103899:	b8 08 00 00 00       	mov    $0x8,%eax
f010389e:	eb 41                	jmp    f01038e1 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01038a0:	8b 45 14             	mov    0x14(%ebp),%eax
f01038a3:	8b 10                	mov    (%eax),%edx
f01038a5:	b9 00 00 00 00       	mov    $0x0,%ecx
f01038aa:	8d 40 04             	lea    0x4(%eax),%eax
f01038ad:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01038b0:	b8 08 00 00 00       	mov    $0x8,%eax
f01038b5:	eb 2a                	jmp    f01038e1 <.L35+0x2a>

f01038b7 <.L35>:
			putch('0', putdat);
f01038b7:	83 ec 08             	sub    $0x8,%esp
f01038ba:	56                   	push   %esi
f01038bb:	6a 30                	push   $0x30
f01038bd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01038c0:	83 c4 08             	add    $0x8,%esp
f01038c3:	56                   	push   %esi
f01038c4:	6a 78                	push   $0x78
f01038c6:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f01038c9:	8b 45 14             	mov    0x14(%ebp),%eax
f01038cc:	8b 10                	mov    (%eax),%edx
f01038ce:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f01038d3:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f01038d6:	8d 40 04             	lea    0x4(%eax),%eax
f01038d9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01038dc:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f01038e1:	83 ec 0c             	sub    $0xc,%esp
f01038e4:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01038e8:	57                   	push   %edi
f01038e9:	ff 75 e0             	pushl  -0x20(%ebp)
f01038ec:	50                   	push   %eax
f01038ed:	51                   	push   %ecx
f01038ee:	52                   	push   %edx
f01038ef:	89 f2                	mov    %esi,%edx
f01038f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01038f4:	e8 20 fb ff ff       	call   f0103419 <printnum>
			break;
f01038f9:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01038fc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01038ff:	83 c7 01             	add    $0x1,%edi
f0103902:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103906:	83 f8 25             	cmp    $0x25,%eax
f0103909:	0f 84 2d fc ff ff    	je     f010353c <vprintfmt+0x1f>
			if (ch == '\0')
f010390f:	85 c0                	test   %eax,%eax
f0103911:	0f 84 91 00 00 00    	je     f01039a8 <.L22+0x21>
			putch(ch, putdat);
f0103917:	83 ec 08             	sub    $0x8,%esp
f010391a:	56                   	push   %esi
f010391b:	50                   	push   %eax
f010391c:	ff 55 08             	call   *0x8(%ebp)
f010391f:	83 c4 10             	add    $0x10,%esp
f0103922:	eb db                	jmp    f01038ff <.L35+0x48>

f0103924 <.L38>:
f0103924:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103927:	83 f9 01             	cmp    $0x1,%ecx
f010392a:	7e 15                	jle    f0103941 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f010392c:	8b 45 14             	mov    0x14(%ebp),%eax
f010392f:	8b 10                	mov    (%eax),%edx
f0103931:	8b 48 04             	mov    0x4(%eax),%ecx
f0103934:	8d 40 08             	lea    0x8(%eax),%eax
f0103937:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010393a:	b8 10 00 00 00       	mov    $0x10,%eax
f010393f:	eb a0                	jmp    f01038e1 <.L35+0x2a>
	else if (lflag)
f0103941:	85 c9                	test   %ecx,%ecx
f0103943:	75 17                	jne    f010395c <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0103945:	8b 45 14             	mov    0x14(%ebp),%eax
f0103948:	8b 10                	mov    (%eax),%edx
f010394a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010394f:	8d 40 04             	lea    0x4(%eax),%eax
f0103952:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103955:	b8 10 00 00 00       	mov    $0x10,%eax
f010395a:	eb 85                	jmp    f01038e1 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010395c:	8b 45 14             	mov    0x14(%ebp),%eax
f010395f:	8b 10                	mov    (%eax),%edx
f0103961:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103966:	8d 40 04             	lea    0x4(%eax),%eax
f0103969:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010396c:	b8 10 00 00 00       	mov    $0x10,%eax
f0103971:	e9 6b ff ff ff       	jmp    f01038e1 <.L35+0x2a>

f0103976 <.L25>:
			putch(ch, putdat);
f0103976:	83 ec 08             	sub    $0x8,%esp
f0103979:	56                   	push   %esi
f010397a:	6a 25                	push   $0x25
f010397c:	ff 55 08             	call   *0x8(%ebp)
			break;
f010397f:	83 c4 10             	add    $0x10,%esp
f0103982:	e9 75 ff ff ff       	jmp    f01038fc <.L35+0x45>

f0103987 <.L22>:
			putch('%', putdat);
f0103987:	83 ec 08             	sub    $0x8,%esp
f010398a:	56                   	push   %esi
f010398b:	6a 25                	push   $0x25
f010398d:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103990:	83 c4 10             	add    $0x10,%esp
f0103993:	89 f8                	mov    %edi,%eax
f0103995:	eb 03                	jmp    f010399a <.L22+0x13>
f0103997:	83 e8 01             	sub    $0x1,%eax
f010399a:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f010399e:	75 f7                	jne    f0103997 <.L22+0x10>
f01039a0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01039a3:	e9 54 ff ff ff       	jmp    f01038fc <.L35+0x45>
}
f01039a8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01039ab:	5b                   	pop    %ebx
f01039ac:	5e                   	pop    %esi
f01039ad:	5f                   	pop    %edi
f01039ae:	5d                   	pop    %ebp
f01039af:	c3                   	ret    

f01039b0 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01039b0:	55                   	push   %ebp
f01039b1:	89 e5                	mov    %esp,%ebp
f01039b3:	53                   	push   %ebx
f01039b4:	83 ec 14             	sub    $0x14,%esp
f01039b7:	e8 93 c7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01039bc:	81 c3 50 39 01 00    	add    $0x13950,%ebx
f01039c2:	8b 45 08             	mov    0x8(%ebp),%eax
f01039c5:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01039c8:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01039cb:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01039cf:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01039d2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01039d9:	85 c0                	test   %eax,%eax
f01039db:	74 2b                	je     f0103a08 <vsnprintf+0x58>
f01039dd:	85 d2                	test   %edx,%edx
f01039df:	7e 27                	jle    f0103a08 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01039e1:	ff 75 14             	pushl  0x14(%ebp)
f01039e4:	ff 75 10             	pushl  0x10(%ebp)
f01039e7:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01039ea:	50                   	push   %eax
f01039eb:	8d 83 d7 c1 fe ff    	lea    -0x13e29(%ebx),%eax
f01039f1:	50                   	push   %eax
f01039f2:	e8 26 fb ff ff       	call   f010351d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01039f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01039fa:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01039fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103a00:	83 c4 10             	add    $0x10,%esp
}
f0103a03:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a06:	c9                   	leave  
f0103a07:	c3                   	ret    
		return -E_INVAL;
f0103a08:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103a0d:	eb f4                	jmp    f0103a03 <vsnprintf+0x53>

f0103a0f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103a0f:	55                   	push   %ebp
f0103a10:	89 e5                	mov    %esp,%ebp
f0103a12:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103a15:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103a18:	50                   	push   %eax
f0103a19:	ff 75 10             	pushl  0x10(%ebp)
f0103a1c:	ff 75 0c             	pushl  0xc(%ebp)
f0103a1f:	ff 75 08             	pushl  0x8(%ebp)
f0103a22:	e8 89 ff ff ff       	call   f01039b0 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103a27:	c9                   	leave  
f0103a28:	c3                   	ret    

f0103a29 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103a29:	55                   	push   %ebp
f0103a2a:	89 e5                	mov    %esp,%ebp
f0103a2c:	57                   	push   %edi
f0103a2d:	56                   	push   %esi
f0103a2e:	53                   	push   %ebx
f0103a2f:	83 ec 1c             	sub    $0x1c,%esp
f0103a32:	e8 18 c7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103a37:	81 c3 d5 38 01 00    	add    $0x138d5,%ebx
f0103a3d:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103a40:	85 c0                	test   %eax,%eax
f0103a42:	74 13                	je     f0103a57 <readline+0x2e>
		cprintf("%s", prompt);
f0103a44:	83 ec 08             	sub    $0x8,%esp
f0103a47:	50                   	push   %eax
f0103a48:	8d 83 d8 da fe ff    	lea    -0x12528(%ebx),%eax
f0103a4e:	50                   	push   %eax
f0103a4f:	e8 b9 f6 ff ff       	call   f010310d <cprintf>
f0103a54:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103a57:	83 ec 0c             	sub    $0xc,%esp
f0103a5a:	6a 00                	push   $0x0
f0103a5c:	e8 86 cc ff ff       	call   f01006e7 <iscons>
f0103a61:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a64:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103a67:	bf 00 00 00 00       	mov    $0x0,%edi
f0103a6c:	eb 46                	jmp    f0103ab4 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0103a6e:	83 ec 08             	sub    $0x8,%esp
f0103a71:	50                   	push   %eax
f0103a72:	8d 83 34 df fe ff    	lea    -0x120cc(%ebx),%eax
f0103a78:	50                   	push   %eax
f0103a79:	e8 8f f6 ff ff       	call   f010310d <cprintf>
			return NULL;
f0103a7e:	83 c4 10             	add    $0x10,%esp
f0103a81:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103a86:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a89:	5b                   	pop    %ebx
f0103a8a:	5e                   	pop    %esi
f0103a8b:	5f                   	pop    %edi
f0103a8c:	5d                   	pop    %ebp
f0103a8d:	c3                   	ret    
			if (echoing)
f0103a8e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103a92:	75 05                	jne    f0103a99 <readline+0x70>
			i--;
f0103a94:	83 ef 01             	sub    $0x1,%edi
f0103a97:	eb 1b                	jmp    f0103ab4 <readline+0x8b>
				cputchar('\b');
f0103a99:	83 ec 0c             	sub    $0xc,%esp
f0103a9c:	6a 08                	push   $0x8
f0103a9e:	e8 23 cc ff ff       	call   f01006c6 <cputchar>
f0103aa3:	83 c4 10             	add    $0x10,%esp
f0103aa6:	eb ec                	jmp    f0103a94 <readline+0x6b>
			buf[i++] = c;
f0103aa8:	89 f0                	mov    %esi,%eax
f0103aaa:	88 84 3b b4 1f 00 00 	mov    %al,0x1fb4(%ebx,%edi,1)
f0103ab1:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0103ab4:	e8 1d cc ff ff       	call   f01006d6 <getchar>
f0103ab9:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0103abb:	85 c0                	test   %eax,%eax
f0103abd:	78 af                	js     f0103a6e <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103abf:	83 f8 08             	cmp    $0x8,%eax
f0103ac2:	0f 94 c2             	sete   %dl
f0103ac5:	83 f8 7f             	cmp    $0x7f,%eax
f0103ac8:	0f 94 c0             	sete   %al
f0103acb:	08 c2                	or     %al,%dl
f0103acd:	74 04                	je     f0103ad3 <readline+0xaa>
f0103acf:	85 ff                	test   %edi,%edi
f0103ad1:	7f bb                	jg     f0103a8e <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103ad3:	83 fe 1f             	cmp    $0x1f,%esi
f0103ad6:	7e 1c                	jle    f0103af4 <readline+0xcb>
f0103ad8:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0103ade:	7f 14                	jg     f0103af4 <readline+0xcb>
			if (echoing)
f0103ae0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103ae4:	74 c2                	je     f0103aa8 <readline+0x7f>
				cputchar(c);
f0103ae6:	83 ec 0c             	sub    $0xc,%esp
f0103ae9:	56                   	push   %esi
f0103aea:	e8 d7 cb ff ff       	call   f01006c6 <cputchar>
f0103aef:	83 c4 10             	add    $0x10,%esp
f0103af2:	eb b4                	jmp    f0103aa8 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0103af4:	83 fe 0a             	cmp    $0xa,%esi
f0103af7:	74 05                	je     f0103afe <readline+0xd5>
f0103af9:	83 fe 0d             	cmp    $0xd,%esi
f0103afc:	75 b6                	jne    f0103ab4 <readline+0x8b>
			if (echoing)
f0103afe:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b02:	75 13                	jne    f0103b17 <readline+0xee>
			buf[i] = 0;
f0103b04:	c6 84 3b b4 1f 00 00 	movb   $0x0,0x1fb4(%ebx,%edi,1)
f0103b0b:	00 
			return buf;
f0103b0c:	8d 83 b4 1f 00 00    	lea    0x1fb4(%ebx),%eax
f0103b12:	e9 6f ff ff ff       	jmp    f0103a86 <readline+0x5d>
				cputchar('\n');
f0103b17:	83 ec 0c             	sub    $0xc,%esp
f0103b1a:	6a 0a                	push   $0xa
f0103b1c:	e8 a5 cb ff ff       	call   f01006c6 <cputchar>
f0103b21:	83 c4 10             	add    $0x10,%esp
f0103b24:	eb de                	jmp    f0103b04 <readline+0xdb>

f0103b26 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103b26:	55                   	push   %ebp
f0103b27:	89 e5                	mov    %esp,%ebp
f0103b29:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103b2c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b31:	eb 03                	jmp    f0103b36 <strlen+0x10>
		n++;
f0103b33:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103b36:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103b3a:	75 f7                	jne    f0103b33 <strlen+0xd>
	return n;
}
f0103b3c:	5d                   	pop    %ebp
f0103b3d:	c3                   	ret    

f0103b3e <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103b3e:	55                   	push   %ebp
f0103b3f:	89 e5                	mov    %esp,%ebp
f0103b41:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b44:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103b47:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b4c:	eb 03                	jmp    f0103b51 <strnlen+0x13>
		n++;
f0103b4e:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103b51:	39 d0                	cmp    %edx,%eax
f0103b53:	74 06                	je     f0103b5b <strnlen+0x1d>
f0103b55:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103b59:	75 f3                	jne    f0103b4e <strnlen+0x10>
	return n;
}
f0103b5b:	5d                   	pop    %ebp
f0103b5c:	c3                   	ret    

f0103b5d <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103b5d:	55                   	push   %ebp
f0103b5e:	89 e5                	mov    %esp,%ebp
f0103b60:	53                   	push   %ebx
f0103b61:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b64:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103b67:	89 c2                	mov    %eax,%edx
f0103b69:	83 c1 01             	add    $0x1,%ecx
f0103b6c:	83 c2 01             	add    $0x1,%edx
f0103b6f:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103b73:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103b76:	84 db                	test   %bl,%bl
f0103b78:	75 ef                	jne    f0103b69 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103b7a:	5b                   	pop    %ebx
f0103b7b:	5d                   	pop    %ebp
f0103b7c:	c3                   	ret    

f0103b7d <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103b7d:	55                   	push   %ebp
f0103b7e:	89 e5                	mov    %esp,%ebp
f0103b80:	53                   	push   %ebx
f0103b81:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103b84:	53                   	push   %ebx
f0103b85:	e8 9c ff ff ff       	call   f0103b26 <strlen>
f0103b8a:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103b8d:	ff 75 0c             	pushl  0xc(%ebp)
f0103b90:	01 d8                	add    %ebx,%eax
f0103b92:	50                   	push   %eax
f0103b93:	e8 c5 ff ff ff       	call   f0103b5d <strcpy>
	return dst;
}
f0103b98:	89 d8                	mov    %ebx,%eax
f0103b9a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b9d:	c9                   	leave  
f0103b9e:	c3                   	ret    

f0103b9f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103b9f:	55                   	push   %ebp
f0103ba0:	89 e5                	mov    %esp,%ebp
f0103ba2:	56                   	push   %esi
f0103ba3:	53                   	push   %ebx
f0103ba4:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ba7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103baa:	89 f3                	mov    %esi,%ebx
f0103bac:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103baf:	89 f2                	mov    %esi,%edx
f0103bb1:	eb 0f                	jmp    f0103bc2 <strncpy+0x23>
		*dst++ = *src;
f0103bb3:	83 c2 01             	add    $0x1,%edx
f0103bb6:	0f b6 01             	movzbl (%ecx),%eax
f0103bb9:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103bbc:	80 39 01             	cmpb   $0x1,(%ecx)
f0103bbf:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103bc2:	39 da                	cmp    %ebx,%edx
f0103bc4:	75 ed                	jne    f0103bb3 <strncpy+0x14>
	}
	return ret;
}
f0103bc6:	89 f0                	mov    %esi,%eax
f0103bc8:	5b                   	pop    %ebx
f0103bc9:	5e                   	pop    %esi
f0103bca:	5d                   	pop    %ebp
f0103bcb:	c3                   	ret    

f0103bcc <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103bcc:	55                   	push   %ebp
f0103bcd:	89 e5                	mov    %esp,%ebp
f0103bcf:	56                   	push   %esi
f0103bd0:	53                   	push   %ebx
f0103bd1:	8b 75 08             	mov    0x8(%ebp),%esi
f0103bd4:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103bd7:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103bda:	89 f0                	mov    %esi,%eax
f0103bdc:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103be0:	85 c9                	test   %ecx,%ecx
f0103be2:	75 0b                	jne    f0103bef <strlcpy+0x23>
f0103be4:	eb 17                	jmp    f0103bfd <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103be6:	83 c2 01             	add    $0x1,%edx
f0103be9:	83 c0 01             	add    $0x1,%eax
f0103bec:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103bef:	39 d8                	cmp    %ebx,%eax
f0103bf1:	74 07                	je     f0103bfa <strlcpy+0x2e>
f0103bf3:	0f b6 0a             	movzbl (%edx),%ecx
f0103bf6:	84 c9                	test   %cl,%cl
f0103bf8:	75 ec                	jne    f0103be6 <strlcpy+0x1a>
		*dst = '\0';
f0103bfa:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103bfd:	29 f0                	sub    %esi,%eax
}
f0103bff:	5b                   	pop    %ebx
f0103c00:	5e                   	pop    %esi
f0103c01:	5d                   	pop    %ebp
f0103c02:	c3                   	ret    

f0103c03 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103c03:	55                   	push   %ebp
f0103c04:	89 e5                	mov    %esp,%ebp
f0103c06:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103c09:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103c0c:	eb 06                	jmp    f0103c14 <strcmp+0x11>
		p++, q++;
f0103c0e:	83 c1 01             	add    $0x1,%ecx
f0103c11:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103c14:	0f b6 01             	movzbl (%ecx),%eax
f0103c17:	84 c0                	test   %al,%al
f0103c19:	74 04                	je     f0103c1f <strcmp+0x1c>
f0103c1b:	3a 02                	cmp    (%edx),%al
f0103c1d:	74 ef                	je     f0103c0e <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103c1f:	0f b6 c0             	movzbl %al,%eax
f0103c22:	0f b6 12             	movzbl (%edx),%edx
f0103c25:	29 d0                	sub    %edx,%eax
}
f0103c27:	5d                   	pop    %ebp
f0103c28:	c3                   	ret    

f0103c29 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103c29:	55                   	push   %ebp
f0103c2a:	89 e5                	mov    %esp,%ebp
f0103c2c:	53                   	push   %ebx
f0103c2d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c30:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c33:	89 c3                	mov    %eax,%ebx
f0103c35:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103c38:	eb 06                	jmp    f0103c40 <strncmp+0x17>
		n--, p++, q++;
f0103c3a:	83 c0 01             	add    $0x1,%eax
f0103c3d:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103c40:	39 d8                	cmp    %ebx,%eax
f0103c42:	74 16                	je     f0103c5a <strncmp+0x31>
f0103c44:	0f b6 08             	movzbl (%eax),%ecx
f0103c47:	84 c9                	test   %cl,%cl
f0103c49:	74 04                	je     f0103c4f <strncmp+0x26>
f0103c4b:	3a 0a                	cmp    (%edx),%cl
f0103c4d:	74 eb                	je     f0103c3a <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103c4f:	0f b6 00             	movzbl (%eax),%eax
f0103c52:	0f b6 12             	movzbl (%edx),%edx
f0103c55:	29 d0                	sub    %edx,%eax
}
f0103c57:	5b                   	pop    %ebx
f0103c58:	5d                   	pop    %ebp
f0103c59:	c3                   	ret    
		return 0;
f0103c5a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c5f:	eb f6                	jmp    f0103c57 <strncmp+0x2e>

f0103c61 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103c61:	55                   	push   %ebp
f0103c62:	89 e5                	mov    %esp,%ebp
f0103c64:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c67:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103c6b:	0f b6 10             	movzbl (%eax),%edx
f0103c6e:	84 d2                	test   %dl,%dl
f0103c70:	74 09                	je     f0103c7b <strchr+0x1a>
		if (*s == c)
f0103c72:	38 ca                	cmp    %cl,%dl
f0103c74:	74 0a                	je     f0103c80 <strchr+0x1f>
	for (; *s; s++)
f0103c76:	83 c0 01             	add    $0x1,%eax
f0103c79:	eb f0                	jmp    f0103c6b <strchr+0xa>
			return (char *) s;
	return 0;
f0103c7b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103c80:	5d                   	pop    %ebp
f0103c81:	c3                   	ret    

f0103c82 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103c82:	55                   	push   %ebp
f0103c83:	89 e5                	mov    %esp,%ebp
f0103c85:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c88:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103c8c:	eb 03                	jmp    f0103c91 <strfind+0xf>
f0103c8e:	83 c0 01             	add    $0x1,%eax
f0103c91:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103c94:	38 ca                	cmp    %cl,%dl
f0103c96:	74 04                	je     f0103c9c <strfind+0x1a>
f0103c98:	84 d2                	test   %dl,%dl
f0103c9a:	75 f2                	jne    f0103c8e <strfind+0xc>
			break;
	return (char *) s;
}
f0103c9c:	5d                   	pop    %ebp
f0103c9d:	c3                   	ret    

f0103c9e <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103c9e:	55                   	push   %ebp
f0103c9f:	89 e5                	mov    %esp,%ebp
f0103ca1:	57                   	push   %edi
f0103ca2:	56                   	push   %esi
f0103ca3:	53                   	push   %ebx
f0103ca4:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103ca7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103caa:	85 c9                	test   %ecx,%ecx
f0103cac:	74 13                	je     f0103cc1 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103cae:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103cb4:	75 05                	jne    f0103cbb <memset+0x1d>
f0103cb6:	f6 c1 03             	test   $0x3,%cl
f0103cb9:	74 0d                	je     f0103cc8 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103cbb:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103cbe:	fc                   	cld    
f0103cbf:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103cc1:	89 f8                	mov    %edi,%eax
f0103cc3:	5b                   	pop    %ebx
f0103cc4:	5e                   	pop    %esi
f0103cc5:	5f                   	pop    %edi
f0103cc6:	5d                   	pop    %ebp
f0103cc7:	c3                   	ret    
		c &= 0xFF;
f0103cc8:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103ccc:	89 d3                	mov    %edx,%ebx
f0103cce:	c1 e3 08             	shl    $0x8,%ebx
f0103cd1:	89 d0                	mov    %edx,%eax
f0103cd3:	c1 e0 18             	shl    $0x18,%eax
f0103cd6:	89 d6                	mov    %edx,%esi
f0103cd8:	c1 e6 10             	shl    $0x10,%esi
f0103cdb:	09 f0                	or     %esi,%eax
f0103cdd:	09 c2                	or     %eax,%edx
f0103cdf:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0103ce1:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103ce4:	89 d0                	mov    %edx,%eax
f0103ce6:	fc                   	cld    
f0103ce7:	f3 ab                	rep stos %eax,%es:(%edi)
f0103ce9:	eb d6                	jmp    f0103cc1 <memset+0x23>

f0103ceb <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103ceb:	55                   	push   %ebp
f0103cec:	89 e5                	mov    %esp,%ebp
f0103cee:	57                   	push   %edi
f0103cef:	56                   	push   %esi
f0103cf0:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cf3:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103cf6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103cf9:	39 c6                	cmp    %eax,%esi
f0103cfb:	73 35                	jae    f0103d32 <memmove+0x47>
f0103cfd:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103d00:	39 c2                	cmp    %eax,%edx
f0103d02:	76 2e                	jbe    f0103d32 <memmove+0x47>
		s += n;
		d += n;
f0103d04:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d07:	89 d6                	mov    %edx,%esi
f0103d09:	09 fe                	or     %edi,%esi
f0103d0b:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103d11:	74 0c                	je     f0103d1f <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103d13:	83 ef 01             	sub    $0x1,%edi
f0103d16:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103d19:	fd                   	std    
f0103d1a:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103d1c:	fc                   	cld    
f0103d1d:	eb 21                	jmp    f0103d40 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d1f:	f6 c1 03             	test   $0x3,%cl
f0103d22:	75 ef                	jne    f0103d13 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103d24:	83 ef 04             	sub    $0x4,%edi
f0103d27:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103d2a:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103d2d:	fd                   	std    
f0103d2e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103d30:	eb ea                	jmp    f0103d1c <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d32:	89 f2                	mov    %esi,%edx
f0103d34:	09 c2                	or     %eax,%edx
f0103d36:	f6 c2 03             	test   $0x3,%dl
f0103d39:	74 09                	je     f0103d44 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103d3b:	89 c7                	mov    %eax,%edi
f0103d3d:	fc                   	cld    
f0103d3e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103d40:	5e                   	pop    %esi
f0103d41:	5f                   	pop    %edi
f0103d42:	5d                   	pop    %ebp
f0103d43:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d44:	f6 c1 03             	test   $0x3,%cl
f0103d47:	75 f2                	jne    f0103d3b <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103d49:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103d4c:	89 c7                	mov    %eax,%edi
f0103d4e:	fc                   	cld    
f0103d4f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103d51:	eb ed                	jmp    f0103d40 <memmove+0x55>

f0103d53 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103d53:	55                   	push   %ebp
f0103d54:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103d56:	ff 75 10             	pushl  0x10(%ebp)
f0103d59:	ff 75 0c             	pushl  0xc(%ebp)
f0103d5c:	ff 75 08             	pushl  0x8(%ebp)
f0103d5f:	e8 87 ff ff ff       	call   f0103ceb <memmove>
}
f0103d64:	c9                   	leave  
f0103d65:	c3                   	ret    

f0103d66 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103d66:	55                   	push   %ebp
f0103d67:	89 e5                	mov    %esp,%ebp
f0103d69:	56                   	push   %esi
f0103d6a:	53                   	push   %ebx
f0103d6b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d6e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103d71:	89 c6                	mov    %eax,%esi
f0103d73:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103d76:	39 f0                	cmp    %esi,%eax
f0103d78:	74 1c                	je     f0103d96 <memcmp+0x30>
		if (*s1 != *s2)
f0103d7a:	0f b6 08             	movzbl (%eax),%ecx
f0103d7d:	0f b6 1a             	movzbl (%edx),%ebx
f0103d80:	38 d9                	cmp    %bl,%cl
f0103d82:	75 08                	jne    f0103d8c <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103d84:	83 c0 01             	add    $0x1,%eax
f0103d87:	83 c2 01             	add    $0x1,%edx
f0103d8a:	eb ea                	jmp    f0103d76 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0103d8c:	0f b6 c1             	movzbl %cl,%eax
f0103d8f:	0f b6 db             	movzbl %bl,%ebx
f0103d92:	29 d8                	sub    %ebx,%eax
f0103d94:	eb 05                	jmp    f0103d9b <memcmp+0x35>
	}

	return 0;
f0103d96:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103d9b:	5b                   	pop    %ebx
f0103d9c:	5e                   	pop    %esi
f0103d9d:	5d                   	pop    %ebp
f0103d9e:	c3                   	ret    

f0103d9f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103d9f:	55                   	push   %ebp
f0103da0:	89 e5                	mov    %esp,%ebp
f0103da2:	8b 45 08             	mov    0x8(%ebp),%eax
f0103da5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103da8:	89 c2                	mov    %eax,%edx
f0103daa:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103dad:	39 d0                	cmp    %edx,%eax
f0103daf:	73 09                	jae    f0103dba <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103db1:	38 08                	cmp    %cl,(%eax)
f0103db3:	74 05                	je     f0103dba <memfind+0x1b>
	for (; s < ends; s++)
f0103db5:	83 c0 01             	add    $0x1,%eax
f0103db8:	eb f3                	jmp    f0103dad <memfind+0xe>
			break;
	return (void *) s;
}
f0103dba:	5d                   	pop    %ebp
f0103dbb:	c3                   	ret    

f0103dbc <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103dbc:	55                   	push   %ebp
f0103dbd:	89 e5                	mov    %esp,%ebp
f0103dbf:	57                   	push   %edi
f0103dc0:	56                   	push   %esi
f0103dc1:	53                   	push   %ebx
f0103dc2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103dc5:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103dc8:	eb 03                	jmp    f0103dcd <strtol+0x11>
		s++;
f0103dca:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0103dcd:	0f b6 01             	movzbl (%ecx),%eax
f0103dd0:	3c 20                	cmp    $0x20,%al
f0103dd2:	74 f6                	je     f0103dca <strtol+0xe>
f0103dd4:	3c 09                	cmp    $0x9,%al
f0103dd6:	74 f2                	je     f0103dca <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103dd8:	3c 2b                	cmp    $0x2b,%al
f0103dda:	74 2e                	je     f0103e0a <strtol+0x4e>
	int neg = 0;
f0103ddc:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103de1:	3c 2d                	cmp    $0x2d,%al
f0103de3:	74 2f                	je     f0103e14 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103de5:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103deb:	75 05                	jne    f0103df2 <strtol+0x36>
f0103ded:	80 39 30             	cmpb   $0x30,(%ecx)
f0103df0:	74 2c                	je     f0103e1e <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103df2:	85 db                	test   %ebx,%ebx
f0103df4:	75 0a                	jne    f0103e00 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103df6:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0103dfb:	80 39 30             	cmpb   $0x30,(%ecx)
f0103dfe:	74 28                	je     f0103e28 <strtol+0x6c>
		base = 10;
f0103e00:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e05:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103e08:	eb 50                	jmp    f0103e5a <strtol+0x9e>
		s++;
f0103e0a:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0103e0d:	bf 00 00 00 00       	mov    $0x0,%edi
f0103e12:	eb d1                	jmp    f0103de5 <strtol+0x29>
		s++, neg = 1;
f0103e14:	83 c1 01             	add    $0x1,%ecx
f0103e17:	bf 01 00 00 00       	mov    $0x1,%edi
f0103e1c:	eb c7                	jmp    f0103de5 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103e1e:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103e22:	74 0e                	je     f0103e32 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0103e24:	85 db                	test   %ebx,%ebx
f0103e26:	75 d8                	jne    f0103e00 <strtol+0x44>
		s++, base = 8;
f0103e28:	83 c1 01             	add    $0x1,%ecx
f0103e2b:	bb 08 00 00 00       	mov    $0x8,%ebx
f0103e30:	eb ce                	jmp    f0103e00 <strtol+0x44>
		s += 2, base = 16;
f0103e32:	83 c1 02             	add    $0x2,%ecx
f0103e35:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103e3a:	eb c4                	jmp    f0103e00 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0103e3c:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103e3f:	89 f3                	mov    %esi,%ebx
f0103e41:	80 fb 19             	cmp    $0x19,%bl
f0103e44:	77 29                	ja     f0103e6f <strtol+0xb3>
			dig = *s - 'a' + 10;
f0103e46:	0f be d2             	movsbl %dl,%edx
f0103e49:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103e4c:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103e4f:	7d 30                	jge    f0103e81 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0103e51:	83 c1 01             	add    $0x1,%ecx
f0103e54:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103e58:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0103e5a:	0f b6 11             	movzbl (%ecx),%edx
f0103e5d:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103e60:	89 f3                	mov    %esi,%ebx
f0103e62:	80 fb 09             	cmp    $0x9,%bl
f0103e65:	77 d5                	ja     f0103e3c <strtol+0x80>
			dig = *s - '0';
f0103e67:	0f be d2             	movsbl %dl,%edx
f0103e6a:	83 ea 30             	sub    $0x30,%edx
f0103e6d:	eb dd                	jmp    f0103e4c <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0103e6f:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103e72:	89 f3                	mov    %esi,%ebx
f0103e74:	80 fb 19             	cmp    $0x19,%bl
f0103e77:	77 08                	ja     f0103e81 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0103e79:	0f be d2             	movsbl %dl,%edx
f0103e7c:	83 ea 37             	sub    $0x37,%edx
f0103e7f:	eb cb                	jmp    f0103e4c <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0103e81:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103e85:	74 05                	je     f0103e8c <strtol+0xd0>
		*endptr = (char *) s;
f0103e87:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103e8a:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0103e8c:	89 c2                	mov    %eax,%edx
f0103e8e:	f7 da                	neg    %edx
f0103e90:	85 ff                	test   %edi,%edi
f0103e92:	0f 45 c2             	cmovne %edx,%eax
}
f0103e95:	5b                   	pop    %ebx
f0103e96:	5e                   	pop    %esi
f0103e97:	5f                   	pop    %edi
f0103e98:	5d                   	pop    %ebp
f0103e99:	c3                   	ret    
f0103e9a:	66 90                	xchg   %ax,%ax
f0103e9c:	66 90                	xchg   %ax,%ax
f0103e9e:	66 90                	xchg   %ax,%ax

f0103ea0 <__udivdi3>:
f0103ea0:	55                   	push   %ebp
f0103ea1:	57                   	push   %edi
f0103ea2:	56                   	push   %esi
f0103ea3:	53                   	push   %ebx
f0103ea4:	83 ec 1c             	sub    $0x1c,%esp
f0103ea7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103eab:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0103eaf:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103eb3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0103eb7:	85 d2                	test   %edx,%edx
f0103eb9:	75 35                	jne    f0103ef0 <__udivdi3+0x50>
f0103ebb:	39 f3                	cmp    %esi,%ebx
f0103ebd:	0f 87 bd 00 00 00    	ja     f0103f80 <__udivdi3+0xe0>
f0103ec3:	85 db                	test   %ebx,%ebx
f0103ec5:	89 d9                	mov    %ebx,%ecx
f0103ec7:	75 0b                	jne    f0103ed4 <__udivdi3+0x34>
f0103ec9:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ece:	31 d2                	xor    %edx,%edx
f0103ed0:	f7 f3                	div    %ebx
f0103ed2:	89 c1                	mov    %eax,%ecx
f0103ed4:	31 d2                	xor    %edx,%edx
f0103ed6:	89 f0                	mov    %esi,%eax
f0103ed8:	f7 f1                	div    %ecx
f0103eda:	89 c6                	mov    %eax,%esi
f0103edc:	89 e8                	mov    %ebp,%eax
f0103ede:	89 f7                	mov    %esi,%edi
f0103ee0:	f7 f1                	div    %ecx
f0103ee2:	89 fa                	mov    %edi,%edx
f0103ee4:	83 c4 1c             	add    $0x1c,%esp
f0103ee7:	5b                   	pop    %ebx
f0103ee8:	5e                   	pop    %esi
f0103ee9:	5f                   	pop    %edi
f0103eea:	5d                   	pop    %ebp
f0103eeb:	c3                   	ret    
f0103eec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103ef0:	39 f2                	cmp    %esi,%edx
f0103ef2:	77 7c                	ja     f0103f70 <__udivdi3+0xd0>
f0103ef4:	0f bd fa             	bsr    %edx,%edi
f0103ef7:	83 f7 1f             	xor    $0x1f,%edi
f0103efa:	0f 84 98 00 00 00    	je     f0103f98 <__udivdi3+0xf8>
f0103f00:	89 f9                	mov    %edi,%ecx
f0103f02:	b8 20 00 00 00       	mov    $0x20,%eax
f0103f07:	29 f8                	sub    %edi,%eax
f0103f09:	d3 e2                	shl    %cl,%edx
f0103f0b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103f0f:	89 c1                	mov    %eax,%ecx
f0103f11:	89 da                	mov    %ebx,%edx
f0103f13:	d3 ea                	shr    %cl,%edx
f0103f15:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103f19:	09 d1                	or     %edx,%ecx
f0103f1b:	89 f2                	mov    %esi,%edx
f0103f1d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103f21:	89 f9                	mov    %edi,%ecx
f0103f23:	d3 e3                	shl    %cl,%ebx
f0103f25:	89 c1                	mov    %eax,%ecx
f0103f27:	d3 ea                	shr    %cl,%edx
f0103f29:	89 f9                	mov    %edi,%ecx
f0103f2b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103f2f:	d3 e6                	shl    %cl,%esi
f0103f31:	89 eb                	mov    %ebp,%ebx
f0103f33:	89 c1                	mov    %eax,%ecx
f0103f35:	d3 eb                	shr    %cl,%ebx
f0103f37:	09 de                	or     %ebx,%esi
f0103f39:	89 f0                	mov    %esi,%eax
f0103f3b:	f7 74 24 08          	divl   0x8(%esp)
f0103f3f:	89 d6                	mov    %edx,%esi
f0103f41:	89 c3                	mov    %eax,%ebx
f0103f43:	f7 64 24 0c          	mull   0xc(%esp)
f0103f47:	39 d6                	cmp    %edx,%esi
f0103f49:	72 0c                	jb     f0103f57 <__udivdi3+0xb7>
f0103f4b:	89 f9                	mov    %edi,%ecx
f0103f4d:	d3 e5                	shl    %cl,%ebp
f0103f4f:	39 c5                	cmp    %eax,%ebp
f0103f51:	73 5d                	jae    f0103fb0 <__udivdi3+0x110>
f0103f53:	39 d6                	cmp    %edx,%esi
f0103f55:	75 59                	jne    f0103fb0 <__udivdi3+0x110>
f0103f57:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0103f5a:	31 ff                	xor    %edi,%edi
f0103f5c:	89 fa                	mov    %edi,%edx
f0103f5e:	83 c4 1c             	add    $0x1c,%esp
f0103f61:	5b                   	pop    %ebx
f0103f62:	5e                   	pop    %esi
f0103f63:	5f                   	pop    %edi
f0103f64:	5d                   	pop    %ebp
f0103f65:	c3                   	ret    
f0103f66:	8d 76 00             	lea    0x0(%esi),%esi
f0103f69:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0103f70:	31 ff                	xor    %edi,%edi
f0103f72:	31 c0                	xor    %eax,%eax
f0103f74:	89 fa                	mov    %edi,%edx
f0103f76:	83 c4 1c             	add    $0x1c,%esp
f0103f79:	5b                   	pop    %ebx
f0103f7a:	5e                   	pop    %esi
f0103f7b:	5f                   	pop    %edi
f0103f7c:	5d                   	pop    %ebp
f0103f7d:	c3                   	ret    
f0103f7e:	66 90                	xchg   %ax,%ax
f0103f80:	31 ff                	xor    %edi,%edi
f0103f82:	89 e8                	mov    %ebp,%eax
f0103f84:	89 f2                	mov    %esi,%edx
f0103f86:	f7 f3                	div    %ebx
f0103f88:	89 fa                	mov    %edi,%edx
f0103f8a:	83 c4 1c             	add    $0x1c,%esp
f0103f8d:	5b                   	pop    %ebx
f0103f8e:	5e                   	pop    %esi
f0103f8f:	5f                   	pop    %edi
f0103f90:	5d                   	pop    %ebp
f0103f91:	c3                   	ret    
f0103f92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103f98:	39 f2                	cmp    %esi,%edx
f0103f9a:	72 06                	jb     f0103fa2 <__udivdi3+0x102>
f0103f9c:	31 c0                	xor    %eax,%eax
f0103f9e:	39 eb                	cmp    %ebp,%ebx
f0103fa0:	77 d2                	ja     f0103f74 <__udivdi3+0xd4>
f0103fa2:	b8 01 00 00 00       	mov    $0x1,%eax
f0103fa7:	eb cb                	jmp    f0103f74 <__udivdi3+0xd4>
f0103fa9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103fb0:	89 d8                	mov    %ebx,%eax
f0103fb2:	31 ff                	xor    %edi,%edi
f0103fb4:	eb be                	jmp    f0103f74 <__udivdi3+0xd4>
f0103fb6:	66 90                	xchg   %ax,%ax
f0103fb8:	66 90                	xchg   %ax,%ax
f0103fba:	66 90                	xchg   %ax,%ax
f0103fbc:	66 90                	xchg   %ax,%ax
f0103fbe:	66 90                	xchg   %ax,%ax

f0103fc0 <__umoddi3>:
f0103fc0:	55                   	push   %ebp
f0103fc1:	57                   	push   %edi
f0103fc2:	56                   	push   %esi
f0103fc3:	53                   	push   %ebx
f0103fc4:	83 ec 1c             	sub    $0x1c,%esp
f0103fc7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0103fcb:	8b 74 24 30          	mov    0x30(%esp),%esi
f0103fcf:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0103fd3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103fd7:	85 ed                	test   %ebp,%ebp
f0103fd9:	89 f0                	mov    %esi,%eax
f0103fdb:	89 da                	mov    %ebx,%edx
f0103fdd:	75 19                	jne    f0103ff8 <__umoddi3+0x38>
f0103fdf:	39 df                	cmp    %ebx,%edi
f0103fe1:	0f 86 b1 00 00 00    	jbe    f0104098 <__umoddi3+0xd8>
f0103fe7:	f7 f7                	div    %edi
f0103fe9:	89 d0                	mov    %edx,%eax
f0103feb:	31 d2                	xor    %edx,%edx
f0103fed:	83 c4 1c             	add    $0x1c,%esp
f0103ff0:	5b                   	pop    %ebx
f0103ff1:	5e                   	pop    %esi
f0103ff2:	5f                   	pop    %edi
f0103ff3:	5d                   	pop    %ebp
f0103ff4:	c3                   	ret    
f0103ff5:	8d 76 00             	lea    0x0(%esi),%esi
f0103ff8:	39 dd                	cmp    %ebx,%ebp
f0103ffa:	77 f1                	ja     f0103fed <__umoddi3+0x2d>
f0103ffc:	0f bd cd             	bsr    %ebp,%ecx
f0103fff:	83 f1 1f             	xor    $0x1f,%ecx
f0104002:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104006:	0f 84 b4 00 00 00    	je     f01040c0 <__umoddi3+0x100>
f010400c:	b8 20 00 00 00       	mov    $0x20,%eax
f0104011:	89 c2                	mov    %eax,%edx
f0104013:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104017:	29 c2                	sub    %eax,%edx
f0104019:	89 c1                	mov    %eax,%ecx
f010401b:	89 f8                	mov    %edi,%eax
f010401d:	d3 e5                	shl    %cl,%ebp
f010401f:	89 d1                	mov    %edx,%ecx
f0104021:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104025:	d3 e8                	shr    %cl,%eax
f0104027:	09 c5                	or     %eax,%ebp
f0104029:	8b 44 24 04          	mov    0x4(%esp),%eax
f010402d:	89 c1                	mov    %eax,%ecx
f010402f:	d3 e7                	shl    %cl,%edi
f0104031:	89 d1                	mov    %edx,%ecx
f0104033:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104037:	89 df                	mov    %ebx,%edi
f0104039:	d3 ef                	shr    %cl,%edi
f010403b:	89 c1                	mov    %eax,%ecx
f010403d:	89 f0                	mov    %esi,%eax
f010403f:	d3 e3                	shl    %cl,%ebx
f0104041:	89 d1                	mov    %edx,%ecx
f0104043:	89 fa                	mov    %edi,%edx
f0104045:	d3 e8                	shr    %cl,%eax
f0104047:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010404c:	09 d8                	or     %ebx,%eax
f010404e:	f7 f5                	div    %ebp
f0104050:	d3 e6                	shl    %cl,%esi
f0104052:	89 d1                	mov    %edx,%ecx
f0104054:	f7 64 24 08          	mull   0x8(%esp)
f0104058:	39 d1                	cmp    %edx,%ecx
f010405a:	89 c3                	mov    %eax,%ebx
f010405c:	89 d7                	mov    %edx,%edi
f010405e:	72 06                	jb     f0104066 <__umoddi3+0xa6>
f0104060:	75 0e                	jne    f0104070 <__umoddi3+0xb0>
f0104062:	39 c6                	cmp    %eax,%esi
f0104064:	73 0a                	jae    f0104070 <__umoddi3+0xb0>
f0104066:	2b 44 24 08          	sub    0x8(%esp),%eax
f010406a:	19 ea                	sbb    %ebp,%edx
f010406c:	89 d7                	mov    %edx,%edi
f010406e:	89 c3                	mov    %eax,%ebx
f0104070:	89 ca                	mov    %ecx,%edx
f0104072:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0104077:	29 de                	sub    %ebx,%esi
f0104079:	19 fa                	sbb    %edi,%edx
f010407b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010407f:	89 d0                	mov    %edx,%eax
f0104081:	d3 e0                	shl    %cl,%eax
f0104083:	89 d9                	mov    %ebx,%ecx
f0104085:	d3 ee                	shr    %cl,%esi
f0104087:	d3 ea                	shr    %cl,%edx
f0104089:	09 f0                	or     %esi,%eax
f010408b:	83 c4 1c             	add    $0x1c,%esp
f010408e:	5b                   	pop    %ebx
f010408f:	5e                   	pop    %esi
f0104090:	5f                   	pop    %edi
f0104091:	5d                   	pop    %ebp
f0104092:	c3                   	ret    
f0104093:	90                   	nop
f0104094:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104098:	85 ff                	test   %edi,%edi
f010409a:	89 f9                	mov    %edi,%ecx
f010409c:	75 0b                	jne    f01040a9 <__umoddi3+0xe9>
f010409e:	b8 01 00 00 00       	mov    $0x1,%eax
f01040a3:	31 d2                	xor    %edx,%edx
f01040a5:	f7 f7                	div    %edi
f01040a7:	89 c1                	mov    %eax,%ecx
f01040a9:	89 d8                	mov    %ebx,%eax
f01040ab:	31 d2                	xor    %edx,%edx
f01040ad:	f7 f1                	div    %ecx
f01040af:	89 f0                	mov    %esi,%eax
f01040b1:	f7 f1                	div    %ecx
f01040b3:	e9 31 ff ff ff       	jmp    f0103fe9 <__umoddi3+0x29>
f01040b8:	90                   	nop
f01040b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01040c0:	39 dd                	cmp    %ebx,%ebp
f01040c2:	72 08                	jb     f01040cc <__umoddi3+0x10c>
f01040c4:	39 f7                	cmp    %esi,%edi
f01040c6:	0f 87 21 ff ff ff    	ja     f0103fed <__umoddi3+0x2d>
f01040cc:	89 da                	mov    %ebx,%edx
f01040ce:	89 f0                	mov    %esi,%eax
f01040d0:	29 f8                	sub    %edi,%eax
f01040d2:	19 ea                	sbb    %ebp,%edx
f01040d4:	e9 14 ff ff ff       	jmp    f0103fed <__umoddi3+0x2d>
