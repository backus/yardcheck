class TestApp
  # Singleton method with correct param definition and incorrect return
  #
  # @param left [Integer]
  # @param right [Integer]
  #
  # @return [String]
  def self.add(left, right)
    left + right
  end

  # Instance method with correct param definition and incorrect return
  #
  # @param left [Integer]
  # @param right [Integer]
  #
  # @return [String]
  def add(left, right)
    left + right
  end

  # Untested method with documentation
  #
  # @param str [String]
  #
  # @return [String]
  def untested_method(str)
  end

  def undocumented
  end
end
