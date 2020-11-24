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
