local M = {}

local registry = {}

local function open_to_register(cmd, id, term_opts)
  vim.cmd('enew')
  local jobid = vim.fn.termopen(cmd, term_opts)
  local bufnr = vim.fn.bufnr('')
  
  local ref_to_term = {
    jobid = jobid,
    bufnr = bufnr,
  }
  
  if ref_to_term.jobid < 0 then
    error('Failed to start terminal for ' .. cmd)
  end
  
  vim.opt_local.bufhidden = 'hide'
  
  -- Set up autocmd to unregister when buffer is deleted
  vim.api.nvim_create_autocmd('BufDelete', {
    buffer = ref_to_term.bufnr,
    callback = function()
      M.unregister(id)
    end,
    once = true,
  })
  
  return ref_to_term
end

function M.start(cmd, opts)
  opts = opts or {}
  local id = opts.id or cmd
  local kill = opts.kill == nil or opts.kill
  local term_opts = opts.terminal_options or vim.empty_dict()
  
  if kill
        and registry[id]
        and registry[id].bufnr
        and vim.fn.bufexists(registry[id].bufnr) == 1 then
      vim.cmd('bdelete! ' .. registry[id].bufnr)
  end
  
  local result = open_to_register(cmd, id, term_opts)
  registry[id] = result
  return registry[id]
end

function M.get_buf(id)
  return registry[id].bufnr
end

function M.switch(id)
  vim.cmd('buffer ' .. registry[id].bufnr)
end

function M.send(id, keys)
  vim.fn.chansend(registry[id].jobid, keys)
end

function M.sendl(id, keys)
  vim.fn.chansend(registry[id].jobid, keys .. "\n")
end

function M.has_started(id)
  return registry[id] ~= nil
end

function M.kill(id)
  if registry[id] then
    vim.fn.jobstop(registry[id].jobid)
    vim.cmd('bdelete! ' .. registry[id].bufnr)
    registry[id] = nil
  end
end

function M.unregister(id)
  if registry[id] then
    registry[id] = nil
  end
end

function M.get_recent_output_lines(id, n)
  local bufnr = registry[id].bufnr
  local bufinfo = vim.fn.getbufinfo(bufnr)[1]
  local endN = bufinfo.linecount
  
  while endN > 0 and vim.fn.getbufoneline(bufnr, endN) == '' do
    endN = endN - 1
  end
  
  local lines = vim.fn.getbufline(bufnr, math.max(1, endN - n + 1), endN)
  return table.concat(lines, "\n")
end

function M.list()
  local keys = {}
  for k in pairs(registry) do
    table.insert(keys, k)
  end
  return keys
end

function M.dump()
  print(vim.inspect(registry))
end

function M.__clear()
  registry = {}
end

return M
