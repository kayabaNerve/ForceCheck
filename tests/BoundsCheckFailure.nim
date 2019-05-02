import ../ForceCheck

proc raisesIE() {.boundsCheck.} =
    var mySeq: seq[int] = @[]
    discard mySeq[5]

raisesIE()
