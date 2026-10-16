CREATE TABLE authors (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name text NOT NULL,
    birth_year integer CHECK (birth_year > 0)
);

CREATE TABLE books (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title text NOT NULL,
    published_year integer NOT NULL CHECK (published_year > 0),
    pages integer NOT NULL CHECK (pages > 0),
    isbn text NOT NULL UNIQUE
);

CREATE TABLE book_authors (
    book_id integer NOT NULL REFERENCES books (id) ON DELETE CASCADE,
    author_id integer NOT NULL REFERENCES authors (id) ON DELETE RESTRICT,
    PRIMARY KEY (book_id, author_id)
);

CREATE TABLE copies (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    book_id integer NOT NULL REFERENCES books (id) ON DELETE RESTRICT,
    inventory_number text NOT NULL UNIQUE,
    condition text NOT NULL DEFAULT 'good'
        CHECK (condition IN ('good', 'worn', 'damaged'))
);

CREATE TABLE readers (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name text NOT NULL,
    email text NOT NULL UNIQUE
);

CREATE TABLE loans (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    copy_id integer NOT NULL REFERENCES copies (id)  ON DELETE RESTRICT,
    reader_id integer NOT NULL REFERENCES readers (id) ON DELETE RESTRICT,
    loaned_at timestamptz NOT NULL DEFAULT now(),
    due_at timestamptz NOT NULL,
    returned_at timestamptz,
    fine numeric(10, 2) NOT NULL DEFAULT 0 CHECK (fine >= 0),
    CHECK (due_at > loaned_at),
    CHECK (returned_at IS NULL OR returned_at >= loaned_at)
);