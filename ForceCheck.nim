#Macros lib.
import macros

#Return the name of a function.
proc getName(
    function: NimNode
): string {.compileTime.} =
    #If it's a lambda, the function has no name.
    if function[0].kind == nnkEmpty:
        result = "lambda"
    #If it's a private operator...
    elif function[0].kind == nnkAccQuoted:
        result = function[0][0].strVal
    #If this is a postfix, it's either a public function or an public operator.
    elif function[0].kind == nnkPostfix:
        #Check if it's an operator.
        for c in 0 ..< function[0].len:
            #If it is, return the operator's strVal.
            if function[0][c].kind == nnkAccQuoted:
                return function[0][c][0].strVal

        #If it's not an operator, it's a public function.
        result = function[0][1].strVal
    #If it's a regular function...
    else:
        result = function[0].strVal

#Rename a proc to the passed string.
proc rename(
    function: var NimNode,
    nameArg: string
) {.compileTime.} =
    var name: NimNode = newIdentNode(nameArg)

    #If the lambda was defined using proc, it's of nnkLambda.
    #If it was defined using func, it's of nnkFuncDef.
    #If it's a lambda, which shouldn't be named, convert it to a proc.
    if function.kind == nnkLambda:
        var functionCopy: NimNode = newNimNode(nnkProcDef)
        function.copyChildrenTo(functionCopy)
        function = functionCopy

    #If it's a private operator, rename it, but preserve it as an operator.
    if function[0].kind == nnkAccQuoted:
        function[0] = newNimNode(
            nnkAccQuoted
        ).add(name)
        return
    #If this function's name node is postfix, it's either a public function or an public operator.
    elif function[0].kind == nnkPostfix:
        #Check if it's an operator.
        for c in 0 ..< function[0].len:
            #If it is, rename it, but preserve it as an operator.
            if function[0][c].kind == nnkAccQuoted:
                function[0] = newNimNode(
                    nnkAccQuoted
                ).add(name)
                return

    #Or, if it's not an operator, just overwrite it with a standard ident node.
    function[0] = name

#Recursively replaces every raise statement in the NimNode with a discard.
#This function also checks to make sure there's no generic excepts (`except:`).
proc removeRaises(
    parent: NimNode,
    index: int
) {.compileTime.} =
    #If this is an except branch, without specifying an error, error.
    if (parent[index].kind == nnkExceptBranch) and (parent[index].len == 1):
        raise newException(Exception, "Except branches must specify an Exception.")

    #If this is a raise statement, replace it with a discard statement.
    if parent[index].kind == nnkRaiseStmt:
        var replacement: NimNode = newNimNode(nnkDiscardStmt)
        parent[index].copyChildrenTo(replacement)
        parent[index] = replacement
        return

    #Iterate over every child and do the same there.
    for i in 0 ..< parent[index].len:
        removeRaises(parent[index], i)

#Recursively replaces every `await` with `waitFor` so the copied function is guaranteed synchronous.
#This is needed as every async proc raises `Exception`, and raises is purposeless when it includes Exception.
proc removeAsync(
    parent: NimNode,
    index: int
) {.compileTime.} =
    #If this is an `await`, replace it with a `waitFor`.
    if (parent[index].kind == nnkIdent) and (parent[index].strVal == "await"):
        parent[index] = newIdentNode("waitFor")

    #Iterate over every child and do the same there.
    for i in 0 ..< parent[index].len:
        parent[index].removeAsync(i)

#Make sure the proc/func doesn't allow any Exceptions to bubble up.
macro forceCheck*(
    exceptions: untyped,
    original: untyped
): untyped =
    var
        #Boolean of whether or not this function is async.
        async: bool
        #Copy the original function.
        copy: NimNode = copy(original)
        #Define a second copy if this is async (explained below).
        asyncCopy: NimNode
        #Create arrays for both recoverable/irrecoverable exceptions, and just irrecoverable.
        both: NimNode = newNimNode(nnkBracket)
        irrecoverable: NimNode = newNimNode(nnkBracket)

    #Rename it.
    copy.rename(original.getName() & "_forceCheck")

    #Add the used pragma.
    copy.addPragma(
        newIdentNode(
            "used"
        )
    )

    #If this is an async proc, remove any traces of async from the copy.
    for pragma in original[4]:
        if (pragma.kind == nnkIdent) and (pragma.strVal == "async"):
            async = true
    if async:
        #Remove the async pragma.
        for p in 0 ..< copy[4].len:
            if (copy[4][p].kind == nnkIdent) and (copy[4][p].strVal == "async"):
                copy[4].del(p)
                break

        #Remove the Future[T] from the copy.
        if copy[3][0].kind != nnkEmpty:
            copy[3][0] = copy[3][0][1]

        #Remove awaits.
        copy.removeAsync(6)

        #Create a second copy. Why?
        #Generally, the original function gets the proper raises pragma, and the copy gets its raises replaced with discards and a blank raises pragma.
        #If it is async, any raises pragma would be forced to include Exception, which would make it purposeless.
        #The solution to this, is create two copies.
        #As before, one raises nothing and has a blank raises. The other is untouched, other than it being made synchronous, and contains the proper raises pragma.
        #The first checks bubble up, the second checks that all possible Exceptions were placed in forceCheck (guaranteeing it's a drop-in replacement for raises).
        asyncCopy = copy(copy)
        asyncCopy.rename(original.getName() & "_asyncForceCheck")

    #Grab the Exceptions.
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

    #Add the proper pragma to the original function if it's not async, or the asyncCopy if the original is.
    if not async:
        original.addPragma(
            newNimNode(
                nnkExprColonExpr
            ).add(
                newIdentNode(
                    "raises"
                ),
                both
            )
        )
    else:
        asyncCopy.addPragma(
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
    copy.addPragma(
        newNimNode(
            nnkExprColonExpr
        ).add(
            newIdentNode(
                "raises"
            ),
            irrecoverable
        )
    )

    #Replace every raises in the copy with a discard statement.
    copy.removeRaises(6)

    #Add the copy (or copies) to the start of the original proc.
    if not asyncCopy.isNil:
        original[6].insert(
            0,
            asyncCopy
        )

    #Place the copy which stops bubble up in a hint block in order to stop duplicate hints.
    #The async copy is not placed in this block so unused Exceptions produce a hint.
    original[6].insert(
        0,
        newNimNode(
            nnkPragma
        ).add(
            newIdentNode("pop")
        )
    )

    original[6].insert(
        0,
        copy
    )

    original[6].insert(
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

    return original
