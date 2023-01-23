1. Lab 3: User Environments
   1. Part A: User Environments and Exception Handling
      1. 练习1 分配环境数组
      2. 练习2. 在 env.c 中，完成对以下功能的编码：
      3. 处理中断和异常
      4. 中断和异常的类型
      5. 建立中断描述符表(IDT)
      6. 练习4 \& challenge
      7. 问题
   2. Part B: Page Faults, Breakpoints Exceptions, and System Calls
      1. Exercise 5
      2. Exercise 6
      3. Questions
      4. Exercise 7
      5. 补充知识：GCC内联汇编
      6. 用户进程启动
      7. Exercise 8.
   3. 页错误 \& 内存保护
      1. 练习9


# Lab 3: User Environments
在本实验中，您将实现基本的内核功能 需要运行受保护的用户模式环境（即“进程”）。 您将增强 JOS 内核 设置数据结构以跟踪用户环境， 创建单用户环境， 将程序图像加载到其中， 并开始运行。 您还将使 JOS 内核能够 处理用户环境进行的任何系统调用 并处理它导致的任何其他异常。

Note: 在这个实验里，术语 `environment` 和 `process` 可互换 - 两者都是指允许您运行程序的抽象。
我们引入术语“环境”而不是传统术语“进程”是为了强调 JOS 环境和 UNIX 进程提供不同的接口，并且不提供相同的语义。

新文件
| file  | name        | description                                               |
| ----- | ----------- | --------------------------------------------------------- |
| inc/  | env.h       | public 定义 user-mode environments (proc)                 |
|       | trap.h      | public 定义 trap handling                                 |
|       | syscall.h   | public 定义 syscalls from user environments to the kernel |
|       | lib.h       | public 定义 the user-mode support library                 |
| kern/ | env.h       | Kernel-private 定义 user-mode environments                |
|       | env.c       | Kernel 实现 user-mode environments                        |
|       | trap.h      | Kernel-private 定义 trap handling                         |
|       | trap.c      | Trap handling code                                        |
|       | trapentry.S | 汇编 trap handler entry-points                            |
|       | syscall.h   | Kernel-private 定义 syscall handling                      |
|       | syscall.c   | System call 实现                                          |
| lib/  | Makefrag    | 用于构建用户模式库的 Makefile 片段, obj/lib/libjos.a      |
|       | entry.S     | 汇编 entry-point for user environments                    |
|       | libmain.c   | User-mode library setup code called from entry.S          |
|       | syscall.c   | User-mode syscall stub functions                          |
|       | console.c   | User-mode 实现 putchar and getchar, providing console I/O |
|       | exit.c      | User-mode 实现 exit                                       |
|       | panic.c     | User-mode 实现 of panic                                   |
| user/ | *           | Various test programs to check kernel lab 3 code          |
## Part A: User Environments and Exception Handling
内核维护了与环境有关的三个主要全局变量:
```c
struct Env *envs = NULL; // 所有环境
struct Env *curenv = NULL; // 当前环境
static struct Env *env_free_list; // 可用环境链表
```
* 一旦JOS启动并运行，envs指针将指向Env代表系统中所有环境的结构数组。JOS内核将最多支持 NENV 个活动环境。
* JOS内核将所有非活动Env结构保留在env_free_list上。这种设计可以轻松分配和释放环境，因为只需将它们添加到空闲列表中或从空闲列表中删除.
* 内核使用该curenv符号在任何给定时间跟踪当前正在执行的环境。在启动期间，在运行第一个环境之前， curenv初始设置为NULL。
```c
struct Env {
	struct Trapframe env_tf;	// Saved registers
	struct Env *env_link;		// Next free Env
	envid_t env_id;			// Unique environment identifier
	envid_t env_parent_id;		// env_id of this env's parent
	enum EnvType env_type;		// Indicates special system environments
	unsigned env_status;		// Status of the environment
	uint32_t env_runs;		// Number of times environment has run

	// Address space
	pde_t *env_pgdir;		// Kernel virtual address of page dir
};
```

以下是这些 Env 字段的用途:
```c
| name          | description                                                              |
| ------------- | ------------------------------------------------------------------------ |
| env_tf        | 在 inc/trap.h 中定义的该结构，在该进程不运行时保存该进程的已保存寄存器值 |
|               | 从用户模式切换到内核模式时，内核会保存这些设置，以便从中断的位置恢复进程 |
| env_link      | 链接指针  env_free_list 指向列表中的第一个可用进程                       |
| env_id        | 唯一地标识当前正在使用此Env结构的进程                                    |
| env_parent_id | 父亲的id                                                                 |
| env_type      | 用于区分特殊进程 对于大多数进程，它将为ENV_TYPE_USER                     |
| env_status    | 此变量保存以下值之一:                                                    |
|               | ENV_FREE:处于非活动状态，位于 env_free_list 上                           |
|               | ENV_RUNNABLE:表示正在等待在处理器上运行的进程                            |
|               | ENV_RUNNING:代表当前正在运行的进程                                       |
|               | ENV_NOT_RUNNABLE:表示当前处于活动状态，但是当前尚未准备好运行            |
|               | 例如，它正在等待来自另一个进程的进程间通信（IPC）                        |
|               | ENV_DYING:僵尸进程 僵尸进程在下一次捕获到内核时将被释放                  |
| env_pgdir     | 此变量保存此进程的页目录的内核虚拟地址                                   |
```

### 练习1 分配环境数组
现在，您将需要进一步修改 mem_init() 以分配一个相似结构数组envs。
```c
    // 分配空间并初始化
    // Make 'envs' point to an array of size 'NENV' of 'struct Env'.
    // LAB 3: Your code here.
    envs = (struct Env*)boot_alloc(NENV * sizeof(struct Env));
    memset(envs, 0, NENV * sizeof(struct Env));
```
```c
    // Map the 'envs' array read-only by the user at linear address UENVS
    // (ie. perm = PTE_U | PTE_P).
    // Permissions:
    //    - the new image at UENVS  -- kernel R, user R
    //    - envs itself -- kernel RW, user NONE
    // LAB 3: Your code here.
    boot_map_region(kern_pgdir, UENVS, ROUNDUP(NENV * sizeof(struct Env), PGSIZE), PADDR(envs), PTE_U);
```

