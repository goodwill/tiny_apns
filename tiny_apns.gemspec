$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "tiny_apns/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "tiny_apns"
  s.version     = TinyApns::VERSION
  s.authors     = ["William Yeung"]
  s.email       = ["william@tofugear.com"]
  s.homepage    = ""
  s.summary     = "An ultra lightweight library for handling Apple Push Notification (APNS)"
  s.description = ""

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "activesupport", "~> 3.0.0"


end
