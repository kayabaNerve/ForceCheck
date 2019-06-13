 import ../ForceCheck

type
    A = ref object of RootObj
    B = ref object of A

method test(a: A) {.forceCheck: [].} =
    discard

method test*(b: B) {.forceCheck: [].} =
    discard
