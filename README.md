# Subsidiary
messing around

uses fishhook

what it does
- Step 1: Compile as a dylib
- Step 2: Insert dylib into launchd
- Step 3: CT Sign launchd
- Step 4: `/usr/lib/TweakInject`, containing the dylibs and filter plists, will be cycled through and the dylibs in there will be injected.
- Step 5: Profit

Note: To enter safemode, create `/var/subsidiary/safemode`, Subsidiary will no longer inject any dylibs
