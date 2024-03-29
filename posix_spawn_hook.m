//Snoolie K / 0xilis, Subsidiary
//Compile this file (posix_spawn_hook.m) as a dylib and inject into launchd
//This hooks posix_spawn / posix_spawnp using fishhook

#include <stdio.h>
#include <string.h>
#include <mach-o/dyld.h>
#include "fishhook.h"
#import <Foundation/Foundation.h>

static int (*orig_posix_spawn)(pid_t *restrict pid, const char *restrict path, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *restrict attrp, char *const orig_argv[restrict], char *const envp[restrict]);
static int (*orig_posix_spawnp)(pid_t *restrict pid, const char *restrict file, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *restrict attrp, char *const orig_argv[restrict], char *const envp[restrict]);

#define SUBSIDIARY_TWEAKINJECT_DIR = /usr/lib/TweakInject
#define SUBSIDIARY_SAFEMODE_FILE = /var/subsidiary/safemode

NSDictionary* filter;


NSString *findProcessInject(const char *path) {
 //get bundle id for process
 NSString *pathString = [NSString stringWithUTF8String:path];
 NSRange range = [pathString rangeOfString:@".app/" options:NSBackwardsSearch];
 if (range.length > 0) {
  //process is an app
  NSString *infoPlistPath = [NSString stringWithFormat:@"%@Info.plist",[pathString substringToIndex:range.location]]; //get the app's infoplist path from file path
  NSDictionary *mainDictionary = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
  if (mainDictionary) {
   return [filter objectForKey:[mainDictionary objectForKey:@"CFBundleIdentifier"]];
  }
 }
 //get the process name if we can't get bundle id
 NSRange range = [pathString rangeOfString:@"/" options:NSBackwardsSearch];
 if (range.length > 0) {
  //process is an app
  return [filter objectForKey:[pathString substringFromIndex:range.location]];
 } else {
  return [filter objectForKey:[NSString stringWithUTF8String:path]]; //sometimes ex with posix_spawnp the file passed in will be the name of the process, so return the input passed
 }
}

