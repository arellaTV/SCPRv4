xml.item do
  xml.title content.headline
  xml.guid  content.remote_link_path
  xml.link  content.remote_link_path
  
  b = render_byline(content,false)
  if b
    xml.dc :creator, b
  end
  
  if content.assets.any?
    xml.enclosure :url => content.assets.first.asset.thumb.url, :type => "image/jpeg", :length => ""
  end
  
  descript = ""
  
  descript << render_asset(content,"feedxml")
  descript << content.body.html_safe
  
  if content.is_a? ContentShell
    descript << content_tag(:p, link_to("Read the full article at #{content.site}".html_safe, content.link_path))
  end
  
  xml.description descript
  
  xml.pubDate content.public_datetime.rfc822
end
