RailsContentMap.create(django_content_type_id: 15,  rails_class_name: "NewsStory")
RailsContentMap.create(django_content_type_id: 25,  rails_class_name: "ShowEpisode")
RailsContentMap.create(django_content_type_id: 24,  rails_class_name: "ShowSegment")
RailsContentMap.create(django_content_type_id: 44,  rails_class_name: "BlogEntry")
RailsContentMap.create(django_content_type_id: 115, rails_class_name: "ContentShell")
RailsContentMap.create(django_content_type_id: 88,  rails_class_name: "Event")
RailsContentMap.create(django_content_type_id: 125, rails_class_name: "VideoShell")
RailsContentMap.create(django_content_type_id: 75,  rails_class_name: "PijQuery")
RailsContentMap.create(django_content_type_id: 13,  rails_class_name: "Bio")
RailsContentMap.create(django_content_type_id: 18,  rails_class_name: "KpccProgram")
RailsContentMap.create(django_content_type_id: 12,  rails_class_name: "OtherProgram")
RailsContentMap.create(django_content_type_id: 58,  rails_class_name: "Homepage")
RailsContentMap.create(django_content_type_id: 121,  rails_class_name: "FeaturedComment")

# Setup permissions based on Admin Resource's regsitered models.
AdminResource.config.registered_models.each do |resource|
  Permission.create(resource: resource)
end
