# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrimoCentralDocument, type: :model do
  let (:config) { PrimoCentralController.new.blacklight_config }
  let(:docs) { { "pnxId" => "foobar" } }
  let (:subject) { PrimoCentralDocument.new(docs, blacklight_config: config) }

  it "is configurable" do
    expect(config).to_not be_nil
    expect(subject.blacklight_config).to_not be_nil
  end

  it "shares field configurations with the primo controller" do
    doc_config = subject.blacklight_config

    expect(doc_config.show_fields).to eql(config.show_fields)
    expect(doc_config.index_fields).to eql(config.index_fields)
  end

  context "a pnxs object is loaded" do
    let(:docs) { { "pnxId" => "TN_fizzfuzz" } }
    it "removes TN_ from beginning of id" do
      expect(subject.id).to eq("fizzfuzz")
    end
  end

  context "url from almaOpenurl" do
    let(:docs) { ActiveSupport::HashWithIndifferentAccess.new(
      delivery: {
        "almaOpenurl": "https://na02.alma.exlibrisgroup.com/view/uresolver/01TULI_INST/openurl?ctx_enc=info:ofi/enc:UTF-8&ctx_id=10_1&ctx_tim=2024-03-07 14:41:20&ctx_ver=Z39.88-2004&url_ctx_fmt=info:ofi/fmt:kev:mtx:ctx&url_ver=Z39.88-2004&rfr_id=info:sid/primo.exlibrisgroup.com-lunacommons_DWU&rft_val_fmt=info:ofi/fmt:kev:mtx:book&rft.genre=unknown&rft.au=Price%2C+Jonathan+Reeve&rft.date=2019&rft.pub=Albuquerque&rft_dat=<lunacommons_DWU>oai_N_A_RUMSEY_8_1_359109_90125885</lunacommons_DWU>&svc_dat=viewit"
      }) }
    it "sets doc['link'] to almaOpenurl" do
      expect(subject["link"]).to eq("https://na02.alma.exlibrisgroup.com/view/uresolver/01TULI_INST/openurl?ctx_enc=info:ofi/enc:UTF-8&ctx_id=10_1&ctx_tim=2024-03-07 14:41:20&ctx_ver=Z39.88-2004&url_ctx_fmt=info:ofi/fmt:kev:mtx:ctx&url_ver=Z39.88-2004&rfr_id=info:sid/primo.exlibrisgroup.com-lunacommons_DWU&rft_val_fmt=info:ofi/fmt:kev:mtx:book&rft.genre=unknown&rft.au=Price%2C+Jonathan+Reeve&rft.date=2019&rft.pub=Albuquerque&rft_dat=<lunacommons_DWU>oai_N_A_RUMSEY_8_1_359109_90125885</lunacommons_DWU>&svc_dat=viewit")
    end
  end

  context "url from OA direct link" do
    let(:docs) { ActiveSupport::HashWithIndifferentAccess.new(
      "pnx" => {
       "addata" => {
          "oa" => [ "free_for_read" ]
        },
        "links" => {
          "linktorsrc" => [ "$$Uhttps://www.davidrumsey.com/luna/servlet/detail/RUMSEY~8~1~359109~90125885$$EView_record_in_Cartography_Associates$$FView_record_in_$$GCartography_Associates$$Hfree_for_read" ]
      }
      }) }
    it "sets doc['link'] to linktorsrc $$U" do
      expect(subject["link"]).to eq("https://www.davidrumsey.com/luna/servlet/detail/RUMSEY~8~1~359109~90125885")
    end
  end

  context "url from non-OA direct link" do
    let(:docs) { ActiveSupport::HashWithIndifferentAccess.new(
      "pnx" => {
       "addata" => {},
        "links" => {
          "linktorsrc" => [ "$$Uhttps://search.proquest.com/docview/2848172314?pq-origsite=primo$$EView_record_in_ProQuest$$FView_record_in_$$GProQuest" ]
      }
      }) }
    it "sets doc['link'] to linktorsrc $$U with ezproxy" do
      expect(subject["link"]).to eq("https://libproxy.temple.edu/login?url=https://search.proquest.com/docview/2848172314?pq-origsite=primo")
    end
  end

  context "with pnx description " do
    let(:docs) { { "pnx" => { "search" => { "description" => [ "foo" ] } } } }

    it "maps the description" do
      expect(subject["description"]).to eq("foo")
    end
  end

  context "with pnx subject" do
    let(:docs) { { "pnx" => { "search" => { "subject" => [ "foo", "bar"] } } } }

    it "maps the subject" do
      expect(subject["subject"]).to eq([ "foo", "bar" ])
    end
  end

  context "with pnx type" do
    let(:docs) { { "pnx" => { "display" => { "type" => [ "foo" ] } } } }

    it "maps the type and format" do
      expect(subject["type"]).to eq([ "foo" ])
      expect(subject["format"]).to eq([ "foo" ])
    end
  end

  context "with pnx title" do
    let(:docs) { { "pnx" => { "display" => { "title" => [ "foo" ] } } } }

    it "maps the title" do
      expect(subject["title"]).to eq("foo")
    end
  end

  context "with pnx contributor" do
    let(:docs) { { "pnx" => { "display" => { "contributor" => [ "foo;bar" ] } } } }

    it "maps the contributor" do
      expect(subject["contributor"]).to eq(["foo", "bar"])
    end
  end

  context "with pnx dislpay publisher" do
    let(:docs) { { "pnx" => { "display" => { "publisher" => [ "foo" ] } } } }
    it "maps the publisher" do
      expect(subject["publisher"]).to eq(["foo"])
    end
  end

  context "with pnx addata pub" do
    let(:docs) { { "pnx" => { "addata" => { "pub" => [ "foo" ] } } } }
    it "maps the publisher" do
      expect(subject["publisher"]).to eq(["foo"])
    end
  end

  context "with pnx display relation" do
    let(:docs) { { "pnx" => { "display" => { "relation" => [ "foo" ] } } } }
    it "maps the relation" do
      expect(subject["relation"]).to eq(["foo"])
    end
  end

  context "with pnx search isbn" do
    let(:docs) { { "pnx" => { "search" => { "isbn" => [ "foo" ] } } } }
    it "maps isbn" do
      expect(subject["isbn"]).to eq(["foo"])
    end
  end

  context "with pnx addata lccn" do
    let(:docs) { { "pnx" => { "addata" => { "lccn" => [ "foo" ] } } } }
    it "maps lccn" do
      expect(subject["lccn"]).to eq(["foo"])
    end
  end

  context "with pnx search issn" do
    let(:docs) { { "pnx" => { "search" => { "issn" => [ "foo" ] } } } }
    it "maps issn" do
      expect(subject["issn"]).to eq(["foo"])
    end
  end

  context "with pnx display ispartof" do
    let(:docs) { { "pnx" => { "display" => { "ispartof" => [ "foo" ] } } } }
    it "maps isPartOf" do
      expect(subject["isPartOf"]).to eq("foo")
    end
  end

  context "with pnx search creatorcontrib" do
    let(:docs) { { "pnx" => { "search" => { "creatorcontrib" => [ "foo" ] } } } }

    it "maps creator" do
      expect(subject["creator"]).to eq(["foo"])
    end
  end

  context "with pnx search creationdate" do
    let(:docs) { { "pnx" => { "search" => { "creationdate" => [ "foo" ] } } } }

    it "maps date" do
      expect(subject["date"]).to eq(["foo"])
    end
  end

  context "with pnx addata doi" do
    let(:docs) { { "pnx" => { "addata" => { "doi" => [ "foo" ] } } } }

    it "maps doi" do
      expect(subject["doi"]).to eq(["foo"])
    end
  end

  context "with pnx search language " do
    let(:docs) { { "pnx" => { "search" => { "language" => [ "foo" ] } } } }

    it "maps language" do
      expect(subject["language"]).to eq(["foo"])
    end
  end

  context "with pnx display language " do
    let(:docs) { { "pnx" => { "display" => { "language" => [ "foo" ] } } } }

    it "maps language" do
      expect(subject["language"]).to eq(["foo"])
    end
  end

  context "with lang3" do
    let(:docs) { { "lang3" => "foo" } }

    it "maps language" do
      expect(subject["language"]).to eq(["foo"])
    end
  end

  describe "#has_direct_link?" do
    context "document is completely empty" do
      let(:docs) { Hash.new }

      it "verifies there is no direct_link" do
        expect(subject.has_direct_link?).to be(false)
      end
    end

    context "document has a direct_link" do
      let(:docs) { ActiveSupport::HashWithIndifferentAccess.new(
        delivery: { availability: ["fulltext_linktorsrc"] }
      )}

      it "verifies that document has a direct_link" do
        expect(subject.has_direct_link?).to be(true)
      end
    end

    context "document does not have a direct link" do
      let(:docs) { ActiveSupport::HashWithIndifferentAccess.new(
        delivery: { availability: ["foobar"] }
      )}

      it "should verifies there is no direct_link" do
        expect(subject.has_direct_link?).to be(false)
      end
    end
  end

  describe "#materials" do
    it "returns a default empty set" do
      expect(subject.materials).to eq([])
    end
  end

  describe "#material_from_barcode" do
    it "returns nothing" do
      expect(subject.material_from_barcode).to be_nil
    end
  end

  context "document direct_link contains rft.isbn = ''" do
    let(:docs) { ActiveSupport::HashWithIndifferentAccess.new(
      delivery: {
        "almaOpenurl": "http://foobar.com?rft.isbn="
      }) }
    it "sets @doc['isbn'] to nil" do
      expect(subject["isbn"]).to be_nil
    end
  end

  context "document direct_link contains a regular value" do
    let(:docs) { ActiveSupport::HashWithIndifferentAccess.new(
      delivery: {
        "almaOpenurl": "http://foobar.com?rft.isbn=a"
      }) }
    it "sets @doc['isbn'] to [a]" do
      expect(subject["isbn"]).to eq(["a"])
    end
  end

  context "document direct_link is proxied and isbn=foo" do
    let(:docs) { ActiveSupport::HashWithIndifferentAccess.new(
      delivery: {
        "almaOpenurl": "http://myproxy.edu?url=http://foobar.com?rft.isbn=foo"
      }) }
    it "sets @doc['isbn'] to foo" do
      expect(subject["isbn"]).to eq(["foo"])
    end
  end


  describe "#purchase_order?" do
    context "with purchase_order false" do
      let(:document) { PrimoCentralDocument.new(purchase_order: false) }

      it "should be false" do
        expect(document.purchase_order?).to be false
      end
    end

    context "with purchase_order true" do
      let(:document) { PrimoCentralDocument.new(purchase_order: true) }

      it "should be false" do
        expect(document.purchase_order?).to be false
      end
    end

    context "with no purchase_order" do
      let(:document) { PrimoCentralDocument.new({}) }

      it "should be false" do
        expect(document.purchase_order?).to be false
      end
    end
  end

  describe "mapping subject / topic facets" do
    let(:primo_hash) { { "pnx" => {
                           "facets" => { "topic" => [ "foo", "bar" ] },
                           "search" => { "subject" => ["bar", "foo"] }
                         } } }

    it "uses the path pnx.facets.topic to get subject values" do
      doc = PrimoCentralDocument.new(primo_hash)
      expect(doc["subject"]).to eq(["foo", "bar"])
    end

    it "uses the path pnx.search.subject when pnx.facets.topic is not available" do
      primo_hash["pnx"]["facets"].delete("topic")
      doc = PrimoCentralDocument.new(primo_hash)
      expect(doc["subject"]).to eq(["bar", "foo"])
    end
  end

  describe "libkey_articles_url" do
    context "doi not present" do
      let(:docs) { {} }

      it "returns a nil" do
        expect(subject.libkey_articles_url).to be_nil
        expect(subject.libkey_articles_url_retracted?).to be_nil
      end
    end

    context "fullTextFile present" do
      let(:docs) { { "pnx" => { "addata" => { "doi" => [ "foo" ] } } } }

      it "returns the fullTextFile URL string" do
        stub_request(:get, /articles/)
          .to_return(status: 200,
                    headers: { "Content-Type" => "application/json" },
                    body: JSON.dump(data: {
                      fullTextFile: "https://www.google.com",
                      contentLocation: "https//www.temple.edu"
                    }))

        expect(subject.libkey_articles_url).to eq("https://www.google.com")
        expect(subject.libkey_articles_url_retracted?).to be false
      end
    end

    context "contentLocation present" do
      let(:docs) { { "pnx" => { "addata" => { "doi" => [ "foo" ] } } } }

      it "returns the contentLocation URL string" do
        stub_request(:get, /articles/)
          .to_return(status: 200,
                    headers: { "Content-Type" => "application/json" },
                    body: JSON.dump(data: { contentLocation: "https://www.temple.edu" }))

        expect(subject.libkey_articles_url).to eq("https://www.temple.edu")
        expect(subject.libkey_articles_url_retracted?).to be false
      end
    end

    context "retractionNoticeUrl present" do
      let(:docs) { { "pnx" => { "addata" => { "doi" => [ "foo" ] } } } }

      it "returns the fullTextFile URL string" do
        stub_request(:get, /articles/)
          .to_return(status: 200,
                    headers: { "Content-Type" => "application/json" },
                    body: JSON.dump(data: {
                      fullTextFile: "https://www.google.com",
                      contentLocation: "https://www.temple.edu",
                      retractionNoticeUrl: "https://librarysearch.temple.edu"
                    }))

        expect(subject.libkey_articles_url).to eq("https://librarysearch.temple.edu")
        expect(subject.libkey_articles_url_retracted?).to be true
      end
    end

  end
end
