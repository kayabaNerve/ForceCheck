 import ../ForceCheck

type
    A = ref object of RootObj
    B = ref object of A

method test(a: A) {.base, forceCheck: [].} =
    discard

method test*(b: B) {.forceCheck: [].} =
    discard
