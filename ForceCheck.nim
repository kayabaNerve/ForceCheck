#Macros lib.
import macros

#The macro wasn't handling raise statements inside except blocks (ones without newException); this is a workaround.
template fcRaise*(): untyped =
    raise getCurrentException()
template fcRaise*(exception: untyped): untyped =
    raise (ref exception)(getCurrentException())

#Recursively replaces every raise statement in the NimNode with a discard.
proc replace(parent: NimNode, index: int) {.compileTime.} =
    #If this is a raise statement, replace it with a discard statement.
    if parent[index].kind == nnkRaiseStmt:
        parent[index] = newNimNode(nnkDiscardStmt).add(newEmptyNode())
        return

    #If this is a fcRaise statement without an Exception, replace it .
    if (parent[index].kind == nnkIdent) and (parent[index].strVal == "fcRaise"):
        parent[index] = newNimNode(nnkDiscardStmt).add(newEmptyNode())
        return

    #If this is a fcRaise statement with an Exception, replace it.
    if (parent[index].kind == nnkCommand) and (parent[index][0].strVal == "fcRaise"):
        parent[index] = newNimNode(nnkDiscardStmt).add(newEmptyNode())
        return

    #Iterate over every child and do the same there.
    for i in 0 ..< parent[index].len:
        replace(parent[index], i)

#Make sure the proc/func doesn't allow any Exceptions to bubble up.
macro forceCheck*(exceptions: untyped, callerArg: untyped): untyped =
    #Copy the caller arg.
    var caller = copy(callerArg)

    #Create arrays for both recoverable/irrecoverable exceptions, and just irrecoverable.
    var
        both: NimNode = newNimNode(nnkBracket)
        irrecoverable: NimNode = newNimNode(nnkBracket)

    #Check to make sure this isn't an empty array.
    if exceptions.len > 0:
        #Check if recoverable/irrecoverable was specified.
        if exceptions[0].kind == nnkExprColonExpr:
            case exceptions[0][0].strVal:
                of "recoverable":
                    for i in 1 ..< exceptions[0].len:
                        both.add(exceptions[0][i])
                of "irrecoverable":
                    for i in 1 ..< exceptions[0].len:
                        both.add(exceptions[0][i])
                        irrecoverable.add(exceptions[0][i])
            #Allow passing just irrecoverable.
            if exceptions.len > 1:
                case exceptions[1][0].strVal:
                    of "recoverable":
                        for i in 1 ..< exceptions[1].len:
                            both.add(exceptions[1][i])
                    of "irrecoverable":
                        for i in 1 ..< exceptions[1].len:
                            both.add(exceptions[1][i])
                            irrecoverable.add(exceptions[1][i])
        #If types weren't specified, just set both to exceptions.
        else:
            both = exceptions

    #Rename it.
    if caller[0].kind == nnkPostfix:
        caller[0] = newIdentNode(caller[0][0].strVal & "_forceCheck")
    else:
        caller[0] = newIdentNode(caller[0].strVal & "_forceCheck")

    #Add a proper raises pragma to the original function.
    callerArg.addPragma(
        newNimNode(
            nnkExprColonExpr
        ).add(
            newIdentNode(
                "raises"
            ),
            both
        )
    )

    #Add a raises to the copy of just the irrecoverable errors.
    caller.addPragma(
        newNimNode(
            nnkExprColonExpr
        ).add(
            newIdentNode(
                "raises"
            ),
            irrecoverable
        )
    )
    #Also add the used pragma.
    caller.addPragma(
        newIdentNode(
            "used"
        )
    )

    #Replace every raises in the copy with a discard statement.
    replace(caller, 6)

    #Add the modified proc to the start of the original proc, inside a block to disable all hints.
    callerArg[6].insert(
        0,
        newNimNode(
            nnkPragma
        ).add(
            newIdentNode("pop")
        )
    )
    callerArg[6].insert(
        0,
        caller
    )
    callerArg[6].insert(
        0,
        newNimNode(
            nnkPragma
        ).add(
            newIdentNode("push"),
            newNimNode(
                nnkExprColonExpr
            ).add(
                newIdentNode("hints"),
                newIdentNode("off")
            ),
        )
    )

    return callerArg
