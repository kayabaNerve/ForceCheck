import ../ForceCheck

type CustomSeq = distinct seq[int]

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

proc caller() {.forceCheck: [].} =
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

caller()
