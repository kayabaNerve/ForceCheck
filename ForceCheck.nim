#Macros lib.
import macros

#Recursively replaces every raise statement in the NimNode with a discard.
#This function also checks to make sure there's no generic excepts.
proc replace(parent: NimNode, index: int) {.compileTime.} =
    #If this is an except branch, without specifying an error, error.
    if (parent[index].kind == nnkExceptBranch) and (parent[index].len == 1):
        raise newException(Exception, "Except branches must specify an Exception.")

    #If this is a raise statement, replace it with a discard statement.
    if parent[index].kind == nnkRaiseStmt:
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
                    for i in 0 ..< exceptions[0][1].len:
                        both.add(exceptions[0][1][i])
                of "irrecoverable":
                    for i in 0 ..< exceptions[0][1].len:
                        both.add(exceptions[0][1][i])
                        irrecoverable.add(exceptions[0][1][i])
            #Allow passing just irrecoverable.
            if exceptions.len > 1:
                if exceptions[1][0].strVal == "recoverable":
                    for i in 0 ..< exceptions[1][1].len:
                        both.add(exceptions[1][1][i])
                else:
                    for i in 0 ..< exceptions[1][1].len:
                        both.add(exceptions[1][1][i])
                        irrecoverable.add(exceptions[1][1][i])
        #If types weren't specified, just set both to exceptions.
        else:
            both = exceptions

    #Rename it.
    #If it's empty, it's a nameless function.
    if caller[0].kind == nnkEmpty:
        caller[0] = newIdentNode("empty_forceCheck")
    #If this is a postfix, it's either a public function or an public operator.
    elif caller[0].kind == nnkPostfix:
        #Check if it's an operator.
        var op: bool = false
        for c in 0 ..< caller[0].len:
            if caller[0][c].kind == nnkAccQuoted:
                op = true
                caller[0] = newNimNode(
                    nnkAccQuoted
                ).add(
                    newIdentNode(caller[0][c][0].strVal & "_forceCheck")
                )

        #If it's not an operator, handle it as a public function.
        if not op:
            caller[0] = newIdentNode(caller[0][1].strVal & "_forceCheck")
    #If it's not a public operator...
    elif caller[0].kind == nnkAccQuoted:
        caller[0] = newIdentNode(caller[0][0].strVal & "_forceCheck")
    #If it's a regular function...
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

    #If the function is a lambda, change the cloned function to a proc.
    if callerArg.kind == nnkLambda:
        var callerProc: NimNode = newNimNode(nnkProcDef)
        caller.copyChildrenTo(callerProc)
        caller = callerProc

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
