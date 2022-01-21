local fzy = require "pounce.fzy_lua"
local matcher = require "pounce.matcher"

local function better_match(state, arguments)
  local needle = arguments[1]
  local a = fzy.score(needle, arguments[2])
  local b = fzy.score(needle, arguments[3])
  if a > b then
    return true
  else
    state.failure_message = string.format("expected \"%s\" (score %d) to be better than \"%s\" (score %d) for needle \"%s\"", arguments[2], a, arguments[3], b, needle)
    return false
  end
end

assert:register(
  "assertion",
  "better_match",
  better_match,
  "assertion.better_match.positive",
  "assertion.better_match.negative"
)

describe("Fuzzy matcher", function()
  it("prefers consecutive characters", function()
    assert.better_match("ab", "abc", "acb")
  end)

  it("prefers beginning and end of lines", function()
    assert.better_match("ab", "abx", "xabx")
    assert.better_match("ab", "xab", "xabx")
    assert.better_match("ab", "ab", "xab")
    assert.better_match("ab", "ab", "abx")
  end)

  it("prefers word boundaries", function()
    assert.better_match("ab", "xa bx", "xacbx")
    assert.better_match("ab", "xa/bx", "xacbx")
    assert.better_match("ab", "xa_bx", "xacbx")
  end)

  it("prefers uppercase characters", function()
    assert.better_match("ab", "xacBx", "xacbx")
  end)

  it("prefers short matches", function()
    assert.better_match("ab", "acb", "accb")
  end)
end)

local function multimatch(needle, haystack)
  local matches = matcher.match(needle, haystack)
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

describe("Fuzzy multimatcher", function()
  it("extracts multiple matches", function()
    local result = multimatch("mid", "abc my_identifier mid myotherid def")
    assert.are.same({ "mid", "my_id", "myotherid" }, result)
  end)

  it("limits matches per line", function()
    local result = multimatch("a", "aaaaaaaaaaaa")
    assert.equal(#result, 10)
  end)

  it("does not return overlapping matches", function()
    local result = multimatch("aa", "aaa")
    assert.equal(#result, 1)
  end)
end)
