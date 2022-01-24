local matcher = require "pounce.matcher"
local log = require "pounce.log"
local vim = vim

local CURRENT_LINE_BONUS = 1
local CURRENT_WINDOW_BONUS = 0.5

local M = {}

local config = {
  accept_keys = "JFKDLSAHGNUVRBYTMICEOXWPQZ",
  accept_best_key = "<enter>",
  multi_window = true,
  debug = false,
}

local last_input = ""

local function getconfig(key, opts)
  if opts and opts[key] ~= nil then
    return opts[key]
  else
    return config[key]
  end
end

function M.setup(opts)
  for k, v in pairs(opts) do
    config[k] = v
  end
end

function M.pounce(opts)
  local active_win = vim.api.nvim_get_current_win()
  local cursor_pos = vim.api.nvim_win_get_cursor(active_win)
  local windows = not string.find(vim.api.nvim_get_mode().mode, "o")
      and getconfig("multi_window", opts)
      and vim.api.nvim_tabpage_list_wins(0)
    or { active_win }
  local ns = vim.api.nvim_create_namespace ""
  local input = opts and opts.do_repeat and last_input or ""

  while true do
    local start_clock = os.clock()

    local accept_key_map = {}

    for _, win in ipairs(windows) do
      vim.api.nvim_buf_clear_namespace(vim.api.nvim_win_get_buf(win), ns, 0, -1)
    end

    -- Fake cursor highlight
    vim.api.nvim_buf_add_highlight(
      vim.api.nvim_win_get_buf(active_win),
      ns,
      "TermCursor",
      cursor_pos[1] - 1,
      cursor_pos[2],
      cursor_pos[2] + 1
    )

    if input ~= "" then
      local hits = {}
      local current_win = vim.api.nvim_get_current_win()

      -- Find and score all matches in visible buffer regions.
      for _, win in ipairs(windows) do
        local buf = vim.api.nvim_win_get_buf(win)
        local win_info = vim.fn.getwininfo(win)[1]
        local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
        for line = win_info.topline, win_info.botline do
          local text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]
          local matches = matcher.match(input, text)
          for _, m in ipairs(matches) do
            local score = m.score
            if win == current_win then
              score = score + CURRENT_WINDOW_BONUS
              if line == cursor_line then
                score = score + CURRENT_LINE_BONUS
              end
            end
            table.insert(hits, { window = win, line = line, indices = m.indices, score = score })
            if getconfig("debug", opts) then
              vim.api.nvim_buf_set_extmark(buf, ns, line - 1, -1, { virt_text = { { tostring(score), "IncSearch" } } })
            end
          end
        end
      end

      -- Discard relatively low-scoring matches.
      hits = matcher.filter(hits)

      table.sort(hits, function(a, b)
        return a.score > b.score
      end)

      -- Highlight and assign accept keys to matches.
      local seen = {}
      for idx, hit in ipairs(hits) do
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

          local accept_keys = getconfig("accept_keys", opts)
          if idx <= accept_keys:len() then
            local accept_key = accept_keys:sub(idx, idx)
            accept_key_map[accept_key] = { window = hit.window, position = { hit.line, hit.indices[1] - 1 } }
            local hl = "PounceAccept"
            if idx == 1 and getconfig("accept_best_key", opts) then
              hl = "PounceAcceptBest"
              local key = vim.api.nvim_replace_termcodes(getconfig("accept_best_key", opts), true, true, true)
              accept_key_map[key] = accept_key_map[accept_key]
            end
            vim.api.nvim_buf_set_extmark(
              buf,
              ns,
              hit.line - 1,
              hit.indices[1] - 1,
              { virt_text = { { accept_key, hl } }, virt_text_pos = "overlay" }
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
    else
      local ch = vim.fn.nr2char(nr)
      local accepted = accept_key_map[ch]
      if accepted ~= nil then
        -- accept match
        vim.cmd "normal! m'"
        vim.api.nvim_win_set_cursor(accepted.window, accepted.position)
        vim.api.nvim_set_current_win(accepted.window)
        break
      elseif type(nr) == "number" and (nr < 32 or nr == 127) then
        -- ignore
      else
        input = input .. ch
      end
    end
    last_input = input
  end

  for _, win in ipairs(windows) do
    vim.api.nvim_buf_clear_namespace(vim.api.nvim_win_get_buf(win), ns, 0, -1)
  end
  vim.api.nvim_echo({}, false, {})
end

return M
