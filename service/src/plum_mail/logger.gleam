import gleam/beam.{ExitReason, Stacktrace}
import gleam_sentry as sentry
import plum_mail/config.{Config}

pub fn handle(
  config: Config,
  reason: ExitReason,
  stacktrace: Stacktrace,
  timestamp,
) {
  sentry.capture_exception(config.sentry_client, reason, stacktrace, timestamp)
  Nil
}
