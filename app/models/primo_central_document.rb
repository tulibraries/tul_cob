class PrimoCentralDocument

    require 'blacklight/primo_central'

    include Blacklight::PrimoCentral::Document


    self.unique_key = 'id'

end
