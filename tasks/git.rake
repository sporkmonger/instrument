namespace :git do
  namespace :tag do
    desc "List tags from the Git repository"
    task :list do
      tags = `git tag -l`
      tags.gsub!("\r", "")
      tags = tags.split("\n").sort {|a, b| b <=> a }
      puts tags.join("\n")
    end

    desc "Create a new tag in the Git repository"
    task :create do
      v = ENV["VERSION"] or abort "Must supply VERSION=x.y.z"
      abort "Versions don't match #{v} vs #{PKG_VERSION}" if v != PKG_VERSION

      tag = "#{PKG_NAME}-#{PKG_VERSION}"
      msg = "Release #{PKG_NAME}-#{PKG_VERSION}"

      puts "Creating git tag '#{tag}'..."
      unless system "git tag -a -m \"#{msg}\" #{tag}"
        abort "Tag creation failed." 
      end
    end
  end
end

task "gem:release" => "git:tag:create"
