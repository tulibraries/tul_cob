# frozen_string_literal: true

class TestBotChallengeController < ApplicationController
  bot_challenge

  def show
    render plain: "hello world"
  end
end
