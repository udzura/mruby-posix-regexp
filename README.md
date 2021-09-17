# mruby-posix-regexp

Regexp class with libc regex (POSIX Regex) backend

## install by mrbgems

- add conf.gem line to `build_config.rb`

```ruby
MRuby::Build.new do |conf|

  # ... (snip) ...

  conf.gem github: 'udzura/mruby-posix-regexp'
end
```

## example

```ruby
b = "xxx".gsub /x/, "y"
#=> "yyy"

"foo bar buz".scan /\w+/
#=> ["foo", "bar", "buz"]
```

## License

under the MIT License:

- see LICENSE file

## Thanks

- Referred from [mruby-pure-regexp](https://github.com/WindProphet/mruby-pure-regexp) in many Ruby methods and basic test cases.
