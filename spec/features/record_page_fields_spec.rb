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
    let (:item_130) { fixtures.fetch("title_uniform_130") }
    scenario "User visits a document with field 130 only" do
      visit "catalog/#{item_130['doc_id']}"
      within "dd.blacklight-title_uniform_display" do
        expect(page).to have_text(item_130['title_uniform'])
      end
    end

    let (:item_240) { fixtures.fetch("title_uniform_240") }
    scenario "User visits a document with field 240 only" do
      visit "catalog/#{item_240['doc_id']}"
      within "dd.blacklight-title_uniform_display" do
        expect(page).to have_text(item_240['title_uniform'])
      end
    end

    let (:item_730) { fixtures.fetch("title_uniform_730") }
    scenario "User visits a document with field 730 only" do
      visit "catalog/#{item_730['doc_id']}"
      within "dd.blacklight-title_uniform_display" do
        expect(page).to have_text(item_730['title_uniform'])
      end
    end

    #[TODO] Which marc field?
    scenario "User visits a document with uniform title vernacular"
  end

  feature "MARC Title Additional Fields" do
    let (:item_210) { fixtures.fetch("title_addl_210") }
    scenario "User visits a document with additional title " do
      visit "catalog/#{item_210['doc_id']}"
      within "dd.blacklight-title_addl_display" do
        expect(page).to have_text(item_210['title_addl'])
      end
    end

    let (:item_246) { fixtures.fetch("title_addl_246") }
    scenario "User visits a document with additional title " do
      visit "catalog/#{item_246['doc_id']}"
      within "dd.blacklight-title_addl_display" do
        expect(page).to have_text(item_246['title_addl'])
      end
    end

    let (:item_247) { fixtures.fetch("title_addl_247") }
    scenario "User visits a document with additional title " do
      visit "catalog/#{item_247['doc_id']}"
      within "dd.blacklight-title_addl_display" do
        expect(page).to have_text(item_247['title_addl'])
      end
    end

    let (:item_740) { fixtures.fetch("title_addl_740") }
    scenario "User visits a document with additional title " do
      visit "catalog/#{item_740['doc_id']}"
      within "dd.blacklight-title_addl_display" do
        expect(page).to have_text(item_740['title_addl'])
      end
    end

    scenario "User visits a document with additional title vernacular"

  end

  feature "MARC Creator Fields" do
    let (:item_100) { fixtures.fetch("creator_100") }
    scenario "User visits a document with creator" do
      visit "catalog/#{item_100['doc_id']}"
      within "dd.blacklight-creator_display" do
        expect(page).to have_text(item_100['creator'])
      end
    end

    let (:item_110) { fixtures.fetch("creator_110") }
    scenario "User visits a document with creator" do
      visit "catalog/#{item_110['doc_id']}"
      within "dd.blacklight-creator_display" do
        expect(page).to have_text(item_110['creator'])
      end
    end

    let (:item_111) { fixtures.fetch("creator_111") }
    scenario "User visits a document with creator" do
      visit "catalog/#{item_111['doc_id']}"
      within "dd.blacklight-creator_display" do
        expect(page).to have_text(item_111['creator'])
      end
    end

    let (:item_700) { fixtures.fetch("creator_700") }
    scenario "User visits a document with creator" do
      visit "catalog/#{item_700['doc_id']}"
      within "dd.blacklight-creator_display" do
        expect(page).to have_text(item_700['creator'])
      end
    end

    let (:item_710) { fixtures.fetch("creator_710") }
    scenario "User visits a document with creator" do
      visit "catalog/#{item_710['doc_id']}"
      within "dd.blacklight-creator_display" do
        expect(page).to have_text(item_710['creator'])
      end
    end

    let (:item_711) { fixtures.fetch("creator_711") }
    scenario "User visits a document with creator" do
      visit "catalog/#{item_711['doc_id']}"
      within "dd.blacklight-creator_display" do
        expect(page).to have_text(item_711['creator'])
      end
    end

    scenario "User visits a document with creator vernacular"

  end

  feature "MARC Format Fields" do
    let (:item) { fixtures.fetch("format") }
    scenario "User visits a document with format"
  end

  feature "MARC Imprint Fields" do
    let (:item_260) { fixtures.fetch("imprint_260") }
    scenario "User visits a document with imprint" do
      visit "catalog/#{item_260['doc_id']}"
      within "dd.blacklight-imprint_display" do
        expect(page).to have_text(item_260['imprint'])
      end
    end

    let (:item_264) { fixtures.fetch("imprint_264") }
    scenario "User visits a document with imprint" do
      visit "catalog/#{item_264['doc_id']}"
      within "dd.blacklight-imprint_display" do
        expect(page).to have_text(item_264['imprint'])
      end
    end
  end

  feature "MARC Edition Fields" do
    let (:item_250) { fixtures.fetch("edition_250") }
    scenario "User visits a document with edition" do
      visit "catalog/#{item_250['doc_id']}"
      within "dd.blacklight-edition_display" do
        expect(page).to have_text(item_250['edition'])
      end
    end

    let (:item_254) { fixtures.fetch("edition_254") }
    scenario "User visits a document with edition" do
      visit "catalog/#{item_254['doc_id']}"
      within "dd.blacklight-edition_display" do
        expect(page).to have_text(item_254['edition'])
      end
    end
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
    scenario "User visits a document with entry language" do
      visit "catalog/#{item['doc_id']}"
      within "dd.blacklight-language" do
        expect(page).to have_text(item['language'])
      end
    end
    let (:item_jpn) { fixtures.fetch("language_jpn") }
    scenario "User visits a document with entry language other than English" do
      visit "catalog/#{item_jpn['doc_id']}"
      within "dd.blacklight-language" do
        expect(page).to have_text(item_jpn['language'])
      end
    end
    let (:item_041) { fixtures.fetch("language_041") }
    scenario "User visits a document with entry languages code specified in field 041"
    # [TODO] The language in field 041 does not appear to be ingested
  end
end
