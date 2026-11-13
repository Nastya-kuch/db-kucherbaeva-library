-- Триггер правила: не больше 5 книг на руках у одного читателя.
CREATE FUNCTION lib.check_reader_limit() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE v_active integer;
BEGIN
    IF NEW.returned_at IS NULL THEN
        SELECT count(*) INTO v_active
        FROM loans
        WHERE reader_id = NEW.reader_id
            AND returned_at IS NULL
            AND id IS DISTINCT FROM NEW.id;

        IF v_active >= 5 THEN
            RAISE EXCEPTION 'У читателя % уже % книг на руках (максимум 5)',
                NEW.reader_id, v_active;
        END IF;
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_check_reader_limit
BEFORE INSERT OR UPDATE OF reader_id, returned_at ON loans
FOR EACH ROW EXECUTE FUNCTION lib.check_reader_limit();

-- Журнал изменений выдач (служебная таблица).
CREATE TABLE lib.loans_audit (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    row_key    integer NOT NULL,
    op         text NOT NULL CHECK (op IN ('INSERT', 'UPDATE', 'DELETE')),
    old_row    jsonb,
    new_row    jsonb,
    changed_by text NOT NULL DEFAULT session_user,
    changed_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

-- Служебный триггер: пишет в журнал каждое изменение loans.
CREATE FUNCTION lib.log_loan_change() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO lib.loans_audit (row_key, op, old_row, new_row)
    VALUES (CASE WHEN TG_OP = 'DELETE' THEN OLD.id ELSE NEW.id END,
            TG_OP, CASE WHEN TG_OP <> 'INSERT' THEN to_jsonb(OLD) END, CASE WHEN TG_OP <> 'DELETE' THEN to_jsonb(NEW) END);
    RETURN NULL;
END $$;

CREATE TRIGGER trg_log_loan_change
AFTER INSERT OR UPDATE OR DELETE ON loans
FOR EACH ROW EXECUTE FUNCTION lib.log_loan_change();

-- Состояние выдачи на заданный момент: последняя запись журнала не позже этого момента.
CREATE FUNCTION lib.loan_state_at(p_loan_id integer, p_at timestamptz)
RETURNS jsonb
LANGUAGE sql STABLE AS $$
    SELECT CASE WHEN a.op = 'DELETE' THEN NULL ELSE a.new_row END
    FROM lib.loans_audit a
    WHERE a.row_key = p_loan_id AND a.changed_at <= p_at
    ORDER BY a.id DESC
    LIMIT 1;
$$;

-- Служебный триггер: время последнего изменения выдачи.
ALTER TABLE loans ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now();

CREATE FUNCTION lib.set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END $$;

CREATE TRIGGER trg_set_updated_at
BEFORE UPDATE ON loans
FOR EACH ROW EXECUTE FUNCTION lib.set_updated_at();