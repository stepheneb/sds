module FromXml
  
  def to_xml
    super(:except => ['portal_id', 'created_at', 'updated_at'])
  end

end
