assert('$1, $2, ...') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal $1, "zx"
  assert_equal $2, nil
  assert_equal $3, "z"
  assert_equal $4, nil
end
