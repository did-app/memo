table! {
    conversations (id) {
        id -> Int4,
        topic -> Nullable<Varchar>,
        resolved -> Bool,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    identifiers (id) {
        id -> Int4,
        email_address -> Varchar,
        nickname -> Nullable<Varchar>,
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
    }
}

table! {
    messages (conversation_id, counter) {
        conversation_id -> Int4,
        counter -> Int4,
        content -> Text,
        author_id -> Int4,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    participants (identifier_id, conversation_id) {
        identifier_id -> Int4,
        conversation_id -> Int4,
        cursor -> Int4,
        notify -> Varchar,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

table! {
    pins (id) {
        id -> Int4,
        conversation_id -> Int4,
        content -> Text,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

joinable!(message_notifications -> identifiers (identifier_id));
joinable!(messages -> conversations (conversation_id));
joinable!(messages -> identifiers (author_id));
joinable!(participants -> conversations (conversation_id));
joinable!(participants -> identifiers (identifier_id));
joinable!(pins -> conversations (conversation_id));

allow_tables_to_appear_in_same_query!(
    conversations,
    identifiers,
    message_notifications,
    messages,
    participants,
    pins,
);
