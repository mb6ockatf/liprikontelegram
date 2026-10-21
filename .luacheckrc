-- .luacheckrc - luacheck settings for main.lua.
--
-- Copyright (C) 2026 mb6ockatf
-- This file is free software; see COPYING for copying conditions.
--
-- The Docker image runs Lua 5.4.  Unused locals (211) and locals that
-- shadow an argument (412) are tolerated: main.lua has several of each.

std = "lua54"
ignore = {"211", "412"}
