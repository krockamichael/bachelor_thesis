return {
  postgres = {
    up = [[
      CREATE TABLE IF NOT EXISTS invalidated_tokens(
        session_id text,
        created_at timestamp without time zone default (CURRENT_TIMESTAMP(0) at time zone 'utc'),
        iat INTEGER,
        exp INTEGER,
        PRIMARY KEY(session_id)
      );
      DO $$
        BEGIN
        IF (SELECT to_regclass('invalidated_session_idx')) IS NULL THEN
          CREATE INDEX invalidated_session_idx ON invalidated_tokens(session_id);
        END IF;
      END$$;
    ]]
  },
  cassandra = {
    up = [[]]
  }
}
