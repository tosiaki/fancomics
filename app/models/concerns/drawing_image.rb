module Concerns::DrawingImage
  extend ActiveSupport::Concern

  included do
    enum orientation: { screen: 0, column: 1 }
    mount_uploader :drawing, DrawingUploader
    validates :drawing, presence: true
    skip_callback :commit, :after, :remove_drawing!

    validates :width, presence: true, numericality: { only_integer: true }
    validates :height, presence: true, numericality: { only_integer: true }
  end
end