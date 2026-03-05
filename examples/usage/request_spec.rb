# Example: Using :authenticated_request in a request spec
#
# The context handles authentication setup and tests the unauthenticated case.
# Your tests inside the block run in an authenticated state.

require "rails_helper"

RSpec.describe "Projects", type: :request do
  let(:http_method) { :get }
  let(:endpoint_path) { projects_path }

  in_context :authenticated_request do
    describe "GET /projects" do
      it "returns 200" do
        get projects_path

        expect(response).to have_http_status(:ok)
      end

      it "lists the user's projects" do
        project = create(:project, account: account)

        get projects_path

        expect(response.body).to include(project.name)
      end
    end
  end
end
