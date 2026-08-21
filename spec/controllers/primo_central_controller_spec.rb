# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrimoCentralController, type: :controller do
  let(:doc) { Hash.new }
  let(:options) { { blacklight_config: controller.blacklight_config } }
  let(:document) { PrimoCentralDocument.new(doc, options) }
  let(:helpers) { double("helper").as_null_object }
  let(:mock_response) { instance_double(Blacklight::PrimoCentral::Response) }
  let(:search_service) { instance_double(Blacklight::SearchService) }

  def capture_active_record_queries
    queries = []

    callback = lambda do |_name, started, finished, _unique_id, payload|
      sql = payload[:sql]

      next if payload[:name] == "SCHEMA"
      next if payload[:cached]
      next if sql.blank?
      next if sql.match?(/\A\s*(?:BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)\b/i)

      queries << {
        name: payload[:name],
        sql: sql,
        duration_ms: ((finished - started) * 1000).round(2)
      }
    end

    ActiveSupport::Notifications.subscribed(
      callback,
      "sql.active_record"
    ) do
      yield
    end

    queries
  end

  before(:each) do
    allow(helpers).to receive(:base_path).and_return("/")
    allow(controller).to receive(:helpers).and_return(helpers)
    allow(controller).to receive(:search_service).and_return(search_service)
    allow(search_service).to receive(:fetch).and_return([mock_response, document])
    allow(search_service).to receive(:search_results).and_return([mock_response, document])
  end

  describe "anonymous bot challenge ActiveRecord usage" do
    around do |example|
      config =
        BotChallengePage::BotChallengePageController.bot_challenge_config
      original_enabled = config.enabled

      config.enabled = true
      example.run
    ensure
      config.enabled = original_enabled
    end

    before do
      allow(helpers).to receive(:current_page?).and_return(false)

      @active_record_strategy =
        Flipflop::FeatureSet.current.strategies.find do |strategy|
          strategy.is_a?(
            Flipflop::Strategies::ActiveRecordStrategy
          )
        end

      raise "Flipflop ActiveRecord strategy not configured" unless @active_record_strategy

      Flipflop::FeatureSet.current.clear!(
        :bot_challenge,
        @active_record_strategy.key
      )
      Flipflop::FeatureSet.current.switch!(
        :bot_challenge,
        @active_record_strategy.key,
        true
      )
      Flipflop::FeatureCache.current.disable!
    end

    after do
      if @active_record_strategy
        Flipflop::FeatureSet.current.clear!(
          :bot_challenge,
          @active_record_strategy.key
        )
      end

      Flipflop::FeatureCache.current.disable!
    end

    it "returns the article bot challenge before search tracking and recaptcha" do
      expect(controller).not_to receive(:recaptcha)
      expect(controller).not_to receive(:set_current_search_session)

      queries = capture_active_record_queries do
        get :index, params: { q: "article bot challenge characterization" }
      end

      warn "\nCaptured SQL during challenged article request:"
      queries.each_with_index do |query, index|
        warn(
          "#{index + 1}. #{query[:name]} " \
          "(#{query[:duration_ms]}ms): #{query[:sql]}"
        )
      end

      expect(response).to have_http_status(:forbidden)
      expect(queries).not_to include(
        a_hash_including(sql: include('"searches"'))
      )
    end
  end

  describe "show action" do
    render_views

    it "handles a record not found exception", with_rescue: true do
      allow(search_service).to receive(:fetch).and_raise(::ArticleNotFound, "glub glub glub")
      get :show, params: { id: 1 }
      expect(response.code).to eq "404"
      expect(response.body).to include "error-header not-found"
    end
  end

  describe "net_read_timeout_rescue", with_rescue: true do
    before do
      allow(controller).to receive(:index) { raise Net::ReadTimeout }
    end

    context "when timeout happens but no deep pagination" do
      it "rescues from Net::ReadTimeout with a friendly error" do
        get :index

        expect(response).to redirect_to "/articles"
        expect(flash[:error]).to eq("Your search has timed out.")
      end
    end

    context "when timeout happens and deep pagination is present" do
      it "rescues from Net::ReadTimeout with a friendly error" do
        get :index, params: { page: 50 }

        expect(response).to redirect_to "/articles"
        expect(flash[:error]).to eq("Your search has timed out. You may have exceeded the maximum number of pages allowed for Article search results in Library Search.")
      end
    end
  end

  describe "recaptcha enabled" do
    around do |example|
      original = Rails.configuration.features[:recaptcha]
      Rails.configuration.features[:recaptcha] = true
      example.run
    ensure
      Rails.configuration.features[:recaptcha] = original
    end

    before do
      stub_const("ENV", ENV.to_h.merge("RECAPTCHA_SITE_KEY" => "foo"))
      allow(controller).to receive(:verify_recaptcha).and_return(false)
    end

    context "with regular query" do
      it "should not allow article searches" do
        expect { get :index, params: { q: "foo " } }.to raise_error(Recaptcha::VerifyError)
      end
    end

    context "with facet query" do
      it "should not allow article searches" do
        expect { get :index, params: { q: "foo " } }.to raise_error(Recaptcha::VerifyError)
      end
    end
  end

  describe "recaptcha disabled" do
    around do |example|
      original = Rails.configuration.features[:recaptcha]
      Rails.configuration.features[:recaptcha] = false
      example.run
    ensure
      Rails.configuration.features[:recaptcha] = original
    end

    before do
      stub_const("ENV", ENV.to_h.merge("RECAPTCHA_SITE_KEY" => "foo"))
    end

    it "skips recaptcha checks" do
      expect(controller).not_to receive(:verify_recaptcha)

      get :index, params: { q: "foo" }

      expect(response).to have_http_status(:ok)
    end
  end
end
