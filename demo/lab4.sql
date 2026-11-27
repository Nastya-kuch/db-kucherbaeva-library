-- Лаба 4. Транзакции и доступ (тема: Библиотека). Формат описан в docs/scenarios.md.
-- Запуск: dbcheck run demo/lab4.sql --sql
-- Шаги с запрещёнными действиями обёрнуты в BEGIN ... ROLLBACK: если права вдруг не сработают,
-- запрос всё равно откатится и данные не изменятся.

-- 1. Выдача 4 до транзакции: книга на руках (returned_at пустой)
SELECT id, returned_at, fine FROM loans WHERE id = 4;

-- 2. Транзакция «принять книгу и выдать другую» падает на второй операции: экземпляра 99999 нет
-- expect: error fk
BEGIN;
UPDATE loans SET returned_at = now() WHERE id = 4;
INSERT INTO loans (copy_id, reader_id, due_at) VALUES (99999, 4, now() + interval '14 days');
COMMIT;

-- 3. Выдача 4 осталась как была: отменилась и первая операция, не только упавшая
-- expect: same 1
SELECT id, returned_at, fine FROM loans WHERE id = 4;

-- 4. Дальше работаем как app_reader
SET ROLE app_reader;

-- 5. app_reader читает представление: можно
SELECT count(*) AS cards FROM lib.v_loan_card;

-- 6. app_reader читает таблицу напрямую: нельзя
-- expect: error permission
SELECT * FROM loans LIMIT 1;

-- 7. app_reader меняет данные: нельзя
-- expect: error permission
BEGIN;
UPDATE loans SET fine = 0 WHERE id = 3;
ROLLBACK;

-- 8. app_reader вызывает бизнес-операцию: нельзя
-- expect: error permission
BEGIN;
SELECT lib.issue_book(1, 11);
ROLLBACK;

-- 9. Возвращаемся к суперпользователю
RESET ROLE;

-- 10. Дальше работаем как app_writer
SET ROLE app_writer;

-- 11. app_writer вставляет в таблицу напрямую: нельзя
-- expect: error permission
BEGIN;
INSERT INTO loans (copy_id, reader_id, due_at) VALUES (11, 1, now() + interval '14 days');
ROLLBACK;

-- 12. app_writer удаляет из таблицы напрямую: нельзя
-- expect: error permission
BEGIN;
DELETE FROM loans WHERE id = 1;
ROLLBACK;

-- 13. app_writer вызывает бизнес-операцию: можно (читатель 2, экземпляр 2, с откатом, чтобы данные не менялись)
BEGIN;
SELECT lib.issue_book(2, 2) AS new_loan_id;
ROLLBACK;

-- 14. Возвращаемся к суперпользователю
RESET ROLE;