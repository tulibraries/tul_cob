# frozen_string_literal: true

require "rails_helper"

# Specs in this file have access to a helper object that includes
# the CatalogHelper. For example:
#
# describe CatalogHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end

RSpec.describe CatalogHelper, type: :helper do

  describe "#isbn_data_attribute" do
    context "document contains an isbn" do
      let(:document) { { isbn_display: ["123456789"] } }
      it "returns the data-isbn string" do
        expect(isbn_data_attribute(document)).to eql "data-isbn=123456789"
      end
    end

    context "document contains multiple isbn" do
      let(:document) { { isbn_display: ["23445667890", "123456789"] } }
      it "returns the data-isbn string" do
        expect(isbn_data_attribute(document)).to eql "data-isbn=23445667890,123456789"
      end
    end

    context "document does not contain an isbn" do
      let(:document) { {} }
      it "does not return the data-isbn string" do
        expect(isbn_data_attribute(document)).to be_nil
      end
    end
  end

  describe "#lccn_data_attribute" do
    context "document contains an lccn" do
      let(:document) { { lccn_display: ["sn#00061556"] } }
      it "returns the data-lccn string" do
        expect(lccn_data_attribute(document)).to eql "data-lccn=sn#00061556"
      end
    end
  end

  describe "#grouped_citations" do
    it "sends all the given document citations to the grouped_citations method of the Citation class" do
      documents = [
        double("Document", citations: :abc),
        double("Document", citations: :def)
      ]
      expect(Citation).to receive(:grouped_citations).with([:abc, :def])
      grouped_citations(documents)
    end
  end

  describe "#render_marc_view" do
    let(:doc) { OpenStruct.new(to_marc: "foo") }
    let(:response) { Blacklight::Solr::Response.new(nil, nil) }

    before(:each) {
      helper.instance_variable_set(:@document, doc)
      helper.instance_variable_set(:@response, response)
      allow(helper).to receive(:render) {}
      helper.render_marc_view
    }

    context "document responds to to_marc" do
      it "renders the marc_view template" do
        expect(helper).to have_received(:render).with("marc_view", document: nil)
      end
    end

    context "document does not respond to to_marc" do
      let(:doc) { double }

      it "renders a default no_marc ouput" do
        expect(helper).to_not have_received(:render)
        expect(helper.render_marc_view).to eq(helper.t("blacklight.search.librarian_view.empty"))
      end
    end
  end

  describe "#render_email_form_field" do
    let(:current_user) { OpenStruct.new(email: nil) }

    before do
      allow(helper).to receive(:current_user) { current_user }
      allow(helper).to receive(:render) { "render_email_form_field" }
    end

    context "user does not have email" do
      it "renders the email field" do
        expect(helper.render_email_form_field).to eq("render_email_form_field")
      end
    end

    context "user has email" do
      let(:current_user) { OpenStruct.new(email: "foo") }

      it "does not render the email form field" do
        expect(helper.render_email_form_field).to be_nil
      end
    end
  end

  describe "#get_search_params" do
    context "with title_uniform_display field" do
      let(:field) { "title_uniform_display" }
      let(:query) { "Beethoven, Symphony no. 5" }

      it "should add quotes to the query and use title search" do
        expect(get_search_params(field, query)).to eq({ search_field: "title",
          q: "\"Beethoven, Symphony no. 5\"" })
      end
    end

    context "with title_statement_vern_display field" do
      let(:field) { "title_statement_vern_display" }
      let(:query) { "Beethoven, Symphony no. 5" }

      it "should not add quotes to the query or use title search" do
        expect(get_search_params(field, query)).to eq({ q: "Beethoven, Symphony no. 5", search_field: "title_statement_vern_display" })
      end
    end
  end

  describe "#record_page_ms_links" do
  context "duplicate genres" do
    let(:args) {
        {
          document:
          {
            genre_ms: [ "foo", "foo", "bar" ]
          },
          field: :genre_ms
        }
      }

    it "filters out duplicate genres" do
      expect(record_page_ms_links(args).count).to eq(2)
    end
  end

  context "donor_info_ms" do
    let(:args) {
        {
          document:
          {
            donor_info_ms: ["Lois G. Brodsky"]
          },
          field: :donor_info_ms
        }
      }

    it "displays donor link" do
      expect(record_page_ms_links(args)).to have_text("Lois G. Brodsky")
    end
  end

  context "collection_ms" do
    let(:args) {
        {
          document:
          {
            collection_ms: ["Russell Conwell Book Collection"]
          },
          field: :collection_ms
        }
      }

    it "displays donor link" do
      expect(record_page_ms_links(args)).to have_text("Russell Conwell Book Collection")
    end
  end
