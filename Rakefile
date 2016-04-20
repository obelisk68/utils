require "bundler/gem_tasks"
require "rake/extensiontask"

task :build => :compile

Rake::ExtensionTask.new("utilsc") do |ext|
  ext.lib_dir = "lib/utilsc"
end

task :default => [:clobber, :compile, :spec]
