// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/assert.h>
#include <inc/memlayout.h>
#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/kdebug.h>
#include <kern/monitor.h>
#include <kern/pmap.h>

#define CMDBUF_SIZE 80  // enough for one VGA text line

struct Command {
    const char* name;
    const char* desc;
    // return -1 to force monitor to exit
    int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
    {"help", "Display this list of commands", mon_help},
    {"kerninfo", "Display information about the kernel", mon_kerninfo},
    {"showmaps", "Show the mappings between given virtual memoryrange",
     mon_showmappings},
    {"setperm", "Set the permission bits of a given mapping", mon_setperm},
    {"dumpmem", "Dump the content of a given virtual/physical memory range ",
     mon_dumpmem},
};

/***** Implementations of basic kernel monitor commands *****/

int mon_help(int argc, char** argv, struct Trapframe* tf) {
    int i;

    for (i = 0; i < ARRAY_SIZE(commands); i++)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
    return 0;
}

int mon_kerninfo(int argc, char** argv, struct Trapframe* tf) {
    extern char _start[], entry[], etext[], edata[], end[];

    cprintf("Special kernel symbols:\n");
    cprintf("  _start                  %08x (phys)\n", _start);
    cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
    cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
    cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
    cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
    cprintf("Kernel executable memory footprint: %dKB\n",
            ROUNDUP(end - entry, 1024) / 1024);
    return 0;
}

int mon_backtrace(int argc, char** argv, struct Trapframe* tf) {
    // Your code here.
    return 0;
}

int mon_showmappings(int argc, char** argv, struct Trapframe* tf) {
    // 参数检查
    static const char* msg = "Usage: showmaps <start> [<length>]\n";

    if (argc < 2)
        goto usage;

    char* errChar;
    uintptr_t start_addr = (uintptr_t)strtol(argv[1], &errChar, 16);
    if (*errChar) {
        cprintf("Invalid virtual address: %s.\n", argv[1]);
        return -1;
    }
    size_t vlen = argc >= 3 ? (size_t)strtol(argv[2], &errChar, 0) : 1;
    if (*errChar) {
        cprintf("Invalid virtual address: %s.\n", argv[2]);
        return -1;
    }
    uintptr_t end_addr = start_addr + vlen;
    if (*errChar) {
        cprintf("Invalid virtual address: %s.\n", argv[2]);
        return -1;
    }
    if (start_addr > end_addr) {
        cprintf("start_addr > end_addr Address error maybe overflow \n");
        return -1;
    }
    // 按页对齐
    start_addr = ROUNDDOWN(start_addr, PGSIZE);
    end_addr = ROUNDUP(end_addr, PGSIZE);

    // 开始循环
    uintptr_t cur_addr = start_addr;
    cprintf("| Virtual address | physical address | permission |\n");
    cprintf("| --------------- | ---------------- | ---------- |\n");
    while (cur_addr <= end_addr) {
        pte_t* cur_pte = pgdir_walk(kern_pgdir, (void*)cur_addr, 0);
        // 记录自己一个错误
        // if ( !cur_pte) {
        if (!cur_pte || !(*cur_pte & PTE_P)) {
            cprintf("| 0x%08x      | not mapped       | ---------- |\n",
                    cur_addr);
        } else {
            // 进入 else 分支说明 PTE_P 肯定为真了
            cprintf(
                "| 0x%08x      | 0x%08x       | -%c----%c%cP  |\n", cur_addr,
                PTE_ADDR(*cur_pte), (*cur_pte & PTE_PS) ? 'S' : '-',
                (*cur_pte & PTE_W) ? 'W' : '-', (*cur_pte & PTE_U) ? 'U' : '-');
        }
        cur_addr += PGSIZE;
    }
    return 0;
usage:
    cprintf(msg);
    return 0;
}
int mon_setperm(int argc, char** argv, struct Trapframe* tf) {
    static const char* msg = "Usage: setperm <virtual address> <permission>\n";

    if (argc != 3)
        goto usage;

    uintptr_t va;
    uint16_t perm;
    pte_t* pte;
    char* errChar;

    va = (uintptr_t)strtol(argv[1], &errChar, 0);
    if (*errChar) {
        cprintf("Invalid virtual address: %s.\n", argv[1]);
        return -1;
    }
    perm = (uint16_t)strtol(argv[2], &errChar, 0);
    if (*errChar) {
        cprintf("Invalid perm: %s.\n", argv[2]);
        return -1;
    };

    pte = pgdir_walk(kern_pgdir, (void*)va, 0);
    if (pte && *pte & PTE_P) {
        *pte = (*pte & ~0xFFF) | (perm & 0xFFF) | PTE_P;
        cprintf("SET PERM SUCC\n");
    } else {
        cprintf("VA NOT MAPPED\n");
    }
    return 0;

usage:
    cprintf(msg);
    return 0;
}