创建和运行环境

现在，您将在运行用户环境所需的kern / env.c中编写代码。因为我们还没有文件系统，所以我们将设置内核以加载嵌入在内核本身中的静态二进制映像。JOS将此二进制文件作为ELF可执行映像嵌入内核。

在 kern/init.c 中的 i386_init() 中，可以看到在一个环境中执行这些二进制镜像的代码。但是，设置用户环境的关键功能还不完善。您将需要填写它们。

###  练习2. 在 env.c 中，完成对以下功能的编码：
```c
| env_init()     | 初始化数组 envs 中的所有 Env 结构并将它们添加到 env_free_list 中          |
|                | 调用env_init_percpu，ring0和ring3的单独段                               |
| env_setup_vm() | 为新环境分配页面目录，初始化地址空间的内核部分                             |
| region_alloc() | 分配和映射环境的物理内存                                                 |
| load_icode()   | 像启动加载程序一样解析ELF二进制映像，将其内容加载到新环境的用户地址空间中    |
| env_create()   | 使用 env_alloc 分配环境，然后调用load_icode将ELF二进制文件加载到其中       |
| env_run()      | 启动以用户模式运行的给定环境                                             |
```
下面是代码的调用图，直到调用用户代码为止，可供参考：
```c
|_start (kern/entry.S)
|_i386_init (kern/init.c)
|___cons_init
|___mem_init
|___env_init
|___trap_init (still incomplete at this point)
|___env_create
|___env_run
|_____env_pop_tf
```
env_init()
作用是初始化 envs 这个数组以及 env_free_list。需要注意的主要是链表的顺序，要求第一个被使用是 envs[0]，所以我们从后往前插入（类似于栈，后进先出）。
```c
// Mark all environments in 'envs' as free, set their env_ids to 0,
// and insert them into the env_free_list.
// Make sure the environments are in the free list in the same order
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
// env_init函数很简单，就是遍历 envs 数组中的所有 Env 结构体，把每一个结构体的 env_id 字段置0，
// 因为要求所有的 Env 在 env_free_list 中的顺序，要和它在 envs 中的顺序一致，所以需要采用头插法。
void env_init(void){
    // Set up envs array
    // LAB 3: Your code here.
    int i;
    env_free_list = NULL;
    for (i = NENV - 1; i >= 0; i--){
        envs[i].env_id = 0;
        envs[i].env_status = ENV_FREE;
        envs[i].env_link = env_free_list;
        env_free_list = &envs[i];
    }
    // Per-CPU part of the initialization
    env_init_percpu();
}
```
env_setup_vm新建并初始化进程的**页目录**，一个页目录占用空间 4kB。需要注意两点：

* 进程的页目录与内核的页目录基本相同，仅需修改一下 UVPT，所以可以直接 memcpy。
* 需要增加页引用。
```c
// 初始化内核虚拟内存 environment
// Allocate a page directory, set e->env_pgdir accordingly,
// and initialize the kernel portion of the new environment's address space.
// 此时还没有map 任何进入用户空间
// Returns 0 on success, < 0 on error.  Errors include:
//	-E_NO_MEM if page directory or table could not be allocated.
//
static int env_setup_vm(struct Env *e){
    int i;
    struct PageInfo *p = NULL;

    // Allocate a page for the page directory
    if (!(p = page_alloc(ALLOC_ZERO)))
        return -E_NO_MEM;

    // 设置 e->env_pgdir 初始化 page directory.
    //
    // Hint:
    //    - The VA space of all envs is identical above UTOP
    //	(except at UVPT, which we've set below).
    //	See inc/memlayout.h for permissions and layout.
    //	Can you use kern_pgdir as a template?  Hint: Yes.
    //	(Make sure you got the permissions right in Lab 2.)
    //    - The initial VA below UTOP is empty.
    //    - You do not need to make any more calls to page_alloc.
    //    - Note: In general, pp_ref is not maintained for
    //	physical pages mapped only above UTOP, but env_pgdir
    //	is an exception -- you need to increment env_pgdir's
    //	pp_ref for env_free to work correctly.
    //    - The functions in kern/pmap.h are handy.

    // LAB 3: Your code here.
    p->pp_ref++;
    e->env_pgdir = page2kva(p);
    memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
    // UVPT maps the env's own page table read-only.
    // Permissions: kernel R, user R
    e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
    return 0;
}
```
region_alloc()
为进程分配内存并完成映射。重点就是想到要利用 lab2 中的 page_alloc() 完成分配内存页， page_insert() 完成虚拟地址到物理页的映射。
```c
// 分配len长度的 物理内存给 env 并在虚拟内存 va 处 map
// 不用清零或者初始化
// Pages should be writable by user and kernel.
// Panic if 失败
//
static void region_alloc(struct Env* e, void* va, size_t len) {
    // LAB 3: Your code here.
    // (But only if you need it for load_icode.)
    //
    // Hint: It is easier to use region_alloc if the caller can pass
    //   'va' and 'len' values that are not page-aligned.
    //   You should round va down, and round (va + len) up.
    //   (Watch out for corner-cases!)
    if ((uintptr_t)va >= UTOP) {
        panic("Mapping virtual address above UTOP for user environment...\n");
    }
    void* start = ROUNDDOWN(va, PGSIZE);
    void* end = ROUNDUP(va + len, PGSIZE);
    // corner case: end overflows
    // 边界情况就是输入的数值不正确，超出了32-bit范围，发生溢出overflow。
    if (start > end)
        panic("region_alloc: requesting length too large.\n");

    for (void* addr = start; addr < end; addr += PGSIZE) {
        struct PageInfo* p = NULL;
        assert(p = page_alloc(0));
        int result = page_insert(e->env_pgdir, p, addr, PTE_W | PTE_U);
        assert(result >= 0);
    }
}
```
load_icode()
这是本 exercise 最难的一个函数。作用是将 ELF 二进制文件读入内存，由于 JOS 暂时还没有自己的文件系统，实际就是从 *binary 这个内存地址读取。可以从 boot/main.c 中找到灵感。

