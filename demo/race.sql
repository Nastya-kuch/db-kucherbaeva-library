-- Лаба 4. Гонка без защиты. Правило: не больше 5 книг на руках у читателя.
-- Два окна одновременно выдают читателю с 4 книгами пятую и шестую: триггер не видит чужую
-- незафиксированную вставку, поэтому пропускает обе.

-- [setup] Читатель, у которого на руках 4 книги (копии 11-14)
DELETE FROM loans WHERE reader_id IN (SELECT id FROM readers WHERE email = 'race@example.com');
DELETE FROM readers WHERE email = 'race@example.com';
INSERT INTO readers (full_name, email) VALUES ('Гонка', 'race@example.com');
INSERT INTO loans (copy_id, reader_id, due_at)
SELECT c, (SELECT id FROM readers WHERE email = 'race@example.com'), now() + interval '14 days'
FROM unnest(ARRAY[11, 12, 13, 14]) AS c;

-- [A] Окно A: на руках 4, место есть, выдаём экземпляр 15
BEGIN;
INSERT INTO loans (copy_id, reader_id, due_at)
SELECT 15, id, now() + interval '14 days' FROM readers WHERE email = 'race@example.com';

-- [B] Окно B в тот же момент: триггер не видит выдачу окна A, тоже выдаёт, экземпляр 1
BEGIN;
INSERT INTO loans (copy_id, reader_id, due_at)
SELECT 1, id, now() + interval '14 days' FROM readers WHERE email = 'race@example.com';

-- [A]
COMMIT;

-- [B]
COMMIT;

-- [check] На руках не больше 5 книг?
-- expect: false
SELECT count(*) <= 5
FROM loans l JOIN readers r ON r.id = l.reader_id
WHERE r.email = 'race@example.com' AND l.returned_at IS NULL;

-- [cleanup]
DELETE FROM loans WHERE reader_id IN (SELECT id FROM readers WHERE email = 'race@example.com');
DELETE FROM readers WHERE email = 'race@example.com';