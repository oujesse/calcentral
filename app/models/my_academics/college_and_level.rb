module MyAcademics
  class CollegeAndLevel
    extend Cache::Cacheable
    include AcademicsModule
    include ClassLogger
    include Cache::UserCacheExpiry

    def merge(data)
      college_and_level = self.class.fetch_from_cache @uid do
        response = Bearfacts::Profile.new(user_id: @uid).get
        feed = response.delete :feed
        # The Bear Facts API can return empty profiles if the user is no longer (or not yet) considered an active student.
        # Partial profiles can be returned for incoming students around the start of the term.
        if (feed.nil? || feed['studentProfile']['studentGeneralProfile'].blank? || feed['studentProfile']['ugGradFlag'].blank?)
          response[:empty] = true
        else
          response.merge! parse_feed(feed)
        end
        response[:termName] = parse_term_name feed
        response
      end
      data[:collegeAndLevel] = college_and_level
    end

    def parse_feed(feed)
      careers = []
      ug_grad_flag = feed['studentProfile']['ugGradFlag'].to_text
      case ug_grad_flag.upcase
        when 'U'
          careers << 'Undergraduate'
        when 'G'
          careers << 'Graduate'
        else
          logger.error("Unknown ugGradFlag '#{ug_grad_flag}' for user #{@uid}")
          return {}
      end

      general_profile = feed['studentProfile']['studentGeneralProfile']

      level = general_profile['corpEducLevel'].to_text.titleize
      nonAPLevel = general_profile['nonAPLevel'].to_text.titleize
      futureTBLevel = general_profile['futureTBLevel'].to_text.titleize

      majors = []
      primary_college_abbv = general_profile['collegePrimary'].to_text
      primary_college = Berkeley::Colleges.get(primary_college_abbv)
      primary_major = Berkeley::Majors.get(general_profile['majorPrimary'].to_text)

      # this code block is not very DRY, but that makes it easier to understand the wacky requirements. See CLC-2017 for background.
      if primary_college_abbv.in?(['GRAD DIV', 'LAW', 'CONCURNT'])
        if primary_major == 'Double' || primary_major == 'Triple'
          majors << {
            :college => (general_profile['collegeSecond'].blank? ? primary_college : Berkeley::Colleges.get(general_profile['collegeSecond'].to_text)),
            :major => Berkeley::Majors.get(general_profile['majorSecond'].to_text)
          }
          majors << {
            :college => Berkeley::Colleges.get(general_profile['collegeThird'].to_text),
            :major => Berkeley::Majors.get(general_profile['majorThird'].to_text)
          }
          if primary_major == 'Triple'
            majors << {
              :college => Berkeley::Colleges.get(general_profile['collegeFourth'].to_text),
              :major => Berkeley::Majors.get(general_profile['majorFourth'].to_text)
            }
          end
        else
          majors << {
            :college => primary_college,
            :major => primary_major
          }
        end
      else
        if primary_major == 'Double' || primary_major == 'Triple'
          majors << {
            :college => primary_college,
            :major => Berkeley::Majors.get(general_profile['majorSecond'].to_text)
          }
          majors << {
            :college => '',
            :major => Berkeley::Majors.get(general_profile['majorThird'].to_text)
          }
          if primary_major == 'Triple'
            majors << {
              :college => '',
              :major => Berkeley::Majors.get(general_profile['majorFourth'].to_text)
            }
          end
        else
          majors << {
            :college => primary_college,
            :major => primary_major
          }
        end
      end

      feed = {
        careers: careers,
        level: level,
        futureTelebearsLevel: futureTBLevel,
        majors: majors
      }
      feed[:nonApLevel] = nonAPLevel if nonAPLevel.present? && nonAPLevel != level
      feed
    end

    def parse_term_name(feed)
      if (feed.nil? || feed['studentProfile']['termName'].blank? || feed['studentProfile']['termYear'].blank?)
        Berkeley::Terms.fetch.current.to_english
      else
        "#{feed['studentProfile']['termName'].to_text} #{feed['studentProfile']['termYear'].to_text}"
      end
    end
  end
end
