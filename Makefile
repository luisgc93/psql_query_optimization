# Define the Makefile targets

all: remove run

recreate: stop remove run restore create-indexes connect

stop:
	docker stop $$(docker ps -a -q)

remove: stop
	docker rm postgres-air

run:
	docker run --name postgres-air -e POSTGRES_HOST_AUTH_METHOD=trust -p 5432:5432 -v postgres-data:/var/lib/postgresql/data -d postgres:15.3

restore:
	@if docker volume ls -q --filter name=postgres-data | grep -q '.'; then \
		echo "Backup already restored."; \
	else \
		docker run --rm -v postgres-data:/volume -v $$(pwd):/backup busybox cp /backup/postgres_air_2023.backup /volume/postgres_air_2023.backup; \
		docker exec -it postgres-air bash -c "while ! pg_isready -U postgres -h localhost -p 5432 > /dev/null; do sleep 1; done"; \
		docker exec -it postgres-air pg_restore -U postgres -d postgres -v /postgres_air_2023.backup; \
	fi

create-indexes:
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "SET search_path TO postgres_air;"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX flight_departure_airport ON postgres_air.flight(departure_airport);"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX flight_scheduled_departure ON postgres_air.flight(scheduled_departure);"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX flight_update_ts ON postgres_air.flight(update_ts);"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX flight_arrival_airport ON postgres_air.flight(arrival_airport);"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX booking_leg_booking_id ON postgres_air.booking_leg(booking_id);"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX booking_leg_flight_id ON postgres_air.booking_leg(flight_id);"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX booking_leg_update_ts ON postgres_air.booking_leg(update_ts);"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX account_last_name ON postgres_air.account(last_name);"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX flight_actual_departure ON postgres_air.flight(actual_departure);"
	docker exec -it postgres-air psql -U postgres -d postgres -p 5432 -c "CREATE INDEX boarding_pass_booking_leg_id ON postgres_air.boarding_pass(booking_leg_id);"


connect:
	# for some reason we still need to run SET search_path TO postgres_air;
	psql -h localhost -p 5432 -U postgres -d postgres
