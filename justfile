run: db-up
    npx concurrently "just run-ui-server" "just run-ui-build" "just run-backend"
run-ui-server:
    cd yak_ui && vite --port 3001
run-ui-build:
    cd yak_ui && watchexec -w src gleam build --target javascript
run-backend:
    cd yak_backend && watchexec -w src -r gleam run

db-up:
    cd yak_backend && docker-compose up -d postgres
db-reset dbname='yak':
    cd yak_backend && docker-compose exec -T -u postgres postgres psql -c 'drop database if exists {{ dbname }}'
    cd yak_backend && docker-compose exec -T -u postgres postgres psql -c 'create database {{ dbname }}'
    cd yak_backend && docker-compose exec -T -u postgres postgres psql -d {{ dbname }} < reset.sql
db-shell:
    cd yak_backend && docker-compose exec -u postgres postgres psql

test: db-up (db-reset 'test')
    cd yak_backend && gleam test
test-watch:
    cd yak_backend && watchexec -w src -w test -r just test
