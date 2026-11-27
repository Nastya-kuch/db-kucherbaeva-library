-- Лаба 4 ★. Взаимоблокировка: два окна блокируют две строки в разном порядке.

-- [setup]
DELETE FROM readers WHERE email IN ('dl1@example.com', 'dl2@example.com');
INSERT INTO readers (full_name, email) VALUES ('dl1', 'dl1@example.com'), ('dl2', 'dl2@example.com');

-- [A] Окно A блокирует читателя dl1
BEGIN;
UPDATE readers SET full_name = 'a1' WHERE email = 'dl1@example.com';

-- [B] Окно B блокирует читателя dl2
BEGIN;
UPDATE readers SET full_name = 'b2' WHERE email = 'dl2@example.com';

-- [A] A хочет dl2, она у B: ждёт
-- expect: blocked
UPDATE readers SET full_name = 'a2' WHERE email = 'dl2@example.com';

-- [B] B хочет dl1, она у A: получился круг ожидания, база отменяет одну транзакцию
-- expect: error deadlock
UPDATE readers SET full_name = 'b1' WHERE email = 'dl1@example.com';

-- [B] Сначала B откатывает свою отменённую транзакцию: это снимает его блокировки
ROLLBACK;

-- [A] Теперь ожидавший UPDATE окна A выполнился, откатываем и его
ROLLBACK;

-- [cleanup]
DELETE FROM readers WHERE email IN ('dl1@example.com', 'dl2@example.com');