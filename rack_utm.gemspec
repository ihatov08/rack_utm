
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rack_utm/version"

Gem::Specification.new do |spec|
  spec.name          = "rack_utm"
  spec.version       = RackUtm::VERSION
  spec.authors       = ["ihatov08"]
  spec.email         = ["ihatov08@gmail.com"]

  spec.summary       = "utm for rack application."
  spec.description   = "Urchin Tracking Module for rack application."
  spec.homepage      = "https://github.com/ihatov08/rack_utm"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rack-test", "~> 1.1.0"
  spec.add_development_dependency "pry-byebug", "~> 3.6.0"
  spec.add_development_dependency "timecop", "~> 0.9.1"
end
