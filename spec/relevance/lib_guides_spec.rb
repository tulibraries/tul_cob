# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Lib Guides Search Relevance", type: "controller", lib_guides_relevance: true do
  render_views

  let(:lib_guides_query_term) do
    @controller = SearchController.new
    get "index", params: { q: query_term, format: "json" }
    term = @controller.instance_variable_get(:@lib_guides_query_term)
    @controller = LibGuidesController.new
    term
  end

  let(:guides) do
    get "index", params: { q: lib_guides_query_term, format: "json" }
    JSON.parse(response.body)
  end

  def self.test_libguides_relevance(term, guide_names)
    context "Term is '#{term}'" do
      let(:query_term) { term }

      it "returns expected guides" do
        names = guides.map { |g| g["name"] }
        expect(names).to eq(guide_names)
      end
    end
  end

  test_libguides_relevance "communication sciences", ["Computer Science and Information Science", "Physical Computing", "Network Analysis"]

  test_libguides_relevance "victimology", ["Criminal Justice", "Find Videos/DVDs", "International Criminal Law"]

  test_libguides_relevance "social problem", ["Social Work", "Political Science Reading Lists for Undergraduates", "Political Science"]

  test_libguides_relevance "polarization", ["Political Science Reading Lists for Undergraduates", "Physics", "Politics in the Philadelphia Metropolitan Area"]

  test_libguides_relevance "continuing education in computer engineering", ["Computer Science and Information Science", "Engineering", "Electrical and computer engineering"]

  test_libguides_relevance "afro-futurism", ["English Language & Literature", "United States History Resources", "Africology & African American Studies"]

  test_libguides_relevance "Kinesiology", ["Kinesiology/Athletic Training", "Board Review Resources", "Physical Therapy"]

  test_libguides_relevance "cuban history", ["Political Science Reading Lists for Undergraduates", "Political Science", "Politics in the Philadelphia Metropolitan Area"]

  test_libguides_relevance "recreational therapy", ["Recreation and Leisure Studies", "Recreational Therapy", "Occupational Therapy"]

  test_libguides_relevance "horror films", ["Film and Media Arts", "History", "Find Videos/DVDs"]

  test_libguides_relevance "claude levi-strauss", ["Anthropology", "Philosophy", "History"]

  test_libguides_relevance "polar ice caps", ["Capstone Seminar in Global Studies  GBST 4096 - 002 ", "Earth & Environmental Science", "Global Studies"]

  test_libguides_relevance "athletic training", ["Kinesiology/Athletic Training", "Sport Management", "Physical Therapy"]

  test_libguides_relevance "health sciences data", ["Open Access for Health Information", "Statistics &amp; Data for Health", "LGBTQ Health and Medicine Resources"]

  test_libguides_relevance "video art", ["Art", "Art Education", "Art History"]

  test_libguides_relevance "APA style", ["English Language & Literature", "Social Work", "Psychology"]

  test_libguides_relevance "alfred hitchcock", ["History", "Film and Media Arts", "Stream Video To My Online Course"]

  test_libguides_relevance "foster care", ["Social Work", "Computer Science and Information Science", "Political Science"]

  test_libguides_relevance "seneca falls", ["Gender, Sexuality, and Women's Studies", "United States History Resources", "History"]

  test_libguides_relevance "icpsr", ["Finding and Using Data from ICPSR", "Economics", "Census Counts"]

  test_libguides_relevance "goffman stigma", ["Writing for Sociology", "Sociology", "English Language & Literature"]

  test_libguides_relevance "evidence-based practice", ["Medical Clerkship Resources", "LGBTQ Health and Medicine Resources", "Podiatric Medicine"]

  test_libguides_relevance "social work", ["Social Work", "Political Science Reading Lists for Undergraduates", "Political Science"]

  test_libguides_relevance "bioengineering", ["Bioengineering", "Engineering", "Mechanical engineering"]

  test_libguides_relevance "Communication Sciences and Disorders", ["Psychiatry", "LGBTQ Health and Medicine Resources", "Medical Clerkship Resources"]

  test_libguides_relevance "water therapy", ["Medical Clerkship Resources", "Podiatric Medicine", "Nursing"]

  test_libguides_relevance "political polarization", ["Political Science Reading Lists for Undergraduates", "American Elections", "Political Science"]

  test_libguides_relevance "palliative care", ["Nursing", "Genomic Medicine", "Medicine"]

  test_libguides_relevance "Recap", ["English Language & Literature", "Sport Management", "Research Impact Toolkit: English Studies"]
end
