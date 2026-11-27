-- Лаба 4 ★. READ COMMITTED (уровень по умолчанию): второе чтение видит чужое изменение.

-- [setup]
DELETE FROM readers WHERE email = 'iso@example.com';
INSERT INTO readers (full_name, email) VALUES ('v1', 'iso@example.com');

-- [A] Окно A начинает транзакцию
BEGIN;

-- [A] Первое чтение
-- expect: value v1
SELECT full_name FROM readers WHERE email = 'iso@example.com';

-- [B] Окно B меняет значение и сразу фиксирует
UPDATE readers SET full_name = 'v2' WHERE email = 'iso@example.com';

-- [A] Второе чтение в той же транзакции: на READ COMMITTED видно новое
-- expect: value v2
SELECT full_name FROM readers WHERE email = 'iso@example.com';

-- [A]
COMMIT;

-- [cleanup]
DELETE FROM readers WHERE email = 'iso@example.com';