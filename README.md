# Subsidiary
dumb coretrust launchd tweak inject

uses fishhook

(note: dylibs are sandboxed and Subsidiary currently does not provide any libs for stuff like function hooking etc, only injects dylibs)

what it does
- Step 1: Compile `posix_spawn_hook.m` (which uses fishhook) as a dylib
- Step 2: Insert dylib into launchd
- Step 3: CT Sign launchd
- Step 4: `/usr/lib/TweakInject`, containing the dylibs and filter plists, will be cycled through and the dylibs in there will be injected.
- Step 5: Profit

Note: To enter safemode, create `/var/subsidiary/safemode`, Subsidiary will no longer inject any dylibs