int hook_posix_spawn(pid_t *restrict pid, const char *restrict path, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *restrict attrp, char *const orig_argv[restrict], char *const envp[restrict]) {
 //GUESS: Add DYLD_INSERT_LIBRARIES to envp
 //This is example code that I think should (theoretically) work?
 //compile this dylib and put it in launchd, then CT sign
 //adds a dylib to process if specified in filter
 //dylib is sandboxed btw, but should be possible for unsandboxed dylibs as well theoretically, see opainject and the nullconga pdf, not in this example code tho bc idc for now
 
 //check if safe mode is on, if so don't inject
 FILE * fp;
 if ((fp = fopen("SUBSIDIARY_SAFEMODE_FILE", "r"))) {
  fclose(fp);
  return orig_posix_spawn(pid, path, file_actions, attrp, orig_argv, envp);
 }
 
 //get the injection string for process
 NSString* injectionString = findProcessInject(path);
 if (!injectionString) {
  //not in whitelist - don't inject dylib, just call posix_spawn as normal
  return orig_posix_spawn(pid, path, file_actions, attrp, orig_argv, envp);
 }
 int dyldLibIndex = -1;
 int index = 0;
 for (char * const *ptr = envp; *ptr; ptr++) {
  if(strncmp(*ptr, "DYLD_INSERT_LIBRARIES=", 22) == 0) { //check if string in envp starts with DYLD_INSERT_LIBRARIES=
   dyldLibIndex = index;
  }
  index++;
 }
 //I *REALLY* hope this code works
 char **ugh;
 if (dyldLibIndex == -1) {
  ugh = malloc(sizeof(char *) * (index + 3)); //if we need to add DYLD_INSERT_LIBRARIES to env instead of modifying existing env, index should be + 1 since we will be adding a env var obv
 } else {
  ugh = malloc(sizeof(char *) * (index + 2));
 }
 char* const *newEnvp = ugh;
 //add env vars to newEnvp from our current environment vars
 int index2 = 0;
 for (size_t idx = 0; idx < index; idx++) {
  char *env = envp[idx];
  if (index2 == dyldLibIndex) {
   NSString *string = [[NSString alloc]initWithUTF8String:envp[idx]]; //make the DYLD_INSERT_LIBRARIES env var to objc string
   string = [NSString stringWithFormat:@"%@:%@",injectionString,[string substringFromIndex:22]];
   env = (char *)[string UTF8String];
  }
  *ugh++ = env;
  index2++;
 }
 if (dyldLibIndex == -1) {
  //add DYLD_INSERT_LIBRARIES env var
  *ugh++ = (char *)[injectionString UTF8String];
 }
 *ugh++ = NULL;
 int ret_posix_spawn = orig_posix_spawn(pid, path, file_actions, attrp, orig_argv, newEnvp);
 free(ugh);
 return ret_posix_spawn;
}
int hook_posix_spawnp(pid_t *restrict pid, const char *restrict file, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *restrict attrp, char *const orig_argv[restrict], char * const envp[restrict]) {
 //GUESS: Add DYLD_INSERT_LIBRARIES to envp
 //This is example code that I think should (theoretically) work?
 //compile this dylib and put it in launchd, then CT sign
 //adds a dylib to process if specified in filter
 //dylib is sandboxed btw, but should be possible for unsandboxed dylibs as well theoretically, see opainject and the nullconga pdf, not in this example code tho bc idc for now
 
 //check if safe mode is on, if so don't inject
 FILE * fp;
 if ((fp = fopen("SUBSIDIARY_SAFEMODE_FILE", "r"))) {
  fclose(fp);
  return orig_posix_spawnp(pid, file, file_actions, attrp, orig_argv, envp);
 }
 
 //get the injection string for process
 NSString* injectionString = findProcessInject(path);
 if (!injectionString) {
  //not in whitelist - don't inject dylib, just call posix_spawn as normal
  return orig_posix_spawn(pid, path, file_actions, attrp, orig_argv, envp);
 }
 int dyldLibIndex = -1;
 int index = 0;
 for (char * const *ptr = envp; *ptr; ptr++) {
  if(strncmp(*ptr, "DYLD_INSERT_LIBRARIES=", 22) == 0) { //check if string in envp starts with DYLD_INSERT_LIBRARIES=
   dyldLibIndex = index;
  }
  index++;
 }
 char **ugh;
 if (dyldLibIndex == -1) {
  ugh = malloc(sizeof(char *) * (index + 3)); //if we need to add DYLD_INSERT_LIBRARIES to env instead of modifying existing env, index should be + 1 since we will be adding a env var obv
 } else {
  ugh = malloc(sizeof(char *) * (index + 2));
 }
 char* const *newEnvp = ugh;
 //add env vars to newEnvp from our current environment vars
 int index2 = 0;
 for (size_t idx = 0; idx < index; idx++) {
  char *env = envp[idx];
  if (index2 == dyldLibIndex) {
   NSString *string = [[NSString alloc]initWithUTF8String:envp[idx]]; //make the DYLD_INSERT_LIBRARIES env var to objc string
   string = [NSString stringWithFormat:@"%@:%@",injectionString,[string substringFromIndex:22]];
   env = (char *)[string UTF8String];
  }
  *ugh++ = env;
  index2++;
 }
 if (dyldLibIndex == -1) {
  //add DYLD_INSERT_LIBRARIES env var
  *ugh++ = (char *)[injectionString UTF8String];
 }
 *ugh++ = NULL;
 int ret_posix_spawnp = orig_posix_spawnp(pid, file, file_actions, attrp, orig_argv, newEnvp);
 free(ugh);
 return ret_posix_spawnp;
}

