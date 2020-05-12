% Minimal Lua binding to epoll
% Kim Alvefur
% 2016-08-08

This is a minimal binding to the Linux epoll API for the Lua language.

# API

Upon importing the module using `require`, an epoll handle is
automatically created. The module exposes two methods, `ctl` and `wait`,
which closely resemble their C counterparts.

It is recommended to read the manual pages for the underlying C
functions, `epoll_create1`, `epoll_ctl` and `epoll_wait`.

``` {.lua}
local epoll = require"epoll";
```

# `ctl(op, fd, flags)`

The `ctl` function is used to register interest in events and file
descriptors. It takes there arguments; which operation to perform, which
file descriptor to do this with and which events to watch for.

The first argument is a short string that determines the action, `"add"`
to add a descriptor, `"mod"` to modify it and `"del"` to delete.

The second argument is the FD number to watch.

The third argument determines which events to watch for, and is a string
that can contain `r` for readable and `w` for writable. This argument is
ignored when deleting.

Return values are `true` for success or `nil, err` for errors.

``` {.lua}
epoll.ctl("add", 0, "r"); -- we are interested in stdin being readable
epoll.ctl("add", 1, "w"); -- and stdout being writable
epoll.ctl("add", 4, "rw"); -- and FD 4 for both read- and writabel

epoll.ctl("mod", 4, "r"); -- we no longer care about writing to FD 4
epoll.ctl("mod", 4, "w"); -- and now we only want to write to it

epoll.ctl("del", 4); -- forget about FD 4
```

# `wait(timeout)`

Wait for an event for at most `timeout` seconds (can be fractional).

Returns an FD number and two booleans that signal if the FD is readable,
writeble or both. If the timeout is reached, `nil, "timeout"` is
returned. Other errors return `nil, err`.
