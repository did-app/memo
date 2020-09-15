function isFunction1(func) {
  if (typeof func === "function" && func.length === 1) {
    return func;
  } else {
    throw (TypeError, "Not a function with single argument");
  }
}

// https://github.com/patrickmichalina/typescript-monads/blob/master/src/monads/result.ts
export function OK(value) {
  return {
    map: function(func) {
      return OK(func(value));
    },
    mapFail: function(_func) {
      return OK(value);
    },
    flatMap: function(func) {
      return func(value);
    },
    asyncFlatMap: async function(func) {
      return await func(value);
    },
    unwrapOr: function(_alt) {
      return value;
    },
    match: function({ ok, fail }) {
      isFunction1(ok);
      isFunction1(fail);
      return ok(value);
    }
  };
}

export function Fail(reason) {
  return {
    map: function(_func) {
      return Fail(reason);
    },
    mapFail: function(func) {
      return Fail(func(reason));
    },
    flatMap: function(_func) {
      return Fail(reason);
    },
    asyncFlatMap: function(_func) {
      return Fail(reason);
    },
    unwrapOr: function(alt) {
      return alt;
    },
    match: function({ ok, fail }) {
      isFunction1(ok);
      isFunction1(fail);
      return fail(reason);
    }
  };
}
