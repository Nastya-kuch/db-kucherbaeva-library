-- Лаба 4 ★. REPEATABLE READ: вся транзакция видит данные на момент первого запроса.

-- [setup]
DELETE FROM readers WHERE email = 'iso@example.com';
INSERT INTO readers (full_name, email) VALUES ('v1', 'iso@example.com');

-- [A] Окно A начинает транзакцию с повышенной изоляцией
BEGIN ISOLATION LEVEL REPEATABLE READ;

-- [A] Первое чтение: здесь фиксируется снимок данных
-- expect: value v1
SELECT full_name FROM readers WHERE email = 'iso@example.com';

-- [B] Окно B меняет значение и сразу фиксирует
UPDATE readers SET full_name = 'v2' WHERE email = 'iso@example.com';

-- [A] Второе чтение: на REPEATABLE READ прежнее значение
-- expect: value v1
SELECT full_name FROM readers WHERE email = 'iso@example.com';

-- [A]
COMMIT;

-- [cleanup]
DELETE FROM readers WHERE email = 'iso@example.com';