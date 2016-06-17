namespace :launch do
  desc "System updating for launch"
  task update: :environment do
    unless Rails.env.production?
      puts "[Error] task only for production env. add param 'RAILS_ENV=production'"
      next
    end
    system "bundle install"
    Rake::Task["db:mongoid:remove_indexes"].invoke
    Rake::Task["db:mongoid:create_indexes"].invoke
    system "bundle exec whenever --update-crontab"
  end

end
