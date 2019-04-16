import ../ForceCheck

import asyncdispatch

proc called(x: int) {.forceCheck: [
    ValueError,
    IndexError
], async.} =
    if x == 0:
        raise newException(ValueError, "0")
    elif x == 1:
        raise newException(IOError, "1")

proc caller() {.forceCheck: [
    ValueError,
    IndexError
], async.} =
    try:
        await called(0)
    except ValueError as e:
        echo e.msg
    except IOError as e:
        echo e.msg
    except Exception as e:
        echo e.msg

waitFor caller()
