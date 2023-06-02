run:
    watchexec -w src -c -r gleam run
db-reset:
    docker-compose exec -T -u postgres postgres psql < reset.sql
