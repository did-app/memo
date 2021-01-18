table! {
    identifiers (id) {
        id -> Int4,
        email_address -> Varchar,
        greeting -> Nullable<Jsonb>,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    link_tokens (selector) {
        selector -> Varchar,
        validator -> Varchar,
        identifier_id -> Int4,
        inserted_at -> Timestamp,
    }
}

table! {
    memo_notifications (id) {
        id -> Int4,
        thread_id -> Int4,
        position -> Int4,
        recipient_id -> Int4,
        success -> Bool,
        inserted_at -> Timestamp,
    }
}

table! {
    memos (thread_id, position) {
        thread_id -> Int4,
        position -> Int4,
        content -> Jsonb,
        authored_by -> Int4,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    pairs (lower_identifier_id, upper_identifier_id) {
        lower_identifier_id -> Int4,
        lower_identifier_ack -> Int4,
        upper_identifier_id -> Int4,
        upper_identifier_ack -> Int4,
        thread_id -> Int4,
    }
}

table! {
    threads (id) {
        id -> Int4,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

joinable!(link_tokens -> identifiers (identifier_id));
joinable!(memo_notifications -> identifiers (recipient_id));
joinable!(memos -> identifiers (authored_by));
joinable!(memos -> threads (thread_id));
joinable!(pairs -> threads (thread_id));

allow_tables_to_appear_in_same_query!(
    identifiers,
    link_tokens,
    memo_notifications,
    memos,
    pairs,
    threads,
);
