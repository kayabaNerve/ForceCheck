import ../ForceCheck

proc called(a: int) {.forceCheck: [KeyError, ValueError].} =
    if a == 0:
        raise newException(KeyError, "This is a KeyError.")
    else:
        raise newException(ValueError, "This is a KeyError.")

proc failure() {.forceCheck: [KeyError].} =
    for i in 0 .. 10:
        called(0)

failure()
