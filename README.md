# Console

Code that powers the official [Helium Roaming Console].

## Running Console Development Environment

- Install homebrew (https://brew.sh/)
- Install postgres (postgres.app on mac)
- Install yarn (`brew install yarn`)
- Install libsodium (`brew install libsodium`)
- Install erlang (https://thinkingelixir.com/install-elixir-using-asdf/) (asdf install erlang 21.1, asdf local erlang 21.1)
- Install elixir (https://thinkingelixir.com/install-elixir-using-asdf/) (asdf install elixir 1.9.0, asdf local elixir 1.9.0)

To start your Phoenix server:

- Install dependencies with `mix deps.get`
- Create and migrate your database with `mix ecto.setup`
- Install Node.js dependencies with `cd assets && yarn`
- Start Phoenix with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
