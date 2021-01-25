CREATE extension "uuid-ossp";

CREATE TABLE threads (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('threads');

-- CREATE TABLE individuals (
--   id SERIAL PRIMARY KEY,
--   name VARCHAR,
--   inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
--   updated_at TIMESTAMP NOT NULL DEFAULT NOW()
-- );

-- SELECT diesel_manage_updated_at('individuals');

CREATE TABLE groups (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR NOT NULL,
  thread_id uuid REFERENCES threads(id) NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('groups');

CREATE TABLE identifiers (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  email_address VARCHAR NOT NULL UNIQUE,
  greeting jsonb,
  group_id uuid UNIQUE REFERENCES groups(id),
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
-- TODO add an individual table and check that an identifier is group or individual
-- TODO above for passwrds
-- https://stackoverflow.com/questions/15178859/postgres-constraint-ensuring-one-column-of-many-is-present
  
SELECT diesel_manage_updated_at('identifiers');

-- TODO Add accepted | pending
-- This points at individuals so we don't get a circular reference
-- could be member id but the participations would have participant id and group would become collective_id

CREATE TABLE invitations (
  group_id uuid REFERENCES groups(id) NOT NULL,
  identifier_id uuid NOT NULL,
  PRIMARY KEY (group_id, identifier_id),
  FOREIGN KEY (identifier_id) REFERENCES identifiers(id),
  invited_by uuid REFERENCES identifiers(id),
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('invitations');

CREATE TABLE participations (
  identifier_id uuid REFERENCES identifiers(id) NOT NULL,
  thread_id uuid REFERENCES threads(id) NOT NULL,
  PRIMARY KEY (identifier_id, thread_id),
  acknowledged INT NOT NULL,
  CHECK (acknowledged >= 0),
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('participations');

CREATE TABLE link_tokens (
  selector VARCHAR PRIMARY KEY,
  validator VARCHAR NOT NULL,
  identifier_id uuid REFERENCES identifiers(id) NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE pairs (
  lower_identifier_id uuid REFERENCES identifiers(id) NOT NULL,
  upper_identifier_id uuid REFERENCES identifiers(id) NOT NULL,
  PRIMARY KEY (lower_identifier_id, upper_identifier_id),
  thread_id uuid REFERENCES threads(id) NOT NULL
  -- Doesn't need a timestamps as it is always references a thread and is an immutable record
);

ALTER TABLE pairs ADD CONSTRAINT pair_identifier_order
    CHECK (lower_identifier_id < upper_identifier_id);
-- This is strictly lower so identifier can't be pair with itself

CREATE TABLE memos (
  thread_id uuid REFERENCES threads(id) NOT NULL,
  position INT NOT NULL,
  CHECK (position > 0),
  PRIMARY KEY (thread_id, position),
  content jsonb NOT NULL,
  authored_by uuid REFERENCES identifiers(id) NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('memos');

CREATE TABLE memo_notifications (
  id SERIAL PRIMARY KEY,
  thread_id uuid NOT NULL,
  position INT NOT NULL,
  FOREIGN KEY (thread_id, position) REFERENCES memos(thread_id, position),
  recipient_id uuid REFERENCES identifiers(id) NOT NULL,
  success BOOLEAN NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
);
