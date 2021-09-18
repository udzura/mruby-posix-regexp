assert('PosixRegexp.quote') do
  m = /((a)?(z)?x)?/
  assert_equal Regexp.quote(m), "\\(\\(a\\)\\?\\(z\\)\\?x\\)\\?"

  m = /[a-z]+.*/
  assert_equal Regexp.quote(m), "\\[a\\-z\\]\\+\\.\\*"

  m = /new\nline\ttab/
  assert_equal Regexp.quote(m), "new\\\\nline\\\\ttab"
end
