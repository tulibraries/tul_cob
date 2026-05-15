# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Basic search after advanced search" do
  let(:response_body) { default_articles_response_body }

  before do
    stub_request(:get, /primo/)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: response_body
      )
  end

  scenario "plain search does not carry advanced params forward" do
    visit "/articles/advanced"
    fill_in "q_1", with: "foo"
    fill_in "q_2", with: "bar"
    click_button "advanced-search-submit"

    expect(current_url).to match(/q_1=foo/)

    fill_in "q", with: "cat"
    click_button "search"

    expect(current_url).to match(/q=cat/)
    expect(current_url).not_to match(/q_1=foo/)
    expect(current_url).not_to match(/q_2=bar/)
    expect(current_url).not_to match(/clause/)
  end

  scenario "catalog plain search does not carry advanced params forward" do
    visit "/catalog?utf8=%E2%9C%93&f_1=all_fields&operator%5Bq_1%5D=contains&q_1=test&op_1=AND&f_2=all_fields&operator%5Bq_2%5D=contains&q_2=&op_2=AND&f_3=all_fields&operator%5Bq_3%5D=contains&q_3=&range%5Bpub_date_sort%5D%5Bbegin%5D=&range%5Bpub_date_sort%5D%5Bend%5D=&range%5Blc_classification%5D%5Bbegin%5D=A&range%5Blc_classification%5D%5Bend%5D=Z&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&search_field=advanced&commit=Search"

    fill_in "q", with: "cat"
    click_button "search"

    expect(current_url).to match(/q=cat/)
    expect(current_url).not_to match(/q_1=test/)
    expect(current_url).not_to match(/f_1=all_fields/)
    expect(current_url).not_to match(/operator/)
    expect(current_url).not_to match(/op_1=AND/)
    expect(current_url).not_to match(/search_field=advanced/)
  end

  def default_articles_response_body
    File.read("spec/fixtures/articles_search_response.json")
  end
end
