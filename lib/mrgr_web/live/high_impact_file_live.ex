defmodule MrgrWeb.HighImpactFileLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user
      repos = Mrgr.Repository.for_user_with_hif_rules(current_user)
      Mrgr.PubSub.subscribe_to_installation(current_user)

      slack_unconnected =
        !Mrgr.Installation.slack_connected?(socket.assigns.current_user.current_installation)

      socket
      |> assign(:form, nil)
      |> assign(:repos, repos)
      |> assign(:slack_unconnected, slack_unconnected)
      |> put_title("High Impact Files")
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("add-hif", %{"id" => repo_id}, socket) do
    repo = Mrgr.List.find(socket.assigns.repos, repo_id)
    changeset = empty_changeset()

    form = build_form(:create, repo, changeset)

    socket
    |> assign(:form, form)
    |> noreply()
  end

  def handle_event("edit-hif", %{"repo" => repo_id, "hif" => hif_id}, socket) do
    repo = Mrgr.List.find(socket.assigns.repos, repo_id)
    hif = Mrgr.List.find(repo.high_impact_file_rules, hif_id)
    changeset = %{build_changeset(hif) | action: :update}

    form = build_form(:edit, repo, changeset, hif)

    socket
    |> assign(:form, form)
    |> noreply()
  end

  def handle_event("form-change", %{"high_impact_file_rule" => params}, socket) do
    # used to trigger updates to label preview
    form = socket.assigns.form

    badge_preview = %{
      color: params["color"],
      name: params["name"]
    }

    # i'm only interested in the badge preview, but i need to set changeset
    # data here otherwise an unknown bug will clear out my :pattern field when
    # :name is changed (but only when adding a new hif).
    form = %{
      form
      | badge_preview: badge_preview,
        changeset: build_changeset(form.changeset.data, params)
    }

    socket
    |> assign(:form, form)
    |> noreply()
  end

  def handle_event("save-hif", %{"high_impact_file_rule" => params}, socket) do
    form = socket.assigns.form

    res =
      case form.action do
        :edit ->
          Mrgr.HighImpactFileRule.update(form.changeset.data, params)

        :create ->
          params
          |> Map.put("repository_id", form.repo.id)
          |> Map.put("user_id", socket.assigns.current_user.id)
          |> Map.put("source", :user)
          |> Mrgr.HighImpactFileRule.create()
      end

    case res do
      {:ok, _hif} ->
        socket
        |> assign(:form, nil)
        |> hide_detail()
        |> Flash.put(:info, "Alert saved ✌️")
        |> noreply()

      {:error, changeset} ->
        form = %{form | changeset: changeset}

        socket
        |> assign(:form, form)
        |> noreply()
    end
  end

  def handle_event("delete-hif", _params, socket) do
    hif = socket.assigns.form.changeset.data

    case Mrgr.Repo.delete(hif) do
      {:ok, hif} ->
        repos = remove_hif_from_its_repo(socket.assigns.repos, hif)

        socket
        |> assign(:repos, repos)
        |> assign(:form, nil)
        |> hide_detail()
        |> Flash.put(:info, "Alert deleted ✌️")
        |> noreply()

      _que ->
        noreply(socket)
    end
  end

  def handle_info({:hif_updated, hif}, socket) do
    repos = update_hif_in_its_repo(socket.assigns.repos, hif)

    socket
    |> assign(:repos, repos)
    |> noreply()
  end

  def handle_info(%{event: @high_impact_file_rule_created, payload: hif}, socket) do
    repos = add_hif_to_its_repo(socket.assigns.repos, hif)

    socket
    |> assign(:repos, repos)
    |> noreply()
  end

  def handle_info(%{event: @high_impact_file_rule_updated, payload: hif}, socket) do
    repos = update_hif_in_its_repo(socket.assigns.repos, hif)

    socket
    |> assign(:repos, repos)
    |> noreply()
  end

  def handle_info(_uninteresting_event, socket) do
    noreply(socket)
  end

  defp remove_hif_from_its_repo(repos, hif) do
    repo = find_hif_repo(repos, hif)

    updated_hifs = Mrgr.List.remove(repo.high_impact_file_rules, hif)

    rebuild_repo_list_with_new_hifs(updated_hifs, repo, repos)
  end

  defp add_hif_to_its_repo(repos, hif) do
    repo = find_hif_repo(repos, hif)

    updated_hifs = [hif | repo.high_impact_file_rules]

    rebuild_repo_list_with_new_hifs(updated_hifs, repo, repos)
  end

  defp update_hif_in_its_repo(repos, hif) do
    repo = find_hif_repo(repos, hif)

    updated_hifs = Mrgr.List.replace(repo.high_impact_file_rules, hif)

    rebuild_repo_list_with_new_hifs(updated_hifs, repo, repos)
  end

  defp find_hif_repo(repos, hif) do
    Mrgr.List.find(repos, hif.repository_id)
  end

  defp rebuild_repo_list_with_new_hifs(hifs, repo, repos) do
    updated_repo = %{repo | high_impact_file_rules: hifs}

    Mrgr.List.replace(repos, updated_repo)
  end

  defp build_changeset(schema, params \\ %{}) do
    Mrgr.Schema.HighImpactFileRule.changeset(schema, params)
  end

  defp empty_changeset do
    %Mrgr.Schema.HighImpactFileRule{}
    |> build_changeset()
  end

  def build_form(:create, repo, changeset) do
    %{
      action: :create,
      repo: repo,
      changeset: changeset,
      badge_preview: %{
        color: changeset.data.color,
        name: nil
      }
    }
  end

  def build_form(:edit, repo, changeset, hif) do
    %{
      action: :edit,
      repo: repo,
      changeset: changeset,
      badge_preview: %{
        color: hif.color,
        name: hif.name
      }
    }
  end
end
