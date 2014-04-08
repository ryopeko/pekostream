class String
  def colorlize(color_number=nil)
    colors = (31..36).to_a + (91..96).to_a
    unless colors_number.nil?
      color_number = colors[self.delete('_').to_i(36) % colors.size]
    end

    "\e[#{color_number}m#{self}\e[0m"
  end

  def bg_colorlize(color_number=nil)
    colors = (41..46).to_a
    unless colors.include?(color_number)
      color_number = colors[self.delete('_').to_i(36) % colors.size]
    end

    self.colorlize(color_number)
  end
end
