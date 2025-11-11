# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, type: :engine) do
    allow_any_instance_of(ArchivesSpaceService).to receive(:refresh_token!).and_return("test-token")
    allow_any_instance_of(ArchivesSpaceService).to receive(:ensure_token!).and_return("test-token")
    allow_any_instance_of(ArchivesSpaceService).to receive(:search).and_return([{ "title" => "Stubbed record" }])
  end
end
