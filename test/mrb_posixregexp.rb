##
## PosixRegexp Test
##

assert("PosixRegexp#hello") do
  t = PosixRegexp.new "hello"
  assert_equal("hello", t.hello)
end

assert("PosixRegexp#bye") do
  t = PosixRegexp.new "hello"
  assert_equal("hello bye", t.bye)
end

assert("PosixRegexp.hi") do
  assert_equal("hi!!", PosixRegexp.hi)
end
