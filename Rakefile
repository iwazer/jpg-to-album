# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  app.name = 'jpg-to-album'
  app.frameworks += ['QuartzCore','AVFoundation','CoreLocation','AssetsLibrary','ImageIO']
  app.info_plist['UIMainStoryboardFile'] = 'Main'
end
