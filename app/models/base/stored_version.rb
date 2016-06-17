module Base
  class StoredVersion
    include Mongoid::Document
    include Mongoid::Timestamps::Updated

    field :stored_at, type: Date

    index({ stored_at: -1 }, { background: true })
    index({ _type: 1, _id: 1 }, { background: true, unique: true })
    index({ _type: 1, stored_at: -1 }, { background: true, unique: true })

  end
end
