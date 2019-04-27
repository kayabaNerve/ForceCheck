when not defined(cpp):
    {.error: "This test must be compiled with the C++ backend.".}

import ../ForceCheck

proc raises() {.forceCheck: [
    ValueError
].} =
    raise newException(ValueError, "Raising a ValueError")

proc raises2() {.forceCheck: [
    ValueError
].} =
    try:
        raises()
    except ValueError as er:
        echo "Triggered raises2 except."
        fcRaise er

try:
    raises2()
except ValueError as e:
    echo "Triggered the main body's except."
    fcRaise e
