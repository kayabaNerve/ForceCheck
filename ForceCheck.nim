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

    #If it's a converter, it must be at the top level.
    #Therefore, we must convert it to a proc.
    if function.kind == nnkConverterDef:
        var functionCopy: NimNode = newNimNode(nnkProcDef)
        function.copyChildrenTo(functionCopy)
        function = functionCopy

    #If it's a module, it must be at the top level.
    #Therefore, we must convert it to a proc.
    if function.kind == nnkMethodDef:
        var functionCopy: NimNode = newNimNode(nnkProcDef)
        function.copyChildrenTo(functionCopy)
        function = functionCopy

        #We also need to remove the base pragma, if it exists.
        for p in 0 ..< function[4].len:
            if (function[4][p].kind == nnkIdent) and (function[4][p].strVal == "base"):
                function[4].del(p)

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

#Checks for a bracket expression which is likely to trigger a bound check.
#This may have false positives, but should never have a false negative.
proc isCheckedBracketExpr(
    node: NimNode
): bool {.compileTime.} =
    #If this is a bracket...
    if node.kind == nnkBracketExpr:
        #Confirm it has more than one child.
        if node.len < 2:
            return false

        if node[0].kind != nnkIdent:
            return true

        #Switch based on the value.
        case node[0].strVal:
            #Overrides for seq definiton/constructor.
            of "seq":
                discard
            of "newSeq":
                discard
            #Override for array definition.
            of "array":
                discard
            #Overrides for table definitions/constructors.
            of "Table":
                discard
            of "TableRef":
                discard
            of "initTable":
                discard
            of "newTable":
                discard
            #Return true.
            else:
                return true

#Recursively checks this node and every child to see if it's a checked bracket expr.
proc hasCheckedBracketExpr(
    node: NimNode
): bool {.compileTime.} =
    result = node.isCheckedBracketExpr()
    if not result:
        #Check every child.
        for child in node.children:
            #If a child has a bracket expr which is checked, return true.
            if child.hasCheckedBracketExpr():
                return true

#Inserts `if false: raise newException(IndexError, "")` to disable XDeclaredButNotUsed hints.
#If there is no `[]` used, it does nothing/
proc insertUncallableRaiseIndexError(
    node: NimNode
) {.compileTime.} =
    if node.hasCheckedBracketExpr():
        node.insert(
            0,
            newNimNode(
                nnkIfStmt
            ).add(
                newNimNode(
                    nnkElifBranch
                ).add(
                    newIdentNode("false"),
                    newNimNode(
                        nnkStmtList
                    ).add(
                        newNimNode(
                            nnkRaiseStmt
                        ).add(
                            newNimNode(
                                nnkCall
                            ).add(
                                newIdentNode("newException"),
                                newIdentNode("IndexError"),
                                newStrLitNode("")
                            )
                        )
                    )
                )
            )
        )

#Recursively checks for `[]` operator usage, and if it finds any, enforces that IndexError is either in the raises OR caught.
proc boundsCheck(
    parent: NimNode,
    index: int
) {.compileTime.} =
    #If this is an override node, strip the override out and continue.
    if (
        (parent[index].kind == nnkCall) and
        (parent[index].len > 0) and
        (parent[index][0].kind == nnkIdent) and
        (parent[index][0].strVal == "fcBoundsCheckOverride")
    ):
        #If there's no checked bracket expression in this block, hint it.
        if not parent[index].hasCheckedBracketExpr():
            hint("fcBoundsCheckOverride was used where there's no bounds check to override.")

        parent[index] = parent[index][1]
        return

    #Is this a try statement which catches IndexError.
    var tryWithCatch: bool = false
    #If this is a try statement...
    if parent[index].kind == nnkTryStmt:
        #Find the except branch with "IndexError".
        for child in parent[index]:
            if child.kind == nnkStmtList:
                continue

            #Generic except.
            if child.len == 0:
                tryWithCatch = true
                break

            #If there is one, set tryWithCatch.
            if child[0].kind == nnkInfix:
                if child[0][1].strVal == "IndexError":
                    tryWithCatch = true
                    break
            elif child[0].strVal == "IndexError":
                tryWithCatch = true
                break
    #If this is a checked bracket expr...
    elif parent[index].isCheckedBracketExpr():
        raise newException(Exception, "Code can throw IndexError which was not caught.")

    #If is a try statement which catches IndexError, we shouldn't check its statement list (item 0).
    #That said, we do need to add an if false: raise newException(IndexError, "") to stop Nim from thinking IndexError isn't used.
    var start: int = 0
    if tryWithCatch:
        #Set start to 1 so we skip the first child.
        start = 1

        #Insert an uncallable raise IndexError.
        parent[index][0].insertUncallableRaiseIndexError()

    #Iterate over every child from start and test them.
    for i in start ..< parent[index].len:
        boundsCheck(parent[index], i)

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

    #If this is an fcRaise statament, replace it as well.
    if (
        (parent[index].kind == nnkCommand) and
        (parent[index][0].kind == nnkIdent) and
        (parent[index][0].strVal == "fcRaise")
    ):
        var replacement: NimNode = newNimNode(nnkDiscardStmt)
        parent[index].del(0)
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

#Turn bounds checks from a fatal error into a managable error.
macro boundsCheck*(
    function: untyped
): untyped =
    function.boundsCheck(6)
    return function

#Make sure the proc/func doesn't allow any Exceptions to bubble up.
macro forceCheck*(
    exceptions: untyped,
    original: untyped
): untyped =
    var
        #Boolean of whether or not this function is async.
        async: bool
        #Copy of the original function.
        copy: NimNode
        #Define a second copy if this is async (explained below).
        asyncCopy: NimNode
        #Create arrays for both recoverable/irrecoverable exceptions, and just irrecoverable.
        both: NimNode = newNimNode(nnkBracket)
        irrecoverable: NimNode = newNimNode(nnkBracket)

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

    #Copy the function.
    copy = copy(original)

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

#Custom version of raise meant as a temporary solution to https://github.com/nim-lang/Nim/issues/11118.
macro fcRaise*(
    e: typed
): untyped =
    newNimNode(nnkRaiseStmt).add(
        newNimNode(nnkCall).add(
            newIdentNode("newException"),
            newIdentNode(e.getTypeInst()[0].strVal),
            newNimNode(nnkDotExpr).add(
                newIdentNode(e.strVal),
                newIdentNode("msg")
            )
        )
    )
