import ../ForceCheck

proc called(a: int) {.forceCheck: [KeyError, ValueError].} =
    if a == 0:
        raise newException(KeyError, "This is a KeyError.")
    else:
        raise newException(ValueError, "This is a KeyError.")

proc caller() {.forceCheck: [KeyError, Exception].} =
    try:
        called(0)
    except:
        fcRaise KeyError

    try:
        called(1)
    except:
        fcRaise

caller()
