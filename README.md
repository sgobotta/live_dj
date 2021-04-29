#

<p align="center">
  <a
    href="https://live-dj.herokuapp.com"
    target="_blank" rel="noopener noreferrer"
  >
    <img
      width="100%" src="assets/static/svg/generic/logo/live-dj-logo-readme.svg"
      alt="LiveDj logo"
    />
  </a>
</p>

<h4 align="center">
  Synchronously share and discover music with people from around the world
</h4>

---

<p align="center" style="margin-top: 14px;">
  <a href="https://github.com/sgobotta/live_dj/actions/workflows/ci.yml">
    <img
      src="https://github.com/sgobotta/live_dj/actions/workflows/ci.yml/badge.svg"
      alt="Build Status"
    >
  </a>
  <a href='https://coveralls.io/github/sgobotta/live_dj'>
    <img
      src='https://coveralls.io/repos/github/sgobotta/live_dj/badge.svg'
      alt='Coverage Status'
    />
  </a>
  <a
    href="https://github.com/sgobotta/live_dj/blob/main/LICENSE"
  >
    <img
      src="https://img.shields.io/badge/License-GPL%20v3-blue.svg"
      alt="License"
    >
  </a>
  <a
    href="https://github.com/sgobotta/live_dj/blob/main/CODE_OF_CONDUCT.md"
  >
    <img
      src="https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg"
      alt="Contributor Covenant"
    >
  </a>
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

+ [**Docker**](https://docs.docker.com/engine/install/ubuntu/)
+ [**Docker Compose**](https://docs.docker.com/compose/install/)
+ [**Elixir**](https://elixir-lang.org/install.html)

### Recommended editors and extensions

+ [**VSCode**](https://code.visualstudio.com/Download)
+ [**VSCodium**](https://vscodium.com/#install) is the Free/Libre version of Visual Studio Code.
+ [**ElixirLS**](https://marketplace.visualstudio.com/items?itemName=JakeBecker.elixir-ls) brings debugging support, static code analysis, formatting, code highlighting, among other features.
+ [**Elixir Linter (Credo)**](https://marketplace.visualstudio.com/items?itemName=pantajoe.vscode-elixir-credo) brings code formatting support, shows refactoring opportunities and promotes code style consistency.

### Environment variables

Configure an `.env` file in the project root using the `.env.example` file as template. Then assign a proper value to each variable.

```bash
cp .env.example .env
```

+ Get a [Youtube API key](https://console.developers.google.com/apis/api/youtube.googleapis.com/credentials)

Once you're done, follow the next steps to get a Phoenix server started:

+ Run `make setup` to get the whole environment ready. This will install client and server side dependencies, set up a database and populate it with fixture seeds.
+ Then you can start the Phoenix server with an interactive Elixir shell using `make server`
+ Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

> This project uses Makefile to run most of the configurations. Type `make` to get a list of available commands.

### Tests

+ Use `make test` to run all tests.
+ Use `make test.wip` to run only tests declared with `@tag :wip`. [Tagging example](https://hexdocs.pm/phoenix/testing.html#running-tests-using-tags).
+ Use `make test.cover` to get a coverage report.

### Services

This project uses `docker-compose` to provide a [PostgreSql](https://www.postgresql.org/) and [pgAdmin](https://www.pgadmin.org/) instances.

#### Postgres Database

Useful commands:

+ Use `make reset` to re-create the whole environment, including the database and get it populated with fixture seeds.
+ Use `make ecto.setup` to run migrations and fixtures only.

#### Postgres Admin

To log in use the credentials provided in the `.env` file:

+ `PG_ADMIN_DEFAULT_EMAIL`
+ `PG_ADMIN_DEFAULT_PASSWORD`.

After the services are up you can:

+ Visit [`localhost:5050`](http://localhost:5050/) from your browser with the credentials provided in the `.env` file.
+ In the menu go to `Object` -> `Create` -> `Server` and make up a server name.
+ Then, in the `Connection` tab use `main_db` as host (this matches the services name declared in the `docker-compose.yml` file) and use the *"Pg Admin"* credentials in the `.env` file to gain access to the database.
+ You'll be able to dig into the dev and test database.

## Contributing

Please make sure to read the [Contributing Guide](https://github.com/sgobotta/live_dj/blob/main/CONTRIBUTING.md) before making a pull request. If you have a Vue-related project/component/tool, add it with a pull request to this curated list!

## License

[GPL v3.0](https://github.com/sgobotta/live_dj/blob/main/LICENSE)

---

<p align="center">
  <code>&lt;/&gt;</code> with ❤️ from <code>Buenos Aires, Argentina</code> 🌎 as an <code>Open Source</code> project.
</p>
