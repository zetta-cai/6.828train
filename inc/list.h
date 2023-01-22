#ifndef JOS_INC_LIST_H
#define JOS_INC_LIST_H
#include <inc/types.h>

// Return the offset of 'member' relative to the beginning of a struct type
#define offsetof(type, member) ((size_t)(&((type*)0)->member))

// obtain the container(struct) pointer from a member pointer
// defined for generic programming
#define container_of(ptr, type, member)                              \
    ({                                                               \
        const typeof(((type*)0)->member)* __mem_type_ptr = (ptr);    \
        ((type*)(((char*)__mem_type_ptr) - offsetof(type, member))); \
    })

// alias
#define list_entry(ptr, type, member) (container_of(ptr, type, member))
#define for_each_list(itr, list_head) \
    for (itr = (list_head)->next; itr != list_head; itr = itr->next)

struct list_head {
    struct list_head *prev, *next;
};
static inline void init_list_head(struct list_head* list_head) {
    list_head->next = list_head->prev = list_head;
}

static inline void __list_add(struct list_head* prev,
                              struct list_head* next,
                              struct list_head* new) {
    prev->next = next->prev = new;
    new->prev = prev;
    new->next = next;
};

static inline void __list_del(struct list_head* prev, struct list_head* next) {
    prev->next = next;
    next->prev = prev;
};

static inline void list_add(struct list_head* new, struct list_head* head) {
    __list_add(head, head->next, new);
}

static inline void list_del(struct list_head* entry) {
    __list_del(entry->prev, entry->next);
};

static inline void list_add_tail(struct list_head* new,
                                 struct list_head* head) {
    __list_add(head->prev, head, new);
}

static inline bool list_empty(struct list_head* list_head) {
    return list_head->next == list_head;
}
#endif /* !JOS_INC_LIST_H */