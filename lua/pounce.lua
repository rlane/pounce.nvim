local fzy = require "pounce_fzy_lua"
local log = require "log"
local vim = vim

local MAX_MATCHES_PER_LINE = 10
local CURRENT_LINE_BONUS = 1
local CURRENT_WINDOW_BONUS = 0.5

local M = {
  config = {
    accept_keys = "JFKDLSAHGNUVRBYTMICEOXWPQZ",
    multi_window = true,
    debug = false,
  },
}

local last_input = ""

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

function M.pounce(opts)
  local windows = not string.find(vim.api.nvim_get_mode().mode, "o") and M.config.multi_window and vim.api.nvim_tabpage_list_wins(0) or { vim.api.nvim_get_current_win() }
  local ns = vim.api.nvim_create_namespace ""
  local input = opts.do_repeat and last_input or ""

  while true do
    local start_clock = os.clock()

    local accept_key_map = {}

    for _, win in ipairs(windows) do
      vim.api.nvim_buf_clear_namespace(vim.api.nvim_win_get_buf(win), ns, 0, -1)
    end

    if input ~= "" then
      local hits = {}
      local best_score = 0
      local current_win = vim.api.nvim_get_current_win()

      -- Find and score all matches in visible buffer regions.
      for _, win in ipairs(windows) do
        local buf = vim.api.nvim_win_get_buf(win)
        local win_info = vim.fn.getwininfo(win)[1]
        local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
        for line = win_info.topline, win_info.botline do
          local text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]
          local matches = match(input, text)
          for _, m in ipairs(matches) do
            local score = m.score
            if win == current_win then
              score = score + CURRENT_WINDOW_BONUS
              if line == cursor_line then
                score = score + CURRENT_LINE_BONUS
              end
            end
            table.insert(hits, { window = win, line = line, indices = m.indices, score = score })
            if M.config.debug then
              vim.api.nvim_buf_set_extmark(buf, ns, line - 1, -1, { virt_text = { { tostring(score), "IncSearch" } } })
            end
            best_score = math.max(best_score, score)
          end
        end
      end

      -- Discard relatively low-scoring matches.
      local filtered_hits = {}
      for _, hit in ipairs(hits) do
        if hit.score > best_score / 2 then
          table.insert(filtered_hits, hit)
        end
      end

      table.sort(filtered_hits, function(a, b)
        return a.score > b.score
      end)

      -- Highlight and assign accept keys to matches.
      local seen = {}
      for idx, hit in ipairs(filtered_hits) do
        local buf = vim.api.nvim_win_get_buf(hit.window)
        -- Avoid duplication when the same buffer is visible in multiple windows.
        local seen_key = string.format("%d.%d.%d", buf, hit.line, hit.indices[1])
        if seen[seen_key] == nil then
          seen[seen_key] = true
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
            accept_key_map[accept_key] = { window = hit.window, position = { hit.line, hit.indices[1] - 1 } }
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
    end

    local elapsed = os.clock() - start_clock
    log.debug("Matching took " .. elapsed * 1000 .. "ms")

    vim.api.nvim_echo({ { "pounce> ", "Keyword" }, { input } }, false, {})
    vim.cmd "redraw"

    local ok, nr = pcall(vim.fn.getchar)
    if not ok then
      break
    end

    if nr == 27 then -- escape
      break
    elseif nr == "\x80kb" then -- backspace
      input = input:sub(1, -2)
    elseif type(nr) == "number" and (nr < 32 or nr == 127) then
      -- ignore
    else
      local ch = vim.fn.nr2char(nr)
      local accepted = accept_key_map[ch]
      if accepted ~= nil then
        -- accept match
        vim.cmd "normal! m'"
        vim.api.nvim_win_set_cursor(accepted.window, accepted.position)
        vim.api.nvim_set_current_win(accepted.window)
        break
      end
      input = input .. ch
    end
    last_input = input
  end

  for _, win in ipairs(windows) do
    vim.api.nvim_buf_clear_namespace(vim.api.nvim_win_get_buf(win), ns, 0, -1)
  end
  vim.api.nvim_echo({}, false, {})
end

return M
