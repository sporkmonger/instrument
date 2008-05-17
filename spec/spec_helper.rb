# We need to test for the presence of RAILS_ROOT in the $CONTROL_PATH
if !defined?(RAILS_ROOT)
  RAILS_ROOT = "somewhere/over/the/rainbow"
end

spec_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.expand_path(File.join(spec_dir, "../lib"))

$:.unshift(lib_dir)
$:.uniq!

require "instrument"
$CONTROL_PATH.unshift(File.join(spec_dir, "control_templates"))
