# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules")

Rails.application.config.assets.unknown_asset_fallback = true

# Cache the available format images for use in helper method.
Rails.application.config.assets.default_cover_image =
  Dir.glob("app/assets/images/svg/*").select { |m| m.match(/.svg$/) }
  .map { |p| File.basename(p, ".svg") }
  .map { |n| [n, n] }.to_h

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
