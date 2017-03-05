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
end
