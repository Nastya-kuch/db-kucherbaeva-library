-- Лаба 3. Функции.

-- Сколько книг сейчас на руках у читателя.
CREATE FUNCTION lib.reader_active_loans(p_reader_id integer)
RETURNS integer
LANGUAGE sql STABLE AS $$
    SELECT count(*)::integer
    FROM loans
    WHERE reader_id = p_reader_id AND returned_at IS NULL;
$$;

-- Сколько свободных экземпляров у книги.
CREATE FUNCTION lib.book_free_copies(p_book_id integer)
RETURNS integer
LANGUAGE sql STABLE AS $$
    SELECT count(*)::integer
    FROM copies c
    WHERE c.book_id = p_book_id
    AND NOT EXISTS (SELECT 1 FROM loans l
                    WHERE l.copy_id = c.id AND l.returned_at IS NULL);
$$;

-- Лимит в 5 книг проверяет триггер trg_check_reader_limit.
CREATE FUNCTION lib.issue_book(p_reader_id integer, p_copy_id integer, p_days integer DEFAULT 14)
RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE
    v_id integer;
BEGIN
    IF p_days <= 0 THEN
        RAISE EXCEPTION 'Срок выдачи должен быть положительным: % дн.', p_days;
    END IF;
    IF EXISTS (SELECT 1 FROM loans WHERE copy_id = p_copy_id AND returned_at IS NULL) THEN
        RAISE EXCEPTION 'Экземпляр % уже выдан', p_copy_id;
    END IF;

    INSERT INTO loans (copy_id, reader_id, due_at)
    VALUES (p_copy_id, p_reader_id, now() + make_interval(days => p_days))
    RETURNING id INTO v_id;

    RETURN v_id;
END $$;

-- Бизнес-операция: принять книгу. Считает штраф 5 за каждый день просрочки и возвращает его.
CREATE FUNCTION lib.return_book(p_loan_id integer)
RETURNS numeric
LANGUAGE plpgsql AS $$
DECLARE
    v_due      timestamptz;
    v_returned timestamptz;
    v_fine     numeric(10, 2);
BEGIN
    SELECT due_at, returned_at INTO v_due, v_returned
    FROM loans WHERE id = p_loan_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Выдача % не найдена', p_loan_id;
    END IF;
    IF v_returned IS NOT NULL THEN
        RAISE EXCEPTION 'Выдача % уже закрыта', p_loan_id;
    END IF;

    v_fine := CASE WHEN now() > v_due
                    THEN 5 * ceil(extract(epoch FROM now() - v_due) / 86400)
                    ELSE 0 END;

    UPDATE loans SET returned_at = now(), fine = v_fine WHERE id = p_loan_id;
    RETURN v_fine;
END $$;

-- Поиск выдач с необязательными фильтрами: любой параметр можно не передавать.
CREATE FUNCTION lib.search_loans(
    p_reader_id   integer DEFAULT NULL,
    p_book_id     integer DEFAULT NULL,
    p_only_active boolean DEFAULT NULL
)
RETURNS TABLE (loan_id integer, reader text, title text,
            loaned_at timestamptz, due_at timestamptz, returned_at timestamptz)
LANGUAGE sql STABLE AS $$
    SELECT v.loan_id, v.reader, v.title, v.loaned_at, v.due_at, v.returned_at
    FROM lib.v_loan_card v
    WHERE (p_reader_id IS NULL OR v.reader_id = p_reader_id) AND (p_book_id   IS NULL OR v.book_id   = p_book_id) AND (p_only_active IS NULL OR (v.returned_at IS NULL) = p_only_active)
    ORDER BY v.loaned_at DESC;
$$;