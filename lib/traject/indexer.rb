
class Traject::Indexer
  # Overrides Traject::Indexer#to_field
  # Allows us to make use of procedures instead of forcing a block.
  #
  # REF: traject/traject#144
  def to_field(field_name, aLambda = nil, block = Proc.new { |*args| })
    if block_given?
      block = Proc.new { |*args| yield args }
    end
    @index_steps << ToFieldStep.new(field_name, aLambda, block, Traject::Util.extract_caller_location(caller.first))
  end
end
