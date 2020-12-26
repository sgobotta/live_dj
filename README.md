# LiveDj

![LiveDj CI](https://github.com/sgobotta/live_dj/workflows/LiveDj%20CI/badge.svg)

## About

LiveDj is an Elixir application, developed using the Phoenix framework. Inspired by the React application [great.dj](great.dj), LiveDj let users connect to the same room and synchronously listen and watch the same video.

Users can optionally register using an email and choose a unique username. Anyone is allowed to create rooms or joined an existing one. At the moment rooms are public, meaning you can't watch videos privately since anyone can join the room you're in and listen to your playlist.

## Technical details

LiveDj embeds the YT API to create a video player that it's shared between connected users. The API lets LiveDj create reproduction controls, volume controls and a track queue.

### Features

+ Create video rooms
+ List of rooms
+ Authentication system
+ Search videos section
+ Save current playlist
+ Add, remove and sort tracks in a playlist
+ Chat with other connected users
+ Notifications on track change

## Development

### Makefile

This project uses Makefile to run most of the configurations. Type `make` to get a list of available commands.

### Getting started

Configure the `.env` file with your database information and a [Youtube API key](https://console.developers.google.com/apis/api/youtube.googleapis.com/credentials)

To start your Phoenix server:

+ Install mix and npm dependencies with `make install`
+ Setup a dockerized postgresql service, an admin client, create and migrate your database with `make setup`
+ Start the Phoenix server with an interactive Elixir shell using `make server`
+ Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### Tests

+ Use `make test` to run the test battery

### Services

This project uses `docker-compose` to provide a postgres and [pgAdmin](https://www.pgadmin.org/) instances. The admin is available at [`localhost:5050`](http://localhost:5050).

#### Postgres Admin

To log in use the credentials provided in the `.env` file: `PG_ADMIN_DEFAULT_EMAIL`, `PG_ADMIN_DEFAULT_PASSWORD`. Then create a server with name `postgres`, username and password as provided in the `.env` file.

#### Postgres Database

Useful commands:

+ Use `make reset` to re-create the database and populate it with fixtures data.
+ Use `make ecto.seed` to run the fixtures only.
+ Use `make ecto.setup` to run migrations only.
