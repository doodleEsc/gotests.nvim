-- Table driven tests based on its target source files' function and method signatures.
-- https://github.com/cweill/gotests

local ut = {}
local empty = require("gotests.utils").empty

ut.GO_NVIM_CFG = {
	test_template = "",
	test_template_dir = "",
	verbose = true,
}

local run = function(setup, extra)
  local j = vim.fn.jobstart(setup, {
    on_stdout = function(jobid, data, event)
      -- print("unit tests generate " .. vim.inspect(data))
    end,
    on_stderr = function(_, data, _)
      -- print("generate tests finished with message: " .. vim.inspect(setup) .. "error: " .. vim.inspect(data))
    end,
	on_exit = function(_, data, _)
		vim.cmd("edit " .. extra.test_gocwd .. "/" .. extra.test_gofile)
		if extra.test_funame ~= nil then
			vim.notify("`"..extra.test_funame.."`".." generated in "..extra.test_gofile)
			vim.fn.search(extra.test_funame)
		else
			vim.notify("All test function generated in "..extra.test_gofile)
		end
	end
  })
end

local get_test_gofile = function(gofile)
	if type(gofile) ~= "string" then
		vim.notify("Invalid File Type", "error")
		return
	end
	local sep = require("gotests.utils").sep()
	local results = require("gotests.utils").split(gofile, sep)
	local test_filename = results[#results]:gsub("%.", "_test.")
	return test_filename
end

local extra_info = function(gocwd, gofile, funame)
	local extra = {}
	local test_gofile = get_test_gofile(gofile)

	local test_func = nil
	if type(funame) == "string" and #funame ~= 0 then
		test_func = "Test" .. funame
	end

	extra.test_gocwd = gocwd
	extra.test_gofile = test_gofile
	extra.test_funame = test_func
	return extra
end

local add_test = function(args, extra)
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

  run(args, extra)
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
  local gofile = vim.fn.expand("%")
  local gocwd = vim.fn.expand("%:p:h")

  local extra = extra_info(gocwd, gofile, funame)
  local args = { "gotests", "-w", "-only", funame, gofile }

  if parallel then
    table.insert(args, "-parallel")
  end
  add_test(args, extra)
end

ut.all_test = function(parallel)
  parallel = parallel or false

  local gofile = vim.fn.expand("%")
  local gocwd = vim.fn.expand("%:p:h")

  local extra = extra_info(gocwd, gofile)
  local args = { "gotests", "-all", "-w", gofile }

  if parallel then
    table.insert(args, "-parallel")
  end
  add_test(args, extra)
end

ut.exported_test = function(parallel)
  parallel = parallel or false

  local gofile = vim.fn.expand("%")
  local gocwd = vim.fn.expand("%:p:h")

  local extra = extra_info(gocwd, gofile)
  local args = { "gotests", "-exported", "-w", gofile }

  if parallel then
    table.insert(args, "-parallel")
  end
  add_test(args, extra)
end

ut.setup = function(cfg)
	cfg = cfg or {}
	ut.GO_NVIM_CFG = vim.tbl_extend("force", ut.GO_NVIM_CFG, cfg)
end

return ut
