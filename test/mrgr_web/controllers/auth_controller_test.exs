defmodule MrgrWeb.AuthControllerTest do
  use MrgrWeb.ConnCase
  import Mrgr.Factory

  describe "post_sign_in_path/2" do
    test "when a user is new" do
      conn = build_conn()
      new_user = build(:user, current_installation_id: nil)

      path = MrgrWeb.AuthController.post_sign_in_path(conn, new_user)
      assert path == "/onboarding"
    end

    test "when a user is returning" do
      conn = build_conn()
      new_user = build(:user, current_installation_id: 1)

      path = MrgrWeb.AuthController.post_sign_in_path(conn, new_user)
      assert path == "/pending-merges"
    end
  end
end
