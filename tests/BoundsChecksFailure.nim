import ../ForceCheck

proc raisesIE() {.forceCheck: [].} =
    var mySeq: seq[int] = @[]
    discard mySeq[5]

raisesIE()
