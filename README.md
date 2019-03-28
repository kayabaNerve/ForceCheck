# ForceCheck

A Nimble package to stop functions from having Exceptions bubble up.

# Usage:

`forceCheck` takes the place of the existing raises pragma. It copies your function, adds a blank raises pragma, replaces every raises in the copy with a discard, and then has that compiled with your actual function. If Nim has an error, your function had a potential bubble up. Your actual function does have a raises pragma added as well, and the copy is removed from the binary as dead code.

`fcRaise` is a workaround for a bug. For some reason, having `raise` inside of an `except` block (with no exception), which is valid and raises the caught error again, doesn't work. `fcRaise` is a template which expands to `raise getCurrentException()`. Since `getCurrentException()` will remove the Exception type, you can also use `fcRaise ExceptionType` which will expand to `raise (ref ExceptionType)(getCurrentException())`.
