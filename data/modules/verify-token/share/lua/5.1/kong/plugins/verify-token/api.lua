local HTTP_RESPONSE = {
  SUCCESS = 204,
  BAD_REQUEST = 400,
  SERVER_ERROR = 500
}

return {
  ["/invalidate-token"] = {
    schema = kong.db.invalidated_tokens.schema,
    methods = {
      before = function(self, db, helpers)
        -- ensusre we are not missing any parameters
        if self.params.session_id == nil or self.params.exp == nil or self.params.iat == nil then
          -- return 400 if any parameters are missing
          return kong.response.exit(HTTP_RESPONSE.BAD_REQUEST, {message = "Invalid request"})
        end
      end,
      -- By convention, we refer to the request object as 'self'
      POST = function(self, db, helpers)
        -- Ensure that the token was not previously added
        local is_blacklisted, err = db.invalidated_tokens:select({session_id = self.params.session_id})

        if err ~= nil then
          ngx.log(ngx.WARN, 'Error on invalidated token lookup')
          return kong.response.exit(HTTP_RESPONSE.SERVER_ERROR, {message = "Error occured when invalidating user token"})
        end

        if is_blacklisted ~= nil then
          return kong.response.exit(HTTP_RESPONSE.BAD_REQUEST, {message = "session was already invalidated"})
        end

        -- Add jwt to invalid token database
        local inserted_token, err = db.invalidated_tokens:insert({

          -- identifier that is unique for every session
          session_id = self.params.session_id,

          -- expiry is used to purge the database later on for expired tokens
          exp = self.params.exp,

          -- issued at field which can also be used to purge the database
          iat = self.params.iat
        })

        if err ~= nil then
          ngx.log(ngx.WARN, err)
          -- TODO: add proper error handling when database call fails
          ngx.log(ngx.WARN, 'Error inserting invalidated token')
          return kong.response.exit(HTTP_RESPONSE.SERVER_ERROR, {message = "Error occured when invalidating user token"})
        end

        -- success - return 204
        return kong.response.exit(HTTP_RESPONSE.SUCCESS)
      end
    }
  }
}
