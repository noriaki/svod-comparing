namespace :launch do
  desc "System updating for launch"
  task update: :environment do
    system "bundle install"
    system "npm install"
    Rake::Task["db:mongoid:remove_indexes"].invoke
    Rake::Task["db:mongoid:create_indexes"].invoke
    if Rails.env.production?
      system "bundle exec whenever --update-crontab"
    end
  end

end
