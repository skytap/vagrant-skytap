require_relative "spec/acceptance/base"

Vagrant::Spec::Acceptance.configure do |c|
  c.component_paths << File.expand_path("../spec/acceptance", __FILE__)
  c.skeleton_paths << File.expand_path("../spec/acceptance/skeletons", __FILE__)

  c.provider "skytap",
    box: File.expand_path("../skytap-test.box", __FILE__),
    contexts: ["provider-context/skytap"]
end
