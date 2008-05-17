module Rake
  def self.browse(filepath)
    if RUBY_PLATFORM =~ /mswin/
      system(filepath)
    else
      try_browsers = lambda do
        result = true
        if !(`which firefox 2>&1` =~ /no firefox/)
          system("firefox #{filepath}")
        elsif !(`which mozilla 2>&1` =~ /no mozilla/)
          system("mozilla #{filepath}")
        elsif !(`which netscape 2>&1` =~ /no netscape/)
          system("netscape #{filepath}")
        elsif !(`which links 2>&1` =~ /no links/)
          system("links #{filepath}")
        elsif !(`which lynx 2>&1` =~ /no lynx/)
          system("lynx #{filepath}")
        else
          result = false
        end
        result
      end
      opened = false
      if RUBY_PLATFORM =~ /darwin/
        opened = true
        system("open #{filepath}")
      elsif !(`which gnome-open 2>&1` =~ /no gnome-open/)
        success =
          !(`gnome-open #{filepath} 2>&1` =~ /There is no default action/)
        if !success
          opened = try_browsers.call() 
        else
          opened = true
        end
      else
        opened = try_browsers.call() 
      end
      if !opened
        puts "Don't know how to browse to location."
      end
    end
  end
end
