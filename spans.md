https://github.com/opentracing/specification/blob/master/semantic_conventions.md
```rust
pub fn handle(request, config) {
  // parent span should be started with application name etc
  // should this be at the server library level
  // in most cases assume span is always present
  // Can they be in two parents.
  // Start piping data into a service seems most reliably way to see whats working.
  // My mission is a slow API with optimistic UI
  // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server-Timing
  // https://www.w3.org/TR/trace-context/
  // https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/trace/semantic_conventions/http.md
  // Do these match the standard apache http logger line
  span = OpenTracing.start(config.span, "http.request")
  |> OpenTracing.set_key("http.method", "GET")
  |> OpenTracing.set_key("http.path", request.path)
  |> OpenTracing.set_keys(Midas.OpenTracing.request_keys(request))
  let case route(request, Config(..config, span: span)) {
    Ok(response)
    Error(reason)
  }
  let span = span
  |> OpenTracing.set_keys(Midas.OpenTracing.response_keys(response))
  |> OpenTracing.stop_span()

}
```
Are there browser tools for this tracing information


### Getting started

https://github.com/open-telemetry/opentelemetry-js/tree/master/getting-started

### Exporter

https://github.com/census-instrumentation/opencensus-node/blob/master/packages/opencensus-core/src/exporters/console-exporter.ts#L36

has become

https://github.com/open-telemetry/opentelemetry-js/pull/300

```js
// TODO ConsoleSpanExporter doesn't exist
// import { SimpleSpanProcessor } from '@opentelemetry/tracing';
// import * as WebTracerProvider from '@opentelemetry/web';
// console.log(WebTracerProvider);
import opentelemetry from '@opentelemetry/api';
console.log(opentelemetry);
```
