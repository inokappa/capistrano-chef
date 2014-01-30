require "capistrano/ext/multistage"
require "capistrano_colors"
#
default_run_options[:pty] = true
ssh_options[:keys] = ["/path/to/key"]
