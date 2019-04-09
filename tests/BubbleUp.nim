import ../ForceCheck

proc called(a: int) {.forceCheck: [KeyError, ValueError].} =
    if a == 0:
        raise newException(KeyError, "This is a KeyError.")
    else:
        raise newException(ValueError, "This is a ValueError.")

proc caller() {.forceCheck: [KeyError, ValueError].} =
    try:
        called(0)
    except KeyError, ValueError:
        fcRaise KeyError

    try:
        called(1)
    except KeyError, ValueError:
        fcRaise ValueError

caller()
