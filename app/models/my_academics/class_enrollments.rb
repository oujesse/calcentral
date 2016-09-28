module MyAcademics
  class ClassEnrollments < UserSpecificModel
    include SafeJsonParser
    include Cache::CachedFeed
    include Cache::UserCacheExpiry
    include CampusSolutions::EnrollmentCardFeatureFlagged

    # Used to identify different enrollment instruction presentations
    ENROLLMENT_INSTRUCTION_TYPES = {
      plan: [
        {instruction_type_code: 'fpf', match: '25000FPFU'},
        {instruction_type_code: 'haas_mba', match: '70141MBAG'},
        {instruction_type_code: 'haas_ewmba', match: '701E1MBAG'},
        {instruction_type_code: 'haas_execmba', match: '70364MBAG'},
      ],
      career: [
        {instruction_type_code: 'law', match: 'LAW'},
        {instruction_type_code: 'concurrent', match: 'UCBX'},
      ]
    }

    def get_feed_internal
      return {} unless is_feature_enabled && user_is_student?
      HashConverter.camelize({
        enrollmentTermInstructionTypes: get_enrollment_term_instruction_types,
        enrollmentTermInstructions: get_enrollment_term_instructions,
        enrollmentTermAcademicPlanner: get_enrollment_term_academic_planner,
        hasHolds: user_has_holds?,
        links: get_links
      })
    end

    def get_enrollment_term_instruction_types
      career_terms = get_active_career_terms
      instruction_types = get_enrollment_instruction_types
      term_instruction_types = []
      instruction_types.keys.each do |type_key|
        instruction_type = instruction_types[type_key]
        career_terms.each do |career_term|
          if (instruction_type[:career_code] == career_term[:acadCareer])
            term_instruction_types << instruction_type.merge({term: career_term.slice(:termId, :termDescr)})
          end
        end
      end
      term_instruction_types
    end

    def get_enrollment_term_academic_planner
      plans = {}
      get_active_term_ids.collect do |term_id|
        academic_plan = CampusSolutions::AcademicPlan.new(user_id: @uid, term_id: term_id).get
        plans[term_id] = academic_plan.try(:[], :feed)
      end
      plans
    end

    def get_enrollment_term_instructions
      instructions = {}
      get_active_term_ids.collect do |term_id|
        term_details = CampusSolutions::EnrollmentTerm.new(user_id: @uid, term_id: term_id).get
        instructions[term_id] = term_details.try(:[], :feed).try(:[], :enrollmentTerm)
      end
      instructions
    end

    def user_has_holds?
      has_holds = false
      response = get_academic_status
      if (holds = AcademicsModule.parse_hub_holds(response))
        has_holds = holds.to_a.length > 0
      end
      has_holds
    end

    def get_enrollment_instruction_types
      types = {}
      get_active_plans.each do |plan|
        type_code = get_enrollment_instruction_type_code(plan)
        career_code = plan[:career][:code]
        type_key = [type_code, career_code]
        types[type_key] = { instruction_type_code: type_code, career_code: career_code, academic_plans: [] } if types[type_key].blank?
        types[type_key][:academic_plans] << plan
      end
      types
    end

    def get_enrollment_instruction_type_code(plan)
      type_codes = []
      ENROLLMENT_INSTRUCTION_TYPES.each do |cpp_category, matchers|
        category_type_codes = matchers.select {|matcher| plan[cpp_category][:code] == matcher[:match]}
        type_codes.concat(category_type_codes)
      end
      type_codes.empty? ? 'default' : type_codes.first[:instruction_type_code]
    end

    def get_active_plans
      active_plans = []
      response = get_academic_status
      if (statuses = AcademicsModule.parse_hub_academic_statuses(response))
        statuses.each do |status|
          Array.wrap(status.try(:[], 'studentPlans')).each do |plan|
            active_plans << flatten_plan(plan)
          end
        end
      end
      active_plans.compact
    end

    def flatten_plan(plan)
      flat_plan = {career: {}, plan: {}}
      if (academic_plan = plan['academicPlan'])
        plan = academic_plan.try(:[], 'plan')
        academic_program = academic_plan.try(:[], 'academicProgram')
        career = academic_program.try(:[], 'academicCareer')
        program = academic_program.try(:[], 'program')
        flat_plan[:career].merge!({
          code: career.try(:[], 'code'),
          description: career.try(:[], 'description')
        })
        flat_plan[:plan].merge!({
          code: plan.try(:[], 'code'),
          description: plan.try(:[], 'description')
        })
      end
      flat_plan
    end

    def get_academic_status
      @academic_status ||= HubEdos::AcademicStatus.new({user_id: @uid}).get
    end

    def get_active_term_ids
      career_terms = get_active_career_terms
      return [] if career_terms.empty?
      career_terms.collect {|term| term[:termId] }.uniq
    end

    def get_active_career_terms
      get_career_terms = Proc.new do
        terms = CampusSolutions::EnrollmentTerms.new({user_id: @uid}).get
        terms.try(:[], :feed).try(:[], :enrollmentTerms)
      end
      @career_terms ||= get_career_terms.call
    end

    def get_links
      cs_links = {}

      campus_solutions_link_settings = [
        { feed_key: :uc_add_class_enrollment, cs_link_key: 'UC_CX_GT_SSCNTENRL_ADD', cs_link_params: {} },
        { feed_key: :uc_edit_class_enrollment, cs_link_key: 'UC_CX_GT_SSCNTENRL_UPD', cs_link_params: {} },
        { feed_key: :uc_view_class_enrollment, cs_link_key: 'UC_CX_GT_SSCNTENRL_VIEW', cs_link_params: {} },
      ]

      campus_solutions_link_settings.each do |setting|
        link = fetch_link(setting[:cs_link_key], setting[:cs_link_params])
        cs_links[setting[:feed_key]] = link unless link.blank?
      end

      cs_links
    end

    def fetch_link(link_key, placeholders = {})
      link = CampusSolutions::Link.new.get_url(link_key, placeholders).try(:[], :link)
      logger.error "Could not retrieve CS link #{link_key} for Class Enrollments feed, uid = #{@uid}" unless link
      link
    end

    private

    def user_is_student?
      HubEdos::UserAttributes.new(user_id: @uid).has_role?(:student)
    end
  end
end