static void dump_vm(uint32_t mstart, uint32_t mend) {
    uint32_t next;
    pte_t* pte;
    while (mstart < mend) {
        if (!(pte = pgdir_walk(kern_pgdir, (void*)mstart, 0))) {
            next = MIN((uint32_t)PGADDR(PDX(mstart) + 1, 0, 0), mend);
            for (; mstart < next; ++mstart)
                cprintf("[VA: 0x%08x, PA: No mapping]: None\n", mstart);
        } else if (!(*pte & PTE_P)) {
            next = MIN((uint32_t)PGADDR(PDX(mstart), PTX(mstart) + 1, 0), mend);
            for (; mstart < next; ++mstart)
                cprintf("[VA: 0x%08x, PA: No mapping]: None\n", mstart);
        } else {
            next = MIN((uint32_t)PGADDR(PDX(mstart), PTX(mstart) + 1, 0), mend);
            for (; mstart < next; ++mstart)
                cprintf("[VA: 0x%08x, PA: 0x%08x]: %02x\n", mstart,
                        PTE_ADDR(*pte) | PGOFF(mstart), *(uint8_t*)mstart);
        }
    }
}

static void dump_pm(uint32_t mstart, uint32_t mend) {
    static const uint32_t map_base = 0;
    uint32_t next, base;

    while (mstart < mend) {
        next = MIN(ROUNDUP(mstart + 1, PGSIZE), mend);
        base = ROUNDDOWN(mstart, PGSIZE);
        page_insert(kern_pgdir, &pages[base / PGSIZE], (void*)map_base, PTE_P);
        for (; mstart < next; ++mstart)
            cprintf("[PA: 0x%08x]: %02x\n", mstart,
                    *((uint8_t*)(mstart - base + map_base)));
    }
    page_remove(kern_pgdir, (void*)map_base);
}

int mon_dumpmem(int argc, char** argv, struct Trapframe* tf) {
    static const char* msg =
        "Usage: dumpmem [option] <start> <length>\n\t-p, --physical\tuse "
        "physical address\n";

    int phys = 0;

    if (argc == 4) {
        int i;
        for (i = 1; i < argc; ++i) {
            if (!strcmp(argv[i], "-p") || !strcmp(argv[i], "--physical")) {
                phys = 1;
                break;
            }
        }
        if (!phys)
            goto usage;
        for (int j = i; j < argc - 1; ++j)
            argv[j] = argv[j + 1];
    } else if (argc != 3) {
        goto usage;
    }

    uint32_t start_addr, end_addr;
    size_t mlen;
    char* errChar;
    start_addr = (uint32_t)strtol(argv[1], &errChar, 16);
    if (*errChar) {
        cprintf("Invalid virtual address: %s.\n", argv[1]);
        return -1;
    }
    mlen = (size_t)strtol(argv[2], &errChar, 16);
    if (*errChar) {
        cprintf("Invalid virtual address: %s.\n", argv[2]);
        return -1;
    }
    end_addr = start_addr + mlen;

    if (phys) {
        if (end_addr > npages * PGSIZE) {
            cprintf("Target memory out of range\n");
            return 0;
        }
        uint32_t next = MIN(end_addr, ~(uint32_t)0 - KERNBASE + 1);
        for (; start_addr < next; ++start_addr) {
            cprintf("[PA: 0x%08x]: %02x\n", start_addr,
                    *(uint8_t*)KADDR(start_addr));
        }
        if (start_addr < end_addr)
            dump_pm(start_addr, end_addr);
    } else {
        dump_vm(start_addr, end_addr);
    }
    return 0;

usage:
    cprintf(msg);
    return 0;
}

/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int runcmd(char* buf, struct Trapframe* tf) {
    int argc;
    char* argv[MAXARGS];
    int i;

    // Parse the command buffer into whitespace-separated arguments
    argc = 0;
    argv[argc] = 0;
    while (1) {
        // gobble whitespace
        while (*buf && strchr(WHITESPACE, *buf))
            *buf++ = 0;
        if (*buf == 0)
            break;

        // save and scan past next arg
        if (argc == MAXARGS - 1) {
            cprintf("Too many arguments (max %d)\n", MAXARGS);
            return 0;
        }
        argv[argc++] = buf;
        while (*buf && !strchr(WHITESPACE, *buf))
            buf++;
    }
    argv[argc] = 0;

    // Lookup and invoke the command
    if (argc == 0)
        return 0;
    for (i = 0; i < ARRAY_SIZE(commands); i++) {
        if (strcmp(argv[0], commands[i].name) == 0)
            return commands[i].func(argc, argv, tf);
    }
    cprintf("Unknown command '%s'\n", argv[0]);
    return 0;
}

void monitor(struct Trapframe* tf) {
    char* buf;

    cprintf("Welcome to the JOS kernel monitor!\n");
    cprintf("Type 'help' for a list of commands.\n");

    while (1) {
        buf = readline("K> ");
        if (buf != NULL)
            if (runcmd(buf, tf) < 0)
                break;
    }
}
