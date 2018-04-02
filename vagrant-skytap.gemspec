# -*- encoding: utf-8 -*-
# stub: vagrant-skytap 0.3.6 ruby lib

Gem::Specification.new do |s|
  s.name = "vagrant-skytap".freeze
  s.version = "0.3.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Eric True".freeze, "Nick Astete".freeze]
  s.date = "2017-08-02"
  s.description = "Enables Vagrant to manage Skytap machines.".freeze
  s.email = ["etrue@skytap.com".freeze, "nastete@skytap.com".freeze]
  s.homepage = "http://www.skytap.com".freeze
  s.licenses = ["MIT".freeze]
  s.rubyforge_project = "vagrant-skytap".freeze
  s.rubygems_version = "2.6.13".freeze
  s.summary = "Vagrant provider plugin for Skytap.".freeze

  s.installed_by_version = "2.6.13" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json_pure>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec-core>.freeze, ["~> 2.14.0"])
      s.add_development_dependency(%q<rspec-expectations>.freeze, ["~> 2.14.0"])
      s.add_development_dependency(%q<rspec-mocks>.freeze, ["~> 2.14.0"])
      s.add_development_dependency(%q<vagrant-spec>.freeze, ["~> 1.4.0"])
      s.add_development_dependency(%q<webmock>.freeze, ["~> 1.20"])
    else
      s.add_dependency(%q<json_pure>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rspec-core>.freeze, ["~> 2.14.0"])
      s.add_dependency(%q<rspec-expectations>.freeze, ["~> 2.14.0"])
      s.add_dependency(%q<rspec-mocks>.freeze, ["~> 2.14.0"])
      s.add_dependency(%q<vagrant-spec>.freeze, ["~> 1.4.0"])
      s.add_dependency(%q<webmock>.freeze, ["~> 1.20"])
    end
  else
    s.add_dependency(%q<json_pure>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-core>.freeze, ["~> 2.14.0"])
    s.add_dependency(%q<rspec-expectations>.freeze, ["~> 2.14.0"])
    s.add_dependency(%q<rspec-mocks>.freeze, ["~> 2.14.0"])
    s.add_dependency(%q<vagrant-spec>.freeze, ["~> 1.4.0"])
    s.add_dependency(%q<webmock>.freeze, ["~> 1.20"])
  end
end
