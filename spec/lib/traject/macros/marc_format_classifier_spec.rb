# frozen_string_literal: true

require "rails_helper"
require "traject"
require "traject/macros/marc_format_classifier"

# Include custom traject macros
require "traject/macros/custom"
extend Traject::Macros::Custom

MarcFormatClassifier = Traject::Macros::MarcFormatClassifier

RSpec.configure do |config|
  config.file_fixture_path = "spec/fixtures/marc_files"
end

def classifier_for(filename)
  record = MARC::XMLReader.new(file_fixture(filename).to_s).to_a.first
  return MarcFormatClassifier.new(record)
end

RSpec.describe MarcFormatClassifier, type: :lib do

  describe "genre" do
    context "Leader 06=a; 07=[m]" do
      it "says book" do
        expect(classifier_for("book_leader_am.xml").genre).to include("Book")
      end
    end
    context "Leader 06=a; 07=[a]" do
      it "says book" do
        expect(classifier_for("book_leader_aa.xml").genre).to include("Book")
      end
    end
    context "Leader 06=a; 07=[c]" do
      it "says book" do
        expect(classifier_for("book_leader_ac.xml").genre).to include("Book")
      end
    end
    context "Leader 06=a; 07=[d]" do
      it "says book" do
        expect(classifier_for("book_leader_ad.xml").genre).to include("Book")
      end
    end
    context "Leader 06=a; 008[21]=m or 006[04]=m" do
      it "says Book" do
        expect(classifier_for("book_07s_008-21m.xml").genre).to include("Book")
      end
    end
    context "Leader 06=a; 008[21]=d or 006[04]=d" do
      it "says database" do
        expect(classifier_for("book_07i_008-21d.xml").genre).to include("Database")
      end
    end
    context "Leader 06=a; 008[21]=w or 006[04]=w" do
      it "says website" do
        expect(classifier_for("book_07i_008-21w.xml").genre).to include("Website")
      end
    end
    context "Leader 06=m; 008[26]=a or 006[09]=a" do
      it "says dataset" do
        expect(classifier_for("data_06m_008-26a.xml").genre).to include("Dataset")
      end
    end
    context "Leader 06=m; 008[26]=c or 006[09]=c" do
      it "says Visual Material" do
        expect(classifier_for("data_06m_008-26c.xml").genre).to include("Visual Material")
        expect(classifier_for("data_06m_006-9c.xml").genre).to include("Visual Material")
      end
    end
    context "Leader 06=m; 008[26]=d or 006[09]=d; Leader 07=m" do
      it "says Book" do
        expect(classifier_for("data_06m_008-26d_7m.xml").genre).to include("Book")
        expect(classifier_for("data_06m_006-9d_7m.xml").genre).to include("Book")
      end
    end
    context "Leader 06=m; 008[26]=d or 006[09]=d; Leader 07=s" do
      it "says Book" do
        expect(classifier_for("data_06m_008-26d_7s.xml").genre).to include("Journal/Periodical")
        expect(classifier_for("data_06m_006-9d_7s.xml").genre).to include("Journal/Periodical")
      end
    end
    context "Leader 06=m; 008[26]=d or 006[09]=d; Leader 07=i" do
      it "says Database" do
        expect(classifier_for("data_06m_008-26d_7i.xml").genre).to include("Database")
        expect(classifier_for("data_06m_006-9d_7i.xml").genre).to include("Database")
      end
    end
    context "Leader 06=m; 008[26]=d or 006[09]=d; Leader 07=c" do
      it "says Database" do
        expect(classifier_for("data_06m_008-26d_7c.xml").genre).to include("Database")
        expect(classifier_for("data_06m_006-9d_7c.xml").genre).to include("Database")
      end
    end
    context "Audio recording" do
      it "says audio" do
        expect(classifier_for("audio.xml").genre).to include("Audio")
      end
    end
    context "Video recording" do
      it "says video" do
        expect(classifier_for("video.xml").genre).to include("Video")
      end
    end
    context "Score" do
      it "says score" do
        expect(classifier_for("score.xml").genre).to include("Score")
      end
    end
    context "Database" do
      it "says database" do
        expect(classifier_for("database.xml").genre).to include("Database")
      end
    end
    context "Archival" do
      it "says archival" do
        expect(classifier_for("archival.xml").genre).to include("Archival Material")
      end
    end
    context "Map" do
      it "says map" do
        expect(classifier_for("map.xml").genre).to include("Map")
      end
    end
    context "Kit" do
      it "says kit" do
        expect(classifier_for("kit.xml").genre).to include("Kit")
      end
    end
    context "Serial" do
      it "says serial" do
        expect(classifier_for("serial.xml").genre).to include("Journal/Periodical")
      end
    end
    context "Visual" do
      it "says image" do
        expect(classifier_for("visual.xml").genre).to include("Visual Material")
      end
    end
    context "Computer File" do
      it "says Computer File" do
        expect(classifier_for("computer_file.xml").genre).to include("Computer Media")
      end
    end
    context "Object" do
      it "says object" do
        expect(classifier_for("object.xml").genre).to include("Object")
      end
    end
    context "Record missing 006 and 008" do
      it "still parses correct from leader" do
        expect(classifier_for("serial_no_control_fields.xml").genre).to include("Journal/Periodical")
      end
    end
  end

  describe "format" do
    context "Thesis" do
      it "says thesis" do
        expect(classifier_for("thesis.xml").formats).to include("Dissertation/Thesis")
      end
    end
    context "Conference Proceedings" do
      describe "Conference Proceedings" do
        subject { classifier_for("proceeding.xml").formats }
        it { is_expected.to include("Book") }
        it { is_expected.to include("Conference Proceeding") }
      end
    end
    context "Government Document Included" do
      describe "Government Documents" do
        subject { classifier_for("govdoc.xml").formats }
        it { is_expected.to include("Government Document") }
      end
    end

    context "Government Document not Included"  do
      describe "Missing leader/06 item" do
        subject { classifier_for("no_govdoc.xml").formats }
        it { is_expected.to_not include("Government Document") }
      end
    end

  end

end