大概需要做的事：

* 根据 ELF header 得出 Programm header。
* 遍历所有 Programm header，分配好内存，加载类型为 ELF_PROG_LOAD 的段。
* 分配用户栈。

需要思考的问题：

* 怎么切换页目录？
lcr3([页目录物理地址]) 将地址加载到 cr3 寄存器。
* 怎么更改函数入口？
将 env->env_tf.tf_eip 设置为 elf->e_entry，等待之后的 env_pop_tf() 调用。

```c
// 设置initial program binary, stack, and processor flags
// This function is ONLY called during kernel initialization,
// before running the first user-mode environment.
// 这个函数加载所有 loadable segments from the ELF binary image到 用户内存
// 从合适的虚拟地址indicated in the ELF program header开始
// 同时它将程序头中标记为已映射的这些段的任何部分清零
// 但实际上并不存在于 ELF 文件中——即程序的 bss 部分。
//
// All this is very similar to what our boot loader does, except the boot
// loader also needs to read the code from disk.  Take a look at
// boot/main.c to get ideas.
//
// 最后 maps one page 作为 initial stack.
//
// load_icode panics if it encounters problems.
//  - How might load_icode fail?  What might be wrong with the given input?
//
static void load_icode(struct Env* e, uint8_t* binary) {
    // Hints:
    //  Load each program segment into virtual memory
    //  at the address specified in the ELF segment header.
    //  You should only load segments with ph->p_type == ELF_PROG_LOAD.
    //  Each segment's virtual address can be found in ph->p_va
    //  and its size in memory can be found in ph->p_memsz.
    //  The ph->p_filesz bytes from the ELF binary, starting at
    //  'binary + ph->p_offset', should be copied to virtual address
    //  ph->p_va.  Any remaining memory bytes should be cleared to zero.
    //  (The ELF header should have ph->p_filesz <= ph->p_memsz.)
    //  Use functions from the previous lab to allocate and map pages.
    //
    //  All page protection bits should be user read/write for now.
    //  ELF segments are not necessarily page-aligned, but you can
    //  assume for this function that no two segments will touch
    //  the same virtual page.
    //
    //  You may find a function like region_alloc useful.
    //
    //  Loading the segments is much simpler if you can move data
    //  directly into the virtual addresses stored in the ELF binary.
    //  So which page directory should be in force during
    //  this function?
    //
    //  You must also do something with the program's entry point,
    //  to make sure that the environment starts executing there.
    //  What?  (See env_run() and env_pop_tf() below.)

    // LAB 3: Your code here.

    struct Elf* elf = (struct Elf*)binary;
    if (elf->e_magic != ELF_MAGIC) {
        panic("Elf binary sequence not valid at header magic number...\n");
    }

    // load each segment 所有程序段
    struct Proghdr *ph, *eph;
    ph = (struct Proghdr*)((uint8_t*)elf + elf->e_phoff);
    eph = ph + elf->e_phnum;
    // 转换到用户页目录，用户空间映射 忘记这个了！！！！
    lcr3(PADDR(e->env_pgdir));
    for (; ph < eph; ph++) {
        if (ph->p_type != ELF_PROG_LOAD)
            continue;
        if (ph->p_memsz < ph->p_filesz)
            panic("ELF size in memory less than size in file...\n");

        region_alloc(e, (void*)ph->p_va, ph->p_memsz);
        // set the rest to 0s according to Hints
        memset((void*)(ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
        // copy to virtual address
        memcpy((void*)ph->p_va, binary + ph->p_offset, ph->p_filesz);
    }

    // set entry in trap frame
    // other parts of env_tf is set in function env_alloc
    e->env_tf.tf_eip = elf->e_entry;

    // Now map one page for the program's initial stack
    // at virtual address USTACKTOP - PGSIZE.
    region_alloc(e, (void*)(USTACKTOP - PGSIZE), PGSIZE);

    // switch back to kernel address mappings 记得改回去
    lcr3(PADDR(kern_pgdir));
}
```
env_create()作用是新建一个进程。调用已经写好的 env_alloc() 函数即可，之后更改类型并且利用 load_icode() 读取 ELF。

```c
//
// Allocates a new env with env_alloc, loads the named elf
// binary into it with load_icode, and sets its env_type.
// This function is ONLY called during kernel initialization,
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void env_create(uint8_t* binary, enum EnvType type) {
    // LAB 3: Your code here.
    struct Env* newenv;
    if (env_alloc(&newenv, 0) < 0)
        panic("env_create: ");
    load_icode(newenv, binary);
    newenv->env_type = type;
}
```
env_run()
启动某个进程。注释已经非常详细地说明了怎么做，主要说下 env_pop_tf() 这个函数。该函数的作用是将 struct Trapframe 中存储的寄存器状态 pop 到相应寄存器中。查看之前写的 load_icode() 函数中的 e->env_tf.tf_eip = elf->e_entry 这一句，经过 env_pop_tf() 之后，指令寄存器的值即设置到了可执行文件的入口。
```c
//
// Context switch from curenv to env e.
// Note: if this is the first call to env_run, curenv is NULL.
//
// This function does not return.
//
void env_run(struct Env* e) {
    // Step 1: If this is a context switch (a new environment is running):
    //	   1. Set the current environment (if any) back to
    //	      ENV_RUNNABLE if it is ENV_RUNNING (think about
    //	      what other states it can be in),
    //	   2. Set 'curenv' to the new environment,
    //	   3. Set its status to ENV_RUNNING,
    //	   4. Update its 'env_runs' counter,
    //	   5. Use lcr3() to switch to its address space.
    // Step 2: Use env_pop_tf() to restore the environment's
    //	   registers and drop into user mode in the
    //	   environment.

    // Hint: This function loads the new environment's state from
    //	e->env_tf.  Go back through the code you wrote above
    //	and make sure you have set the relevant parts of
    //	e->env_tf to sensible values.

    // LAB 3: Your code here.
    if (curenv != NULL && curenv->env_status == ENV_RUNNING) {
        curenv->env_status = ENV_RUNNABLE;
    }

    curenv = e;
    curenv->env_status = ENV_RUNNING;
    curenv->env_runs++;
    lcr3(PADDR(curenv->env_pgdir));

    // unlock_kernel();
    // iret退出内核, 回到用户环境执行,
    // 在load_icode() 中 env_tf保存了可执行文件的eip等信息
    env_pop_tf(&curenv->env_tf);
    // panic("env_run not yet implemented");
}
```

