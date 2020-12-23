// HTTP types

interface Get<Path extends (number | string)[], Data> {
  method: "GET",
  path: Path,
  // _data?: D
}

interface Post<Path, Params, Data> {
  method: "POST",
  path: Path,
  params: Params,
  // _data?: D
}

// Response data types

export type Identifier = {
  id: number,
  email_address: string
}

// Calls

export type AuthenticateWithCode = Post<
  ["authenticate", "code"],
  {code: string},
  Identifier
>

// type Id extends number
// it is NOT possible to extend number in this way, TypeScript is structural.
// https://stackoverflow.com/questions/56737033/how-to-define-an-opaque-type-in-typescript

export type GetIdentifier = Get<
  ["identifiers", number],
  Identifier
>

type Api = AuthenticateWithCode | GetIdentifier

// function post<P, D>(params: Post<P, D>): D {
//   return JSON.parse("")
// }
function post<Path extends (number | string)[], Params, Data>(request: Get<Path, Data> | Post<Path, Params, Data>): Data {

  request.path.join("/")
  return JSON.parse("")
}

// let request: Api = {method: "POST", path: "boo", params: 5}
let request: Api = {method: "GET", path: ["identifiers", 5]}
let response: {foo: true} = post(request)

// let p: AuthenticateWithCode = {params: {code: "2"}}
// let y = post(p)
// y.foo
// let raw = post<AuthenticateWithCode>({code: "hello"})

// let identifier: Identifier = (function(raw) {
//   // Typescript type narrowing is wang.
//   if (typeof raw === 'object' && raw !== null && 'id' in raw) {
//     // let refined = raw
//     let {id, email_address} = raw
//     // if (typeof raw['id'] === 'string') {
//     if (typeof id === 'number') {
//       // let x: string = refined.id;
//       return {id: raw.id, email_address: raw.email_address}
//
//     } else {
//       throw "bad"
//     }
//   } else {
//     throw "bad"
//   }
// }(raw))
