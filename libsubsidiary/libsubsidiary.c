#include <objc/runtime.h>
#include "libsubsidiary.h"

//TODO: objc method hook functions actually aren't only a shim for class_replaceMethod, they actually have some more behavior, see kirb's comment https://www.reddit.com/r/jailbreak/comments/111kbp4/comment/j8hvk9l/ as well as substrate docs http://www.cydiasubstrate.com/api/c/MSHookMessageEx/
//but for now, as wip im just gonna have it be a wrapper until i have time

void SubsidiaryGenericHookMethod(Class cls, SEL name, IMP imp, IMP *orig) {
 Method hookMethod = class_getInstanceMethod(cls, name);
 if (!hookMethod) {
  return -1;
 }
 *orig = class_replaceMethod(cls, name, imp, method_getTypeEncoding(hookMethod));
}