### 处理中断和异常
在这一点上，int $0x30用户空间中的第一个系统调用指令是一个死胡同：一旦处理器进入用户模式，就无法退出。现在，您将需要实现基本的异常和系统调用处理，以便内核有可能从用户模式代码中恢复对处理器的控制。您应该做的第一件事是完全熟悉x86中断和异常机制。

异常和中断都是“受保护的控制权转移” (protected control transfers)，使处理器从用户模式转到内核模式，用户模式代码无法干扰内核或者其他进程的运行。区别在于，中断是由处理器外部的异步事件产生；而异常是由目前处理的代码产生，例如除以0。

为保证切换是被保护的，处理器的中断、异常机制使得正在运行的代码无须选择在哪里以什么方式进入内核。相反，处理器将保证内核在严格的限制下才能被进入。在 x86 架构下，一共有两个机制提供这种保护：

1. 中断描述符表(Interrupt Descriptor Table, IDT)

处理器将确保从一些内核预先定义的条目才能进入内核，而不是由中断或异常发生时运行的代码决定。 \
x86 支持最多 256 个不同中断和异常的条目。每个包含一个中断向量，是一个 0~255 之间的数（那为什么叫向量？），代表中断来源：不同的设备以及错误类型。CPU 利用这些向量作为中断描述符表的索引。而这个表是内核定义在私有内存上（用户没有权限），就像全局描述符表(Global Descripter Table, GDT)一样。从表中恰当的条目，处理器可以获得：
* 需要加载到指令指针寄存器(EIP)的值，该值指向内核中处理这类异常的代码。
* 需要加载到代码段寄存器(CS)的值，其中最低两位表示优先级（这也是为什么说可以寻址 2^46 的空间而不是 2^48)。 在JOS 中，所有的异常都在内核模式处理，优先级为0 (用户模式为3)。

2. 任务状态段(Task State Segment, TSS)

处理器需要保存中断和异常出现时的自身状态，例如 EIP 和 CS，以便处理完后能返回原函数继续执行。但是存储区域必须禁止用户访问，避免恶意代码或 bug 的破坏。 \
因此，当 x86 处理器处理从用户到内核的模式转换时，也会切换到内核栈。而 TSS 指明段选择器和栈地址。处理器将`SS, ESP, EFLAGS, CS, EIP` 压入新栈，然后从 IDT 读取 CS 和 EIP，根据新栈设置 ESP 和 SS。 \
JOS 仅利用 `TSS` 来定义需要切换的内核栈。由于内核模式在 JOS 优先级是 0，因此处理器用 `TSS` 的 `ESP0` 和 `SS0` 来定义内核栈，无需 `TSS` 结构体中的其他内容。其中， `SS0` 存储的是 `GD_KD(0x10)`，`ESP0` 种存储的是 `KSTACKTOP(0xf0000000)`。相关定义在`inc/memlayout.h`中可以找到。

### 中断和异常的类型
x86 的所有异常可以用中断向量 0~31 表示，对应 IDT 的第 0~31 项。例如，页错误产生一个中断向量为 14 的异常。大于 32 的中断向量表示的都是中断，其中，软件中断用 int 指令产生，而硬件中断则由硬件在需要关注的时候产生。

一个例子 \
通过一个例子来理解上面的知识。假设处理器正在执行用户环境的代码，遇到了"除0"异常。

1. 处理器切换到内核栈，利用了上文 TSS 中的 `ESP0` 和 `SS0`。 
2. 处理器将异常参数 push 到了内核栈。一般情况下，按顺序 `push SS, ESP, EFLAGS, CS, EIP`
3. 存储这些寄存器状态的意义是：SS(堆栈选择器) 的低 16 位与 ESP 共同确定当前栈状态；EFLAGS(标志寄存器)存储当前FLAG；CS(代码段寄存器) 和 EIP(指令指针寄存器) 确定了当前即将执行的代码地址，E 代表"扩展"至32位。根据这些信息，就能保证处理中断结束后能够恢复到中断前的状态。
4. 因为我们将处理一个"除0"异常，其对应中断向量是0，因此，处理器读取 IDT 的条目0，设置 CS:EIP 指向该条目对应的处理函数。
5. 处理函数获得程序控制权并且处理该异常。例如，终止进程的运行。

```c
                     +--------------------+ KSTACKTOP             
                     | 0x00000 | old SS   |     " - 4
                     |      old ESP       |     " - 8
                     |     old EFLAGS     |     " - 12
                     | 0x00000 | old CS   |     " - 16
                     |      old EIP       |     " - 20 <---- ESP 
                     +--------------------+             
```
有的时候也会多压入一个错误代码：(页错误异常（中断向量=14）就是一个重要的例子)
```c
                     +--------------------+ KSTACKTOP             
                     | 0x00000 | old SS   |     " - 4
                     |      old ESP       |     " - 8
                     |     old EFLAGS     |     " - 12
                     | 0x00000 | old CS   |     " - 16
                     |      old EIP       |     " - 20
                     |     error code     |     " - 24 <---- ESP
                     +--------------------+             
```
这样的方式同样可以处理嵌套异常和中断，就是继续往堆栈里面压东西就好啦。

