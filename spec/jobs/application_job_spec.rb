require 'rails_helper'

RSpec.describe ApplicationJob, type: :channel do
  describe "Simple instantiation test in lieu of usage" do
    subject { ApplicationJob.new(any_args) }
    it { is_expected.to be }
  end
end
