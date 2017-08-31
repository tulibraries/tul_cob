require "yaml"
require "csv"

module ErrorLogger
  def self.log_crash_info(error=$!)
    program_name = $0
    process_id   = $$
    timestamp    = Time.now.utc.strftime("%Y%m%d-%H%M%S")

    filename = "crash-#{process_id}-#{timestamp}.yml"

    error_info = {}
    error_info["error"]       = error
    error_info["stacktrace"]  = error.backtrace
    error_info["environment"] = ENV.to_h

    File.write(filename, error_info.to_yaml)
    filename
  end
  
  def self.log_retry(csv_filename, retry_hash=nil, header) 
    CSV.open(csv_filename, "w",
                           :write_headers=> true,
                           :headers => header) do |csv|
      csv << retry_hash unless retry_hash.nil?
    end
  end
end