module B64

  def folding_encode(str, eol = "\n", limit = 60)
    [str].pack('m')
  end

  def encode(str)
    [str].pack('m').tr( "\r\n", '')
  end

  def decode(str, strict = false)
    str.unpack('m').first
  end

end
