# Subsidiary
dumb coretrust launchd tweak inject

uses fishhook

what it does
- Step 1: Compile `posix_spawn_hook.m` (which uses fishhook) as a dylib
- Step 2: Insert dylib into launchd
- Step 3: CT Sign launchd
- Step 4: `/usr/lib/TweakInject`, containing the dylibs and filter plists, will be cycled through and the dylibs in there will be injected.
- Step 5: Profit

current limitations:
- dylibs are sandboxed
- Subsidiary currently does not provide any libs for stuff like function hooking etc, only injects dylibs, you'll need to inject dylibs that don't need a lib or add your own lib for the dylib to use

Note: To enter safemode, create `/var/subsidiary/safemode`, Subsidiary will no longer inject any dylibs
