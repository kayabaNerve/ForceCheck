import ../ForceCheck

proc empty() {.forceCheck: [].} =
    discard

proc publicEmpty*() {.forceCheck: [].} =
    discard

proc unneeded() {.forceCheck: [
    OSError
].} =
    discard

proc multitype(
    a: int or string)
 {.forceCheck: [].} =
    discard

var procLambda: proc () {.raises: [].} = proc () {.forceCheck: [].} =
    discard

proc `!`(a: int) {.forceCheck: [].} =
    discard

proc raises() {.forceCheck: [
    OSError
].} =
    raise newException(OSError, "")

proc publicRaises*() {.forceCheck: [
    OSError
].} =
    raise newException(OSError, "")

func funcEmpty() {.forceCheck: [].} =
    discard

func funcPublicEmpty*() {.forceCheck: [].} =
    discard

func funcUnneeded() {.forceCheck: [
    OSError
].} =
    discard

func funcMultitype(a: int or string) {.forceCheck: [].} =
    discard

var funcLambda: proc () {.noSideEffect.} = func () {.forceCheck: [].} =
    discard

func `@`*(a: int) {.forceCheck: [].} =
    discard

func funcRaises() {.forceCheck: [
    OSError
].} =
    raise newException(OSError, "")

func funcPublicRaises*() {.forceCheck: [
    OSError
].} =
    raise newException(OSError, "")

empty()
publicEmpty()
unneeded()
multitype(5)
procLambda()
!5

funcEmpty()
funcPublicEmpty()
funcUnneeded()
funcMultitype("x")
funcLambda()
@5

raises()
publicRaises()
funcRaises()
funcPublicRaises()
