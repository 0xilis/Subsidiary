# Subsidiary
messing around

uses fishhook

what it does
- Step 1: Modify whitelist array to choose the bundle ids / process names to inject /var/subsidiary/TweakDylib.dylib into
- Step 2: Compile as a dylib
- Step 3: Insert dylib into launchd
- Step 4: CT Sign launchd
- Step 5: Every process in the whitelist array should have /var/subsidiary/TweakDylib.dylib injected into it
