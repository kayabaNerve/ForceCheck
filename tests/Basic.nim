import ../ForceCheck

proc basic() {.forceCheck: [KeyError].} =
    raise newException(KeyError, "")

basic()
