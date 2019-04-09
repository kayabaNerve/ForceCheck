import ../ForceCheck

proc called() {.forceCheck: [KeyError].} =
    raise newException(KeyError, "This is a KeyError.")

proc failure() {.forceCheck: [KeyError].} =
    try:
        called()
    except:
        discard

failure()
