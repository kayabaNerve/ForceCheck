# ForceCheck

A Nimble package to stop functions from allowing Exceptions to bubble up.

# Usage:

`forceCheck` takes the place of the existing raises pragma. The macro copies your function, adds a blank raises pragma, replaces every raises in the copy with a discard, and then has that compiled with your actual function. If Nim has an error, your function had a potential bubble up. Your actual function does have a raises pragma added as well, and the copy is removed from the binary as dead code.

`forceCheck` can be used with asynchronous functions, as long as the pragmas are in the following order: `{.forceCheck: [], async.}`. Every async function can raise `Exception`, making a raises worthless. That said, when `forceCheck` copies your function, it removes `async` from the copy and replaces every `await` with `waitFor`, allowing proper bubble-up detection. Since there's no value in adding raises to your actual function, it isn't done.

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
