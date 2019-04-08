import ../ForceCheck

proc empty*() {.forceCheck: [].} =
    discard

proc unneeded() {.forceCheck: [OSError].} =
    discard

proc raises() {.forceCheck: [KeyError].} =
    raise newException(KeyError, "")

func funcEmpty() {.forceCheck: [].} =
    discard

func funcUnneeded*() {.forceCheck: [OSError].} =
    discard

func funcRaises() {.forceCheck: [KeyError].} =
    raise newException(KeyError, "")

empty()
unneeded()

funcEmpty()
funcUnneeded()

raises()
funcRaises()
