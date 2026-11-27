-- Лаба 4. Та же гонка, но выдача идёт через исправленную операцию lib.issue_book:
-- она блокирует строку читателя (FOR UPDATE), и второе окно ждёт первое.

-- [setup] Читатель, у которого на руках 4 книги (копии 11-14)
DELETE FROM loans WHERE reader_id IN (SELECT id FROM readers WHERE email = 'race@example.com');
DELETE FROM readers WHERE email = 'race@example.com';
INSERT INTO readers (full_name, email) VALUES ('Гонка', 'race@example.com');
INSERT INTO loans (copy_id, reader_id, due_at)
SELECT c, (SELECT id FROM readers WHERE email = 'race@example.com'), now() + interval '14 days'
FROM unnest(ARRAY[11, 12, 13, 14]) AS c;

-- [A] Окно A: выдаём пятую книгу, строка читателя заблокирована до конца транзакции
BEGIN;
SELECT lib.issue_book((SELECT id FROM readers WHERE email = 'race@example.com'), 15);

-- [B] Окно B в тот же момент: упирается в блокировку и ждёт
-- expect: blocked
BEGIN;
SELECT lib.issue_book((SELECT id FROM readers WHERE email = 'race@example.com'), 1);

-- [A]
COMMIT;

-- [B] После COMMIT окна A окно B продолжило, триггер увидел пятую книгу и отказал
COMMIT;

-- [check] На руках не больше 5 книг?
-- expect: true
SELECT count(*) <= 5
FROM loans l JOIN readers r ON r.id = l.reader_id
WHERE r.email = 'race@example.com' AND l.returned_at IS NULL;

-- [cleanup]
DELETE FROM loans WHERE reader_id IN (SELECT id FROM readers WHERE email = 'race@example.com');
DELETE FROM readers WHERE email = 'race@example.com';