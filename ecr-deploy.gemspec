# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ecr_deploy/version'

Gem::Specification.new do |spec|
  spec.name          = "ecr-deploy"
  spec.version       = EcrDeploy::VERSION
  spec.authors       = ["Keitaroh Kobayashi"]
  spec.email         = ["keita@kbys.me"]

  spec.summary       = %q{A simple script to deploy services and tasks on AWS ECS}
  spec.homepage      = "https://github.com/KotobaMedia/ecr-deploy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk", "~> 2.1"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
