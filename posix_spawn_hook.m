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

NSString *findBundleID(const char *path) {
 NSString *pathString = [NSString stringWithUTF8String:path];
 NSRange range = [pathString rangeOfString:@".app/" options:NSBackwardsSearch];
 if (range.length > 0) {
  //process is an app
  NSString *infoPlistPath = [NSString stringWithFormat:@"%@Info.plist",[pathString substringToIndex:range.location]]; //get the app's infoplist path from file path
  NSDictionary *mainDictionary = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
  if (mainDictionary) {
   return [mainDictionary objectForKey:@"CFBundleIdentifier"];
  }
 }
 return NULL;
}

NSString *findProcessName(const char *path) {
 NSString *pathString = [NSString stringWithUTF8String:path];
 NSRange range = [pathString rangeOfString:@"/" options:NSBackwardsSearch];
 if (range.length > 0) {
  //process is an app
  return [pathString substringFromIndex:range.location];
 } else {
  return [NSString stringWithUTF8String:path]; //sometimes ex with posix_spawnp the file passed in will be the name of the process, so return the input passed
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
 
 //get bundle id for process and check if its in whitelist
 NSString *process = findBundleID(path);
 if (!process) {
  //get the process name if we can't get bundle id
  process = findProcessName(path);
 }
 if (![[filter allKeys] containsObject:process]) {
  //not in whitelist - don't inject dylib, just call posix_spawn as normal
  return orig_posix_spawn(pid, path, file_actions, attrp, orig_argv, envp);
 }
 NSString* injectionString = [filter objectForKey:process];
 int dyldLibIndex = -1;
 char **ptr;
 int index = 0;
 for (ptr = envp; *ptr != NULL; ptr++) {
  if(strncmp(*ptr, "DYLD_INSERT_LIBRARIES=", 22) == 0) { //check if string in envp starts with DYLD_INSERT_LIBRARIES=
   dyldLibIndex = index;
  }
  index++;
 }
 if (dyldLibIndex == -1) {
  index++;
 }
 const char* newEnvp[index];
 //add env vars to newEnvp from our current environment vars
 int index2 = 0;
 for (ptr = envp; *ptr != NULL; ptr++) {
  newEnvp[index2] = *ptr;
  index2++;
 }
 if (dyldLibIndex == -1) {
  //add DYLD_INSERT_LIBRARIES env var 
  //index2 should be equal to dyldLibIndex at this moment
  newEnvp[index2] = [[NSString stringWithFormat:@"DYLD_INSERT_LIBRARIES=%@",injectionString]UTF8String];
 } else {
  //modify existing DYLD_INSERT_LIBRARIES env var to use /var/subsidiary/TweakDylib.dylib
  //ex if DYLD_INSERT_LIBRARIES env var is DYLD_INSERT_LIBRARIES=/some/lib.dylib, it should now be DYLD_INSERT_LIBRARIES=/var/subsidiary/TweakDylib.dylib:/some/lib.dylib
  NSString *string = [[NSString alloc]initWithUTF8String:newEnvp[dyldLibIndex]]; //make the DYLD_INSERT_LIBRARIES env var to objc string
  string = [NSString stringWithFormat:@"DYLD_INSERT_LIBRARIES=%@:%@",injectionString,[string substringFromIndex:22]];
  newEnvp[dyldLibIndex] = [string UTF8String];
 }
 //TODO: this won't work bc I'm returning a const char* [] instead of a char * const[]
 return orig_posix_spawn(pid, path, file_actions, attrp, orig_argv, newEnvp);
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
 
 //get bundle id for process and check if its in whitelist
 NSString *process = findBundleID(file);
 if (!process) {
  //get the process name if we can't get bundle id
  process = findProcessName(file);
 }
 if (![[filter allKeys] containsObject:process]) {
  //not in whitelist - don't inject dylib, just call posix_spawn as normal
  return orig_posix_spawnp(pid, file, file_actions, attrp, orig_argv, envp);
 }
 NSString* injectionString = [filter objectForKey:process];
 int dyldLibIndex = -1;
 char **ptr;
 int index = 0;
 for (ptr = envp; *ptr != NULL; ptr++) {
  if(strncmp(*ptr, "DYLD_INSERT_LIBRARIES=", 22) == 0) { //check if string in envp starts with DYLD_INSERT_LIBRARIES=
   dyldLibIndex = index;
  }
  index++;
 }
 if (dyldLibIndex == -1) {
  index++;
 }
 const char* newEnvp[index];
 //add env vars to newEnvp from our current environment vars
 int index2 = 0;
 for (ptr = envp; *ptr != NULL; ptr++) {
  newEnvp[index2] = *ptr;
  index2++;
 }
 if (dyldLibIndex == -1) {
  //add DYLD_INSERT_LIBRARIES env var 
  //index2 should be equal to dyldLibIndex at this moment
  newEnvp[index2] = [[NSString stringWithFormat:@"DYLD_INSERT_LIBRARIES=%@",injectionString]UTF8String];
 } else {
  //modify existing DYLD_INSERT_LIBRARIES env var to use /var/subsidiary/TweakDylib.dylib
  //ex if DYLD_INSERT_LIBRARIES env var is DYLD_INSERT_LIBRARIES=/some/lib.dylib, it should now be DYLD_INSERT_LIBRARIES=/var/subsidiary/TweakDylib.dylib:/some/lib.dylib
  NSString *string = [[NSString alloc]initWithUTF8String:newEnvp[dyldLibIndex]]; //make the DYLD_INSERT_LIBRARIES env var to objc string
  string = [NSString stringWithFormat:@"DYLD_INSERT_LIBRARIES=%@:%@",injectionString,[string substringFromIndex:22]];
  newEnvp[dyldLibIndex] = [string UTF8String];
 }
 //TODO: this won't work bc I'm returning a const char* [] instead of a char * const[]
 return orig_posix_spawnp(pid, file, file_actions, attrp, orig_argv, newEnvp);
}

int main(void) {
 NSMutableDictionary *mutableFilter = [[NSMutableDictionary alloc]init];
 NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"SUBSIDIARY_TWEAKINJECT_DIR" error:nil];
 NSMutableArray *plistFiles = [[NSMutableArray alloc] init];
 [dirs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
  NSString *filename = (NSString *)obj;
  NSString *extension = [[filename pathExtension] lowercaseString];
  if ([extension isEqualToString:@"plist"]) {
   NSArray *bundleIDs = [[[NSDictionary dictionaryWithContentsOfFile:[@"SUBSIDIARY_TWEAKINJECT_DIR" stringByAppendingPathComponent:filename]]objectForKey:@"Filter"]objectForKey:@"Bundles"];
   for (id bundleid in bundleIDs) {
    if ([mutableFilter objectForKey:bundleid]) {
     [mutableFilter setObject:[NSString stringWithFormat:@"%@:%@",[mutableFilter objectForKey:bundleid],[[@"SUBSIDIARY_TWEAKINJECT_DIR" stringByAppendingPathComponent:filename]stringByReplacingOccurrencesOfString:@".plist" withString:@".dylib"]] forKey:bundleid];
    } else {
     [mutableFilter setObject:[[@"SUBSIDIARY_TWEAKINJECT_DIR" stringByAppendingPathComponent:filename]stringByReplacingOccurrencesOfString:@".plist" withString:@".dylib"] forKey:bundleid];
    }
   }
   NSArray *executables = [[[NSDictionary dictionaryWithContentsOfFile:[@"SUBSIDIARY_TWEAKINJECT_DIR" stringByAppendingPathComponent:filename]]objectForKey:@"Filter"]objectForKey:@"Executables"];
   for (id executable in executables) {
    if ([mutableFilter objectForKey:executable]) {
     [mutableFilter setObject:[NSString stringWithFormat:@"%@:%@",[mutableFilter objectForKey:executable],[[@"SUBSIDIARY_TWEAKINJECT_DIR" stringByAppendingPathComponent:filename]stringByReplacingOccurrencesOfString:@".plist" withString:@".dylib"]] forKey:executable];
    } else {
     [mutableFilter setObject:[[@"SUBSIDIARY_TWEAKINJECT_DIR" stringByAppendingPathComponent:filename]stringByReplacingOccurrencesOfString:@".plist" withString:@".dylib"] forKey:executable];
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
