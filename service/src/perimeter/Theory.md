# Unified theory of Errors

Search for the cannonical approach to error handling

## Does one exist

Well designed API's e.g. Postmark have a single error model with an enumerated set of Errors
https://postmarkapp.com/developer/api/overview

Most web applications have a very wide set of api endpoints, and yet they come up with a single error structure.
Admin, Query, Commands, authed vs not

Because of this my assertion is:

There is probably a pretty useful version 



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


