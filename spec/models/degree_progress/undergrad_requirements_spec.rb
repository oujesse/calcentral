describe DegreeProgress::UndergradRequirements do

  let(:model) { described_class.new(user_id) }
  let(:user_id) { '12345' }
  let(:emplid) { '12345678' }
  before do
    proxy_class = CampusSolutions::DegreeProgress::UndergradRequirements
    fake_proxy = proxy_class.new(user_id: user_id, fake: true)
    allow(proxy_class).to receive(:new).and_return fake_proxy
    allow(Settings.features).to receive(flag).and_return(true)
  end

  describe '#get_feed_internal' do
    let(:flag) { :cs_degree_progress_ugrd_advising }
    subject { model.get_feed_internal }

    it_behaves_like 'a proxy that observes a feature flag'
    it_behaves_like 'a proxy that returns undergraduate milestone data'

    it 'includes the Academic Progress Report link in the response' do
      expect(subject[:feed][:links]).to be
      expect(subject[:feed][:links][:academicProgressReport]).to be
      expect(subject[:feed][:links][:academicProgressReport][:url]).to eq 'https://bcswebqat.is.berkeley.edu/psp/bcsqat/EMPLOYEE/PSFT_CS/c/SSR_ADVISEE_OVRD.SAA_SS_DPR_ADB.GBL?EMPLID=25738808'
    end
  end
end
