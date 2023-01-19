AT&T assembly syntax and IA-32 instructions [ref](https://gist.github.com/lvhlvh/f6c456b95182d99385f2694257ac77e2)
1. Hardware
2. Compilation
3. AT\&T Syntax
4. 数据
5. BSS
6. Moving data
7. 寻址
   1. 索引寻址 Indexed addressing
   2. 间接内存寻址 Indirect memory addressing
8. Stack. Pushing and Poping data
9. Branch instructions
10. Integer math
    1. Addition
    2. 递增和递减
    3. Multiplication
    4. Division

# Hardware
指令代码格式（IA-32）
- 可选指令前缀 Optional instruction prefix
- 操作代码  Operational code
- 可选修饰符  Optional modifier(s)
- 可选数据元素 Optional data element(s)
```
- Registers
|__ General purpose (Eight 32-bit registers used for storing working data)
    通用（八个32位寄存器用于存储工作数据）
    |__ EAX (RAX for 64-bit) Accumulator for operands and results data
        EAX（64位RAX）用于操作数和结果数据的累加器
    |__ EBX Pointer to data in the data memory segment
        EBX 指向数据内存段中数据的指针
    |__ ECX Counter for string and loop operations
        字符串和循环操作的 ECX 计数器
    |__ EDX I/O pointer
        EDX I/O 指针
    |__ EDI Data pointer for destination of string operations
        字符串操作目标的 EDI 数据指针
    |__ ESI Data pointer for source of string operations
        ESI 字符串操作源的数据指针
    |__ ESP Stack pointer
        ESP 堆栈指针
    |__ EBP Stack data pointer
        ESP 是栈顶。
            ESP is the top of the stack.
            EBP is usually set to esp at the start of the function.
            Local variables are accessed by subtracting a constant 
            offset from ebp. All x86 calling conventions define ebp 
            as being preserved across function calls. ebp itself
            actually points to the previous frame's base pointer,
            which enables stack walking in a debugger and viewing 
            other frames local variables to work
            ESP 是栈顶。
            EBP 通常在函数开始时设置为 esp。
            通过减去常量访问局部变量
            从 ebp 偏移。 所有 x86 调用约定都定义了 ebp
            在函数调用中保留。 ebp本身
            实际上指向前一帧的基址指针，
            启用调试器中的堆栈遍历和查看
            其他帧局部变量工作
|__ Segment (Six 16-bit registers used for handling memory access)
            (6 个 16 位寄存器，用于处理内存访问）
    |__ Flat memory model
    |__ Segmented memory model
    |__ Real-address mode
    |__ CS (Code segment)
    |__ DS (Data segment)
    |__ SS (Stack segment)
    |__ ES (Extra segment pointer)
    |__ FS (Extra segment pointer)
    |__ GS (Extra segment pointer)
|__ 指令指针（32位寄存器指向下一条指令代码）\
EIP 寄存器，有时称为程序计数器在平面内存模型中，指令指针包含下一个内存位置的线性地址指令代码。 如果应用程序使用分段内存模型，指令指针指向一个逻辑内存地址，由CS寄存器的内容引用
|__ Control (Five 32-bit registers used to detstringermine the operating mode)
    |__ CR0 (System flags that control  mode and states of the processor)
    |__ CR1 (Not currently used)
    |__ CR2 (Memory page fault information)
    |__ CR3 (Memory page directory information)
    |__ CR4 (Flags enable processor features and indicate capabilities)
```
```
- Flags
|__Status flags
   |__ CF 0 Carry flag 进位
   |__ PF 2 Parity flag 奇偶校验标志
   |__ AF 4 Adjust flag 调整标志
   |__ ZF 6 Zero flag 零标志
   |__ SF 7 Sign flag 标志标志
   |__ OF 11 Overflow flag 溢出标志
|__Control flags
   |__ DF flag, or direction flag (DF flag is set (set to one), string
       instructions automatically decrement memory addresses to get
       the next byte in the string. When the DF flag is cleared
       (set to zero), string instructions automatically increment
       memory addresses to get the next  byte in the string
        DF标志，或方向标志（DF标志被设置（设置为一），
        字符串指令自动递减内存地址以获得字符串中的下一个字节。
        当DF标志被清除（设置为零）时，
        字符串指令自动递增内存地址以获得字符串中的下一个字节
```

# Compilation

```
as cpuid.s -o cpuid.o && ld cpuid.o -o cpuid

or rename "_start" to "main" and run
gcc cpuid.s -o cpuid 

“-gstabs”额外调试信息帮助 gdb 遍历源代码
as -gstabs -o cpuid.o cpuid.s 
```

# AT&T Syntax

- AT&T immediate operands use a $ to denote them, whereas Intel immediate 
  operands are undelimited. Thus, when referencing the decimal value 4 in 
  AT&T syntax, you would use $4 , and in Intel syntax you would just use 4.
- AT&T 立即操作数使用 $ 来表示它们，而 Intel 立即
   操作数是undelimited的。 因此，当引用十进制值 4 时
   在 AT&T 语法中，您将使用 $4 ，而在 Intel 语法中，您将只使用 4。
- AT&T prefaces register names with a % , while Intel does not. 
  Thus, referencing the EAX register in AT&T syntax, you would use %eax .
- AT&T 以 % 开头register，而 Intel 则没有。
   因此，在 AT&T 语法中引用 EAX 寄存器时，您将使用 %eax 。
- AT&T syntax uses the opposite order for source and destination operands. 
  To move the decimal value 4 to the EAX register, AT&T syntax would be 
  movl $4, %eax , whereas for Intel it would be mov eax, 4 .
- AT&T 语法对源操作数和目标操作数使用相反的顺序。
   要将十进制值 4 移动到 EAX 寄存器，AT&T 语法将是
   movl $4, %eax ，而对于英特尔来说则是 mov eax, 4 。
- AT&T syntax uses a separate character at the end of mnemonics to reference 
 the data size used in the operation, whereas in Intel syntax the size is 
 declared as a separate operand. The AT&T instruction movl $test, %eax is 
 equivalent to mov eax, dword ptr test in Intel syntax.
- AT&T 语法在助记符末尾使用一个单独的字符来引用
  操作中使用的数据大小，而在 Intel 语法中，大小是
  声明为单独的操作数。 AT&T 指令 movl $test, %eax 是
  相当于 Intel 语法中的 mov eax, dword ptr test。
- Long calls and jumps use a different syntax to define the segment and 
  offset values. AT&T syntax uses ljmp $section, $offset , whereas Intel 
  syntax uses jmp section:offset .
- 长调用和跳转使用不同的语法来定义段和
   偏移值。 AT&T 语法使用 ljmp $section, $offset ，而 Intel
   语法使用 jmp section:offset 。

# 数据
```
.ascii # 文本字符串
.asciz # 以空字符结尾的文本字符串
.byte # 字节值
.double # 双精度浮点数
.float # 单精度浮点数
.int # 32位整数
.long # 32 位整数（与 .int 相同）
.octa # 16字节整数
.quad # 8字节整数
.short # 16 位整数
.single # 单精度浮点数（同.float）
```
# BSS
.comm 为未初始化的数据声明一个公共内存区
.lcomm 为未初始化的数据声明一个本地公共内存区

.comm symbol, length, alignment

.section .bss
.lcomm buffer, 10000

# Moving data


movx source, destination

The source and destination values can be memory addresses,
data values stored in memory, data values defined
in the instruction statement, or registers.

源值和目标值可以是内存地址，数据值存储在内存中，数据值定义在指令语句或寄存器中。

where x can be the following:
- l for a 32-bit long word value
- w for a 16-bit word value
- b for an 8-bit byte value
- q for a 64-bit quad word value (64-bit systems)

Combinations for a MOV instruction:
- An immediate data element 立即数据元素 to a general-purpose register 通用寄存器
- An immediate data element 立即数据元素 to a memory location 内存
- A general-purpose register 通用寄存器 to another general-purpose register 通用寄存器
- A general-purpose register 通用寄存器 to a segment register 段寄存器
- A segment register 段寄存器 to a general-purpose register 通用寄存器
- A general-purpose register 通用寄存器 to a control register 控制寄存器
- A control register 控制寄存器 to a general-purpose register 通用寄存器
- A general-purpose register 通用寄存器 to a debug register 调试寄存器
- A debug register 调试寄存器 to a general-purpose register 通用寄存器
- A memory location 内存 to a general-purpose register 通用寄存器
- A memory location 内存 to a segment register 段寄存器
- A general-purpose register 通用寄存器 to a memory location 内存
- A segment register 段寄存器 to a memory location 内存
```assembly
example: 
movl $0, %eax # moves the value 0 to the EAX register 
movl $0x80, %ebx # moves the hexadecimal value 80 to the EBX register 
movl $100, height # moves the value 100 to the height memory location
```
八个通用寄存器（ EAX 、 EBX 、 ECX 、 EDX 、 EDI 、 ESI 、 EBP 和 ESP ）
是用于保存数据的最常用寄存器。 这些寄存器可以移动到任何其他类型的可用寄存器。 
与通用寄存器不同，专用寄存器（控制、调试和段寄存器）只能移入或移出通用寄存器。
```assembly
# An example of moving data from memory to a register
.section .data
value:
    .int 1
.section .text
.globl _start
_start:
    nop
    movl value, %ecx
    movl $1, %eax
    movl $0, %ebx
    int $0x80

# An example of moving register data to memory
.section .data
value:
    .int 1
.section .text
.globl _start
_start:
    nop
    movl $100, %eax
    movl %eax, value
    movl $1, %eax
    movl $0, %ebx
    int $0x80
```

# 寻址
## 索引寻址 Indexed addressing

这样做的方式称为索引内存模式。
内存位置由以下因素决定：
- 基地址
- 添加到基地址的偏移地址
- 数据元素的大小
- 确定选择哪个数据元素的索引
表达式的格式是
base_address(offset_address, index, size)
检索到的数据值位于
base_address + offset_address + index * size

如果任何值是零，它们可以被省略
（但逗号仍然需要作为占位符）。
```assembly
movl $2, %edi
movl values(, %edi, 4), %eax
```
## 间接内存寻址 Indirect memory addressing
```assembly
movl $values, %edi
movl %ebx, (%edi)

# $values->(%edi)代表一个内存地址
```
如果 EDI 寄存器周围没有括号，该指令只会将 EBX 寄存器中的值加载到 EDI 寄存器。 通过 EDI 寄存器周围的括号，该指令将 EBX 寄存器中的值移动到 EDI 寄存器中包含的内存位置。
```assembly
movl %edx, 4(%edi) # 4 bytes after location pointed to by the EDI register.
movl %edx, -4(&edi) # 4 bytes before
```

# Stack. Pushing and Poping data
pushx source
popx destination

# Branch instructions 

Indirectly alter program couter (instruction pointer) 
set value (address of next instruction).

- Unconditional branches (Jumps, Calls, Interrupts) \
  (The instruction pointer is automatically routed to a different location)
- Conditional branches
jmp location
```assembly
_start:
    jmp overhere
    movl $10, %ebx
overhere:
    movl $20, %ebx
```
- Short jump
- Near jump
- Far jump

call address

CALL指令执行时，先将EIP寄存器压栈，然后修改EIP寄存器指向被调用函数地址。 返回指令没有操作数，只有助记符 RET 。 它通过查看堆栈知道返回到哪里。


jxx address
Supports:
- Short jumps
- Near jumps
```
# JA - Jump if above CF=0 and ZF=0
# JAE - Jump if above or equal CF=0
# JB - Jump if below CF=1
# JBE - Jump if below or equal CF=1 or ZF=1
# JC - Jump if carry CF=1
# JCXZ - Jump if CX register is 0 JECXZ Jump if ECX register is 0 JE Jump if equal ZF=1
# JG - Jump if greater ZF=0 and SF=OF
# JGE - Jump if greater or equal SF=OF
# JL - Jump if less SF<>OF
# JLE - Jump if less or equal ZF=1 or SF<>OF
# JNA - Jump if not above CF=1 or ZF=1
# JNAE - Jump if not above or equal CF=1
# JNB - Jump if not below CF=0
# JNBE - Jump if not below or equal CF=0 and ZF=0
# JNC - Jump if not carry CF=0
# JNE - Jump if not equal ZF=0
# JNG - Jump if not greater ZF=1 or SF<>OF
# JNGE - Jump if not greater or equal SF<>OF
# JNL - Jump if not less SF=OF
# JNLE - Jump if not less or equal ZF=0 and SF=OF
# JNO - Jump if not overflow OF=0
# JNP - Jump if not parity PF=0
# JNS - Jump if not sign SF=0
# JNZ - Jump if not zero ZF=0
# JO - Jump if overflow OF=1
# JP - Jump if parity PF=1
# JPE - Jump if parity even PF=1
# JPO - Jump if parity odd PF=0
# JS - Jump if sign SF=1
# JZ - Jump if zero ZF=1
```
cmp operand1, operand2 \
它比较两个值并相应地设置 EFLAGS 寄存器。

LOOP - 循环直到 ECX 寄存器为零

LOOPE/LOOPZ - 循环直到 ECX 寄存器为零，或者 ZF flag is not set \
LOOPNE/LOOPNZ - 循环直到 ECX 寄存器为零，或者ZF flag is set \
循环指令只支持 8 位偏移量，因此只能执行短跳转。 \

# Integer math

## Addition

add source, destination
```assembly
addb $10, %al # adds the immediate value 10 to the 8-bit AL register
addw %bx, %cx # adds the 16-bit value of the BX register to the CX register
addl data, %eax # adds the 32-bit integer value at the data label to EAX
addl %eax, %eax # adds the value of the EAX register to itself
```
ADC 指令可用于将两个无符号或有符号整数值与先前 ADD 指令的进位标志中包含的值相加。
```assembly
adc source, destination

sub source, destination
sbb source, destination
```
## 递增和递减
```assembly
dec destination
inc destination
```
## Multiplication
```assembly
mul source
```
一方面，目标位置总是使用某种形式的 EAX 寄存器，具体取决于源操作数的大小。 因此，乘法中使用的操作数之一必须放在 AL 、 AX 或 EAX 寄存器中，具体取决于值的大小。 MUL 指令只能用于无符号整数，而 IMUL 指令可用于有符号和无符号整数
```assembly
imul source
```

## Division
```assembly
div divisor
idiv divisor
```
被除数必须已经存储在 AX 寄存器（对于 16 位值）、DX:AX 寄存器对（对于 32 位值）或 EDX:EAX 寄存器对（对于 64 位值）中 执行 DIV 指令。

lea是load effective address的缩写，简单的说，lea指令可以用来将一个内存地址直接赋给目的操作数，例如：lea eax,[ebx+8]就是将ebx+8这个值直接赋给eax，而不是把ebx+8处的内存地址里的数据赋给eax。而mov指令则恰恰相反，例如：mov eax,[ebx+8]则是把内存地址为ebx+8处的数据赋给eax。

