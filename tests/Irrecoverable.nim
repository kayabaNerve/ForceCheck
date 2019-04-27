import ../ForceCheck

proc called(
    a: int
) {.forceCheck: [
    recoverable: [
        IOError,
        ValueError
    ],
    irrecoverable: [
        OSError
    ]
].} =
    if a == 0:
        raise newException(IOError, "This is an IOError.")
    elif a == 1:
        raise newException(ValueError, "This is a ValueError.")
    else:
        raise newException(OSError, "")

proc caller() {.forceCheck: [
    recoverable: [
        IOError,
        ValueError
    ],
    irrecoverable: [
        OSError
    ]
].} =
    try:
        called(0)
    except IOError as e:
        raise e
    except ValueError as e:
        raise e

caller()
