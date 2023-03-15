#include <stdio.h>
#include <objc/runtime.h>
#include "libsubsidiary.h"

void MSHookMessageEx(Class _class, SEL message, IMP hook, IMP *old);
void SubHookMessageEx(Class class, SEL selector, void *replacement, void *old_ptr, bool *created_imp_ptr);
int LBHookMessage(Class objcClass, SEL selector, void *replacement, void *old_ptr);