int main(void) {
 //TODO: This is a horrible method of seeing what to inject a dylib into. Improve the making of the filter dictionary latr
 NSMutableDictionary *mutableFilter = [[NSMutableDictionary alloc]init];
 NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"SUBSIDIARY_TWEAKINJECT_DIR" error:nil];
 [dirs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
  NSString *filename = (NSString *)obj;
  NSString *extension = [[filename pathExtension] lowercaseString];
  if ([extension isEqualToString:@"plist"]) {
   NSArray *bundleIDs = [[[NSDictionary dictionaryWithContentsOfFile:[@"SUBSIDIARY_TWEAKINJECT_DIR" stringByAppendingPathComponent:filename]]objectForKey:@"Filter"]objectForKey:@"Bundles"];
   for (id bundleid in bundleIDs) {
    if ([mutableFilter objectForKey:bundleid]) {
     [mutableFilter setObject:[NSString stringWithFormat:@"%@:%@",[mutableFilter objectForKey:bundleid],[[@"SUBSIDIARY_TWEAKINJECT_DIR" stringByAppendingPathComponent:filename]stringByReplacingOccurrencesOfString:@".plist" withString:@".dylib"]] forKey:bundleid];
    } else {
     [mutableFilter setObject:[NSString stringWithFormat:@"DYLD_INSERT_LIBRARIES=%@",[[@"SUBSIDIARY_TWEAKINJECT_DIR" stringByAppendingPathComponent:filename]stringByReplacingOccurrencesOfString:@".plist" withString:@".dylib"]] forKey:bundleid];
    }
   }
   NSArray *executables = [[[NSDictionary dictionaryWithContentsOfFile:[@"SUBSIDIARY_TWEAKINJECT_DIR" stringByAppendingPathComponent:filename]]objectForKey:@"Filter"]objectForKey:@"Executables"];
   for (id executable in executables) {
    if ([mutableFilter objectForKey:executable]) {
     [mutableFilter setObject:[NSString stringWithFormat:@"%@:%@",[mutableFilter objectForKey:executable],[[@"SUBSIDIARY_TWEAKINJECT_DIR" stringByAppendingPathComponent:filename]stringByReplacingOccurrencesOfString:@".plist" withString:@".dylib"]] forKey:executable];
    } else {
     [mutableFilter setObject:[NSString stringWithFormat:@"DYLD_INSERT_LIBRARIES=%@",[[@"SUBSIDIARY_TWEAKINJECT_DIR" stringByAppendingPathComponent:filename]stringByReplacingOccurrencesOfString:@".plist" withString:@".dylib"]] forKey:executable];
    }
   }
  }
 }];
 filter = [[NSDictionary alloc] initWithDictionary:mutableFilter]; //dictionary of apps/processes to inject a dylib into
 //ex, here is a filter dict that injects /var/subsidiary/TweakDylib.dylib into SpringBoard and installd: filter = [[NSDictionary alloc] initWithObjectsAndKeys:@"com.apple.springboard",@"/var/subsidiary/TweakDylib.dylib",@"installd",@"/var/subsidiary/TweakDylib.dylib",nil];
 uint32_t dyld_image_count = _dyld_image_count();
 //find our image
 for (int i=0; i<dyld_image_count; i++) {
  const char *name = _dyld_get_image_name(i); //get image name
  if ([[[NSString alloc]initWithUTF8String:name]isEqualToString:[[NSProcessInfo processInfo] processName]]) { //check if we found our image
    rebind_symbols_image(_dyld_get_image_header(index), _dyld_get_image_vmaddr_slide(index), (struct rebinding[1]){{"posix_spawn", hook_posix_spawn, (void *)&orig_posix_spawn }}, 1);
    rebind_symbols_image(_dyld_get_image_header(index), _dyld_get_image_vmaddr_slide(index), (struct rebinding[1]){{"posix_spawnp", hook_posix_spawnp, (void *)&orig_posix_spawnp }}, 1);
  }
 }
}
