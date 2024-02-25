# yak

Exploring what it's like to develop a fullstack app in [Gleam](https://gleam.run/)

## Overview

- Automatic rebuild with [Watchexec](https://watchexec.github.io/)
- [Caddy](https://caddyserver.com/) as a dev server with local HTTPS
- UI is written in [Lustre](https://lustre.build/) (and my ham-fisted attempt at recreating the app structure of [elm-spa](https://www.elm-spa.dev/) but without routing) and is built with [Vite](https://vitejs.dev/)
- Backend uses [elli](https://github.com/gleam-lang/elli) and docker-compose for managing the database (and other services in the future)
- Features a shared module with common types and json codecs/decoders
- Uses my WIP [CORS library](https://github.com/ffigiel/gleam_cors) (and my fork of [gleam/fetch](https://github.com/ffigiel/fetch) to add support for session cookies)

## Development

**Initial setup**

- run `make db-reset` to initialize the project's database (see `yak_backend/reset.sql`)
- `cd yak_ui` and `npm install`
- clone `ffigiel/gleam_cors` and `ffigiel/fetch` adjacent to this project's directory
- add `127.0.0.1 yak.localhost api.yak.localhost` to your hosts file

**Development**

Run `make` to start a dev server and navigate to `https://yak.localhost:3000/`

**Testing**

You can run tests via `make test` or `make test-watch`
