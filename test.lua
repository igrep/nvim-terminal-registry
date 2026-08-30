-- Set a wide enough terminal width to avoid line wrapping in the output of commands
vim.o.columns = 150

local tr = require("terminal_registry")

tr.start("PS1=test-runner: bash --norc --noprofile", { id = "test-runner" })
tr.sendl("test-runner", "./bin/cli start 'PS1=bash-1: bash --norc --noprofile' '{ \"id\": \"bash-1\" }'")
tr.sendl("test-runner", "./bin/cli start 'PS1=bash-2: bash --norc --noprofile' '{ \"id\": \"bash-2\", \"terminal_options\": { \"cwd\": \"/\" } }'")

vim.wait(
  1000,
  function()
    local list = tr.list()
    return list["bash-1"] and list["bash-2"]
  end
)
tr.sendl("test-runner", "./bin/cli list")

tr.sendl("test-runner", "./bin/cli sendl 'bash-1' 'echo hello'")
tr.sendl("test-runner", "./bin/cli sendl 'bash-2' 'pwd'")

local function wait_for_output(id, expected_lines_count, extra_lines_count)
  return vim.wait(
    1000,
    function()
      local lines = tr.get_recent_output_lines(
        id,
        -- get_recent_output_lines should accept line count greater than the
        -- actual number of lines in the buffer.
        expected_lines_count + extra_lines_count
      )
      return #lines >= expected_lines_count, lines
    end
  )
end

local _, result1 = wait_for_output("bash-1", 3, 0)
vim.fn.assert_equal(result1[1], "bash-1:echo hello")
vim.fn.assert_equal(result1[2], "hello")
vim.fn.assert_equal(result1[3], "bash-1:")

local _, result2 = wait_for_output("bash-2", 3, 1)
vim.fn.assert_equal(result2[1], "bash-2:pwd")
vim.fn.assert_equal(result2[2], "/")
vim.fn.assert_equal(result2[3], "bash-2:")

tr.sendl("test-runner", "./bin/cli get_recent_output_lines 'bash-1' 2")

-- expected_lines_count can vary depending on the command executed
local _, result_all = wait_for_output("test-runner", 17, 0)
vim.fn.assert_equal(result_all[1], "./bin/cli start 'PS1=bash-1: bash --norc --noprofile' '{ \"id\": \"bash-1\" }'")
vim.fn.assert_equal(result_all[2], "./bin/cli start 'PS1=bash-2: bash --norc --noprofile' '{ \"id\": \"bash-2\", \"terminal_options\": { \"cwd\": \"/\" } }'")
vim.fn.assert_equal(result_all[3], "test-runner:./bin/cli start 'PS1=bash-1: bash --norc --noprofile' '{ \"id\": \"bash-1\" }'")
vim.fn.assert_equal(result_all[4], "test-runner:./bin/cli start 'PS1=bash-2: bash --norc --noprofile' '{ \"id\": \"bash-2\", \"terminal_options\": { \"cwd\": \"/\" } }'")
vim.fn.assert_equal(result_all[5], "./bin/cli list")
vim.fn.assert_equal(result_all[6], "./bin/cli sendl 'bash-1' 'echo hello'")
vim.fn.assert_equal(result_all[7], "./bin/cli sendl 'bash-2' 'pwd'")
vim.fn.assert_equal(result_all[8], "test-runner:./bin/cli list")
vim.fn.assert_equal(result_all[9], "{")
vim.fn.assert_equal(result_all[10], '  ["bash-1"] = "PS1=bash-1: bash --norc --noprofile",')
vim.fn.assert_equal(result_all[11], '  ["bash-2"] = "PS1=bash-2: bash --norc --noprofile",')
vim.fn.assert_equal(result_all[12], '  ["test-runner"] = "PS1=test-runner: bash --norc --noprofile"')
vim.fn.assert_equal(result_all[13], "}test-runner:./bin/cli sendl 'bash-1' 'echo hello'")
vim.fn.assert_equal(result_all[14], "test-runner:./bin/cli sendl 'bash-2' 'pwd'")
vim.fn.assert_equal(result_all[15], "test-runner:./bin/cli get_recent_output_lines 'bash-1' 2")
vim.fn.assert_equal(result_all[16], "hello")
vim.fn.assert_equal(result_all[17], "bash-1:test-runner:")

if #vim.v.errors > 0 then
  print("Errors:\n")
  for _, err in ipairs(vim.v.errors) do
    print("  " .. err .. "\n")
  end
  os.exit(1)
end
print("All tests passed.\n")
os.exit(0)
