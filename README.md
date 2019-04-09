# ForceCheck

A Nimble package to stop functions from allowing Exceptions to bubble up.

# Usage:

`forceCheck` takes the place of the existing raises pragma. The macro copies your function, adds a blank raises pragma, replaces every raises in the copy with a discard, and then has that compiled with your actual function. If Nim has an error, your function had a potential bubble up. Your actual function does have a raises pragma added as well, and the copy is removed from the binary as dead code.

As some exceptions shouldn't be handled, irrecoverable exceptions, it's possible to specify those:
```
{.forceCheck: [
    recoverable: [
        KeyError,
        ValueError
    ],
    irrecoverable: [
        OSError
    ]
].}
```
The irrecoverable exception must be specified in every function it bubbles up through, as well as the function that raises it.

`fcRaise` is a workaround for Nim's raise behavior. `raise` inside of an `except` block (with no exception), which is valid and raises the caught exception again, triggers a `ReraiseError` and `Exception` in the effects system, and just doesn't work with properly `raises`. `fcRaise ExceptionType` is a template which expands to `raise (ref ExceptionType)(getCurrentException())`.
