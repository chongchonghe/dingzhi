local function is_macos()
  if jit and jit.os then
    return jit.os == "OSX"
  end

  local uname = io.popen("uname -s")
  if uname then
    local ok, result = pcall(function()
      return uname:read("*l")
    end)
    uname:close()

    if ok and result then
      return result == "Darwin"
    end
  end

  return false
end

require("git"):setup()

require("githead"):setup({
    branch_prefix = "on",
    branch_symbol = " ",
    branch_borders = "()",
    hovered_status_clean = "=",
    hovered_untracked_symbol = "+",
})