嵌套的异常和中断
内核和用户进程都会引起异常和中断。然而，仅在从用户环境进入内核时才会切换栈。如果中断发生时已经在内核态了(此时， CS 寄存器的低 2bit 为 00) ，那么 CPU 就直接将状态压入内核栈，不再需要切换栈。这样，内核就能处理内核自身引起的"嵌套异常"，这是实现保护的重要工具。 \
如果处理器已经处于内核态，然后发生了嵌套异常，由于它并不进行栈切换，所以无须存储 SS 和 ESP 寄存器状态。对于不包含 error code 的异常，在进入处理函数前内核栈状态如下所示：
```c
                 +--------------------+ <---- old ESP
                 |     old EFLAGS     |     " - 4
                 | 0x00000 | old CS   |     " - 8
                 |      old EIP       |     " - 12
                 +--------------------+             
```
### 建立中断描述符表(IDT)
通过上文，已经了解到了建立 IDT 以及处理异常所需要的基本信息。头文件 inc/trap.h 和 kern/trap.h 包含了与中断和异常相关的定义，需要仔细阅读。其中 kern/trap.h 包含内核私有定义，而 inc/trap.h 包含对内核以及用户进程和库都有用的定义。 \

现在，您应该具有设置IDT和处理JOS中的异常所需的基本信息。现在，您将设置IDT以处理中断向量0-31（处理器异常。您应该实现的总体控制流程如下所示：
```c
      IDT                   trapentry.S         trap.c
   
+----------------+                        
|   &handler1    |---------> handler1:          trap (struct Trapframe *tf)
|                |             // do stuff      {
|                |             call trap          // handle the exception/interrupt
|                |             // ...           }
+----------------+
|   &handler2    |--------> handler2:
|                |            // do stuff
|                |            call trap
|                |            // ...
+----------------+
       .
       .
       .
+----------------+
|   &handlerX    |--------> handlerX:
|                |             // do stuff
|                |             call trap
|                |             // ...
+----------------+
```
每个异常或中断都应在trapentry.S中拥有自己的处理程序， 并trap_init()应使用这些处理程序的地址来初始化IDT。每个处理程序都应在堆栈上构建一个struct Trapframe （请参见inc/trap.h），并使用指向Trapframe的指针进行调用 trap()（在trap.c中）。 trap()然后处理异常/中断或调度到特定的处理函数。

练习4就是要编辑 trapentry.S 和 trap.c 并实现上述功能，它没有很明确地告诉你每个步骤，不过给了很多提示。

首先来看 trapentry.S，这部分其实和 xv6 里面基本一样，如果有什么不清楚的话照抄即可。需要注意的是：

TRAPHANDLER_NOEC 对应着上述第一种堆栈，TRAPHANDLER 对应第二种，多加了一个 error code 参数；
堆栈里面整个内存布局和 struct Trapframe 有个一一对应的联系；
pushal 很有用，去查一下；
ds 和 es 寄存器是不能直接设置的，要中转。

### 练习4 & challenge

kern/trapentry.inc
新建一个文件kern/trapentry.inc，列出以下各项。TH(n)表示不会产生error-code的第n号中断的trap handler；THE(n)表示会产生error-code的第n号中断的trap handler。
```c
TH(0)
TH(1)
TH(2)
TH(3)
TH(4)
TH(5)
TH(6)
TH(7)
THE(8)
THE(10)
THE(11)
THE(12)
THE(13)
THE(14)
TH(16)
THE(17)
TH(18)
TH(19)
TH(48)
```
kern/trapentry.S
在kern/trapentry.S中定义TH和THE，引入kern/trapentry.inc，构成各个中断处理例程：
```c
#define TH(n) \
TRAPHANDLER_NOEC(handler##n, n)

#define THE(n) \
TRAPHANDLER(handler##n, n)

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
#include <kern/trapentry.inc>
```
_alltraps
先补齐trapframe所需要的信息，更改段寄存器，接着将ESP压栈作为参数struct Trapframe* tf并调用trap函数。

```c
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
```
这部分较有难度，首先要搞明白，栈是从高地址向低地址生长，而结构体在内存中的存储是从低地址到高地址。而 cpu 以及TRAPHANDLER宏已经将压栈工作进行到了中断向量部分，若要形成一个 Trapframe，则还应该依次压入 ds, es以及 struct PushRegs中的各寄存器（倒序，可使用 pusha指令）。此后还需要更改数据段为内核的数据段。**注意，不能用立即数直接给段寄存器赋值**。因此不能直接写movw $GD_KD, %ds。

kern/trap.c
在kern/trap.c中定义TH和THE，引入kern/trapentry.inc，构成中断向量表：
```c
#define TH(n) extern void handler##n (void);
#define THE(n) TH(n)

#include <kern/trapentry.inc>

#undef THE
#undef TH

#define TH(n) [n] = handler##n,
#define THE(n) TH(n)

static void (* handlers[256])(void) = {
#include <kern/trapentry.inc>
};

#undef THE
#undef TH
```

trap_init
考虑到处理的方便，将所有的中断向量都设为中断门，也就是处理过程中屏蔽外部中断。
```c
void trap_init(void){
    extern struct Segdesc gdt[];
    
    // LAB 3: Your code here.
    for (int i = 0; i < 32; ++i) 
        SETGATE(idt[i], 0, GD_KT, handlers[i], 0);
    SETGATE(idt[T_BRKPT], 0, GD_KT, handlers[T_BRKPT], 3);
    SETGATE(idt[T_SYSCALL], 0, GD_KT, handlers[T_SYSCALL], 3);
    // Per-CPU setup 
    trap_init_percpu();
}
```
重点是两个问题。

