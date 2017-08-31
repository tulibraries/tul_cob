require 'alma'
require 'error_logger'

blank_email = "blank@expired.temple.edu"
namespace :fortytu do
  namespace :patron do
    
    desc 'Clean up expired user accounts from CSV file'
    task :expire, [:user_file] => :environment do |t, args|
      csv_source = args[:user_file] ? args[:user_file] : "expired_users.csv"
      Alma.configure do |config|
        env_config = YAML.load_file(File.expand_path "config/alma.yml")
        config.apikey = env_config[Rails.env]['apikey']
        config.region = env_config[Rails.env]['region']
      end
      csv_encoding = `file -b --mime-encoding #{csv_source}`.rstrip
      csv = CSV.read(csv_source, headers: true, encoding: 'utf-8') 
      retries = []
      
      progressbar = ProgressBar.create(:title => "Clean", :total => csv.count, format: "%t (%c/%C) %a |%B|")
      csv.each_with_index do |user, i|
        begin
          u = Alma::User.find(user['Username'])
          user_hash = u.response
          user_hash['contact_info']['email'].each do |email|
             email['email_address'] = blank_email if email['email_address'] == user['Email']
          end
          u.update(user_hash)
        rescue Exception => e
          unless $!.nil? || $!.is_a?(SystemExit)
            puts "Blank #{user['Username']} failed : #{e.message}"
            ErrorLogger.log_crash_info
            retries << user
          end
        end
        progressbar.increment
      end
      ErrorLogger.log_retry("retries_expire.csv", retries, csv.headers) if retries.count > 0
    end
    
    desc 'List expired user accounts [DEV]'
    task list: :environment do
      Alma.configure do |config|
        env_config = YAML.load_file(File.expand_path "config/alma.yml")
        config.apikey = env_config[Rails.env]['apikey']
        config.region = env_config[Rails.env]['region']
      end
      csv_source = "expired_users.csv"
      csv_encoding = `file -b --mime-encoding #{csv_source}`.rstrip
      csv = CSV.read(csv_source, headers: true, encoding: 'utf-8') 
      
      csv.each_with_index do |user, i|
        begin
          u = Alma::User.find(user['Username'])
        rescue Exception => e
          unless $!.nil? || $!.is_a?(SystemExit)
            puts "List #{user['Username']} failed : #{e.message}"
          end
        end
        puts "#{i}/#{csv.count}: #{u.id} #{u.email}"
      end
    end
    
    desc 'Restore expired user accounts from CSV file[DEV]'
    task :reset, [:user_file] => :environment do |t, args|
      csv_source = args[:user_file] ? args[:user_file] : "expired_users.csv"
      Alma.configure do |config|
        env_config = YAML.load_file(File.expand_path "config/alma.yml")
        config.apikey = env_config[Rails.env]['apikey']
        config.region = env_config[Rails.env]['region']
      end
      csv_source = "expired_users.csv"
      csv_encoding = `file -b --mime-encoding #{csv_source}`.rstrip
      csv = CSV.read(csv_source, headers: true, encoding: 'utf-8') 
      retries = []
      
      progressbar = ProgressBar.create(:title => "Clean", :total => csv.count, format: "%t (%c/%C) %a |%B|")
      csv.each_with_index do |user, i|
        begin
          u = Alma::User.find(user['Username'])
          user_hash = u.response
          user_hash['contact_info']['email'].each do |email|
            email['email_address'] = user['Email'] if email['email_address'] == blank_email
            u['contact_info']['email'].first['email_address'] = user['Email']
          end
          Alma::User.save!(user['Username'], user_hash)
        rescue Exception => e
          unless $!.nil? || $!.is_a?(SystemExit)
            puts "Reset #{user['Username']} failed : #{e.message}"
            ErrorLogger.log_crash_info
            retries << user
          end
        end
        progressbar.increment
      end
      ErrorLogger.log_retry("reset_expire.csv", retries, csv.headers) if retries.count > 0
    end
    
  end
end
