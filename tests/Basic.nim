import ../ForceCheck

proc empty() {.forceCheck: [].} =
    discard

proc unneeded() {.forceCheck: [OSError].} =
    discard

proc raises() {.forceCheck: [KeyError].} =
    raise newException(KeyError, "")

empty()
unneeded()
raises()
