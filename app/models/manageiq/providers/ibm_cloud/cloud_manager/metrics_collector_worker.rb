class ManageIQ::Providers::IbmCloud::CloudManager::MetricsCollectorWorker < ManageIQ::Providers::BaseManager::MetricsCollectorWorker
  require_nested :Runner

  self.default_queue_name = "ibm_cloud"

  def friendly_name
    @friendly_name ||= "C&U Metrics Collector for ManageIQ::Providers::IbmCloud"
  end
end