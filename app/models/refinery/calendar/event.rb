module Refinery
  module Calendar
    class Event < Refinery::Core::BaseModel
      extend FriendlyId

      friendly_id :title, :use => :slugged

      translates :title, :excerpt, :description
      class Translation
        attr_accessible :locale
      end
      acts_as_indexed :fields => [:title, :excerpt, :description]

      belongs_to :venue

      validates :title, :presence => true, :uniqueness => true

      attr_accessible :title, :from, :to, :registration_link,
                      :venue_id, :excerpt, :description,
                      :featured, :position

      alias_attribute :from, :starts_at
      alias_attribute :to, :ends_at

      delegate :name, :address,
                :to => :venue,
                :prefix => true,
                :allow_nil => true

      scope :featured, where(:featured => true)
      scope :future,   lambda { where('refinery_calendar_events.starts_at >= ?', Time.now) }
      scope :archive,  lambda { where('refinery_calendar_events.starts_at < ?',  Time.now) }

      scope :starting_on_day, lambda { |day| where(starts_at: day.beginning_of_day..day.tomorrow.beginning_of_day) }
      scope :ending_on_day,   lambda { |day| where(ends_at:   day.beginning_of_day..day.tomorrow.beginning_of_day) }
      scope :on_day, lambda { |day|
        where("refinery_calendar_events.starts_at < ? AND refinery_calendar_events.ends_at > ?", day.tomorrow.beginning_of_day, day.beginning_of_day)
      }

      scope :chronological,         order('refinery_calendar_events.starts_at ASC')
      scope :reverse_chronological, order('refinery_calendar_events.starts_at DESC')

      def self.upcoming(n=5)
        future.chronological.limit(n)
      end

      def self.recent(n=5)
        archive.reverse_chronological.limit(n)
      end

      def multiday?
        starts_at.to_date != ends_at.to_date
      end

    end
  end
end
