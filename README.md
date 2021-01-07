# plum mail

### Local Development

Change to the correct directory and run.
This only needs to be done once but must be done before either of the following commands is run

```
docker-compose down --remove-orphans --volumes
```

You need to access two terminals to run locally.

```
docker-compose run -p 8000:8000 service bash
    mix deps.get
    diesel migration run
    mix test
    iex -S mix
```

```
docker-compose run -p 8080:8080 -e SNOWPACK_PUBLIC_GLANCE_ORIGIN=https://glance.did.app pwa bash
    npm i
    npm start
```

Visit http://localhost:8080 and sign in.

Login with email will not send emails when running locally.
You can open the terminal where you are running the backend "service" and copy the link that would have been sent from there.

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
