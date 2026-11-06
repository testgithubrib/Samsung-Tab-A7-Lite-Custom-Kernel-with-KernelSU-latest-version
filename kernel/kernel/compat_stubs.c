#include <linux/export.h>
#include <linux/types.h>

char rcu_lock_map[64] = {0};
EXPORT_SYMBOL(rcu_lock_map);

int debug_lockdep_rcu_enabled(void)
{
	return 0;
}
EXPORT_SYMBOL(debug_lockdep_rcu_enabled);

void lock_acquire(void *lock, unsigned int subclass, int trylock, int read, int check, void *nest_lock, unsigned long ip)
{
}
EXPORT_SYMBOL(lock_acquire);

void lock_release(void *lock, int nested, unsigned long ip)
{
}
EXPORT_SYMBOL(lock_release);

void lockdep_rcu_suspicious(const char *file, const int line, const char *s)
{
}
EXPORT_SYMBOL(lockdep_rcu_suspicious);
