-- Лаба 4. Роли приложения. Пароли берутся из переменных окружения (файл .env),
-- которые docker-compose.yml передаёт в контейнер.

\getenv reader_password APP_READER_PASSWORD
\getenv writer_password APP_WRITER_PASSWORD

CREATE ROLE app_reader LOGIN PASSWORD :'reader_password';
CREATE ROLE app_writer LOGIN PASSWORD :'writer_password' IN ROLE app_reader;

-- По умолчанию функции может вызывать кто угодно (PUBLIC): закрываем.
REVOKE EXECUTE ON ALL ROUTINES IN SCHEMA public FROM PUBLIC;
REVOKE EXECUTE ON ALL ROUTINES IN SCHEMA lib FROM PUBLIC;

-- Таблицы приложению не открываем совсем.
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM app_reader, app_writer;
REVOKE ALL ON ALL TABLES IN SCHEMA lib FROM app_reader, app_writer;

-- app_reader: заходит в схему lib и читает только представления.
GRANT USAGE ON SCHEMA lib TO app_reader, app_writer;
GRANT SELECT ON lib.v_loan_card, lib.v_reader_load TO app_reader;
GRANT EXECUTE ON FUNCTION lib.search_loans(integer, integer, boolean) TO app_reader;

-- app_writer: таблицы напрямую менять не может, но вызывает бизнес-операции.
GRANT EXECUTE ON FUNCTION lib.issue_book(integer, integer, integer) TO app_writer;
GRANT EXECUTE ON FUNCTION lib.return_book(integer) TO app_writer;

-- Роли входят в базу сами (dbcheck, приложение), поэтому им нужен search_path:
-- иначе представления из схемы lib надо писать с префиксом lib.
ALTER ROLE app_reader SET search_path = public, lib;
ALTER ROLE app_writer SET search_path = public, lib;