source "https://rubygems.org"

gemspec

group :development do
  # We depend on Vagrant for development, but we don't add it as a
  # gem dependency because we expect to be installed within the
  # Vagrant environment itself using `vagrant plugin`.
  if File.exist?(File.expand_path("../../vagrant", __FILE__))
    gem 'vagrant', path: "../vagrant"
  else
    gem "vagrant", :git => "git://github.com/mitchellh/vagrant.git", :tag => 'v1.7.2'
  end

  if File.exist?(File.expand_path("../../vagrant-spec", __FILE__))
    gem 'vagrant-spec', path: "../vagrant-spec"
  else
    gem 'vagrant-spec', git: "https://github.com/mitchellh/vagrant-spec.git"
  end

  gem "rspec-expectations", "~> 2.14.0"
end

group :plugins do
  gem "vagrant-skytap", path: "."
end
