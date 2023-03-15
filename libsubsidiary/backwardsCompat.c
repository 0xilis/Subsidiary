#include "libsubsidiary.h"

void MSHookMessageEx(Class _class, SEL message, IMP hook, IMP *old) {
 SubsidiaryGenericHookMethod(_class, message, hook, *old);
}

void SubHookMessageEx(Class class, SEL selector, void *replacement, void *old_ptr, bool *created_imp_ptr) {
 SubsidiaryGenericHookMethod(class, selector, *replacement, *old_ptr);
}

int LBHookMessage(Class objcClass, SEL selector, void *replacement, void *old_ptr) {
 SubsidiaryGenericHookMethod(objcClass, selector, *replacement, *old_ptr);
 return 0;
}
