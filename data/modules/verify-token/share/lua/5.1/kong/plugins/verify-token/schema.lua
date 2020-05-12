return {
  no_consumer = false,
  fields = {
    -- describe the plugin's configuration here
  },
  self_check = function(schema, plugin_t, dao, is_updating)
    -- perform any custom verification
    return true
  end
}
