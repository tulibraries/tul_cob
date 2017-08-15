require 'alma'

namespace :fortytu do
  namespace :patron do
    
    desc 'Clean up expired user accounts'
    task expire: :environment do
      Alma.configure do |config|
        env_config = YAML.load_file(File.expand_path "config/alma.yml")
        config.apikey = env_config[Rails.env]["apikey"]
        config.region = env_config[Rails.env]["region"]
      end
      csv_source = "expired_users.csv"
      csv_encoding = `file -b --mime-encoding #{csv_source}`.rstrip
      csv = CSV.read(csv_source, headers: true, encoding: 'utf-8') 
      
      progressbar = ProgressBar.create(:title => "Clean", :total => csv.count, format: "%t (%c/%C) %a |%B|")
      csv.each_with_index do |user, i|
        # begin
          u = Alma::User.find(user['Username'])
          u["contact_info"]["email"].first["email_address"] = "blank@expired.temple.edu"
          Alma::User.save!(user['Username'], u.response)
        # rescue Exception => e
        #   unless $!.nil? || $!.is_a?(SystemExit)
        #     puts "Blank #{user['Username']} failed : #{e.message}"
        #   end
        # end
        progressbar.increment
      end
    end
    
    desc 'List expired user accounts [DEV]'
    task list: :environment do
      Alma.configure do |config|
        env_config = YAML.load_file(File.expand_path "config/alma.yml")
        config.apikey = env_config[Rails.env]["apikey"]
        config.region = env_config[Rails.env]["region"]
      end
      csv_source = "expired_users.csv"
      csv_encoding = `file -b --mime-encoding #{csv_source}`.rstrip
      csv = CSV.read(csv_source, headers: true, encoding: 'utf-8') 
      
      csv.each_with_index do |user, i|
        # begin
          u = Alma::User.find(user['Username'])
        # rescue Exception => e
        #   unless $!.nil? || $!.is_a?(SystemExit)
        #     puts "List #{user['Username']} failed : #{e.message}"
        #   end
        # end
        puts "#{i}/#{csv.count}: #{user['Username']} -> #{u.email}"
      end
    end
    
    desc 'Restore user accounts [DEV]'
    task reset: :environment do
      Alma.configure do |config|
        env_config = YAML.load_file(File.expand_path "config/alma.yml")
        config.apikey = env_config[Rails.env]["apikey"]
        config.region = env_config[Rails.env]["region"]
      end
      csv_source = "expired_users.csv"
      csv_encoding = `file -b --mime-encoding #{csv_source}`.rstrip
      csv = CSV.read(csv_source, headers: true, encoding: 'utf-8') 
      
      csv.each_with_index do |user, i|
        # begin
          u = Alma::User.find(user['Username'])
          puts "#{i}/#{csv.count}: #{user['Username']}, #{u.email} -> #{user['Email']}"
          u["contact_info"]["email"].first["email_address"] = user['Email']
          Alma::User.save!(user['Username'], u.response)
        # rescue Exception => e
        #   unless $!.nil? || $!.is_a?(SystemExit)
        #     puts "Reset #{user['Username']} failed : #{e.message}"
        #   end
        # end
      end
    end
    
  end
end
