<p align="center">
  <a href="live-dj.herokuapp.com" target="_blank" rel="noopener noreferrer">
    <img width="240" src="assets/static/svg/generic/logo/live-dj-logo-white.svg" alt="LiveDj logo" />
  </a>
</p>

<h4 align="center">
  Synchronously share and discover music with people from around the world
</h4>

---

<p align="center" style="margin-top: 14px;">
  <img
    src="https://github.com/sgobotta/live_dj/workflows/LiveDj%20CI/badge.svg"
    alt="Build Status"
  >
  <a href="https://github.com/sgobotta/live_dj/blob/main/CODE_OF_CONDUCT.md"><img src="https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg" alt="Contributor Covenant"></a>
</p>

## About

LiveDj presents a collection of video playlists created by the community and for the community. It is designed to bring people together in the same creative and musical environment, where everyone can share the same musical experience in real time and synchrony.

## Features

+ Create public rooms
+ Edit room management and permissions
+ Users registration
+ Search Youtube videos
+ Save current playlist
+ Add, remove and sort tracks in a playlist
+ Room chat
+ Notifications
+ Medals/awards system

## Technical details

This application is developed under the Phoenix framework. Inspired by the React application [great.dj](great.dj), LiveDj let users connect to the same room and synchronously listen and watch the same video.

Users can optionally register using an email and choose a unique username. Anyone is allowed to create rooms or joined an existing one. At the moment rooms are public, meaning you can't watch videos privately since anyone can join the room you're in and listen to your playlist.

LiveDj embeds the YT API to create a video player that it's shared between connected users. The API lets LiveDj create reproduction controls, volume controls and a track queue.

## Development

### Requirements

+ [Docker](https://docs.docker.com/engine/install/ubuntu/)
+ [Docker Compose](https://docs.docker.com/compose/install/)
+ [Elixir](https://elixir-lang.org/install.html)

### Getting started

Configure an `.env` file in the project root using the `.env.example` file as template.

+ [Youtube API key](https://console.developers.google.com/apis/api/youtube.googleapis.com/credentials)

Once you're done, follow the next steps to get a Phoenix server started:

+ Install mix and npm dependencies with `make install`
+ Setup a dockerized postgresql service, an admin client, create and migrate your database with `make setup`
+ Start the Phoenix server with an interactive Elixir shell using `make server`
+ Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

> This project uses Makefile to run most of the configurations. Type `make` to get a list of available commands.

### Tests

+ Use `make test` to run all tests
+ Use `make test.only` to run only tests declared with `@tag :wip`. [Tagging example](https://hexdocs.pm/phoenix/testing.html#running-tests-using-tags).

### Services

This project uses `docker-compose` to provide a postgres and [pgAdmin](https://www.pgadmin.org/) instances..

#### Postgres Admin

To log in use the credentials provided in the `.env` file:

+ `PG_ADMIN_DEFAULT_EMAIL`
+ `PG_ADMIN_DEFAULT_PASSWORD`.

Visit [`localhost:5050`](http://localhost:5050), then create a server with name `postgres`. Use the values provided in the `.env` file for `username` and `password`.

#### Postgres Database

Useful commands:

+ Use `make reset` to re-create the database and populate it with fixture seeds.
+ Use `make ecto.seed` to re-load fixtures.
+ Use `make ecto.setup` to run migrations only.

## Contributing

Please make sure to read the [Contributing Guide](https://github.com/sgobotta/live_dj/blob/main/CONTRIBUTING.md) before making a pull request. If you have a Vue-related project/component/tool, add it with a pull request to this curated list!

## License

[GPL 3.0](https://opensource.org/licenses/GPL-3.0)

---

<p align="center">
  <code>&lt;/&gt;</code> with ❤️ from Buenos Aires, Argentina 🌎 as an <code>Open Source</code> project.
</p>