函数如何声明？
这个问题其实已经在 trapentry.S 的注释里回答了。注意该函数已经是全局的了，不需要再添加 extern 画蛇添足。
SETGATE 如何使用？
参见 inc/mmu.h 中的函数定义。
```c
#define SETGATE(gate, istrap, sel, off, dpl)            
{                               
    (gate).gd_off_15_0 = (uint32_t) (off) & 0xffff;     
    (gate).gd_sel = (sel);                  
    (gate).gd_args = 0;                 
    (gate).gd_rsv1 = 0;                 
    (gate).gd_type = (istrap) ? STS_TG32 : STS_IG32;    
    (gate).gd_s = 0;                    
    (gate).gd_dpl = (dpl);                  
    (gate).gd_p = 1;                    
    (gate).gd_off_31_16 = (uint32_t) (off) >> 16;       
}
```
```c
| gate                             | 这是一个 struct Gatedesc。                           |
| istrap                           | 该中断是 trap(exception) 则为1, 是 interrupt 则为0。  |
| sel                              | 代码段选择器 进入内核的话是 GD_KT                      |
| off                              | 相对于段的偏移,简单来说就是函数地址                    |
| dpl(Descriptor Privileged Level) | 权限描述符                                           |
```
### 问题
1.
What is the purpose of having an individual handler function for each exception/interrupt? (i.e., if all exceptions/interrupts were delivered to the same handler, what feature that exists in the current implementation could not be provided?)
为每个异常/中断设置单独的处理函数的目的是什么？（即，如果所有异常/中断都传递给了同一处理程序，则无法提供当前实现中存在的功能？）

因为有的中断硬件会多压一个错误码，采用分立的handler目的在于处理这种不一致以提供一致的trapframe。

2.
Did you have to do anything to make the user/softint program behave correctly? The grade script expects it to produce a general protection fault (trap 13), but softint's code says int $14. Why should this produce interrupt vector 13? What happens if the kernel actually allows softint's int $14 instruction to invoke the kernel's page fault handler (which is interrupt vector 14)?
您是否需要做任何事情来使 softint 程序正常运行？等级脚本期望它会产生一般的保护故障（陷阱13），但是softint的代码说 int $14。 为什么要产生中断向量13？如果内核实际上允许softint的 int $14指令调用内核的页面错误处理程序（即中断向量14），会发生什么？

因为14号中断向量的DPL为0，即内核特权级。根据x86 ISA的说明（https://www.felixcloutier.com/x86/intn:into:int3:int1）：
```
IF software interrupt (* Generated by INT n, INT3, or INTO; does not apply to INT1 *)
        THEN
            IF gate DPL < CPL (* PE = 1, DPL < CPL, software interrupt *)
                THEN #GP(error_code(vector_number,1,0)); FI;
                (* idt operand to error_code set because vector is used *)
                (* ext operand to error_code is 0 because INT n, INT3, or INTO*)
```
在用户态使用int $14，会触发保护异常（Gerenal Protection Fault，伪代码中的GP）。

如果内核允许用户主动触发缺页异常，将会导致严重的不一致性，内核将难以辨识用户态触发的缺页异常到底因何发生。

具体进入 trap 的时候，我们在 alltraps 之后调用了 trap 函数，通过 trap_dispatch 进行进一步处理，然后调用 env_run 返回用户态。主要处理逻辑在 trap_dispatch 里面。不过我们暂时还不用修改，这样就已经能通过 partA 啦。


## Part B: Page Faults, Breakpoints Exceptions, and System Calls
用户进程通过系统调用来让内核为他们服务。当用户进程召起一次系统调用，处理器将进入内核态，处理器以及内核合作存储用户进程的状态，内核将执行适当的代码来完成系统调用，最后返回用户进程继续执行。实现细节各个系统有所不同。 \
JOS 内核使用 int 指令来触发一个处理器中断。特别的，我们使用 int $0x30 作为系统调用中断。它并不能由硬件产生，因此使用它不会产生歧义。 \
应用程序会把系统调用号 (与中断向量不是一个东西) 以及系统调用参数传递给寄存器。这样，内核就不用在用户栈或者指令流里查询这些信息。系统调用号将存放于%eax，参数（至多5个）会存放于%edx, %ecx,%ebx, %edi 以及 %esi，调用结束后，内核将返回值放回到%eax。之所以用 %eax 来传递返回值，是由于系统调用导致了栈的切换。

kern 中有一套 syscall.h syscall.c，inc和lib中又有一套syscall.h syscall.c。需要理清这两者之间的关系。

**一个是public的一个是private的(个人理解)**

###  Exercise 5
简答地识别trapno并派发即可：
```c
    switch(tf->tf_trapno) {
    case T_PGFLT: {
        page_fault_handler(tf);
        return;
    }
    default:
        break;
    }
```
### Exercise 6
在switch语句中添加一个case即可：
```c
    case T_BRKPT: {
        monitor(tf);
        return;
    }
```
### Questions
3. The break point test case will either generate a break point exception or a general protection fault depending on how you initialized the break point entry in the IDT (i.e., your call to SETGATE from trap_init). Why? How do you need to set it up in order to get the breakpoint exception to work as specified above and what incorrect setup would cause it to trigger a general protection fault?

断点测试用例将生成断点异常或一般保护错误，具体取决于您在 IDT 中初始化断点条目的方式（即，您从 trap_init 调用 SETGATE）。 为什么？ 您需要如何设置它才能使断点异常按上面指定的方式工作，以及什么不正确的设置会导致它触发一般保护错误？

该test使用int $3指令触发断点异常，因此3号中断向量的DPL必须设为3，即用户特权级。如果没有如此设置，将会触发保护异常。

