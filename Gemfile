source "https://rubygems.org"

gemspec

VAGRANT_GEM_TAG = ENV['VAGRANT_GEM_TAG'] || 'v1.7.4'
# vagrant-spec made a change in 1d09951e which created a dependency conflict
# in our test environment. For now, default to the preceding revision.
VAGRANT_SPEC_GEM_REF = ENV['VAGRANT_SPEC_REF'] || '5006bc73'

group :development do
  # We depend on Vagrant for development, but we don't add it as a
  # gem dependency because we expect to be installed within the
  # Vagrant environment itself using `vagrant plugin`.
  if File.exist?(File.expand_path("../../vagrant", __FILE__))
    gem 'vagrant', path: "../vagrant"
  else
    gem "vagrant", :git => "git://github.com/mitchellh/vagrant.git", tag: VAGRANT_GEM_TAG
  end

  if File.exist?(File.expand_path("../../vagrant-spec", __FILE__))
    gem 'vagrant-spec', path: "../vagrant-spec"
  else
    gem 'vagrant-spec', git: "https://github.com/mitchellh/vagrant-spec.git", ref: VAGRANT_SPEC_GEM_REF
  end

  gem "rspec-expectations", "~> 2.14.0"
end

group :plugins do
  gem "vagrant-skytap", path: "."
end
