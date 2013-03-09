namespace :guests do
  desc "Remove guest accounts more than 10 days old"
  task :cleanup => :environment do
    User.where(guest: true).where("created_at < ?", 10.days.ago).destroy_all
  end
end
