local fzy = require "pounce_fzy_lua"
local pounce = require "pounce"

local function better_match(_, arguments)
  local needle = arguments[1]
  return fzy.score(needle, arguments[2]) > fzy.score(needle, arguments[3])
end

assert:register("assertion", "better_match", better_match, "assertion.better_match.positive", "assertion.better_match.negative")

describe('Fuzzy matcher', function()
  it('prefers consecutive characters', function()
    assert.better_match("ab", "abc", "acb")
  end)

  it('prefers word boundaries', function()
    assert.better_match("ab", "a b", "acb")
    assert.better_match("ab", "a/b", "acb")
    assert.better_match("ab", "a_b", "acb")
  end)

  it('prefers uppercase characters', function()
    assert.better_match("ab", "acB", "acb")
  end)

  it('prefers short matches', function()
    assert.better_match("ab", "acb", "accb")
  end)
end)

local function multimatch(needle, haystack)
  local matches = pounce.match(needle, haystack)
  table.sort(matches, function(a, b)
    return a.score > b.score
  end)
  local result = {}
  for _, m in ipairs(matches) do
    local text = haystack:sub(m.indices[1], m.indices[#m.indices])
    table.insert(result, text)
  end
  return result
end

describe('Fuzzy multimatcher', function()
  it('extracts multiple matches', function()
    local result = multimatch("mid", "abc my_identifier mid myotherid")
    assert.are.same({ "mid", "my_id", "myotherid" }, result)
  end)

  it('limits matches per line', function()
    local result = multimatch("a", "aaaaaaaaaaaa")
    assert.equal(#result, 10)
  end)

  it('does not return overlapping matches', function()
    local result = multimatch("aa", "aaa")
    assert.equal(#result, 1)
  end)
end)
