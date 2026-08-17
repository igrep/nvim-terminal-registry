local args = { unpack(_G.arg, 1) }
--[[
This script generates the argument for the `--report-expr` option of the `nvim` command to call and print the result of the corresponding function in the autoload/terminal_registry.vim
--]]

local call
if args[1] == "start" then
  local cmd = args[2]
  if not cmd then
    error("Missing command (first argument) for 'start'")
  end
  local opts = vim.json.decode(args[3] or "{}")
  call = 'start(' .. vim.inspect(cmd) .. ', ' .. vim.inspect(opts) .. ')'
elseif args[1] == "list" then
  call = 'list()'
elseif args[1] == "get_buf" then
  local id = args[2]
  if not id then
    error("Missing id (first argument) for 'get_buf'")
  end
  call = 'get_buf(' .. vim.inspect(id) .. ')'
elseif args[1] == "get_recent_output_lines" then
  local id = args[2]
  if not id then
    error("Missing id (first argument) for 'get_recent_output_lines'")
  end
  if not args[3] then
    error("Missing or invalid n (second argument) for 'get_recent_output_lines'")
  end
  local n = tonumber(args[3])
  call = 'get_recent_output_lines(' .. vim.inspect(id) .. ', ' .. n .. ')'
elseif args[1] == "send" then
  local id = args[2]
  local keys = args[3]
  if not id or not keys then
    error("Missing id (first argument) or keys (second argument) for 'send'")
  end
  call = 'send(' .. vim.inspect(id) .. ', ' .. vim.inspect(keys) .. ')'
elseif args[1] == "sendl" then
  local id = args[2]
  local keys = args[3]
  if not id or not keys then
    error("Missing id (first argument) or keys (second argument) for 'sendl'")
  end
  call = 'sendl(' .. vim.inspect(id) .. ', ' .. vim.inspect(keys) .. ')'
elseif args[1] == "kill" then
  local id = args[2]
  if not id then
    error("Missing id (first argument) for 'kill'")
  end
  call = 'kill(' .. vim.inspect(id) .. ')'
else
  error("Unsupported subcommand: " .. vim.inspect(args[1]))
end

local exp = 'require("terminal_registry").' .. call
print("luaeval(" .. vim.inspect(exp) .. ")")
