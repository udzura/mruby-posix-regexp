MRuby::Build.new do |conf|
  toolchain :gcc
  conf.gembox 'default'
  conf.gem File.expand_path('../../', __FILE__)
  conf.gem mgem: 'mruby-env'
  conf.gem mgem: 'mruby-catch-throw'

  conf.enable_test

  #if ENV['RELEASE'] != 'true'
    conf.enable_debug
    conf.cc.defines = %w(MRB_ENABLE_DEBUG_HOOK)
    # conf.gem core: 'mruby-bin-debugger'
  #end
end

MRuby::Build.new('utf8') do |conf|
  toolchain :gcc
  conf.compilers.each { |cc| cc.defines << 'MRB_UTF8_STRING' }
  conf.gem core: 'mruby-bin-mruby'
  conf.gem core: 'mruby-print'
  conf.gem core: 'mruby-sprintf'
  conf.gem File.expand_path('../../', __FILE__)
  conf.gem core: 'mruby-bin-mrbc' if MRuby::Source::MRUBY_RELEASE_NO <= 30000

  conf.enable_test
  conf.enable_debug
end
