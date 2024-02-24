run: db-up
	npx concurrently "make run-ui-server" "make run-ui-build" "make run-backend" "caddy run"
run-ui-server:
	cd yak_ui && vite --port 3001
run-ui-build:
	cd yak_ui && watchexec -w src gleam build --target javascript
run-backend:
	cd yak_backend && watchexec -w src -r gleam run

db-up:
	cd yak_backend && docker-compose up -d postgres
db-reset:
	cd yak_backend && docker-compose exec -T -u postgres postgres psql -c 'drop database if exists yak'
	cd yak_backend && docker-compose exec -T -u postgres postgres psql -c 'create database yak'
	cd yak_backend && docker-compose exec -T -u postgres postgres psql -d yak < reset.sql
db-reset-test:
	cd yak_backend && docker-compose exec -T -u postgres postgres psql -c 'drop database if exists test'
	cd yak_backend && docker-compose exec -T -u postgres postgres psql -c 'create database test'
	cd yak_backend && docker-compose exec -T -u postgres postgres psql -d test < reset.sql
db-shell:
	cd yak_backend && docker-compose exec -u postgres postgres psql

test: db-up db-reset-test
	cd yak_backend && gleam test
test-watch:
	cd yak_backend && watchexec -w src -w test -r make test
