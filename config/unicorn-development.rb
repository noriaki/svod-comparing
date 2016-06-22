worker_processes 1
preload_app true

listen 8081
pid    File.expand_path(
  "tmp/pids/unicorn-development.pid",     ENV["RAILS_ROOT"])

stderr_path File.expand_path(
  "log/unicorn-development.log",          ENV["RAILS_ROOT"])
stdout_path File.expand_path(
  "log/unicorn-development-error.log",    ENV["RAILS_ROOT"])
