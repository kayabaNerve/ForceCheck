import ../ForceCheck

proc empty() {.forceCheck: [].} =
    discard
proc publicEmpty*() {.forceCheck: [].} =
    discard
proc unneeded() {.forceCheck: [OSError].} =
    discard
proc multitype(a: int or string) {.forceCheck: [].} =
    discard
var nameless: proc () {.raises: [].} = proc () {.forceCheck: [].} =
    discard
proc `!`(a: int) {.forceCheck: [].} =
    discard

proc raises() {.forceCheck: [KeyError].} =
    raise newException(KeyError, "")
proc publicRaises*() {.forceCheck: [KeyError].} =
    raise newException(KeyError, "")

func funcEmpty() {.forceCheck: [].} =
    discard
func funcPublicEmpty*() {.forceCheck: [].} =
    discard
func funcUnneeded() {.forceCheck: [OSError].} =
    discard
func funcMultitype(a: int or string) {.forceCheck: [].} =
    discard
var funcNameless: proc () {.noSideEffect.} = func () {.forceCheck: [].} =
    discard
func `@`*(a: int) {.forceCheck: [].} =
    discard

func funcRaises() {.forceCheck: [KeyError].} =
    raise newException(KeyError, "")
func funcPublicRaises*() {.forceCheck: [KeyError].} =
    raise newException(KeyError, "")

empty()
publicEmpty()
unneeded()
multitype(5)
nameless()
!5

funcEmpty()
funcPublicEmpty()
funcUnneeded()
funcMultitype("x")
funcNameless()
@5

raises()
publicRaises()
funcRaises()
funcPublicRaises()
