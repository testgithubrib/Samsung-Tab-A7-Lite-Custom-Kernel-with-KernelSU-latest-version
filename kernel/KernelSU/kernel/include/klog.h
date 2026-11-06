#ifndef __KSU_H_KLOG
#define __KSU_H_KLOG

#include <linux/printk.h>
#include <linux/version.h>
#include <linux/uaccess.h>

#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 8, 0)
#ifndef strncpy_from_user_nofault
#define strncpy_from_user_nofault(dst, src, count) strncpy_from_unsafe_user(dst, src, count)
#endif
#ifndef copy_to_kernel_nofault
#define copy_to_kernel_nofault(dst, src, size) probe_kernel_write(dst, src, size)
#endif
#ifndef copy_from_kernel_nofault
#define copy_from_kernel_nofault(dst, src, size) probe_kernel_read(dst, src, size)
#endif
#ifndef copy_to_user_nofault
#define copy_to_user_nofault(dst, src, size) probe_user_write(dst, src, size)
#endif
#ifndef copy_from_user_nofault
#define copy_from_user_nofault(dst, src, size) probe_user_read(dst, src, size)
#endif
#endif

#ifdef pr_fmt
#undef pr_fmt
#define pr_fmt(fmt) "KernelSU: " fmt
#endif

#endif
