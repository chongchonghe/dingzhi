-- vifm-zoxide: frecency-based directory jumping
--
-- Automatically adds every visited directory to zoxide, and provides:
--   :z <keywords>  — jump to the best frecent match
--   :za            — manually register current directory
--
-- Keymap (set in vifmrc): ,z → :z<space>

do
  local function shell_escape(s)
      return "'" .. s:gsub("'", "'\\''") .. "'"
  end

  local function zoxide_add(path)
      vifm.startjob({ cmd = 'zoxide add ' .. shell_escape(path) })
  end

  local function zoxide_query(args, exclude)
      local escaped = {}
      for _, a in ipairs(args) do
          table.insert(escaped, shell_escape(a))
      end
      local cmd = 'zoxide query --exclude ' .. shell_escape(exclude)
          .. ' -- ' .. table.concat(escaped, ' ')
          .. ' 2>/dev/null'
      local handle = io.popen(cmd)
      if not handle then return nil end
      local line = handle:read('*l')
      handle:close()
      return line
  end

  -- :z <keywords> — cd to best zoxide match
  assert(vifm.cmds.add({
      name        = 'z',
      description = 'Jump to a frecent directory via zoxide',
      minargs     = 1,
      maxargs     = 10,
      handler     = function(info)
          local curview = vifm.currview()
          local path = zoxide_query(info.argv, curview.cwd)
          if path and path ~= '' then
              curview:cd(path)
          else
              vifm.sb.error('zoxide: no match for "' .. info.args .. '"')
          end
      end,
  }))

  -- :za — manually add current directory
  assert(vifm.cmds.add({
      name        = 'za',
      description = 'Add current directory to zoxide database',
      minargs     = 0,
      maxargs     = 0,
      handler     = function(info)
          local curview = vifm.currview()
          zoxide_add(curview.cwd)
          print('zoxide: added ' .. curview.cwd)
      end,
  }))
end

return {}
