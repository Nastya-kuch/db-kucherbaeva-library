-- Всё, что добавляет лаба 3, лежит в отдельной схеме lib: так в public остаются
CREATE SCHEMA lib;

-- Карточка выдачи: читатель, книга, экземпляр и статус одним запросом.
CREATE VIEW lib.v_loan_card AS
SELECT l.id AS loan_id,
        r.id AS reader_id,
        r.full_name AS reader,
        r.email,
        b.id AS book_id,
        b.title,
        c.inventory_number,
        l.loaned_at,
        l.due_at,
        l.returned_at,
        l.fine,
        CASE WHEN l.returned_at IS NOT NULL THEN 'возвращена'
            WHEN l.due_at < now()          THEN 'просрочена'
            ELSE 'на руках'
        END AS status
FROM loans l
JOIN readers r ON r.id = l.reader_id
JOIN copies  c ON c.id = l.copy_id
JOIN books   b ON b.id = c.book_id;

-- Нагрузка читателя: сколько книг на руках и сколько ещё можно взять (лимит 5).
CREATE VIEW lib.v_reader_load AS
SELECT r.id AS reader_id,
    r.full_name,
    count(l.id) AS active_loans,
    5 - count(l.id) AS slots_left
FROM readers r
LEFT JOIN loans l ON l.reader_id = r.id AND l.returned_at IS NULL
GROUP BY r.id, r.full_name;

-- Отчёт по книгам. Хранит результат, обновляется командой REFRESH MATERIALIZED VIEW.
CREATE MATERIALIZED VIEW lib.mv_book_report AS
SELECT b.id AS book_id,
        b.title,
        count(DISTINCT c.id) AS copies_total,
        count(l.id) AS loans_total,
        count(l.id) FILTER (WHERE l.returned_at IS NULL) AS on_hand
FROM books b
LEFT JOIN copies c ON c.book_id = b.id
LEFT JOIN loans  l ON l.copy_id = c.id
GROUP BY b.id, b.title;