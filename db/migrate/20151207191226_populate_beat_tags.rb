class PopulateBeatTags < ActiveRecord::Migration

  TAG_NAMES = [
    ["Public Safety", "public-safety", "insert description here"],
    ["SoCal Economy", "socal-economy", "insert description here"],
    ["SoCal Politics", "socal-politics", "insert description here"],
    ["The Social Safety Net", "social-safety-net", "insert description here"],
    ["Vets", "vets", "insert description here"],
    ["Workplace", "workplace", "insert description here"],
    ["Changing Neighborhoods & Affordability", "changing-neighborhoods", "insert description here"],
    ["Commuting", "commuting", "insert description here"],
    ["Immigration 3.0", "immigration", "insert description here"],
    ["Infrastructure", "infrastructure", "insert description here"],
    ["Orange County", "orange-county", "insert description here"]
  ]

  def up
    Tag.where(slug: "immigration").first.update(slug: "immigration-reform")
    TAG_NAMES.each do |tag|
      Tag.where(title: tag[0], slug: tag[1], description: tag[2], tag_type: "Beat").first_or_create
    end
  end

  def down
    Tag.where(title: TAG_NAMES.map(&:first), tag_type: "Beat").destroy_all
    Tag.where(slug: "immigration-reform").not(tag_type: "Beat").first.update(slug: "immigration")
  end
end