end

  describe "#subject_links(args)" do
    let(:base_path) { "foo" }

    before do
      allow(helper).to receive(:base_path) { base_path }
    end

    context "links to exact subject facet string" do
      let(:args) {
          {
            document:
            {
              subject_display: ["Middle East"]
            },
            field: :subject_display
          }
        }

      it "includes link to exact subject" do
        expect(subject_links(args).first).to have_link("Middle East", href: "#{base_path}?f[subject_facet][]=Middle+East")
      end
      it "does not link to only part of the subject" do
        expect(subject_links(args).first).to have_no_link("Middle East", href: "#{base_path}?f[subject_facet][]=Middle")
      end
    end

    context "links to subjects with special characters" do
      let(:args) {
          {
            document:
            {
              subject_display: ["Regions & Countries - Asia & the Middle East"]
            },
            field: :subject_display
          }
        }
      it "includes link to whole subject string" do
        expect(subject_links(args).first).to have_link("Regions & Countries - Asia & the Middle East", href: "#{base_path}?f[subject_facet][]=Regions+%26+Countries+-+Asia+%26+the+Middle+East")
      end
    end

    context "does not display double hyphens" do
      let(:args) {
          {
            document:
            {
              subject_display: ["Regions & Countries — —  Asia & the Middle East"]
            },
            field: :subject_display
          }
        }
      it "displays only one hyphen" do
        expect(subject_links(args).first).to have_text("Regions & Countries —  Asia & the Middle East")
      end
    end

    context "duplicate entry" do
      let(:args) {
          {
            document:
            {
              subject_display: [
                "Regions & Countries — —  Asia & the Middle East",
                "Regions & Countries — —  Asia & the Middle East",
              ]
            },
            field: :subject_display
          }
        }

      it "filters out duplicates" do
        expect(subject_links(args).count).to eq(1)
      end
    end
  end

  describe "#database_links(args)" do
    let(:base_path) { "foo" }

    before do
      allow(helper).to receive(:base_path) { base_path }
    end

    context "links to database type facet" do
      let(:args) {
          {
            document:
            {
              az_format: ["eBooks"]
            },
            field: :az_format
          }
        }

      it "includes link to database type" do
        expect(database_type_links(args).first).to have_link("eBooks", href: "#{base_path}?f[az_format][]=eBooks")
      end
    end
  end

  describe "#database_subject_links(args)" do
    let(:base_path) { "foo" }

    before do
      allow(helper).to receive(:base_path) { base_path }
    end

    context "links to database type facet" do
      let(:args) {
          {
            document:
            {
              az_subject_facet: ["art"]
            },
            field: :az_subject_facet
          }
        }

      it "includes link to database type" do
        expect(database_subject_links(args).first).to have_link("art", href: "#{base_path}?f[az_subject_facet][]=art")
      end
    end
  end

  describe "#ez_borrow_list_item(controller_name)" do
    context "catalog controller" do
      let(:controller_name) { "catalog" }
      let(:params) { { "q": "test" } }

      it "adds an ez_borrow list item" do
        expect(ez_borrow_list_item(controller_name)).to eql "<li>For books not available at Temple, search <a target=\"_blank\" href=\"https://ezborrow.reshare.indexdata.com/Search/Results?lookfor=test&amp;type=AllFields\">E-ZBorrow</a>.</li>"
      end
    end

    context "journal controller" do
      let(:controller_name) { "journal" }
      it "does not add an ez_borrow list item" do
        expect(ez_borrow_list_item(controller_name)).to be_nil
      end
    end
  end

  describe "doc_field_joiner(document, field)" do
    let(:string) { helper.doc_field_joiner(document, field) }
    let(:field) { "test" }
    let(:document) {  { "#{field}" => value } }
    context "the field value is empty" do
      let(:value) { "" }
      it "returns an empty string" do
        expect(string).to eql ""
      end
    end
    context "the field value is nil" do
      let(:value) { nil }
      it "returns an empty string" do
        expect(string).to eql ""
      end
    end
    context "the field value is non empty string value" do
      let(:value) { "an id" }
      it "returns an empty string" do
        expect(string).to eql "an id"
      end
    end

    context "the field value is an empty array" do
      let(:value) { [] }
      it "returns an empty string" do
        expect(string).to eql ""
      end
    end

    context "the field value is an array with a single string value" do
      let(:value) { ["one value"] }
      it "returns an empty string" do
        expect(string).to eql "one value"
      end
    end

    context "the field value is an array with a single integer value" do
      let(:value) { [3] }
      it "returns an empty string" do
        expect(string).to eql "3"
      end
    end
    context "the field value is an array with a single integer value" do
      let(:value) { [3] }
      it "returns an empty string" do
        expect(string).to eql "3"
      end
    end
    context "the field value is an array multiple string values" do
      let(:value) { ["one", "two"] }
      it "returns an empty string" do
        expect(string).to eql "one, two"
      end
    end
  end

  describe "#digital_help_allowed?(document)" do
    context "is not a physical item" do
      let(:document) { { "availability_facet" => "Online" } }
      it "returns false" do
        expect(digital_help_allowed?(document)).to be false
      end
    end
    context "is a physical item" do
      let(:document) { { "availability_facet" => "At the Library" } }
      it "returns true" do
        expect(digital_help_allowed?(document)).to be true
      end
    end
    context "is a physical item with hathitrust access denied" do
      let(:document) { {
         "availability_facet" => "At the Library",
         "hathi_trust_bib_key_display" => "foo"
          } }
      it "returns true" do
        expect(digital_help_allowed?(document)).to be true
      end
    end
    context "is an object" do
      let(:document) { { "format" => "Object" } }
      it "returns false" do
        expect(digital_help_allowed?(document)).to be false
      end
    end
    context "has a hathitrust link" do
       let(:document) { { "hathi_trust_bib_key_display" => [ { "bib_key" => "000005117", "access" => "allow" } ].first } }
       it "returns false" do
         expect(digital_help_allowed?(document)).to be false
       end
     end
    context "is a physical item and an online item" do
      let(:document) { {
        "availability_facet" => "At the Library",
        "electronic_resource_display" => "foo"
         } }
      it "returns false" do
        expect(digital_help_allowed?(document)).to be false
      end
    end
  end

  describe "#open_shelves_allowed?(document)" do
    context "is not in a relevant library" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "LAW",
        "permanent_location" => "reference",
        "current_library" => "LAW",
        "current_location" => "reference",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
          }
        }

      it "returns false" do
        expect(open_shelves_allowed?(document)).to be false
      end
    end

    context "is in a relevant Charles location" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "MAIN",
        "permanent_location" => "juvenile",
        "current_library" => "MAIN",
        "current_location" => "juvenile" }]
          }
        }
      it "returns true" do
        expect(open_shelves_allowed?(document)).to be true
      end
    end

    context "is in a relevant Ambler location" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "stacks",
        "current_library" => "AMBLER",
        "current_location" => "stacks" }]
          }
        }
      it "returns true" do
        expect(open_shelves_allowed?(document)).to be true
      end
    end

    context "is in a relevant library, but not location" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "MAIN",
        "permanent_location" => "Reference",
        "current_library" => "MAIN",
        "current_location" => "reference" }]
          }
        }
      it "returns false" do
        expect(open_shelves_allowed?(document)).to be false
      end
    end

    context "is in a relevant location, but not library" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23433968230003811",
        "item_policy" => "0",
        "permanent_library" => "JAPAN",
        "permanent_location" => "stacks",
        "current_library" => "JAPAN",
        "current_location" => "stacks" },
        { "item_pid" => "23311482710003811",
        "item_policy" => "2",
        "permanent_library" => "MAIN",
        "permanent_location" => "serials",
        "current_library" => "MAIN",
        "current_location" => "serials" }]
          }
        }
      it "returns false" do
        expect(open_shelves_allowed?(document)).to be false
      end
    end
  end

  describe "LibGuidesApi#derived_lib_guides_search_term(solr_response)" do
    before do
      allow(helper).to receive(:params) { params }
      allow(LibGuidesApi).to receive(:_subject_topic_facet_terms).and_return(["wu tang", "clan aint"])
    end
    let(:params) { { "q" => "thing" } }

    it "returns the origial search term and subject topics in parenthesis and combined with OR " do
      expect(derived_lib_guides_search_term(nil)).to eq("(thing) OR (wu tang) OR (clan aint)")
    end
  end

  describe "#_subject_topic_facet_terms(response)" do
    let(:subject) { LibGuidesApi.send(:_subject_topic_facet_terms, response) }
    let(:solr_response) { Blacklight::Solr::Response.new({ responseHeader: {}, facet_counts: { facet_fields: [facet_field] } }, {}) }
    let(:facet_field) { ["wrong", []] }

    context "nil response" do
      let(:response) { nil }
      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "empty solr response" do
      let(:response) { solr_response }
      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "solr_response without subject_topic_facet" do
      let(:response) { solr_response }
      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "solr_response with subject_topic_facet" do
      let(:facet_field) { ["subject_topic_facet", ["foo", 1]] }
      let(:response) { solr_response }
      it "returns an empty array" do
        expect(subject).to eq(["foo"])
      end
    end

    context "solr_response with subject_topic_facet multiple values" do
      let(:facet_field) { ["subject_topic_facet", ["foo", 1, "boo", 2]] }
      let(:response) { solr_response }
      it "returns an empty array" do
        expect(subject).to eq(["foo", "boo"])
      end
    end
  end

  describe "#subject_links" do
    let(:args) { {
      document: SolrDocument.new(id: "foo", subject_display: subject),
      field: "subject_display"
    } }

    before do
      allow(helper).to receive(:base_path) { "foo/bar" }
    end

    context "subjet is hierarchical string" do
      let(:subject) { ["Foo — Bar"] }

      it "splits the subject into a hierarchical list of links" do
        expect(helper.subject_links(args).first).to match(/<a.*href=".*Foo".*>Foo<\/a>.*href=".*Foo\+%E2%80%94\+Bar.*>Bar<\/a>/)
      end
    end
  end

  describe "#additional_title_link" do
    let(:args) { {
      document: SolrDocument.new(id: "foo", title_addl_display: title),
      field: "title_addl_display"
    } }

    before do
      without_partial_double_verification do
        allow(helper).to receive(:search_action_path) { "/catalog" }
      end
    end

    context "additional title and relation present" do
      let(:title) { [
        "{\"relation\":\"Foo\",\"title\":\"Bar\"}",
      ] }

      it "appends relation to a title link" do
        expect(helper.additional_title_link(args).first).to eq('<li class="list_items">Foo <a href="/catalog">Bar</a></li>')
        expect(helper.additional_title_link(args).count).to eq(1)
      end
    end

    context "only title present" do
      let(:title) { [
        "{\"title\":\"Bar\"}",
      ] }

      it "generates a title link" do
        expect(helper.additional_title_link(args).first).to eq('<li class="list_items"><a href="/catalog">Bar</a></li>')
        expect(helper.additional_title_link(args).count).to eq(1)
      end
    end

    context "only relation present" do
      let(:title) { [
        "{\"relation\":\"Bar\"}",
      ] }

      it "does not generate a link" do
        expect(helper.additional_title_link(args)).to eq([nil])
      end
    end
  end
end
