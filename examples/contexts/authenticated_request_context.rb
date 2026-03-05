# A context that sets up authentication, tests the unauthenticated case,
# then lets you inject your authenticated tests via execute_tests.
#
# Expects the caller to define:
#   - http_method (e.g. :get, :post)
#   - endpoint_path (e.g. users_path)

RSpec.define_context :authenticated_request do
  let(:user) { create(:user) }
  let(:account) { user.accounts.first }

  before { sign_in user }

  describe "authentication" do
    context "without authentication" do
      before { sign_out user }

      it "redirects to login" do
        send(http_method, endpoint_path)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  execute_tests
end
