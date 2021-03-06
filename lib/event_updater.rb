module DiscourseCalendar
  class EventUpdater
    def self.update(post)
      op = post.topic.first_post
      dates = post.local_dates

      # if we don’t have any date it's not an event anymore
      if dates.empty?
        DiscourseCalendar::EventDestroyer.destroy(op, post.post_number.to_s)
        op.publish_change_to_clients!(:calendar_change)
        return
      end

      first_date = dates[0]
      if first_date['time']
        from = Time.strptime("#{first_date['date']} #{first_date['time']} UTC", "%Y-%m-%d %H:%M:%S %Z")
      else
        from = Time.strptime("#{first_date['date']} UTC", "%Y-%m-%d %Z").beginning_of_day
      end

      if dates.count == 2
        second_date = dates[1]

        if second_date['time']
          to = Time.strptime("#{second_date['date']} #{second_date['time']} UTC", "%Y-%m-%d %H:%M:%S %Z")
        else
          to = Time.strptime("#{second_date['date']} UTC", "%Y-%m-%d %Z").end_of_day
        end
      end

      post_number = post.post_number.to_s

      current_details = op.custom_fields[DiscourseCalendar::CALENDAR_DETAILS_CUSTOM_FIELD] || {}

      detail = []
      detail[DiscourseCalendar::MESSAGE_INDEX] = post.excerpt(15, strip_links: true, text_entities: true).tr("\n", " ")
      detail[DiscourseCalendar::USERNAME_INDEX] = post.user.username_lower
      detail[DiscourseCalendar::FROM_INDEX] = from.iso8601.to_s
      detail[DiscourseCalendar::TO_INDEX] = to.iso8601.to_s if to

      # investigate why sometimes it has been saved as an array
      if current_details.kind_of?(Array)
        current_details = current_details[0]
      end
      current_details[post_number] = detail

      op.custom_fields[DiscourseCalendar::CALENDAR_DETAILS_CUSTOM_FIELD] = current_details
      op.save_custom_fields(true)
      op.publish_change_to_clients!(:calendar_change)
    end
  end
end
