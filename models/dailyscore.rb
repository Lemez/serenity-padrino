class DailyScore < ActiveRecord::Base
	include ActiveModel::Dirty # for checking changed status

	serialize :topics, Array
	before_create :set_just_created
	after_save :set_was_changed

	scope :since_day, -> (day) { where('date > ?', day) }
	scope :on_date, -> (day) { where(date:day) } #day must be Date format, not string
												# need to chain with .first as this returns ARarray

#<DailyScore id: 7020, mail: 0.5, telegraph: -0.8, times: 1.0, average: -2.3, guardian: -6.6, independent: -1.1, express: -4.7, date: "2016-05-21 00:00:00", created_at: "2016-05-21 16:54:25", updated_at: "2016-05-21 16:54:25">

	def self.from_today
		self.where(date:Date.today)
	end

	def is_complete?
		attributes.values == attributes.values.compact
	end

	def nil_attributes
		arr = []
		attributes.each_pair{|k,v| arr << k if v.nil?}
		arr.map(&:to_sym)
	end

	def no_topics?
		topics.empty?
	end

	def log_missing_attrs (time)
		File.open(Padrino.root("public", "log/dailyscore/#{time}.txt") , 'a+') { |file| file.write("DailyScore,#{self.id},#{self.nil_attributes}\n") }
	end

	def self.get_trophies_since(d)
		@trophies = ActiveSupport::OrderedHash.new
		CURRENT_NAMES.each{|f| @trophies[f]=0}
		fields = CURRENT_NAMES.map(&:to_sym)

		self.since_day(d).select(fields).each do |day|
          object = day.attributes # AR to hash
          sample = day.attributes.values[-1]
          next if sample.nil? || sample.nan?

          winner = object.key(object.values.compact.min) # compact: without nil, then min value
          @trophies[winner] += 1
          end 

        @trophies.sort_by{|paper,trophies|trophies}.reverse

	end

	def self.get_scores_since(day)
		@totalDailyScores = {}

		CURRENT_NAMES.each{|f| @totalDailyScores[f]=0}
		@totalDailyScores['average']=0
		@totalDailyScores['size']=self.since_day(day).count

		self.since_day(day).select(CURRENT_NAMES.map(&:to_sym),:average).each do |d|

	          d.attributes.each_pair do |key,value|
	          	unless value.nil? || value.nan?
	          		@totalDailyScores[key] += value
	          	end
	          end
        end 

        @totalDailyScores.each_with_object({}) { |(key, value), hash| hash[key] = value.round(1) }

	end

	def just_created?
    	@just_created || false
  	end

  	def was_changed?
    	@just_changed || false
  	end

  	def changed_attribute_names
  		@changed_attrs
  	end

private

  # Set a flag indicating this model is just created

	def set_just_created
	    @just_created = true
	end

	def set_was_changed
	    @just_changed = changed.any?
	    @changed_attrs = changed
	end

end
