table! {
    identifiers (id) {
        id -> Int4,
        email_address -> Varchar,
        nickname -> Nullable<Varchar>,
        inserted_at -> Timestamp,
        updated_at -> Timestamp,
    }
}
