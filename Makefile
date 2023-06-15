# Define the Makefile targets


all: stop run

recreate: stop remove run restore create-indexes connect

stop:
	docker stop $$(docker ps -a -q)

remove:
	docker rm postgres-air


run:
	docker run --name postgres-air -e POSTGRES_PASSWORD=secretpassword -p 5432:5432 -d postgres

restore:
	docker cp postgres_air_2023.backup postgres-air:/postgres_air_2023.backup
	docker exec -it postgres-air bash -c "while ! pg_isready -U postgres -h localhost -p 5432 > /dev/null; do sleep 1; done"
	docker exec -it postgres-air pg_restore -U postgres -d postgres -v /postgres_air_2023.backup

create-indexes:
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "SET search_path TO postgres_air;"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX flight_departure_airport ON postgres_air.flight(departure_airport);"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX flight_scheduled_departure ON postgres_air.flight(scheduled_departure);"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX flight_update_ts ON postgres_air.flight(update_ts);"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX booking_leg_booking_id ON postgres_air.booking_leg(booking_id);"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX booking_leg_update_ts ON postgres_air.booking_leg(update_ts);"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX account_last_name ON postgres_air.account(last_name);"

connect:
	psql -h localhost -p 5432 -U postgres -d postgres
