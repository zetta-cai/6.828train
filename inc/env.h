/* See COPYRIGHT for copyright information. */

#ifndef JOS_INC_ENV_H
#define JOS_INC_ENV_H

#include <inc/types.h>
#include <inc/trap.h>
#include <inc/memlayout.h>

typedef int32_t envid_t;

// An environment ID 'envid_t' has three parts:
//
// +1+---------------21-----------------+--------10--------+
// |0|          Uniqueifier             |   Environment    |
// | |                                  |      Index       |
// +------------------------------------+------------------+
//                                       \--- ENVX(eid) --/
//
// The environment index ENVX(eid) equals the environment's index in the
// 'envs[]' array.  The uniqueifier distinguishes environments that were
// created at different times, but share the same environment index.
//
// All real environments are greater than 0 (so the sign bit is zero).
// envid_ts less than 0 signify errors.  The envid_t == 0 is special, and
// stands for the current environment.

#define LOG2NENV 10
#define NENV (1 << LOG2NENV)
#define ENVX(envid) ((envid) & (NENV - 1))

// Values of env_status in struct Env
enum
{
	ENV_FREE = 0,
	ENV_DYING,
	ENV_RUNNABLE,
	ENV_RUNNING,
	ENV_NOT_RUNNABLE
};

// Special environment types
enum EnvType
{
	ENV_TYPE_USER = 0,
};

struct Env
{
	struct Trapframe env_tf; // Saved registers
	struct Env *env_link;	 // Next free Env
	envid_t env_id;			 // Unique environment identifier
	envid_t env_parent_id;	 // env_id of this env's parent
	enum EnvType env_type;	 // Indicates special system environments
	unsigned env_status;	 // Status of the environment
	uint32_t env_runs;		 // Number of times environment has run

	// Address space
	pde_t *env_pgdir; // Kernel virtual address of page dir
};
/*
env_tf:
这个类型的结构体在inc/trap.h文件中被定义，里面存放着当用户环境暂停运行时，所有重要寄存器的值。内核也会在系统从用户态切换到内核态时保存这些值，这样的话用户环境可以在之后被恢复，继续执行。
env_link:
这个指针指向在env_free_list中，该结构体的后一个free的Env结构体。当然前提是这个结构体还没有被分配给任意一个用户环境时，该域才有用。
env_id:
这个值可以唯一的确定使用这个结构体的用户环境是什么。当这个用户环境终止，内核会把这个结构体分配给另外一个不同的环境，这个新的环境会有不同的env_id值。
env_parent_id:
创建这个用户环境的父用户环境的env_id
env_type:
用于区别出来某个特定的用户环境。对于大多数环境来说，它的值都是 ENV_TYPE_USER.
env_status:
这个变量存放以下可能的值
ENV_FREE: 代表这个结构体是不活跃的，应该在链表env_free_list中。
ENV_RUNNABLE: 代表这个结构体对应的用户环境已经就绪，等待被分配处理机。
ENV_RUNNING: 代表这个结构体对应的用户环境正在运行。
ENV_NOT_RUNNABLE: 代表这个结构体所代表的是一个活跃的用户环境，但是它不能被调度运行，因为它在等待其他环境传递给它的消息。
ENV_DYING: 代表这个结构体对应的是一个僵尸环境。一个僵尸环境在下一次陷入内核时会被释放回收。
env_pgdir:
这个变量存放着这个环境的页目录的虚拟地址
*/
#endif // !JOS_INC_ENV_H
