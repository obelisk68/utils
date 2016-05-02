# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'utils/version'

Gem::Specification.new do |spec|
  spec.name          = "utils"
  spec.version       = Utils::VERSION
  spec.authors       = ["obelisk68"]
  spec.email         = ["hwksy232@ybb.ne.jp"]

  spec.summary       = %q{My utility kit.}
  spec.description   = %q{My utility kit. \nUtils.imgexist?(url), String#imgsufix, Utils.getfile(url, file_name, max=0), Array#nest_loop {}, String#pickup(left, right, step=nil), Array#pickup(left, right, step=nil)}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "fastimage"
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
end
