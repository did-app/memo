# plum mail

### Local Development

```
docker-compose run service bash
    iex -S mix

docker-compose run -p 5000:5000 client bash
    npm i
    npm run start:dev
```

### Prepare Heroku app

This app uses the container stack.

```
heroku stack:set -a plum-mail container
```
