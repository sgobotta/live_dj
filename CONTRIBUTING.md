# LiveDj Contributing Guide

Hi! We're really excited that you are interested in contributing to LiveDj. Before submitting your contribution, please make sure to take a moment and read through the following guidelines:

+ [Code of Conduct](https://github.com/sgobotta/live_dj/blob/main/.github/CODE_OF_CONDUCT.md)
+ [Issue Reporting Guidelines](#issue-reporting-guidelines)
+ [Pull Request Guidelines](#pull-request-guidelines)
+ [Development Setup](#development-setup)
+ [Project Structure](#project-structure)

## Issue Reporting Guidelines

+ Always use our [**bug**](https://github.com/sgobotta/live_dj/issues/new?assignees=&labels=bug&template=bug_report.md&title=) or [**feature**](https://github.com/sgobotta/live_dj/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=) templates to create an issue.

## Pull Request Guidelines

+ The `main` branch is just a snapshot of the latest stable release. All development should be done in dedicated branches. **Do not submit PRs against the `main` branch.**
+ Checkout a topic branch from the relevant branch, e.g. `develop`, and merge back against that branch. Please follow this convention for the new branch: `issueNumber-githubUsername-commitTitle`.
+ Most of the contributed work should generally target the `lib` directory or the `assets` directory on rare occasions when the client needs a `javascript` poke.
+ It's OK to have multiple small commits as you work on the PR. We may squash them before merging if necessary.
+ Make sure `make test` passes. (see [**development setup**](#development-setup))
+ If adding a new feature:
  + Add accompanying test cases.
  + Provide a convincing reason to add this feature. Ideally, you should open a suggestion issue first and have it approved before working on it.
+ If fixing a bug:
  + If you are resolving a special issue, please follow the branch naming convention mentioned above.
  + Provide a detailed description of the bug in the PR. Live demo preferred.
    + Add appropriate test coverage if applicable.

## Development Setup

You will need the `mix` program, which is provided when installing [Elixir](https://elixir-lang.org/install.html).

After cloning the forked repository, run:

```bash
make setup
```

This script will install Elixir, node dependencies, set up a database and populate it with fixtures.

### Committing Changes

We don't expect any strict convention, but we'd be grateful if you summarize what your modifications content is about when writing a commit.

**Git hooks should be automatically installed after dependencies are installed. You should find them by listing files like `ls .git/hooks` to find some "pre hooks". If they're not there please run them manually by typing `mix git_hooks.install`. This help us guarantee code style consistency.**

### Commonly used scripts during development

``` bash
# Setups the whole environment. Also useful when checking out new branches.
make setup

# Installs server and client dependencies
make install

# Runs all tests
make test

# Runs only tests tagged with :wip e.g: `@tag :wip`
make test.wip

# Gets a test coverage report
make test.cover

# Initialises a local server with hot-reload and an interactive elixir prompt
make server

# Re-creates databases, runs migrations and loads fixture seeds
make ecto.reset

# Simulates a fresh installation
make reset
```

**Please make sure tests pass successfully before submitting a PR.** Although the same tests will be run against your PR on the CI server, it is better to have it working locally.

## Project Structure

> This project was created using the `mix phx.new --live` [command](https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html). Documentation about the directory structure can be found in the [official docs](https://hexdocs.pm/phoenix/directory_structure.html). Here we cover those specific directories were contributions work is commonly expected to land.

+   **`assets`**: contains the source code related to the client side.

    +   **`assets/js`**: contains the main application entrypoint (`app.js`) where the rest of the client modules are included.

    +   **`assets/js/deps`**: contains modules that instance third party client libraries.

    +   **`assets/js/hooks`**: contains all implementations for the client hooks provided by the Phoenix framework.

+   **`lib`**: contains the source code related to the server side.

    +   **`lib/live_dj`**: directory where Ecto schemas and domain specific logic is implemented. Mostly contains modules created using the `mix phx.gen.context` tool.

    +   **`lib/live_dj_web`**: contains modules related to router updates, routes controllers, live views, live components and templates.

    +   **`lib/live_dj_web/components`**: contains implementations for reusable [live components](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html).

    +   **`lib/live_dj_web/controllers`**: contains [controllers](https://hexdocs.pm/phoenix/Phoenix.Controller.html) implementations for non live views.

    +   **`lib/live_dj_web/live`**: contains implementations of [live view](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) pages.

    +   **`lib/live_dj_web/templates`**: contains markup for non live views and re-usable html templates which are generally included in other non live views.

+   **`priv`**: contains code that is private to the application itself. Most of the work in this directory is related to seeds implementation when new schemas have been created or internationalization features.

    + **`priv/gettext`**: contains language translations.

    + **`priv/repo/seeds`**: contains scripts to populate an existing databse with new information.

+   **`test`**: contains all the application tests.

    +   **`test/live_dj`**: contains unit tests mostly related to domain specific modules.

    +   **`test/live_dj_web`**: contains integration tests mostly related to controllers and live views behaviour.

## Attribution

This Contributing Guidelines were adapted from the [Vue.js Contributing Guide][vue-js-contributing-guide].

[vue-js-contributing-guide]: https://github.com/vuejs/vue/blob/dev/.github/CONTRIBUTING.md
