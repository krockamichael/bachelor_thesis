return {
  {
    name = "2018-11-29-2108400_init_abstore",
    up = [[
      CREATE TABLE IF NOT EXISTS abjwtstore(
        id text,
        key text UNIQUE,
        PRIMARY KEY (id)
      );

      CREATE TABLE IF NOT EXISTS abinstanceidstore(
        instance_id text,
        key text UNIQUE,
        PRIMARY KEY (instance_id)
      );
    ]],

    down = [[
      DROP TABLE abjwtstore;
      DROP TABLE abinstanceidstore;
    ]]
  }
}
