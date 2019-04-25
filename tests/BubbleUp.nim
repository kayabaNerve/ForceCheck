import ../ForceCheck

proc called(
    a: int
) {.forceCheck: [
    KeyError,
    ValueError
].} =
    if a == 0:
        raise newException(KeyError, "This is a KeyError.")
    else:
        raise newException(ValueError, "This is a ValueError.")

func caller() {.forceCheck: [
    KeyError,
    ValueError
].} =
    try:
        called(0)
    except KeyError as e:
        raise e
    except ValueError as e:
        raise e

    try:
        called(1)
    except KeyError as e:
        raise e
    except ValueError as e:
        raise e

caller()
