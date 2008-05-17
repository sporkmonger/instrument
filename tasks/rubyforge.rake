require 'rubyforge'
require 'rake/contrib/sshpublisher'

namespace :gem do
  desc 'Package and upload to RubyForge'
  task :release => [:package] do |t|
    v = ENV['VERSION'] or abort 'Must supply VERSION=x.y.z'
    abort "Versions don't match #{v} vs #{PROJ.version}" if v != PKG_VERSION
    pkg = "pkg/#{GEM_SPEC.full_name}"

    rf = RubyForge.new
    puts 'Logging in...'
    rf.login

    c = rf.userconfig
    changelog = File.open("CHANGELOG") { |file| file.read }
    c['release_changes'] = changelog
    c['preformatted'] = true

    files = ["#{pkg}.tgz", "#{pkg}.zip", "#{pkg}.gem"]

    puts "Releasing #{PKG_NAME} v. #{PKG_VERSION}"
    rf.add_release RUBY_FORGE_PROJECT, PKG_NAME, PKG_VERSION, *files
  end
end

namespace :doc do
  desc "Publish RDoc to RubyForge"
  task :release => ["doc:rdoc"] do
    config = YAML.load(
      File.read(File.expand_path('~/.rubyforge/user-config.yml'))
    )
    host = "#{config['username']}@rubyforge.org"
    remote_dir = RUBY_FORGE_PATH + "/api"
    local_dir = "doc"
    Rake::SshDirPublisher.new(host, remote_dir, local_dir).upload
  end
end
