# frozen_string_literal: true

# Rails 7.2 requires callers of `Module#deprecate` to supply a `deprecator:`
# keyword. Several bundled gems (including Bento Search and Blacklight) still
# rely on the old signature, so we provide a shim that preserves compatibility
# by defaulting to Rails' global deprecator when one is not supplied.
module ModuleDeprecateFallback
  def deprecate(*method_names, deprecator: nil, **options)
    resolved_deprecator = deprecator || ActiveSupport::Deprecation._instance
    super(*method_names, deprecator: resolved_deprecator, **options)
  end
end

Module.prepend(ModuleDeprecateFallback)
