Gem::Specification.new do |spec|
  spec.name          = "lita-hipchat"
  spec.version       = "1.6.2"
  spec.authors       = ["Jimmy Cuadra"]
  spec.email         = ["jimmy@jimmycuadra.com"]
  spec.description   = %q{A HipChat adapter for Lita.}
  spec.summary       = %q{A HipChat adapter for the Lita chat robot.}
  spec.homepage      = "https://github.com/jimmycuadra/lita-hipchat"
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "adapter" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 2.5"
  spec.add_runtime_dependency "xmpp4r", ">= 0.5.6"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.0.0.beta2"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
end
