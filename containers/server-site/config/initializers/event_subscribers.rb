# Event subscribers are no longer needed - Python script handles player logging
# This file is kept for compatibility but does nothing

Rails.application.config.after_initialize do
  # Ensure data directory exists
  Dir.mkdir('/data') unless Dir.exist?('/data')
  
  Rails.logger.info "Data directory structure ensured: /data"
end
