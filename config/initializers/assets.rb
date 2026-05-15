# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

Rails.application.config.assets.paths << Rails.root.join("node_modules")

# Cache the available format images for use in helper methods.
Rails.application.config.x.default_cover_image =
  Rails.root
    .glob("app/assets/images/svg/*.svg")
    .map { |path| path.basename(".svg").to_s }
    .index_with(&:itself)

# Map document format types to cover image names.
Rails.application.config.x.format_cover_image_mapping = {
  "archival_material_manuscript" => "archival_material",
  "article" => "journal_periodical",
  "book_chapter" => "book",
  "book_review" => "legal",
  "computer_file" => "computer_media",
  "dissertation" => "script",
  "dissertation_thesis" => "script",
  "government_document" => "legal",
  "image" => "visual_material",
  "journal" => "journal_periodical",
  "journal_article" => "journal_periodical",
  "legal_document" => "legal",
  "magazine_article" => "journal_periodical",
  "market_research" => "dataset",
  "microform" => "legal",
  "newsletter_article" => "legal",
  "newspaper" => "legal",
  "newspaper_article" => "legal",
  "other" => "unknown",
  "patent" => "legal",
  "preprint" => "legal",
  "reference_entry" => "legal",
  "report" => "legal",
  "research_dataset" => "dataset",
  "review" => "legal",
  "review_article" => "legal",
  "standard" => "legal",
  "statistical_data_set" => "dataset",
  "technical_report" => "legal",
  "text_resource" => "legal",
  "web_resource" => "website",
}.freeze