require 'rails_helper'
require 'yaml'

RSpec.feature "RecordPageFields", type: :feature do
  let (:fixtures) {
    YAML.load_file("#{fixture_path}/features.yml")
  }

  feature "MARC Title Statement Fields" do
    let (:item) {
      fixtures.fetch("title_statement")
    }

    scenario "User visits a document with full title statement" do
      visit "catalog/#{item['doc_id']}"
      expect(page).to have_text(item['title_statement'])
    end

    scenario "User visits a document with title statement vernacular" do
      visit "catalog/#{item['doc_id']}"
      within "dd.blacklight-title_statement_vern_display" do
        expect(page).to have_text(item['title_statement_vern'])
      end
    end
  end

  feature "MARC Title Uniform Fields" do
    let (:item) { fixtures.fetch("title_uniform") }
    scenario "User visits a document with title uniform"
    scenario "User visits a document with uniform title vernacular"
  end

  feature "MARC Title Additional Fields" do
    let (:item) { fixtures.fetch("title_addl") }
    scenario "User visits a document with title additional"
    scenario "User visits a document with additional title vernacular"
  end

  feature "MARC Creator Fields" do
    let (:item) { fixtures.fetch("creator") }
    scenario "User visits a document with creator"
    scenario "User visits a document with creator vernacular"
  end

  feature "MARC Format Fields" do
    let (:item) { fixtures.fetch("format") }
    scenario "User visits a document with format"
  end

  feature "MARC Imprint Fields" do
    let (:item) { fixtures.fetch("imprint") }
    scenario "User visits a document with imprint"
  end

  feature "MARC Edition Fields" do
    let (:item) { fixtures.fetch("edition") }
    scenario "User visits a document with edition"
  end

  feature "MARC Publication Date Fields" do
    let (:item) { fixtures.fetch("pub_date") }
    scenario "User visits a document with publication date"
  end

  feature "MARC Physical Description Fields" do
    let (:item) { fixtures.fetch("phys_desc") }
    scenario "User visits a document with physical description"
  end

  feature "MARC Series Title Fields" do
    let (:item) { fixtures.fetch("title_series") }
    scenario "User visits a document with series title"
    scenario "User visits a document with series title vernacular"
  end

  feature "MARC Volume Fields" do
    let (:item) { fixtures.fetch("volume") }
    scenario "User visits a document with volume"
  end

  feature "MARC Duration Fields" do
    let (:item) { fixtures.fetch("duration") }
    scenario "User visits a document with duration"
  end

  feature "MARC Frequency Fields" do
    let (:item) { fixtures.fetch("frequency") }
    scenario "User visits a document with frequency"
  end

  feature "MARC Sound Fields" do
    let (:item) { fixtures.fetch("sound") }
    scenario "User visits a document with sound"
  end

  feature "MARC Digital File Fields" do
    let (:item) { fixtures.fetch("digital_file") }
    scenario "User visits a document with digital file"
  end

  feature "MARC Fom Work Fields" do
    let (:item) { fixtures.fetch("fom_work") }
    scenario "User visits a document with fom work"
  end

  feature "MARC Performance Fields" do
    let (:item) { fixtures.fetch("performance") }
    scenario "User visits a document with performance"
  end

  feature "MARC Music No Fields" do
    let (:item) { fixtures.fetch("music_no") }
    scenario "User visits a document with music no"
  end

  feature "MARC Note Fields" do
    let (:item) { fixtures.fetch("note") }
    scenario "User visits a document with note"
  end

  feature "MARC Note With Fields" do
    let (:item) { fixtures.fetch("note_with") }
    scenario "User visits a document with note with"
  end

  feature "MARC Note Diss Fields" do
    let (:item) { fixtures.fetch("note_diss") }
    scenario "User visits a document with note diss"
  end

  feature "MARC Note Biblio Fields" do
    let (:item) { fixtures.fetch("note_biblio") }
    scenario "User visits a document with note biblio"
  end

  feature "MARC Note Toc Fields" do
    let (:item) { fixtures.fetch("note_toc") }
    scenario "User visits a document with note toc"
  end

  feature "MARC Note Restrictions Fields" do
    let (:item) { fixtures.fetch("note_restrictions") }
    scenario "User visits a document with note restrictions"
  end

  feature "MARC Note References Fields" do
    let (:item) { fixtures.fetch("note_references") }
    scenario "User visits a document with note references"
  end

  feature "MARC Note Summary Fields" do
    let (:item) { fixtures.fetch("note_summary") }
    scenario "User visits a document with note summary"
  end

  feature "MARC Note Cite Fields" do
    let (:item) { fixtures.fetch("note_cite") }
    scenario "User visits a document with note cite"
  end

  feature "MARC Note Terms Fields" do
    let (:item) { fixtures.fetch("note_terms") }
    scenario "User visits a document with note terms"
  end

  feature "MARC Note Bio Fields" do
    let (:item) { fixtures.fetch("note_bio") }
    scenario "User visits a document with note bio"
  end

  feature "MARC Note Finding Aid Fields" do
    let (:item) { fixtures.fetch("note_finding_aid") }
    scenario "User visits a document with note finding aid"
  end

  feature "MARC Note Custodial Fields" do
    let (:item) { fixtures.fetch("note_custodial") }
    scenario "User visits a document with note custodial"
  end

  feature "MARC Note Binding Fields" do
    let (:item) { fixtures.fetch("note_binding") }
    scenario "User visits a document with note binding"
  end

  feature "MARC Note Related Fields" do
    let (:item) { fixtures.fetch("note_related") }
    scenario "User visits a document with note related"
  end

  feature "MARC Note Accruals Fields" do
    let (:item) { fixtures.fetch("note_accruals") }
    scenario "User visits a document with note accruals"
  end

  feature "MARC Note Local Fields" do
    let (:item) { fixtures.fetch("note_local") }
    scenario "User visits a document with note local"
  end

  feature "MARC Subject Fields" do
    let (:item) { fixtures.fetch("subject") }
    scenario "User visits a document with subject"
  end

  feature "MARC Entry Preced Fields" do
    let (:item) { fixtures.fetch("entry_preced") }
    scenario "User visits a document with entry preced"
  end

  feature "MARC Entry Succeed Fields" do
    let (:item) { fixtures.fetch("entry_succeed") }
    scenario "User visits a document with entry succeed"
  end

  feature "MARC Isbn Fields" do
    let (:item) { fixtures.fetch("isbn") }
    scenario "User visits a document with entry isbn"
  end

  feature "MARC Issn Fields" do
    let (:item) { fixtures.fetch("issn") }
    scenario "User visits a document with entry issn"
  end

  feature "MARC Pub No Fields" do
    let (:item) { fixtures.fetch("pub_no") }
    scenario "User visits a document with entry pub no"
  end

  feature "MARC Govdoc Fields" do
    let (:item) { fixtures.fetch("govdoc") }
    scenario "User visits a document with entry govdoc"
  end

  feature "MARC Language Fields" do
    let (:item) { fixtures.fetch("language") }
    scenario "User visits a document with entry language"
  end
end
