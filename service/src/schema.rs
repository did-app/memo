table! {
    groups (id) {
        id -> Int4,
        name -> Varchar,
        thread_id -> Int4,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    identifiers (id) {
        id -> Int4,
        email_address -> Varchar,
        greeting -> Nullable<Jsonb>,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
        group_id -> Nullable<Int4>,
    }
}

table! {
    invitations (group_id, identifier_id) {
        group_id -> Int4,
        identifier_id -> Int4,
        invited_by -> Nullable<Int4>,
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
        upper_identifier_id -> Int4,
        thread_id -> Int4,
    }
}

table! {
    participations (identifier_id, thread_id) {
        identifier_id -> Int4,
        thread_id -> Int4,
        acknowledged -> Int4,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    threads (id) {
        id -> Int4,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

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
