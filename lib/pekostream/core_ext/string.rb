class String
  def colorlize(color_number=nil)
    colors = (31..36).to_a + (91..96).to_a

    if color_number.nil? || !colors.include?(color_number)
      color_number = colors[self.delete('_').to_i(36) % colors.size]
    end

    "\e[#{color_number}m#{self}\e[0m"
  end
end
