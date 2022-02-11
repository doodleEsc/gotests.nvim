-- Table driven tests based on its target source files' function and method signatures.
-- https://github.com/cweill/gotests

local ut = {}
local empty = require("gotests.utils").empty

ut.GO_NVIM_CFG = {
	test_template = "",
	test_template_dir = "",
	verbose = true,

}

local run = function(setup)
  local j = vim.fn.jobstart(setup, {
    on_stdout = function(jobid, data, event)
      print("unit tests generate " .. vim.inspect(data))
    end,
    on_stderr = function(_, data, _)
      print("generate tests finished with message: " .. vim.inspect(setup) .. "error: " .. vim.inspect(data))
    end,
	on_exit = function(_, data, _)
		print(vim.inspect(setup))
	end
  })
end

local add_test = function(args)
  require("gotests.install").install("gotests")

  local test_template = ut.GO_NVIM_CFG.test_template or ""
  local test_template_dir = ut.GO_NVIM_CFG.test_template_dir or ""

  if string.len(test_template) > 1 then
    table.insert(args, "-template")
    table.insert(args, test_template)
    if string.len(test_template_dir) > 1 then
      table.insert(args, "-template_dir")
      table.insert(args, test_template_dir)
    end
  end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row, col = row + 1, col + 1
  local ns = require("gotests.ts.go").get_func_method_node_at_pos(row, col)
  if empty(ns) then
    return
  end

  run(args)
end

ut.fun_test = function(parallel)
  parallel = parallel or false
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row, col = row + 1, col + 1
  local ns = require("gotests.ts.go").get_func_method_node_at_pos(row, col)
  if empty(ns) then
    return
  end

  local funame = ns.name
  -- local rs, re = ns.dim.s.r, ns.dim.e.r
  local gofile = vim.fn.expand("%")
  local args = { "gotests", "-w", "-only", funame, gofile }
  if parallel then
    table.insert(args, "-parallel")
  end
  add_test(args)
end

ut.all_test = function(parallel)
  parallel = parallel or false
  local gofile = vim.fn.expand("%")
  local args = { "gotests", "-all", "-w", gofile }
  if parallel then
    table.insert(args, "-parallel")
  end
  add_test(args)
end

ut.exported_test = function(parallel)
  parallel = parallel or false
  local gofile = vim.fn.expand("%")
  local args = { "gotests", "-exported", "-w", gofile }
  if parallel then
    table.insert(args, "-parallel")
  end
  add_test(args)
end

return ut
