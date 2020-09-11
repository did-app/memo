CREATE TABLE link_tokens (
  selector VARCHAR PRIMARY KEY,
  validator VARCHAR NOT NULL,
  identifier_id INT REFERENCES identifiers(id) NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE refresh_tokens (
  selector VARCHAR PRIMARY KEY,
  validator VARCHAR NOT NULL,
  link_token_selector VARCHAR REFERENCES link_tokens(selector) ON DELETE CASCADE NOT NULL,
  user_agent VARCHAR NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE session_tokens (
  selector VARCHAR PRIMARY KEY,
  validator VARCHAR NOT NULL,
  refresh_token_selector VARCHAR REFERENCES refresh_tokens(selector) ON DELETE CASCADE NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
);
