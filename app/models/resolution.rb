class Resolution < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  belongs_to :supplier_import
  belongs_to :product, optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true

  enum :strategy, { exact: 0, normalized: 1, trigram: 2, llm: 3 }, prefix: true
  enum :status, { needs_review: 0, auto_matched: 1, unmatched: 2, confirmed: 3, rejected: 4 }

  validates :raw_name, presence: true
  validates :normalized_name, presence: true
  validates :product, presence: true, if: -> { auto_matched? || confirmed? }
end
