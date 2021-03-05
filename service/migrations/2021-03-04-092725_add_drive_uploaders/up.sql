CREATE TABLE google_authorizations (
  sub VARCHAR PRIMARY KEY,
  email_address VARCHAR NOT NULL UNIQUE,
  refresh_token VARCHAR NOT NULL,
  expires_in INTEGER NOT NULL,
  access_token VARCHAR NOT NULL,

  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('google_authorizations');

CREATE TABLE drive_uploaders (
  id VARCHAR PRIMARY KEY,
  authorization_sub VARCHAR REFERENCES google_authorizations(sub),
  name VARCHAR NOT NULL,
  parent_id VARCHAR,
  parent_name VARCHAR,

  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('drive_uploaders');
