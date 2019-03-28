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

    #Rename it.
    caller[0] = newIdentNode(caller[0].strVal & "_forceCheck")

    #Add a proper raises pragma to the original function.
    callerArg.addPragma(
        newNimNode(
            nnkExprColonExpr
        ).add(
            newIdentNode(
                "raises"
            ),
            exceptions
        )
    )

    #Add a blank raises to the copy.
    caller.addPragma(
        newNimNode(
            nnkExprColonExpr
        ).add(
            newIdentNode(
                "raises"
            ),
            newNimNode(nnkBracket)
        )
    )

    #Replace every raises in the copy with a discard statement.
    replace(caller, 6)

    #Add the modified proc to the start of the original proc, inside a Block to disable XDeclaredButNotUsed hints.
    callerArg[6].insert(
        0,
        newNimNode(
            nnkPragmaBlock
        ).add(
            newNimNode(
                nnkPragma
            ).add(
                newNimNode(
                    nnkExprColonExpr
                ).add(
                    newNimNode(
                        nnkBracketExpr
                    ).add(
                        newIdentNode("hint"),
                        newIdentNode("XDeclaredButNotUsed")
                    ),
                    newIdentNode("off")
                ),
            ),
            newStmtList(
                caller
            )
        )
    )

    return callerArg
