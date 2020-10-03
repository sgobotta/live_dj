# LiveDj

## Development

### Makefile

This project uses Makefile to run most of the configurations. Type `make` to get a list of available commands.

### Getting started

Configure the `.env` file with your database information and a [Youtube API key](https://console.developers.google.com/apis/api/youtube.googleapis.com/credentials)

To start your Phoenix server:

+ Install mix and npm dependencies with `make install`
+ Setup a dockerized postgresql service, an admin client, create and migrate your database with `make db`
+ Start the Phoenix server with an interactive Elixir shell using `make server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### Database

This project uses `docker-compose` to provide a pgAdmin image. It is available at `localhost:5050`. There you will have to login with the credentials provided in the `.env` file: `PG_ADMIN_DEFAULT_EMAIL`, `PG_ADMIN_DEFAULT_PASSWORD`. Then create a server with name `postgres`, username and password as provided in the `.env` file.

You can reset the database using `make reset`.
