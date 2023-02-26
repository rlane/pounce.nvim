local fzy = require "pounce.fzy_lua"

local MAX_MATCHES_PER_LINE = 10

local M = {}

-- Returns the most relevant non-overlapping matches on a line.
function M.match(needle_, haystack_)
  local match_inner = nil
  local results = {}
  match_inner = function(needle, haystack, offset)
    if #results >= MAX_MATCHES_PER_LINE then
      return
    end

    if fzy.has_match(needle, haystack, false) then
      local indices, score = fzy.positions(needle, haystack, false)
      if #indices == 0 then
        return
      end

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

-- Discard relatively poor matches.
function M.filter(hits)
  local best_score = -1000.0
  for _, hit in ipairs(hits) do
    best_score = math.max(best_score, hit.score)
  end

  local filtered_hits = {}
  for _, hit in ipairs(hits) do
    if hit.score > best_score / 2 then
      table.insert(filtered_hits, hit)
    end
  end
  return filtered_hits
end

return M
