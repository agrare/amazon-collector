module Amazon
  class Parser
    module VolumeType
      def parse_volume_types(data, _scope)
        uid         = parse_volume_type_uid(data)
        volume_type = TopologicalInventory::IngressApi::Client::VolumeType.new(
          :source_ref  => uid,
          :name        => uid,
          :description => "#{data["product"]["attributes"]["volumeType"]}",
          :extra       => {
            :storageMedia  => data["product"]["attributes"]["storageMedia"],
            :volumeType    => data["product"]["attributes"]["volumeType"],
            :maxIopsvolume => data["product"]["attributes"]["maxIopsvolume"],
            :maxVolumeSize => data["product"]["attributes"]["maxVolumeSize"],
          }
        )

        collections[:volume_types].data << volume_type

        uid(volume_type)
      end

      def parse_volume_type_uid(data)
        usage_type = data["product"]["attributes"]["usagetype"]
        match      = /.*EBS\:VolumeUsage\.(.*)$/.match(usage_type)

        return 'magnetic' unless match

        match[1]
      end

      def parse_volume_type_source_ref(source_ref)
        case source_ref
        when "piops"
          "io1" # For some reason the 'io1' is called 'piops' in pricint data?
        else
          source_ref
        end
      end
    end
  end
end