4. What do you think is the point of these mechanisms, particularly in light of what the user/softint test program does?

意义在于防止用户随意地触发异常，但同时又留出一个接口供用户使用系统服务。

### Exercise 7
在内核中为中断向量 T_SYSCALL 添加一个处理程序。 您将不得不编辑 kern/trapentry.S 和 kern/trap.c 的 trap_init()。 您还需要更改 trap_dispatch() 以通过使用适当的参数调用 syscall()（在 kern/syscall.c 中定义）来处理系统调用中断，然后安排返回值在 % 中传递回用户进程 伊克斯。 最后，您需要在 kern/syscall.c 中实现 syscall()。 如果系统调用号无效，请确保 syscall() 返回 -E_INVAL。 您应该阅读并理解 lib/syscall.c（尤其是内联汇编例程）以确认您对系统调用接口的理解。 通过为每个调用调用相应的内核函数来处理 inc/syscall.h 中列出的所有系统调用。

在trap_dispatch中的switch语句添加一个case，通过trapframe获得syscall参数，并设置返回值。
```c
    case T_SYSCALL: {
        // eax, edx, ecx, ebx, edi, esi;
        struct PushRegs *r = &tf->tf_regs;
        r->reg_eax = syscall(
            r->reg_eax, 
            r->reg_edx, 
            r->reg_ecx, 
            r->reg_ebx, 
            r->reg_edi, 
            r->reg_esi
        );
        return;
    }
```
如果编译器开启了-Werror,要记得在syscall中使用的时候进行以下类型转换

```c
int32_t syscall(uint32_t syscallno,
                uint32_t a1,
                uint32_t a2,
                uint32_t a3,
                uint32_t a4,
                uint32_t a5) {
    // Call the function corresponding to the 'syscallno' parameter.
    // Return any appropriate return value.
    // LAB 3: Your code here.

    // panic("syscall not implemented");
    switch (syscallno) {
        case SYS_cputs:
            sys_cputs((const char*)a1, a2);
            return 0;
        case (SYS_cgetc):
            return sys_cgetc();
        case SYS_getenvid:
            return sys_getenvid();
        case SYS_env_destroy:
            return sys_env_destroy(sys_getenvid());
        case NSYSCALLS:
        default:
            return -E_INVAL;
    }
}
```
注意后续练习也需要往这个里面加syscall

### 补充知识：GCC内联汇编
其语法固定为：
```c
asm volatile ("asm code"：output：input：changed);
asm volatile("int %1\n"
            : "=a" (ret)
            : "i" (T_SYSCALL),
            "a" (num),
            "d" (a1),
            "c" (a2),
            "b" (a3),
            "D" (a4),
            "S" (a5)
            : "cc", "memory");
```
| 限定符          | 意义                              |
| --------------- | --------------------------------- |
| "m","v","o"     | 内存单元                          |
| "r"             | 任何寄存器                        |
| "q"             | 寄存器eax,ebx,ecx,edx之一         |
| "i","h"         | 直接操作数                        |
| "E","F"         | 浮点数                            |
| "g"             | 任意                              |
| "a","b","c","d" | 分别表示寄存器 eax、ebx、ecx和edx |
| "S","D"         | 寄存器esi、edi                    |
| "I"             | 常数 (0至31)                      |

除了这些约束之外, 输出值还包含一个约束修饰符:

| 输出修饰符 | 描述                                         |
| ---------- | -------------------------------------------- |
| +          | 可以读取和写入操作数                         |
| =          | 只能写入操作数                               |
| %          | 如果有必要操作数可以和下一个操作数切换       |
| &          | 在内联函数完成之前, 可以删除和重新使用操作数 |

通过 exercise 7，可以看出 JOS系 统调用的步骤为：

1. 用户进程使用 inc/ 目录下暴露的接口
2. lib/syscall.c 中的函数将系统调用号及必要参数传给寄存器，并引起一次 int $0x30 中断
3. kern/trap.c 捕捉到这个中断，并将 TrapFrame 记录的寄存器状态作为参数，调用处理中断的函数 
4. kern/syscall.c 处理中断

### 用户进程启动
用户进程从 lib/entry.S 开始运行。经过一些设置，调用了 lib/libmain.c 下的 libmain() 函数。在 libmain() 中，我们需要把全局指针 thisenv 指向该程序在 envs[] 数组中的位置。
libmain() 会调用 umain，即用户进程的main函数。在user/hello.c中，可以看到其内容为：
```c
void umain(int argc, char **argv){
    cprintf("hello, world\n");
    cprintf("i am environment %08x\n", thisenv->env_id);  // 之前就在这里报错，因为thisenv = 0
}
```
在 Exercise 8 中，我们将设置好 thisenv，这样就能正常运行用户进程了。这也是我们第一次用到内存的 UENVS 区域。
```c
// An environment ID 'envid_t' has three parts:
//
// +1+---------------21-----------------+--------10--------+
// |0|          Uniqueifier             |   Environment    |
// | |                                  |      Index       |
// +------------------------------------+------------------+
//                                       \--- ENVX(eid) --/
// 环境索引 ENVX(eid) 等于 envs[] 数组中的环境索引。 
// 唯一标识符区分在不同时间创建但共享相同环境索引的环境。
// 所有真实环境都大于 0（因此符号位为零）。 
// envid_ts 小于 0 表示错误。 envid_t == 0 比较特殊，代表当前环境。
```

### Exercise 8.
Add the required code to the user library, then boot your kernel. You should see user/hello print "hello, world" and then print "i am environment 00001000". user/hello then attempts to "exit" by calling sys_env_destroy() (see lib/libmain.c and lib/exit.c). Since the kernel currently only supports one user environment, it should report that it has destroyed the only environment and then drop into the kernel monitor. You should be able to get make grade to succeed on the hello test.

