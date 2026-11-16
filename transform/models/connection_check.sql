-- Proves a dbt environment can connect and build (ticket #4). Replace or delete once real
-- models exist (#5).
select
    current_user() as user_name,
    current_role() as role_name,
    current_database() as database_name,
    current_schema() as schema_name,
    current_warehouse() as warehouse_name
