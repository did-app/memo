import {get, post} from "./client"

type Call<T> = Promise<T | {error: {detail: string}}>
const Call = Promise
// https://github.com/microsoft/TypeScript/issues/32574

type identifier = {id: number, emailAddress: string, hasAccount: boolean}
// typescript type for anything, so it needs checking
// unknown is the type we need

export async function authenticateWithSession(): Call<identifier>{
  const path = "/authenticate/session"
  const response = await get(path)
  return mapData(response, function(data) {
    const identifier = {
      id: data.id,
      emailAddress: data.email_address,
      hasAccount: data.has_account
    }
    return {identifier}
  })
}
export async function authenticateWithCode(code){

}

function mapData(response, mapper) {
  if ("data" in response) {
    return mapper(response.data)
  } else {
    return response
  }
}
