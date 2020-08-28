import plum_mail/authentication
import plum_mail/discuss/start_conversation as inner_sc

pub fn identifier_from_email(email_address) {
    authentication.identifier_from_email(email_address)
}

pub fn start_conversation(topic, owner_id) {
    inner_sc.execute(topic, owner_id)
}
