run: db-up
    npx concurrently "just run-ui-server" "just run-ui-build" "just run-backend"
run-ui-server:
    cd ui && vite --port 3001
run-ui-build:
    cd ui && watchexec -w src gleam build --target javascript
run-backend:
    watchexec -w src -r gleam run

db-up:
    docker-compose up -d postgres
db-reset dbname='yak':
    docker-compose exec -T -u postgres postgres psql -c 'drop database if exists {{ dbname }}'
    docker-compose exec -T -u postgres postgres psql -c 'create database {{ dbname }}'
    docker-compose exec -T -u postgres postgres psql -d {{ dbname }} < reset.sql
db-shell:
    docker-compose exec -u postgres postgres psql

test: db-up (db-reset 'test')
    gleam test
test-watch:
    watchexec -w src -w test -r just test
