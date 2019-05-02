import ../ForceCheck

import tables

type CustomSeq = distinct seq[int]

proc falsePositive() {.forceCheck: [].} =
    var
        a: seq[int] = @[]
        b: seq[string] = @["abc"]
        c: Table[bool, int] = initTable[bool, int]()
        d: TableRef[string, string] = newTable[string, string]()
    discard a
    discard b
    discard c
    discard d

proc testHint() {.boundsCheck.} =
    fcBoundsOverride:
        discard

proc raisesIE() {.boundsCheck, forceCheck: [].} =
    var mySeq: seq[int] = @[]
    try:
        discard mySeq[5]
    except IndexError:
        discard

proc custom() {.boundsCheck, forceCheck: [].} =
    var mySeq: CustomSeq
    try:
        discard cast[seq[int]](mySeq)[0]
    except IndexError:
        discard

proc deref() {.forceCheck: [].} =
    var a: ref int = new(int)
    a[] = 5

proc override() {.boundsCheck, forceCheck: [].} =
    var mySeq: seq[int] = @[0]
    fcBoundsOverride:
        discard mySeq[0]

proc caller() {.forceCheck: [].} =
    falsePositive()

    testHint()

    try:
        raisesIE()
    except IndexError:
        echo "Caught raisesIE."

    try:
        raisesIE()
    except IndexError as e:
        echo "Caught raisesIE with `as e` syntax."
        discard e

    try:
        try:
            raisesIE()
        except IndexError:
            echo "Caught nested raisesIE."
    except IOError:
        discard

    try:
        custom()
    except IndexError:
        echo "Caught custom."

    deref()

    override()

caller()
