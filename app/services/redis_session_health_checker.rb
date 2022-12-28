module RedisSessionHealthChecker
  module_function

  # @return [HealthCheckSummary]
  def check
    HealthCheckSummary.new(healthy: true, result: health_write_and_read)
  rescue StandardError => err
    NewRelic::Agent.notice_error(err)
    HealthCheckSummary.new(healthy: false, result: err.message)
  end

  # @api private
  def health_write_and_read
    REDIS_POOL.with do |client|
      client.setex(health_record_key, health_record_ttl, "healthy at " + Time.now.iso8601)
      client.get(health_record_key) or raise "Unable to read back #{health_record_key} from Redis"
    end
  end

  # @api private
  def health_record_key
    "healthcheck_" + Socket.gethostname
  end

  # @api private
  def health_record_ttl
    # If we can't read back within a second that is just unacceptable
    1
  end
end
