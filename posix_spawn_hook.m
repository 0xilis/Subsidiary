//Snoolie K / 0xilis, Subsidiary
//just toying around rn

#include <stdio.h>
#include <string.h>
#include <mach-o/dyld.h>
#include "fishhook.h"
#import <Foundation/Foundation.h>

static int (*orig_posix_spawn)(pid_t *restrict pid, const char *restrict path, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *restrict attrp, char *const argv[restrict], char *const envp[restrict]);
static int (*orig_posix_spawnp)(pid_t *restrict pid, const char *restrict path, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *restrict attrp, char *const argv[restrict], char *const envp[restrict]);

int hook_posix_spawn(pid_t *restrict pid, const char *restrict path, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *restrict attrp, char *const argv[restrict], char *const envp[restrict]) {
 //GUESS: Add DYLD_INSERT_LIBRARIES to envp
 //This is example code that I think should (theoretically) work?
 //compile this dylib and put it in launchd, then CT sign
 //adds a dylib to every process (that being, "/var/subsidiary/TweakDylib.dylib")
 //dylib is sandboxed btw, but should be possible for unsandboxed dylibs as well theoretically, see opainject and the nullconga pdf, not in this example code tho bc idc for now
 //in real world we shouldn't want to insert this dylib in *everything* and only insert it in stuff it should be inserted in, but once again, only an example
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
  newEnvp[index2] = "DYLD_INSERT_LIBRARIES=/var/subsidiary/TweakDylib.dylib";
 } else {
  //modify existing DYLD_INSERT_LIBRARIES env var to use /var/subsidiary/TweakDylib.dylib
  //ex if DYLD_INSERT_LIBRARIES env var is DYLD_INSERT_LIBRARIES=/some/lib.dylib, it should now be DYLD_INSERT_LIBRARIES=/var/subsidiary/TweakDylib.dylib:/some/lib.dylib
  NSString *string = [[NSString alloc]initWithUTF8String:newEnvp[dyldLibIndex]]; //make the DYLD_INSERT_LIBRARIES env var to objc string
  string = [NSString stringWithFormat:@"DYLD_INSERT_LIBRARIES=/var/subsidiary/TweakDylib.dylib:%@",[string substringFromIndex:22]];
  newEnvp[dyldLibIndex] = [string UTF8String];
 }
 return orig_posix_spawn(pid, path, file_actions, attrp, orig_argv, newEnvp);
}
int hook_posix_spawnp(pid_t *restrict pid, const char *restrict file, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *restrict attrp, char *const argv[restrict], char * const envp[restrict]) {
  //GUESS: Add DYLD_INSERT_LIBRARIES to envp
 //This is example code that I think should (theoretically) work?
 //compile this dylib and put it in launchd, then CT sign
 //adds a dylib to every process (that being, "/var/subsidiary/TweakDylib.dylib")
 //dylib is sandboxed btw, but should be possible for unsandboxed dylibs as well theoretically, see opainject and the nullconga pdf, not in this example code tho bc idc for now
 //in real world we shouldn't want to insert this dylib in *everything* and only insert it in stuff it should be inserted in, but once again, only an example
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
  newEnvp[index2] = "DYLD_INSERT_LIBRARIES=/var/subsidiary/TweakDylib.dylib";
 } else {
  //modify existing DYLD_INSERT_LIBRARIES env var to use /var/subsidiary/TweakDylib.dylib
  //ex if DYLD_INSERT_LIBRARIES env var is DYLD_INSERT_LIBRARIES=/some/lib.dylib, it should now be DYLD_INSERT_LIBRARIES=/var/subsidiary/TweakDylib.dylib:/some/lib.dylib
  NSString *string = [[NSString alloc]initWithUTF8String:newEnvp[dyldLibIndex]]; //make the DYLD_INSERT_LIBRARIES env var to objc string
  string = [NSString stringWithFormat:@"DYLD_INSERT_LIBRARIES=/var/subsidiary/TweakDylib.dylib:%@",[string substringFromIndex:22]];
  newEnvp[dyldLibIndex] = [string UTF8String];
 }
 return orig_posix_spawnp(pid, orig_path, file_actions, attrp, orig_argv, newEnvp);
}

int main(void) {
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
