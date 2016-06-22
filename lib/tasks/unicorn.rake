namespace :unicorn do
  desc "Start unicorn app server"
  task start: :environment do
    config_path = Rails.root.join "config/unicorn-#{Rails.env}.rb"
    sh "bundle exec unicorn_rails -c #{config_path} -E #{Rails.env} -D"
  end

  desc "Stop unicorn app server"
  task stop: :environment do
    unicorn_signal(:INT)
  end

  desc "Restart unicorn app server"
  task restart: :environment do
    Rake::Task['unicorn:stop'].invoke
    Rake::Task['unicorn:start'].invoke
  end

  desc "Unicorn pstree (depends on pstree command)"
  task pstree: :environment do
    sh "pstree '#{unicorn_pid}'"
  end

end

# Helpers
def unicorn_signal(signal)
  Process.kill signal, unicorn_pid
end

def unicorn_pid
  File.read(Rails.root.join("tmp/pids/unicorn-#{Rails.env}.pid")).to_i
rescue Errno::ENOENT
  raise 'Unicorn does not seem to be running'
end
