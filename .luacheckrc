std = "luajit"
max_line_length = 120
globals = { "love" }
self = false -- methods keep the same signature even when they don't use self
exclude_files = { ".luarocks", "lovejs/**", "build/**" }
