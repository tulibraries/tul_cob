# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules")
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.unknown_asset_fallback = true

# Cache the available format images for use in helper method.
Rails.application.config.assets.default_cover_image =
  Dir.glob("app/assets/images/svg/*").select { |m| m.match(/.svg$/) }
  .map { |p| File.basename(p, ".svg") }
  .map { |n| [n, n] }.to_h

# Map document format types to cover image names
Rails.application.config.assets.format_cover_image_mapping = {
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
}

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( faustina.woff2 roboto-condensed.woff2 )
