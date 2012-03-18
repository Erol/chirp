$:.unshift(File.expand_path('..', File.dirname(__FILE__)))
$:.unshift(File.expand_path('../lib', File.dirname(__FILE__)))
$:.unshift(File.expand_path(File.dirname(__FILE__)))

require 'minitest/autorun'