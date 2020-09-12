# Persistent Sessions

(Note Sticky sessions not a good name)

Some notes on implementing sessions, might not be completely up to date but the resources are useful.
Ideally sessions would be extracted to a framework level, although this might not be so easy while they are in the DB.

## Refresh token and Rotation (OAuth)

This doesn't exactly help because we need to also implement the OAuth Provider
https://tools.ietf.org/html/rfc6819#section-5.2.2.3

It does say that remember tokens should be invalidated completely if reused

## Implementation

### RefreshTokens / Remember me

id | hashed_secret | identifier_id | fingerprint | inserted_at


- Authentication table
selector | validator | identifier_id | fingerprint | inserted_at

https://www.codejava.net/coding/how-to-implement-remember-password-remember-me-for-java-web-application

lookup | validator

https://security.stackexchange.com/questions/44/how-to-securely-implement-a-remember-me-feature/109439#109439
https://github.com/psecio/gatekeeper/blob/7b8ec374e208148692316a34c1b4700d5407ef9b/src/Psecio/Gatekeeper/Session/RememberMe.php#L5

If a refresh conflict is detected then the


### Main session

Django replay attacks
https://stackoverflow.com/questions/54819263/django-signed-cookie-session-storage-replay-attacks-and-session-cookie-age
https://github.com/django/django/blob/9a56b4b13ed92d2d5bb00d6bdb905a73bc5f2f0a/django/contrib/sessions/middleware.py#L51
https://github.com/django/django/blob/545dae24fd01a9165d869a13aad04f5b88d626c1/django/core/signing.py#L182

session_id | validator | identifier_id | inserted_at

```sql
SELECT identifier_id, validator
FROM sessions
JOIN remembers ON remembers.id = sessions.remember_id
WHERE id = $1
```

<!-- Absolute and idle, doesn't really make sense as a new one is added -->
<!-- Update the token which leads to an updated and created -->
<!-- This is called clients or devices ingress addmitance admission identification/recognition -->
<!-- doorman gatekeeper warden token -->
<!-- If reminders can only have one session single table -->

```sql
SELECT identifier_id, validator, user_agent
FROM remembers
WHERE id = $1
```

session -> session_tokens
refresh -> refresh_tokens
link -> link_tokens ( was challenges )

- session
- refresh

Needs DB for revoction


session_id | session_validator | identifier_id

Just run from the test suite
- A session should not be usable after 24 hours
- A refresh should not be usable after 1 month
- A refresh should not be usable after 1 week idle
- Refreshing a session should expire the refresh token
- Trying to refresh twice should invalidate the session
- A session should be secure, unless HTTP and localhost

## CSRF

https://engineering.mixmax.com/blog/modern-csrf/
Current setup requires an origin header.
It might want to pass for no origin sent, this is a vulnerability in old browsers,
however in newer browsers an attacker cannot force a change of origin header or for the origin header to not be sent.
