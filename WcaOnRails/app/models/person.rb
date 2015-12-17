class Person < ActiveRecord::Base
  self.table_name = "Persons"
  self.primary_key = "id"
  has_one :user, foreign_key: "wca_id"
  has_many :results, foreign_key: "personId"
  has_many :competitions, -> { distinct }, through: :results

  alias_method :wca_id, :id

  def likely_delegates
    all_delegates = competitions.order(:year, :month, :day).map(&:delegates).flatten.select(&:any_kind_of_delegate?)
    if all_delegates.empty?
      return []
    end

    counts_by_delegate = all_delegates.each_with_object(Hash.new(0)) { |d, counts| counts[d] += 1 }
    most_frequent_delegate, count = counts_by_delegate.max_by { |delegate, count| count }
    most_recent_delegate = all_delegates.last

    [ most_frequent_delegate, most_recent_delegate ].uniq
  end

  def sub_ids
    Person.where(id: id).map(&:subId)
  end

  def dob
    year == 0 || month == 0 || day == 0 ? nil : Date.new(year, month, day)
  end

  def country_iso2
    c = Country.find(countryId)
    c ? c.iso2 : nil
  end

  def to_jsonable(include_private_info: false)
    json = {
      class: self.class.to_s.downcase,
      url: "/results/p.php?i=#{self.wca_id}",

      id: self.id,
      wca_id: self.wca_id,
      name: self.name,

      gender: self.gender,
      country_iso2: self.country_iso2,
    }

    if include_private_info
      json[:dob] = person.dob
    end

    # If there's a user for this Person, merge in all their data,
    # the Person's data takes priority, though.
    json = (user || User.new).to_jsonable.merge(json)

    json
  end
end
