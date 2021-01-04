# plum mail

### Local Development

```
docker-compose run service bash
    iex -S mix
        :plum_mail.identifier_from_email("peter@example.com")
        :plum_mail.generate_link_token(123)

docker-compose run -p 5000:5000 client bash
    npm i
    npm run start:dev
```



### Prepare Heroku app

This app uses the container stack.

```
heroku stack:set -a plum-mail container
```

## Naming

- An entry in a thread is a **Memo**
  - Note was considered but this had more connotations with just text and not an audience.
  - Also Message
- A memo has a **Position** in a thread
- A memo has content which consists of one or more blocks
  - The could also be the body/text of a memo
  - Text is reused as the lowest component
  - The content of a memo is everything produced by a user so perhaps would include headings etc
