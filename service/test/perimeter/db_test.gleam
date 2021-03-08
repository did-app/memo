// "null value in column \"thread_id\" violates not-null constraint"
// "column \"zz\" does not exist"
// "relation \"moo\" does not exist"
// ** (exit) exited in: :pgo_pool.checkout(:defaultzz, [])
//  ** (EXIT) no process: the process is not alive or there's no process currently associated with the given name, possibly because its application isn't started
// {wrong_number_of_arguments,1,0}
// {other,none_available} -> When the DB is down
// "syntax error at or near \"SELECTss\""
import gleam/atom
import gleam/io
import gleam/pgo
// Constrain can be part of migrations, non null
// contstaint can be unknowable because of uniqueness
// Let's say that if the constraint is known then the query should have an on conflict value
// Therefore it's a programmer error
// Errors are meant to be pgo_error but seem to most come out as pgsql_error types
// https://github.com/erleans/pgo/blob/6bbd5478ac08ae184cdd8f2331ff81fd94b66610/src/pgo.erl#L37
