run:
    just db-up
    npx concurrently "just run-ui-server" "just run-ui-build" "just run-backend"
run-ui-server:
    cd ui && vite --port 3001
run-ui-build:
    cd ui && watchexec -w src gleam build --target javascript

run-backend:
    watchexec -w src -r gleam run

db-up:
    docker-compose up -d
db-reset:
    docker-compose exec -T -u postgres postgres psql < reset.sql
db-shell:
    docker-compose exec -u postgres postgres psql
