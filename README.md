# mruby-posix-regexp   [![Build Status](https://travis-ci.org/udzura/mruby-posix-regexp.svg?branch=master)](https://travis-ci.org/udzura/mruby-posix-regexp)
PosixRegexp class
## install by mrbgems
- add conf.gem line to `build_config.rb`

```ruby
MRuby::Build.new do |conf|

    # ... (snip) ...

    conf.gem :github => 'udzura/mruby-posix-regexp'
end
```
## example
```ruby
p PosixRegexp.hi
#=> "hi!!"
t = PosixRegexp.new "hello"
p t.hello
#=> "hello"
p t.bye
#=> "hello bye"
```

## License
under the MIT License:
- see LICENSE file
