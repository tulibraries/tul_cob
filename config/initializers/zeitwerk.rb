# frozen_string_literal: true

Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "cdm_engine" => "CDMEngine",
    "ris_creator" => "RISCreator",
    "lc_classifications" => "LCClassifications",
  )
end
