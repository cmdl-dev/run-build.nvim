local M = {}

M.build_command = ""
local config_dir = vim.fn.getcwd() .. "/.run_build"
local config_file = config_dir .. "/command.txt"

function M.load_command()
  if vim.fn.filereadable(config_file) == 1 then
    local lines = vim.fn.readfile(config_file)
    if #lines > 0 then
      M.build_command = lines[1]
    end
  end
end

function M.save_command(cmd)
  if vim.fn.isdirectory(config_dir) == 0 then
    vim.fn.mkdir(config_dir, "p")
  end
  vim.fn.writefile({ cmd }, config_file)
  M.build_command = cmd
end

function M.set_command()
  vim.ui.input({ prompt = "Build Command: ", default = M.build_command }, function(input)
    if input and input ~= "" then
      M.save_command(input)
      print("Build command set to: " .. input)
    end
  end)
end

function M.run_silent()
  if M.build_command == "" then
    print("No build command set. Use :RunBuildSelect first.")
    return
  end

  print("Running: " .. M.build_command .. " (Silent)")
  local output = {}
  
  vim.fn.jobstart(M.build_command, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          local clean_line = line:gsub("\r", "")
          if clean_line ~= "" then table.insert(output, clean_line) end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          local clean_line = line:gsub("\r", "")
          if clean_line ~= "" then table.insert(output, clean_line) end
        end
      end
    end,
    on_exit = function(_, exit_code)
      local items = {}
      local i = 1
      while i <= #output do
        local line = output[i]
        local file, lnum, col, msg = line:match("^(.-)%((%d+):(%d+)%)%s+(.*)$")
        
        if file and lnum and col then
          table.insert(items, {
            filename = file,
            lnum = tonumber(lnum),
            col = tonumber(col),
            text = msg,
            valid = 1,
          })
          
          local j = i + 1
          while j <= #output do
            local next_line = output[j]
            if next_line:find("^\t") then
              table.insert(items, {
                text = next_line,
                valid = 0,
              })
              j = j + 1
            else
              break
            end
          end
          i = j
        else
          i = i + 1
        end
      end

      if #items > 0 then
        vim.fn.setqflist({}, "r", { 
          title = M.build_command, 
          items = items,
        })
        if exit_code ~= 0 then
          vim.cmd("copen")
          print("Build failed. Quickfix list updated.")
        else
          print("Build finished successfully.")
        end
      else
        vim.fn.setqflist({}, "r", { title = M.build_command, items = {} })
        vim.cmd("cclose")
        print("Build finished with exit code " .. exit_code .. ". Quickfix cleared.")
      end
    end,
  })
end

function M.add_to_qf()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local items = {}
  local i = 1
  while i <= #lines do
    local line = lines[i]
    local file, lnum, col, msg = line:match("^(.-)%((%d+):(%d+)%)%s+(.*)$")
    
    if file and lnum and col then
      table.insert(items, {
        filename = file,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = msg,
        valid = 1,
      })
      
      local j = i + 1
      while j <= #lines do
        local next_line = lines[j]
        if next_line:find("^\t") then
          table.insert(items, {
            text = next_line,
            valid = 0,
          })
          j = j + 1
        else
          break
        end
      end
      i = j
    else
      i = i + 1
    end
  end

  if #items > 0 then
    vim.fn.setqflist({}, "r", { 
      title = "Buffer Errors", 
      items = items,
    })
    vim.cmd("copen")
    print("Quickfix list updated with errors from buffer.")
  else
    vim.fn.setqflist({}, "r", { title = "Buffer Errors", items = {} })
    vim.cmd("cclose")
    print("No errors found in buffer. Quickfix cleared.")
  end
end

function M.run_buffer()
  if M.build_command == "" then
    print("No build command set. Use :RunBuildSelect first.")
    return
  end

  local old_buf = vim.fn.bufnr("*Build Output*")
  if old_buf ~= -1 then
    vim.api.nvim_buf_delete(old_buf, { force = true })
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "*Build Output*")
  vim.api.nvim_set_option_value("filetype", "bash", { buf = buf })

  vim.keymap.set("n", "<Leader>aq", M.add_to_qf, { buffer = buf, desc = "Add buffer errors to quickfix" })
  vim.keymap.set("n", "<Esc>", "<cmd>q<cr>", { buffer = buf, desc = "Close build output" })

  local win = vim.api.nvim_get_current_win()
  vim.cmd("vsplit")
  vim.api.nvim_set_current_buf(buf)

  print("Running: " .. M.build_command .. " (Buffer)")

  vim.fn.jobstart(M.build_command, {
    on_stdout = function(_, data)
      if data then
        local clean_data = {}
        for _, line in ipairs(data) do
          table.insert(clean_data, (line:gsub("\r", "")))
        end
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, clean_data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        local clean_data = {}
        for _, line in ipairs(data) do
          table.insert(clean_data, (line:gsub("\r", "")))
        end
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, clean_data)
      end
    end,
    on_exit = function(_, exit_code)
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "", "Finished with exit code " .. exit_code })
    end,
  })
end

function M.setup(opts)
  -- Merge opts if needed in the future
  
  vim.api.nvim_create_user_command("RunBuildSelect", function()
    M.set_command()
  end, { desc = "Select build command" })

  vim.api.nvim_create_user_command("RunBuildSilent", function()
    M.run_silent()
  end, { desc = "Run build command in silent mode" })

  vim.api.nvim_create_user_command("RunBuildBuffer", function()
    M.run_buffer()
  end, { desc = "Run build command and show in buffer" })
  
  M.load_command()
end

return M
