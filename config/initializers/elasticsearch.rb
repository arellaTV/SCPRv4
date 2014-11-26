ES_CLIENT = Elasticsearch::Client.new(
  hosts:              Rails.configuration.secrets.elasticsearch_host,
  retry_on_failure:   3,
  reload_connections: true,
)

ES_PREFIX = Rails.configuration.secrets.elasticsearch_prefix