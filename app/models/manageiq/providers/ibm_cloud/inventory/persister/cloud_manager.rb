class ManageIQ::Providers::IbmCloud::Inventory::Persister::CloudManager < ManageIQ::Providers::IbmCloud::Inventory::Persister
  include ManageIQ::Providers::IbmCloud::Inventory::Persister::Definitions::CloudCollections

  def initialize_inventory_collections
    initialize_cloud_inventory_collections
  end
end
