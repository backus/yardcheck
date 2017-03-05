class TestApp
  # Method with correct param definition
  #
  # @param name [String]
  def hello(name)
    puts "Hello, #{name}"
  end

  # Method with incorrect param definition
  #
  # @param name [Symbol]
  def bye(name)
    puts "Goodbye, #{name}"
  end
end
