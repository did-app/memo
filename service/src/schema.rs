table! {
    drive_uploaders (id) {
        id -> Varchar,
        authorization_sub -> Nullable<Varchar>,
        name -> Varchar,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    google_authorizations (sub) {
        sub -> Varchar,
        email_address -> Varchar,
        refresh_token -> Varchar,
        access_token -> Varchar,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    groups (id) {
        id -> Uuid,
        name -> Varchar,
        thread_id -> Uuid,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    identifiers (id) {
        id -> Uuid,
        email_address -> Varchar,
        greeting -> Nullable<Jsonb>,
        group_id -> Nullable<Uuid>,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    invitations (group_id, identifier_id) {
        group_id -> Uuid,
        identifier_id -> Uuid,
        invited_by -> Nullable<Uuid>,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    link_tokens (selector) {
        selector -> Varchar,
        validator -> Varchar,
        identifier_id -> Uuid,
        inserted_at -> Timestamp,
    }
}

table! {
    memo_notifications (id) {
        id -> Int4,
        thread_id -> Uuid,
        position -> Int4,
        recipient_id -> Uuid,
        success -> Bool,
        inserted_at -> Timestamp,
    }
}

table! {
    memos (thread_id, position) {
        thread_id -> Uuid,
        position -> Int4,
        content -> Jsonb,
        authored_by -> Uuid,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    pairs (lower_identifier_id, upper_identifier_id) {
        lower_identifier_id -> Uuid,
        upper_identifier_id -> Uuid,
        thread_id -> Uuid,
    }
}

table! {
    participations (identifier_id, thread_id) {
        identifier_id -> Uuid,
        thread_id -> Uuid,
        acknowledged -> Int4,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    threads (id) {
        id -> Uuid,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

joinable!(drive_uploaders -> google_authorizations (authorization_sub));
joinable!(groups -> threads (thread_id));
joinable!(identifiers -> groups (group_id));
joinable!(invitations -> groups (group_id));
joinable!(link_tokens -> identifiers (identifier_id));
joinable!(memo_notifications -> identifiers (recipient_id));
joinable!(memos -> identifiers (authored_by));
joinable!(memos -> threads (thread_id));
joinable!(pairs -> threads (thread_id));
joinable!(participations -> identifiers (identifier_id));
joinable!(participations -> threads (thread_id));

allow_tables_to_appear_in_same_query!(
    drive_uploaders,
    google_authorizations,
    groups,
    identifiers,
    invitations,
    link_tokens,
    memo_notifications,
    memos,
    pairs,
    participations,
    threads,
);
