#include <objc/runtime.h>
#include "libsubsidiary.h"

//TODO: objc method hook functions actually aren't only a shim for class_replaceMethod, they actually have some more behavior, see kirb's comment https://www.reddit.com/r/jailbreak/comments/111kbp4/comment/j8hvk9l/ as well as substrate docs http://www.cydiasubstrate.com/api/c/MSHookMessageEx/

void SubsidiaryGenericHookMethod(Class cls, SEL name, IMP imp, IMP *orig) {
 Method hookMethod = class_getInstanceMethod(cls, name);
 if (!hookMethod) {
  printf("libsubsidiary error\n");
  return;
 }
 unsigned int numberOfMethods = 0;
 Method *methods = class_copyMethodList(cls, &numberOfMethods);
 for (Method m = methods; m < numberOfMethods; methods++) {
  if (method_getName(m) == name) {
   //the method is in this class so we can safely replace the method
   *orig = class_replaceMethod(cls, name, imp, method_getTypeEncoding(hookMethod));
   return;
  }
 }
 //the method is in the superclass, add the method instead to not override superclass and get IMP of orig
 *orig = method_getImplementation(hookMethod);
 class_addMethod(cls, name, imp, method_getTypeEncoding(hookMethod));
}
