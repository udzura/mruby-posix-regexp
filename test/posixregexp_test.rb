assert('PosixRegexp.compile') do
  assert_false PosixRegexp.compile("((a)?(z)?x)") === "ZX"

  assert_true PosixRegexp.compile("((a)?(z)?x)", 'i') === "ZX"

  assert_false PosixRegexp.compile("z.z", 'i') === "z\nz"

  assert_true PosixRegexp.compile("z.z", 'im') === "z\nz"
end

assert('PosixRegexp#match') do
  assert_nil PosixRegexp.compile("z.z").match("zzz", 1)
  PosixRegexp.compile("z.z").match("zzz") do |m|
    assert_equal "zzz", m[0]
  end

  assert_not_nil PosixRegexp.compile("z.z", 'mm').match("z\nz")

  assert_not_nil PosixRegexp.compile("5").match("123456789", 4)
  assert_nil PosixRegexp.compile("5").match("123456789", 5)
  assert_nil PosixRegexp.compile("5").match("123456789", -4)
  assert_not_nil PosixRegexp.compile("5").match("123456789", -5)
  assert_nil PosixRegexp.compile("5").match("123456789", -0x01000000)
end

assert('PosixRegexp#eql?') do
  assert_true  PosixRegexp.compile("z.z") == /z.z/
  assert_true  PosixRegexp.compile("z.z").eql? /z.z/
  assert_false PosixRegexp.compile("z.z") == /z.z/mi
end

assert('PosixRegexp#=~') do
  assert_nil PosixRegexp.compile("z.z") =~ "azz"
  assert_nil PosixRegexp.compile("z.z") =~ nil
  assert_equal 1, PosixRegexp.compile("z.z") =~ "azzz"
  assert_equal 0, PosixRegexp.compile("z.z") =~ "zzz"
  assert_equal 0, PosixRegexp.compile("y?") =~ "zzz"
end

assert('PosixRegexp#casefold?') do
  assert_true PosixRegexp.compile("z.z", 'i').casefold?
end

assert('PosixRegexp#source') do
  assert_equal "((a)?(z)?x)", PosixRegexp.compile("((a)?(z)?x)").source
end

assert('PosixRegexp#===') do
  assert_true  /^$/ === ""
  assert_true  /((a)?(z)?x)/ === "zx"
  assert_false /((a)?(z)?x)/ === "z"
  assert_true  /c?/ === ""
end

assert('PosixMatchData#==') do
  m = /((a)?(z)?x)?/.match("zx")
  m2 = /((a)?(z)?x)?/.match("zx")
  assert_true m == m2
end

assert('PosixMatchData#[]') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal "zx", m[0]
  assert_equal "zx", m[1]
  assert_equal nil,  m[2]
  assert_equal "z",  m[3]

  assert_equal ["zx", nil], m[1..2]
end

assert('PosixMatchData#begin') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal 0, m.begin(0)
  assert_equal 0, m.begin(1)
  assert_equal nil, m.begin(2)
  assert_equal 0, m.begin(3)
  assert_raise(IndexError) { m.begin(4) }
  assert_raise(IndexError) { m.begin(-1) }
end

assert('PosixMatchData#end') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal 2, m.end(0)
  assert_equal 2, m.end(1)
  assert_equal nil, m.end(2)
  assert_equal 1, m.end(3)
  assert_raise(IndexError) { m.end(4) }
  assert_raise(IndexError) { m.end(-1) }
end

assert('PosixMatchData#post_match') do
  m = /c../.match("abcdefg")
  assert_equal "fg", m.post_match

  assert_equal "", /c?/.match("").post_match
end

assert('PosixMatchData#pre_match') do
  m = /c../.match("abcdefg")
  assert_equal "ab", m.pre_match

  assert_equal "", /c?/.match("").pre_match
end

assert('PosixMatchData#captures') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal ["zx", nil, "z"], m.captures
end

assert('PosixMatchData#to_a') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal ["zx", "zx", nil, "z"], m.to_a

  assert_equal [""], /c?/.match("").to_a
end

assert('PosixMatchData#length') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal 4, m.length
  assert_equal 4, m.size
end

assert('PosixMatchData#offset') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal [0, 2],     m.offset(0)
  assert_equal [0, 2],     m.offset(1)
  assert_equal [nil, nil], m.offset(2)
  assert_equal [0, 1],     m.offset(3)
end

assert('PosixMatchData#to_s') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal "zx", m.to_s
end

assert('PosixMatchData#values_at') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal ["zx", nil, "z"], m.values_at(0, 2, 3)
end

assert('String#scan') do
  assert_equal ["abcd", "efgh", "ijkl"], "abcdefghijklmn".scan(/..../)

  assert_equal [["b", "cd"], ["f", "gh"], ["j", "kl"]],
  "abcdefghijklmn".scan(/.(.)(..)/)

  "abcde".scan(/.(.)(..)/) do |a, b|
    assert_equal "b", a
    assert_equal "cd", b
  end

  "abcdefg".scan(/..../) do |a|
    assert_equal "abcd", a
  end
end

assert('String#gsub') do
  assert_equal "@-@-ackb@-@-", "acbabackbacbab".gsub(/a.?b/, "@-")
  assert_equal "@-acbcb@-abbackb@-acbcb@-abb", "acbabackbacbab".gsub(/a(.?b)/, '@-\0\1')
  assert_equal "aBcdaBcd", "abcdabcd".gsub(/b/, 'B')
  assert_equal "@-acbcb@-abbackb@-acbcbaxxb", "acbabackbacbaxxb".gsub(/a(.?b)/, '@-\0\1')

  assert_equal ",1,2,3,4,5,6,7,8,9,", "123456789".gsub(/()/, ",")
  assert_equal ",,,,,,,,,,", "123456789".gsub(/(.?)/, ",")
  assert_equal ",1,,2,3,4,5,6,7,8,9,", "1:23456789".gsub(/(:?)/, ",")
  assert_equal ",1,,2,,3,,4,,5,6,7,8,9,", "1:2:3:4:56789".gsub(/(:)?/, ",")
end

assert('String#sub') do
  assert_equal "@-abackbacbab", "acbabackbacbab".sub(/a.?b/, "@-")
  assert_equal "@-acbcbabackbacbab", "acbabackbacbab".sub(/a(.?b)/, '@-\0\1')
end

# See the commit message below for the reason why the emoji is used to determine UTF-8.
# However, it would be better to rewrite it in the future.
# https://github.com/mruby/mruby/commit/906f9f2ba752c53162bf4bab6264b78a38f05fd8
if "💫".size == 1
  assert('PosixRegexp#match (with UTF-8)') do
    assert_not_nil /５/.match("１２３４５６７８９", 4)
    assert_nil /５/.match("１２３４５６７８９", 5)
    assert_nil /５/.match("１２３４５６７８９", -4)
  end

  assert('PosixMatchData#begin') do
    m = /((ａ)?(ｚ)?ｘ)?/.match("ｚｘ")
    assert_equal 0, m.begin(3)
  end

  assert('PosixMatchData#end') do
    m = /((ａ)?(ｚ)?ｘ)?/.match("ｚｘ")
    assert_equal 1, m.end(3)
  end

  assert('String#gsub (with UTF-8)') do
    assert_equal "１２３４５６７８９✔", "１２３４５６７８９✘".gsub(/✘/, "✔")
  end
end
