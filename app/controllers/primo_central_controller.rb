class PrimoCentralController < CatalogController
  include Blacklight::Catalog

    configure_blacklight do |config|
      # Class for sending and receiving requests from a search index
      config.repository_class = Blacklight::PrimoCentral::Repository

      # Class for converting Blacklight's url parameters to into request parameters for the search index
      config.search_builder_class = Blacklight::PrimoCentral::SearchBuilder

      # Model that describes a Document
      config.document_model = ::PrimoCentralDocument

      # Model that maps search index responses to the blacklight response model
      config.response_model = Blacklight::PrimoCentral::Response

      config.index.document_presenter_class = PrimoCentralPresenter



      config.add_index_field 'id'
      config.add_index_field 'title', label: 'Title'
      config.add_index_field 'link'
      config.add_index_field 'year', label: 'Year'
      config.add_index_field 'subtitle', label: 'Subtitle'
      config.add_index_field 'authors'


    end


end
