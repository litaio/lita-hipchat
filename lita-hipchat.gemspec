Gem::Specification.new do |spec|
  spec.name          = "lita-hipchat"
  spec.version       = "0.0.1"
  spec.authors       = ["Jimmy Cuadra"]
  spec.email         = ["jimmy@jimmycuadra.com"]
  spec.description   = %q{A Lita adapter for HipChat.}
  spec.summary       = %q{A Lita adapter for HipChat.}
  spec.homepage      = "https://github.com/jimmycuadra/lita-hipchat"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "xmpp4r", "~> 0.5"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 2.14.0rc1"
end
