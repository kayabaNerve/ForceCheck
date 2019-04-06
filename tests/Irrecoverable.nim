import ../ForceCheck

proc called(a: int) {.forceCheck: [
    recoverable:
        ValueError,
    irrecoverable:
        OSError
].} =
    if a == 0:
        raise newException(ValueError, "This is a KeyError.")
    else:
        raise newException(OSError, "")

proc caller() {.forceCheck: [
    recoverable:
        ValueError,
    irrecoverable:
        OSError
].} =
    try:
        called(0)
    except ValueError:
        fcRaise ValueError

caller()