在 lib/libmain.c 中把 thisenv = 0 改为：
```c
    thisenv = &envs[ENVX(sys_getenvid())];
```

## 页错误 & 内存保护
内存保护是操作系统的关键功能，它确保了一个程序中的错误不会导致其他程序或是操作系统自身的崩溃。 \
操作系统通常依赖硬件的支持来实现内存保护。操作系统会告诉硬件哪些虚拟地址可用哪些不可用。当某个程序想访问不可用的内存地址或不具备权限时，处理器将在出错指令处停止程序，然后陷入内核。如果错误可以处理，内核就处理并恢复程序运行，否则无法恢复。 \
作为可以修复的错误，设想某个自动生长的栈。在许多系统中内核首先分配一个页面给栈，如果某个程序访问了页面外的空间，内核会自动分配更多页面以让程序继续。这样，内核只用分配程序需要的栈内存给它，然而程序感觉仿佛可以拥有任意大的栈内存。 \
系统调用也为内存保护带来了有趣的问题。许多系统调用接口允许用户传递指针给内核，这些指针指向待读写的用户缓冲区。内核处理系统调用的时候会对这些指针解引用。这样就带来了两个问题：

1. 内核的页错误通常比用户进程的页错误严重得多，如果内核在操作自己的数据结构时发生页错误，这就是一个内核bug，会引起系统崩溃。因此，内核需要记住这个错误是来自用户进程。
2. 内核比用户进程拥有更高的内存权限，用户进程给内核传递的指针可能指向一个只有内核能够读写的区域，内核必须谨慎避免解引用这类指针，因为这样可能导致内核的私有信息泄露或破坏内核完整性。

我们将对用户进程传给内核的指针做一个检查来解决这两个问题。内核将检查指针指向的是内存中用户空间部分，页表也允许内存操作。

### 练习9
修改trap.c,如果是在内核态下发生页面错误,应该调用panic,阅读kern/pmap.c中的user_mem_assert并在该文件中实现user_mem_check函数,修改一下 kern/syscall.c 去检查系统调用的输入参数。启动内核后，运行 user/buggyhello 程序，用户环境应该被销毁，内核不会panic，应该会打印出如下信息：

```c
[00001000] user_mem_check assertion failure for va 00000001
[00001000] free env 00001000
Destroyed the only environment - nothing more to do!
```
在 kern/trap.c 中加入判断页错误来源。原理见 IDT 表部分的讲解。

**我这里脑残了，一开始没加括号，优先级出错了**
```c
void page_fault_handler(struct Trapframe *tf){
    ···
    // LAB 3: Your code here.
    // 在这里判断 cs 的低 2bit
    if ((tf->tf_cs & 3) == 0) panic("Page fault in kernel-mode");
    ···
}
```

在 kern/pmap.c 中修改检查用户内存的部分。需要注意的是由于需要存储第一个访问出错的地址，va 所在的页面需要单独处理一下，不能直接对齐。

```c
// Check that an environment is allowed to access the range of memory
// [va, va+len) with permissions 'perm | PTE_P'.
// Normally 'perm' will contain PTE_U at least, but this is not required.
// 'va' and 'len' need not be page-aligned; you must test every page that
// contains any of that range.  You will test either 'len/PGSIZE',
// 'len/PGSIZE + 1', or 'len/PGSIZE + 2' pages.
//
// A user program can access a virtual address if (1) the address is below
// ULIM, and (2) the page table gives it permission.  These are exactly
// the tests you should implement here.
//
// If there is an error, set the 'user_mem_check_addr' variable to the first
// erroneous virtual address.
//
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
//  user_mem_check 函数的功能是检查一下当前用户态程序是否有对虚拟地址空间 [va,
//  va+len] 的 perm| PTE_P 访问权限。
// 自然我们要做的事情应该是，先找到这个虚拟地址范围对应于当前用户态程序的页表中的页表项，
// 然后再去看一下这个页表项中有关访问权限的字段，是否包含 perm | PTE_P，
// 只要有一个页表项是不包含的，就代表程序对这个范围的虚拟地址没有 perm|PTE_P
// 的访问权限。

int user_mem_check(struct Env* env, const void* va, size_t len, int perm) {
    // LAB 3: Your code here.
    void* end = ROUNDUP((void*)(va + len), PGSIZE);
    void* start = ROUNDDOWN((void*)va, PGSIZE);
    pte_t* cur = NULL;
    for (; start < end; start += PGSIZE) {
        cur = pgdir_walk(env->env_pgdir, (void*)start, 0);
        if ((int)start > ULIM || cur == NULL ||
            ((uint32_t)(*cur) & perm) != perm) {
            if (start == ROUNDDOWN((char*)va, PGSIZE))
                user_mem_check_addr = (uintptr_t)va;
            else
                user_mem_check_addr = (uintptr_t)start;
            return -E_FAULT;
        }
    }
    return 0;
}
```
kern/syscall.c
当前的syscall只有cons_cputs有涉及到访存，故只需在其中加入内存检查即可：
```c
    user_mem_assert(curenv, s, len, PTE_U);
```
debuginfo_eip
加入如下检查语句：
```c
···
// Make sure this memory is valid.
// Return -1 if it is not.  Hint: Call user_mem_check.
// LAB 3: Your code here.
if (curenv && 
        user_mem_check(curenv, (void*)usd, 
                        sizeof(struct UserStabData), PTE_U) < 0)
    return -1;
···
// Make sure the STABS and string table memory is valid.
// LAB 3: Your code here.
if (curenv && (
        user_mem_check(curenv, (void*)stabs, 
                        (uintptr_t)stab_end - (uintptr_t)stabs, PTE_U) < 0 || 
        user_mem_check(curenv, (void*)stabstr, 
                        (uintptr_t)stabstr_end - (uintptr_t)stabstr, PTE_U) < 0))
    return -1;
···
```
![b](/pic/lab3/backtrace.png)

