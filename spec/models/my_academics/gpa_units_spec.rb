describe MyAcademics::GpaUnits do

  let(:uid) { random_id }
  let(:eight_digit_cs_id) { '87654321' }
  let(:ten_digit_cs_id) { random_cs_id }
  let(:edo_response) do
    {
      'pnp_taken' => 3,
      'pnp_passed' => 5
    }
  end
  let(:academic_roles) do
    {
      'law' => has_law_role
    }
  end
  let(:has_law_role) { false }
  let(:status_proxy) { HubEdos::AcademicStatus.new(user_id: uid, fake: true) }
  let(:transfer_credit_proxy) { CampusSolutions::TransferCredit.new(user_id: uid, fake: true) }

  subject do
    {}.tap { |feed| MyAcademics::GpaUnits.new(uid).merge feed }
  end

  context 'when legacy user but non-legacy term' do
    before do
      allow_any_instance_of(described_class).to receive(:lookup_campus_solutions_id).and_return eight_digit_cs_id
      allow(Settings.terms).to receive(:legacy_cutoff).and_return('spring-2010')
    end
    context 'CS data is ready to go' do
      it 'sources from Hub' do
        expect(CampusOracle::Queries).to receive(:get_student_info).never
        expect(HubEdos::AcademicStatus).to receive(:new).and_return status_proxy
        expect(subject[:gpaUnits][:cumulativeGpa]).to eq '3.8'
      end
    end
  end

  context 'when sourced from Hub academic status' do
    before do
      allow(HubEdos::AcademicStatus).to receive(:new).and_return status_proxy
    end

    context 'when auxiliary proxies provide data' do
      before do
        allow_any_instance_of(described_class).to receive(:lookup_campus_solutions_id).and_return ten_digit_cs_id
        allow(EdoOracle::Queries).to receive(:get_pnp_unit_count).and_return edo_response
        allow(CampusSolutions::TransferCredit).to receive(:new).and_return transfer_credit_proxy
        allow_any_instance_of(MyAcademics::MyAcademicRoles).to receive(:get_feed).and_return academic_roles
      end

      it 'translates GPA' do
        expect(subject[:gpaUnits][:cumulativeGpa]).to eq '3.8'
      end
      it 'translates total units' do
        expect(subject[:gpaUnits][:totalUnits]).to eq 73
      end
      it 'translates total units attempted' do
        expect(subject[:gpaUnits][:totalUnitsAttempted]).to eq 8
      end
      it 'provides the pass/no pass unit totals' do
        expect(subject[:gpaUnits][:totalUnitsTakenNotForGpa]).to eq 3
        expect(subject[:gpaUnits][:totalUnitsPassedNotForGpa]).to eq 5
      end
      it 'provides units transferred as the sum of transfer and test units' do
        expect(subject[:gpaUnits][:totalTransferAndTestingUnits]).to eq 75.2
      end

      context 'when student is active in a LAW career' do
        let(:has_law_role) { true }
        it 'suppresses the pass/no pass unit totals' do
          expect(subject[:gpaUnits][:totalUnitsTakenNotForGpa]).not_to be
          expect(subject[:gpaUnits][:totalUnitsPassedNotForGpa]).not_to be
        end
        it 'suppresses units transferred' do
          expect(subject[:gpaUnits][:totalTransferAndTestingUnits]).not_to be
        end
      end

      context 'when academic status feed is empty' do
        before { status_proxy.set_response(status: 200, body: '{}') }
        it 'gracefully provides an empty feed' do
          expect(subject[:gpaUnits]).to be
        end
      end

      context 'when academic status feed errors' do
        before { status_proxy.set_response(status: 502, body: '') }
        it 'reports error' do
          expect(subject[:gpaUnits][:errored]).to eq true
        end
      end

      context 'when academic status feed lacking some data' do
        before do
          status_proxy.override_json do |json|
            json['apiResponse']['response']['any']['students'][0]['academicStatuses'][0].delete 'cumulativeUnits'
          end
        end
        it 'returns what data it can' do
          expect(subject[:gpaUnits][:cumulativeGpa]).to be_present
          expect(subject[:gpaUnits][:totalUnits]).to be nil
        end
      end
    end

    context 'when CalNet campus solutions id lookup fails' do
      before do
        allow_any_instance_of(described_class).to receive(:lookup_campus_solutions_id).and_return nil
      end
      it 'cannot call the EDO query' do
        expect(subject[:gpaUnits][:totalUnitsTakenNotForGpa]).not_to be
        expect(subject[:gpaUnits][:totalUnitsPassedNotForGpa]).not_to be
      end
    end

    context 'when EDO DB provides no data' do
      before do
        allow_any_instance_of(described_class).to receive(:lookup_campus_solutions_id).and_return ten_digit_cs_id
        allow(EdoOracle::Queries).to receive(:get_pnp_unit_count).and_return nil
      end
      it 'cannot provide the pass/no pass unit totals' do
        expect(subject[:gpaUnits][:totalUnitsTakenNotForGpa]).not_to be
        expect(subject[:gpaUnits][:totalUnitsPassedNotForGpa]).not_to be
      end
    end

    context 'when the Transfer Credit API provides no data' do
      before do
        allow(CampusSolutions::TransferCredit).to receive(:new).and_return double(get: nil)
      end
      it 'cannot provide the units transferred' do
        expect(subject[:gpaUnits][:totalTransferAndTestingUnits]).not_to be
      end
    end
  end
end
