import ../ForceCheck

type
   A = object
   B = object

converter cA(a: A): bool {.forceCheck: [].} =
   false

converter cB*(b: B): bool {.forceCheck: [].} =
   true

discard cA(A())
discard cB(B())
