assert('$1, $2, ...') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal $1, "zx"
  assert_equal $2, nil
  assert_equal $3, "z"
  assert_equal $4, nil
end

assert('$1, $2, ... when no match') do
  m = /((a)?(z)?x)?/.match("bb")
  assert_equal $1, nil
  assert_equal $2, nil
  assert_equal $3, nil
  assert_equal $4, nil
  assert_equal $5, nil
  assert_equal $6, nil
  assert_equal $7, nil
  assert_equal $8, nil
  assert_equal $9, nil
end
