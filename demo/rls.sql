-- 1. Суперпользователь политик не замечает: видит все выдачи
-- expect: true
SELECT count(*) > 100 FROM loans;

-- 2. Дальше работаем как app_member (читатель в приложении)
SET ROLE app_member;

-- 3. Приложение ещё не сказало, какой это читатель: не видно ни одной выдачи
-- expect: value 0
SELECT count(*) FROM loans;

-- 4. Приложение сообщает: это читатель 1
SELECT set_config('app.reader_id', '1', false);

-- 5. Видны только выдачи читателя 1
-- expect: true
SELECT count(*) > 0 AND bool_and(reader_id = 1) FROM loans;

-- 6. Выдачи читателя 2 не видны, хотя запрос прямо о них
-- expect: value 0
SELECT count(*) FROM loans WHERE reader_id = 2;

-- 7. Теперь это читатель 2
SELECT set_config('app.reader_id', '2', false);

-- 8. Видны только выдачи читателя 2
-- expect: true
SELECT count(*) > 0 AND bool_and(reader_id = 2) FROM loans;

-- 9. Менять данные app_member не может: у роли только право чтения
-- expect: error permission
BEGIN;
UPDATE loans SET fine = 0 WHERE reader_id = 2;
ROLLBACK;

-- 10. Возвращаемся к суперпользователю и сбрасываем номер читателя
RESET ROLE;
RESET app.reader_id;

-- 11. Суперпользователь снова видит все выдачи
-- expect: true
SELECT count(*) > 100 FROM loans;