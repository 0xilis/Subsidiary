# Subsidiary
messing around

uses fishhook

what it does
- Step 1: Modify filter dict to choose the bundle ids / process names to inject into, and the filepath of the dylib you want to inject
- Step 2: Compile as a dylib
- Step 3: Insert dylib into launchd
- Step 4: CT Sign launchd
- Step 5: The processes / bundle ids you specified to inject a dylib at a certain filepath should now have your dylib injected into it
