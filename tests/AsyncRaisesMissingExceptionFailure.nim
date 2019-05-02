import ../ForceCheck

import asyncdispatch

proc called(
    x: int
) {.forceCheck: [], async.} =
    if x == 0:
        raise newException(ValueError, "0")
    elif x == 1:
        raise newException(IOError, "1")

waitFor called(0)
