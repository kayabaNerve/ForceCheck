import ../ForceCheck

func called(
    a: int
) {.forceCheck: [
    OSError,
    ValueError
].} =
    if a == 0:
        raise newException(OSError, "This is an OSError.")
    else:
        raise newException(ValueError, "This is a ValueError.")

proc caller() {.forceCheck: [
    OSError,
    ValueError
].} =
    try:
        called(0)
    except OSError as e:
        raise e
    except ValueError as e:
        raise e

    try:
        called(1)
    except OSError as e:
        raise e
    except ValueError as e:
        raise e

caller()
