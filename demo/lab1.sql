-- Лаба 1. Сценарий для показа. Формат описан в docs/scenarios.md.
-- Запуск: dbcheck run demo/lab1.sql, или в psql: \i /demo/lab1.sql

-- 1. Таблицы на месте: 6 таблиц
-- expect: rows 6
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY 1;

-- 2. Повтор email читателя: ошибка UNIQUE
-- expect: error unique
INSERT INTO readers (full_name, email) VALUES ('Двойник', 'ivan@example.com');

-- 3. Отрицательное число страниц: ошибка CHECK
-- expect: error check
INSERT INTO books (title, published_year, pages, isbn)
VALUES ('Тест', 2020, -5, '978-5-9999-0000-0');

-- 4. Выдача несуществующего экземпляра: ошибка внешнего ключа
-- expect: error fk
INSERT INTO loans (copy_id, reader_id, due_at)
VALUES (99999, 1, now() + interval '14 days');