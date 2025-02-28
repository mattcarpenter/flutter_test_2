PGPASSWORD=your-super-secret-and-long-postgres-password psql -U postgres -d postgres -h localhost -p 5433 -f postgres_powersync.sql
PGPASSWORD=your-super-secret-and-long-postgres-password psql -U postgres -d postgres -h localhost -p 5433 -f policies_powersync.psql
PGPASSWORD=your-super-secret-and-long-postgres-password psql -U postgres -d postgres -h localhost -p 5433 -f triggers_powersync.psql
