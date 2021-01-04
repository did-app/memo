table! {
    conversations (id) {
        id -> Int4,
        topic -> Nullable<Varchar>,
        started_by -> Int4,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    identifiers (id) {
        id -> Int4,
        email_address -> Varchar,
        referred_by -> Int4,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
        greeting -> Nullable<Jsonb>,
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
    message_notifications (id) {
        id -> Int4,
        conversation_id -> Int4,
        counter -> Int4,
        identifier_id -> Int4,
        inserted_at -> Timestamp,
        success -> Bool,
    }
}

table! {
    messages (conversation_id, counter) {
        conversation_id -> Int4,
        counter -> Int4,
        content -> Text,
        conclusion -> Bool,
        authored_by -> Int4,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    note_notifications (id) {
        id -> Int4,
        thread_id -> Int4,
        position -> Int4,
        identifier_id -> Int4,
        success -> Bool,
        inserted_at -> Timestamp,
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
    participants (identifier_id, conversation_id) {
        identifier_id -> Int4,
        conversation_id -> Int4,
        invited_by -> Nullable<Int4>,
        cursor -> Int4,
        notify -> Varchar,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
        done -> Int4,
    }
}

table! {
    pins (id) {
        id -> Int4,
        conversation_id -> Int4,
        counter -> Int4,
        authored_by -> Int4,
        content -> Text,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    refresh_tokens (selector) {
        selector -> Varchar,
        validator -> Varchar,
        link_token_selector -> Varchar,
        user_agent -> Varchar,
        inserted_at -> Timestamp,
    }
}

table! {
    session_tokens (selector) {
        selector -> Varchar,
        validator -> Varchar,
        refresh_token_selector -> Varchar,
        inserted_at -> Timestamp,
    }
}

table! {
    threads (id) {
        id -> Int4,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

joinable!(conversations -> identifiers (started_by));
joinable!(link_tokens -> identifiers (identifier_id));
joinable!(memos -> identifiers (authored_by));
joinable!(memos -> threads (thread_id));
joinable!(message_notifications -> identifiers (identifier_id));
joinable!(messages -> conversations (conversation_id));
joinable!(messages -> identifiers (authored_by));
joinable!(note_notifications -> identifiers (identifier_id));
joinable!(pairs -> threads (thread_id));
joinable!(participants -> conversations (conversation_id));
joinable!(pins -> identifiers (authored_by));
joinable!(refresh_tokens -> link_tokens (link_token_selector));
joinable!(session_tokens -> refresh_tokens (refresh_token_selector));

allow_tables_to_appear_in_same_query!(
    conversations,
    identifiers,
    link_tokens,
    memos,
    message_notifications,
    messages,
    note_notifications,
    pairs,
    participants,
    pins,
    refresh_tokens,
    session_tokens,
    threads,
);
