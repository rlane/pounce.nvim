local fzy = require('pounce_fzy_lua')
local vim = vim

local M = {}

function M.pounce()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local win_info = vim.fn.getwininfo(win)[1]
  local ns = vim.api.nvim_create_namespace("")

  local input = ""
  local bestpos = nil
  local offset = 0

  while true do
    vim.api.nvim_echo({ {'pounce> ', 'Keyword'}, {input} }, false, {})
    vim.cmd("redraw")
    local ok, nr = pcall(vim.fn.getchar)
    if not ok then
      break
    end

    if nr == 13 then  -- enter
      if bestpos then
        vim.cmd("normal! m'")
        vim.api.nvim_win_set_cursor(win, bestpos)
      end
      break
    elseif nr == 27 then  -- escape
      break
    elseif nr == "\x80kb" then  -- backspace
      input = input:sub(1, -2)
      offset = 0
    elseif nr == 10 then  -- <C-j>
      offset = offset + 1
    elseif nr == 11 then  -- <C-k>
      offset = offset - 1
    elseif nr < 32 or nr == 127 then
      -- ignore
    else
      local ch = vim.fn.nr2char(nr)
      input = input .. ch
      offset = 0
    end

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    if input ~= nil then
      local hits = {}
      for line=win_info.topline,win_info.botline do
        local text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]
        if fzy.has_match(input, text, false) then
          local indices, score = fzy.positions(input, text, false)
          if #indices > 0 then
            table.insert(hits, {line=line, indices=indices, score=score})
          end
        end
      end

      if #hits > 0 then
        local bestidx = nil
        for idx, hit in ipairs(hits) do
          if bestidx == nil or hit.score > hits[bestidx].score then
            bestidx = idx
          end
        end
        local selectedidx = 1 + (bestidx + offset - 1) % #hits

        for idx, hit in ipairs(hits) do
          local hit_highlight = "PounceUnselectedMatchHit"
          local miss_highlight = "PounceUnselectedMatchMiss"
          if idx == selectedidx then
            hit_highlight = "PounceSelectedMatchHit"
            miss_highlight = "PounceSelectedMatchMiss"
            bestpos = {hit.line, hit.indices[1] - 1}
          end

          vim.api.nvim_buf_add_highlight(buf, ns, miss_highlight, hit.line - 1, hit.indices[1] - 1, hit.indices[#hit.indices] - 1)
          for _, index in ipairs(hit.indices) do
            vim.api.nvim_buf_add_highlight(buf, ns, hit_highlight, hit.line - 1, index - 1, index)
          end
        end
      end
    end
  end

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.api.nvim_echo({}, false, {})
end

return M
