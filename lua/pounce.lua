local fzy = require "pounce_fzy_lua"
local log = require "log"
local vim = vim

local MAX_MATCHES_PER_LINE = 10

local M = {
  config = {
    accept_keys = "FJGHDKSLARVUMNYTBIECWXOPQZ",
    debug = false,
  }
}

function M.setup(config)
  for k, v in pairs(config) do
    M.config[k] = v
  end
end

-- Returns the most relevant non-overlapping matches on a line.
local function match(needle_, haystack_)
  local match_inner = nil
  local results = {}
  match_inner = function(needle, haystack, offset)
    if #results >= MAX_MATCHES_PER_LINE then
      return
    end

    if fzy.has_match(needle, haystack, false) then
      local indices, score = fzy.positions(needle, haystack, false)
      local left_haystack = string.sub(haystack, 1, indices[1] - 1)
      local right_haystack = string.sub(haystack, indices[#indices] + 1, -1)
      assert(left_haystack:len() < haystack:len())
      assert(right_haystack:len() < haystack:len())

      for i, v in ipairs(indices) do
        indices[i] = v + offset
        assert(indices[i] <= haystack_:len())
      end
      table.insert(results, { indices = indices, score = score })

      match_inner(needle, left_haystack, offset)
      return match_inner(needle, right_haystack, indices[#indices])
    end
  end

  match_inner(needle_, haystack_, 0)
  return results
end

function M.pounce()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local win_info = vim.fn.getwininfo(win)[1]
  local ns = vim.api.nvim_create_namespace ""

  local input = ""
  local accept_key_to_position = {}

  while true do
    vim.api.nvim_echo({ { "pounce> ", "Keyword" }, { input } }, false, {})
    vim.cmd "redraw"
    local ok, nr = pcall(vim.fn.getchar)
    if not ok then
      break
    end

    local start_clock = os.clock()

    if nr == 27 then -- escape
      break
    elseif nr == "\x80kb" then -- backspace
      input = input:sub(1, -2)
    elseif type(nr) == "number" and (nr < 32 or nr == 127) then
      -- ignore
    else
      local ch = vim.fn.nr2char(nr)
      local accepted = accept_key_to_position[ch]
      if accepted ~= nil then
        -- accept match
        vim.cmd "normal! m'"
        vim.api.nvim_win_set_cursor(win, accepted)
        break
      end
      input = input .. ch
    end

    accept_key_to_position = {}

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    if input ~= "" then
      local hits = {}
      local best_score = 0
      for line = win_info.topline, win_info.botline do
        local text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]
        local matches = match(input, text)
        for _, m in ipairs(matches) do
          table.insert(hits, { line = line, indices = m.indices, score = m.score })
          if M.config.debug then
            vim.api.nvim_buf_set_extmark(buf, ns, line - 1, -1, { virt_text = { { tostring(m.score), "IncSearch" } } })
          end
          best_score = math.max(best_score, m.score)
        end
      end

      local filtered_hits = {}
      for _, hit in ipairs(hits) do
        if hit.score > best_score / 2 then
          table.insert(filtered_hits, hit)
        end
      end

      table.sort(filtered_hits, function(a, b)
        return a.score > b.score
      end)

      for idx, hit in ipairs(filtered_hits) do
        vim.api.nvim_buf_add_highlight(
          buf,
          ns,
          "PounceGap",
          hit.line - 1,
          hit.indices[1] - 1,
          hit.indices[#hit.indices] - 1
        )
        for _, index in ipairs(hit.indices) do
          vim.api.nvim_buf_add_highlight(buf, ns, "PounceMatch", hit.line - 1, index - 1, index)
        end

        if idx <= M.config.accept_keys:len() then
          local accept_key = M.config.accept_keys:sub(idx, idx)
          accept_key_to_position[accept_key] = { hit.line, hit.indices[1] - 1 }
          vim.api.nvim_buf_set_extmark(
            buf,
            ns,
            hit.line - 1,
            hit.indices[1] - 1,
            { virt_text = { { accept_key, "PounceAccept" } }, virt_text_pos = "overlay" }
          )
        end
      end
    end

    local elapsed = os.clock() - start_clock
    log.debug("Matching took " .. elapsed * 1000 .. "ms")
  end

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.api.nvim_echo({}, false, {})
end

return M
