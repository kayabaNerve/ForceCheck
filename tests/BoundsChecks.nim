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

proc raisesIE() {.forceCheck: [
    IndexError
].} =
    if false: raise newException(IndexError, "")
    var mySeq: seq[int] = @[]
    discard mySeq[5]

proc irrecoverable() {.forceCheck: [
    irrecoverable: [
        IndexError
    ]
].} =
    var mySeq: seq[int] = @[]
    discard mySeq[5]

proc custom() {.forceCheck: [
    IndexError
].} =
    var mySeq: CustomSeq
    discard cast[seq[int]](mySeq)[0]

proc override() {.forceCheck: [].} =
    var mySeq: seq[int] = @[0]
    fcBoundsOverride:
        discard mySeq[0]

proc pragmaOverride() {.forceCheck: [], fcBoundsOverride.} =
    var mySeq: seq[int] = @[0]
    discard mySeq[0]

proc caller() {.forceCheck: [].} =
    falsePositive()
    
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
        irrecoverable()
    except IndexError:
        echo "Caught irrecoverable."

    try:
        custom()
    except IndexError:
        echo "Caught custom."

    override()

    pragmaOverride()

caller()
