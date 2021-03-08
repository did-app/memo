# Unified theory of Errors

Search for the cannonical approach to error handling

## Does one exist

Well designed API's e.g. Postmark have a single error model with an enumerated set of Errors
https://postmarkapp.com/developer/api/overview

Most web applications have a very wide set of api endpoints, and yet they come up with a single error structure.
Admin, Query, Commands, authed vs not

Because of this my assertion is:

There is probably a pretty useful version 

## What is a Program

input + state -> logic + services -> output

This works for function call, API call, CLI execution

Error attributes.

## Problems with input. Smarter type systems can reduce this but it's always possible.
With an API call there's far more options for bad input.
RejectedInput

## Problem with the logic, 
So called Bugs and can be fixed by a programmer

## Problem with the state.
These aren't really errors at all. 
For example a user tries to reserve a username that's already taken.

The input is good, there is no way to the client to know the username is taken so it makes the request
The server knows the username is taken and so performs properly and disallows the request.

These are 

## Design outcomes

```
http.get(uri)
```

If the uri is invalid the downstream service should reject the input.

But how should this service react, well if the uri was an argument to this program then it needs to tell the caller
If the uri was part of the program then it needs to tell the call there is problem with the logic.

We want to fall into the pit of success here.

```rust
fn call(input) {
  try uri = uri.parse(input)
  try reponse = http.get(uri)
}
```

```rust
const uri = Uri("https://example.com")

fn call() {
  try reponse = http.get(uri)
}
```

The http library can always say that getting an invalid url is a program error, because even if the url comes from input, it is a programmer error to not validate the calls.

This principle works for all service calls,

A call is made to service A which in turn makes a call to service B.
If B returns early because of rejected input. 
A should return early due to a Logic Error, because it is assumed that it should validate it's own input before calling downstream.



Calling stuff error's one of the biggest mistakes.

- RejectedInput -> LogicError
- Unprocessable -> Unprocessable
- LogicError -> ServiceError
- ServiceUnavailable -> ServiceUnavailable
- ServiceError -> ServiceError

Added to the set
UnknownError (treated as logic error by client)
AlreadyDone (maybe, not using it)