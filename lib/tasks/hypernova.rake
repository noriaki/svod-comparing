namespace :hypernova do
  desc "Start hypernova server"
  task start: :environment do
    server_path =  Rails.root.join "lib/hypernova.jsx"
    logfile_path = Rails.root.join "log/hypernova-server-#{Rails.env}.log"
    pid = spawn(
      { "NODE_ENV" => Rails.env },                   # ENV
      "node_modules/.bin/babel-node #{server_path}", # Command
      [:out, :err] => [logfile_path, "a"]            # File redirect
    )
    Process.detach(pid)
    File.write(hypernova_pid_path, pid)
    true
  end

  desc "Stop hypernova server"
  task stop: :environment do
    if hypernova_signal(:INT) > 0
      File.delete(hypernova_pid_path)
    end
  end

  desc "Restart hypernova server"
  task restart: :environment do
    Rake::Task['hypernova:stop'].invoke
    Rake::Task['hypernova:start'].invoke
  end

end

def hypernova_signal(signal)
  Process.kill signal, hypernova_pid
end

def hypernova_pid
  File.read(hypernova_pid_path).to_i
rescue Errno::ENOENT
  raise "Hypernova server does not seem to be running"
end

def hypernova_pid_path
  Rails.root.join("tmp/pids/hypernova-#{Rails.env}.pid")
end
