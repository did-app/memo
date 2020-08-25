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
    participants (id) {
        id -> Int4,
        conversation_id -> Int4,
        identifier_id -> Int4,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}

joinable!(participants -> conversations (conversation_id));
joinable!(participants -> identifiers (identifier_id));

allow_tables_to_appear_in_same_query!(
    conversations,
    identifiers,
    participants,
);
