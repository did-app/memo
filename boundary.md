# Approaches to typing the front end backend boundary.

## Considerations

1. Client is an untrusted environment, deliberately malformed messages may be sent.
2. The API might be public, i.e. many clients.
3. Client and Server might not be of the same form.
4. it's worth noting that deriving from a json schema doesn't get you any named types. interesting application types, ip etc etc

## Case studies

### Typescript validation library

https://spin.atomicobject.com/2018/03/26/typescript-data-validation/
https://ajv.js.org/docs/standalone.html
https://colinhacks.com/essays/zod
https://spin.atomicobject.com/2020/11/05/type-safe-rest-api/

### Runtime decoders

https://nvie.com/posts/introducing-decoders/


#### Quicktype

https://app.quicktype.io/

Can start from typescript as a spec


# Future
- Serverless compile to JS or WASM


## Gleam vs Elm

Less open development https://github.com/elm/compiler/blob/d07679322ef5d71de1bd2b987ddc660a85599b87/compiler/src/Elm/Package.hs#L72
Wow

https://blog.bitsrc.io/elm-and-why-its-not-quite-ready-yet-2c516a81e252

Gleam has a Great FFI story, decide what your guarantees are at the edge.
but rely on them every where.
Same as Rust unsafe.
I consider them axioms.
