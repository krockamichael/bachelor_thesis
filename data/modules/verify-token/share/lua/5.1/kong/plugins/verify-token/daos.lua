local typedefs = require "kong.db.schema.typedefs"

return {
  invalidated_tokens = {
    name                  = "invalidated_tokens", -- the actual table in the database
    endpoint_key          = "session_id",
    primary_key           = { "session_id" },
    generate_admin_api    = false,
    fields = {
      {
        created_at = typedefs.auto_timestamp_s
      },
      {
        iat = {type = "number", immutable = true}
      },
      {
        exp = {type = "number", immutable = true}
      },
      {
        session_id = {type = "string", required = true, immutable = true}
      }
    }
  }
}

