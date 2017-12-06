# frozen_string_literal: true

require 'spec_helper'
require 'marc'
require 'traject/macros/marc_format_classifier'
require 'pry'

require "traject"

# # To have access to various built-in logic
# # for pulling things out of MARC21, like `marc_languages`
# require "traject/macros/marc21_semantics"
# extend  Traject::Macros::Marc21Semantics
# 
# # To have access to the traject marc format/carrier classifier
# require "traject/macros/marc_format_classifier"
# extend Traject::Macros::MarcFormats

# Include custom traject macros
require "traject/macros/custom"
extend Traject::Macros::Custom
MarcFormatClassifier = Traject::Macros::MarcFormatClassifier

def classifier_for(filename)
  source_path = File.expand_path(File.join("../../..", "fixtures"), File.dirname(__FILE__))
  file_path = File.join(source_path, filename )
  record = MARC::XMLReader.new(file_path).to_a.first
  return MarcFormatClassifier.new( record )
end

RSpec.describe MarcFormatClassifier, type: :lib do
  
  describe "genre" do
    # We don't have the patience to test every case, just a sampling
    it "says book" do
      expect(classifier_for("book_leader_07_acdm.xml").genre).to include("book")
    end
    # it "says Book for a weird one" do
    #   expect(classifier_for("microform_online_conference.marc").genre).to be(["Book"])
    # end
    # it "says Musical Recording" do
    #   expect(classifier_for("musical_cage.marc").genre).to be(["Musical Recording"])
    # end
    # it "says Journal" do
    #   expect(classifier_for("the_business_ren.marc").genre).to be(["Journal/Newspaper"])
    # end
  end

end
