import ../ForceCheck

proc basic1() {.forceCheck: [].} =
    discard

proc basic2() {.forceCheck: [KeyError].} =
    raise newException(KeyError, "")

basic1()
basic2()
