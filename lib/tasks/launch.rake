namespace :launch do
  desc "System updating for launch"
  task update: :environment do
    system "bundle install"
    Rake::Task["db:mongoid:remove_indexes"].invoke
    Rake::Task["db:mongoid:create_indexes"].invoke
    system "bundle exec whenever --update-crontab"
  end

end
