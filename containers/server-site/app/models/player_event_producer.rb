# Event Producer for Player Events
# Publishes player_join and player_leave events

class PlayerEventProducer
  TOPIC_PLAYER_JOIN = 'player_join'
  TOPIC_PLAYER_LEAVE = 'player_leave'
  
  # Publish a player join event
  def self.publish_join(uuid, player_name, timestamp)
    event_data = {
      uuid: uuid,
      name: player_name,
      timestamp: timestamp
    }
    
    EventSystem.publish(TOPIC_PLAYER_JOIN, event_data)
  end
  
  # Publish a player leave event
  def self.publish_leave(uuid, player_name, timestamp)
    event_data = {
      uuid: uuid,
      name: player_name,
      timestamp: timestamp
    }
    
    EventSystem.publish(TOPIC_PLAYER_LEAVE, event_data)
  end
end

