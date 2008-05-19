require 'spec/rake/verify_rcov'

namespace :spec do
  Spec::Rake::SpecTask.new(:rcov) do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts = ['--color', '--format', 'specdoc']
    t.rcov = true
    t.rcov_opts = [
      '--exclude', 'spec',
      '--exclude', '1\\.8\\/gems',
      '--exclude', '1\\.9\\/gems'
    ]
  end

  RCov::VerifyTask.new(:verify) do |t| 
    t.threshold = 100.0
    t.index_html = 'coverage/index.html'
  end

  task :verify => :rcov

  desc "Generate HTML Specdocs for all specs"
  Spec::Rake::SpecTask.new(:specdoc) do |t|
    specdoc_path = File.expand_path(
      File.join(File.dirname(__FILE__), '../specdoc/'))
    Dir.mkdir(specdoc_path) if !File.exist?(specdoc_path)
    
    output_file = File.join(specdoc_path, 'index.html')
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts = ["--format", "\"html:#{output_file}\"", "--diff"]
    t.fail_on_error = false
  end  

  desc "Browse the code coverage report."
  task :rcov_browse => :rcov do
    Rake.browse("coverage/index.html")
  end
end

desc "Alias to spec:verify"
task "spec" => "spec:verify"

task "clobber" => ["spec:clobber_rcov"]
