require "rails_helper"
require "pp"

RSpec.describe "Auth Endpoints", type: :request do
  let(:invite_code) { build(:invite_code) }
  let(:user) { build(:user) }

  before { invite_code.save }

  describe "POST /auth/sign_up" do
    context "without access code" do
      let(:invalid_attributes) do
        {
          first_name: "Test",
          last_name: "Smith",
          email: "test@smith.com",
          password: "hunter2",
          password_confirmation: "hunter2"
        }
      end

      before { post "/auth", params: { user: invalid_attributes } }
      it "returns HTTP code 302" do
        expect(response).to have_http_status(302)
      end

      it "redirects back to sign up page" do
        expect(response).to redirect_to(new_user_registration_path)
      end
    end

    context "with invalid access code" do
      let(:invalid_attributes) do
        {
          first_name: "Test",
          last_name: "Smith",
          email: "test@smith.com",
          password: "hunter2",
          password_confirmation: "hunter2",
          access_code: "some_dumb_code"
        }
      end

      before { post "/auth", params: { user: invalid_attributes } }
      it "returns HTTP code 302" do
        expect(response).to have_http_status(302)
      end

      it "redirects back to sign up page" do
        expect(response).to redirect_to(new_user_registration_path)
      end
    end

    context "with access code" do
      let(:valid_attributes) do
        # add password_confirm attribute to request..?
        attributes_for(:user, password_confirmation: user.password, access_code: invite_code.code)
      end

      before { post "/auth", params: { user: valid_attributes } }
      # redirects to homepage
      it "returns http code 302" do
        expect(response).to have_http_status(302)
      end
    end
  end

  describe "DELETE /auth" do
    let(:user) { create(:user) }

    it "allows users to deactivate their own account" do
      sign_in user
      delete user_registration_path
      expect(response).to have_http_status(302)
      expect(flash[:success]).to be_present
      expect(flash[:success]).to include("success", "deactivated")

      expect(User.find_by_id(user[:id])[:deleted_at]).to_not be_nil

      # check that user gets signed out because their account got deactivated
      get user_path(user[:id])
      expect(response).to have_http_status(403)
    end

    it "prevents users from signing in again" do
      sign_in user
      delete user_registration_path
      expect(response).to have_http_status(302)
      expect(flash[:success]).to be_present
      expect(flash[:success]).to include("success", "deactivated")
    end
  end
end
