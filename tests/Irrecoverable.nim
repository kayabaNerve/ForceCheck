import ../ForceCheck

proc called(a: int) {.forceCheck: [
    recoverable: [
        KeyError,
        ValueError
    ],
    irrecoverable: [
        OSError
    ]
].} =
    if a == 0:
        raise newException(KeyError, "This is a KeyError.")
    elif a == 1:
        raise newException(ValueError, "This is a ValueError.")
    else:
        raise newException(OSError, "")

proc caller() {.forceCheck: [
    recoverable: [
        KeyError,
        ValueError
    ],
    irrecoverable: [
        OSError
    ]
].} =
    try:
        called(0)
    except KeyError as e:
        raise e
    except ValueError as e:
        raise e

caller()
