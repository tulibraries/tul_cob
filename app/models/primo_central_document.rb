class PrimoCentralDocument

    require_dependency 'blacklight/primo'

    include Blacklight::Primo::Document


    self.unique_key = 'id'

end
