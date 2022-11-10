defmodule Mrgr.Github.API.Fake do
  def update_repo_settings(_repo, _params) do
    %{}
  end

  def update_branch_protection(_repo, _params) do
    %{}
  end

  def fetch_repository_settings_graphql(_repo) do
    %{"node" => %{}}
  end

  def get_new_installation_token(_installation) do
    []
  end

  def merge_pull_request(_client, _owner, _repo, _number, _message) do
    {:ok, %{"sha" => "0xdeadbeef"}}
  end

  def fetch_filtered_pulls(_installation, _repo, _opts) do
    %{}
  end

  def fetch_pulls_graphql(_installation, _repo) do
    %{
      "repository" => %{
        "pullRequests" => %{
          "edges" => []
        }
      }
    }
  end

  def fetch_issue_comments(_installation, _repo, _number) do
    []
  end

  def fetch_pr_review_comments(_installation, _repo, _number) do
    []
  end

  def fetch_members(_installation) do
    []
  end

  def fetch_mergeable_statuses_on_open_pull_requests(_repository) do
    %{
      "repository" => %{
        "pullRequests" => %{
          "edges" => [
            %{
              "node" => %{
                "id" => "PR_kwDOGGc3xc4uat-e",
                "mergeStateStatus" => "DIRTY",
                "mergeable" => "CONFLICTING",
                "number" => 19
              }
            },
            %{
              "node" => %{
                "id" => "PR_kwDOGGc3xc4-PQGc",
                "mergeStateStatus" => "BLOCKED",
                "mergeable" => "MERGEABLE",
                "number" => 32
              }
            },
            %{
              "node" => %{
                "id" => "PR_kwDOGGc3xc4_j-Vs",
                "mergeStateStatus" => "BLOCKED",
                "mergeable" => "MERGEABLE",
                "number" => 33
              }
            },
            %{
              "node" => %{
                "id" => "PR_kwDOGGc3xc5Bs6kZ",
                "mergeStateStatus" => "DIRTY",
                "mergeable" => "CONFLICTING",
                "number" => 38
              }
            }
          ]
        }
      }
    }
  end

  def fetch_most_pull_request_data(_pull_request) do
    %{
      "node" => %{
        "files" => %{
          "nodes" => [
            %{"changeType" => "MODIFIED", "path" => "assets/css/app.css"},
            %{"changeType" => "MODIFIED", "path" => "assets/tailwind.config.js"},
            %{"changeType" => "MODIFIED", "path" => "lib/mrgr_web.ex"},
            %{
              "changeType" => "MODIFIED",
              "path" => "lib/mrgr_web/components/form.ex"
            },
            %{
              "changeType" => "MODIFIED",
              "path" => "lib/mrgr_web/components/pending_merge.ex"
            },
            %{"changeType" => "MODIFIED", "path" => "lib/mrgr_web/components/ui.ex"},
            %{"changeType" => "MODIFIED", "path" => "lib/mrgr_web/live/nav_bar.ex"},
            %{
              "changeType" => "MODIFIED",
              "path" => "lib/mrgr_web/live/pending_merge_live.ex"
            },
            %{
              "changeType" => "MODIFIED",
              "path" => "lib/mrgr_web/templates/layout/live.html.heex"
            },
            %{
              "changeType" => "MODIFIED",
              "path" => "lib/mrgr_web/templates/layout/signed_in.html.heex"
            },
            %{"changeType" => "MODIFIED", "path" => "mix.exs"},
            %{"changeType" => "MODIFIED", "path" => "mix.lock"},
            %{"changeType" => "MODIFIED", "path" => "socks"}
          ]
        },
        "headRef" => %{
          "id" => "REF_kwDOGGc3xbtyZWZzL2hlYWRzL3BldGFsLWNvbXBvbmVudHM",
          "name" => "petal-components",
          "target" => %{"oid" => "b9294de8d07e6c8fae6e7c4069b9689d957dd1d2"}
        },
        "id" => "PR_kwDOGGc3xc5Bs6kZ",
        "mergeStateStatus" => "DIRTY",
        "mergeable" => "CONFLICTING",
        "number" => 38,
        "title" => "WIP"
      }
    }
  end

  def fetch_branch_protection(%{name: "no-branch-protection"}) do
    %{
      "documentation_url" => "https://docs.github.com/rest/reference/repos#get-branch-protection",
      "message" => "Branch not protected"
    }
  end

  def fetch_branch_protection(_repository) do
    %{
      "allow_deletions" => %{"enabled" => true},
      "allow_force_pushes" => %{"enabled" => true},
      "allow_fork_syncing" => %{"enabled" => false},
      "block_creations" => %{"enabled" => false},
      "enforce_admins" => %{
        "enabled" => false,
        "url" =>
          "https://api.github.com/repos/crevalle/mrgr/branches/master/protection/enforce_admins"
      },
      "lock_branch" => %{"enabled" => false},
      "required_conversation_resolution" => %{"enabled" => false},
      "required_linear_history" => %{"enabled" => false},
      "required_pull_request_reviews" => %{
        "dismiss_stale_reviews" => true,
        "require_code_owner_reviews" => false,
        "require_last_push_approval" => false,
        "required_approving_review_count" => 2,
        "url" =>
          "https://api.github.com/repos/crevalle/mrgr/branches/master/protection/required_pull_request_reviews"
      },
      "required_signatures" => %{
        "enabled" => false,
        "url" =>
          "https://api.github.com/repos/crevalle/mrgr/branches/master/protection/required_signatures"
      },
      "url" => "https://api.github.com/repos/crevalle/mrgr/branches/master/protection"
    }
  end

  def fetch_repository(_installation, _repository) do
    %{
      labels_url: "https://api.github.com/repos/crevalle/mrgr/labels{/name}",
      keys_url: "https://api.github.com/repos/crevalle/mrgr/keys{/key_id}",
      fork: false,
      owner: %{
        avatar_url: "https://avatars.githubusercontent.com/u/7728671?v=4",
        events_url: "https://api.github.com/users/crevalle/events{/privacy}",
        followers_url: "https://api.github.com/users/crevalle/followers",
        following_url: "https://api.github.com/users/crevalle/following{/other_user}",
        gists_url: "https://api.github.com/users/crevalle/gists{/gist_id}",
        gravatar_id: "",
        html_url: "https://github.com/crevalle",
        id: 7_728_671,
        login: "crevalle",
        node_id: "MDEyOk9yZ2FuaXphdGlvbjc3Mjg2NzE=",
        organizations_url: "https://api.github.com/users/crevalle/orgs",
        received_events_url: "https://api.github.com/users/crevalle/received_events",
        repos_url: "https://api.github.com/users/crevalle/repos",
        site_admin: false,
        starred_url: "https://api.github.com/users/crevalle/starred{/owner}{/repo}",
        subscriptions_url: "https://api.github.com/users/crevalle/subscriptions",
        type: "Organization",
        url: "https://api.github.com/users/crevalle"
      },
      hooks_url: "https://api.github.com/repos/crevalle/mrgr/hooks",
      id: 15_190_990,
      teams_url: "https://api.github.com/repos/crevalle/mrgr/teams",
      full_name: "crevalle/mrgr",
      git_commits_url: "https://api.github.com/repos/crevalle/mrgr/git/commits{/sha}",
      default_branch: "master",
      downloads_url: "https://api.github.com/repos/crevalle/mrgr/downloads",
      stargazers_url: "https://api.github.com/repos/crevalle/mrgr/stargazers",
      blobs_url: "https://api.github.com/repos/crevalle/mrgr/git/blobs{/sha}",
      collaborators_url:
        "https://api.github.com/repos/crevalle/mrgr/collaborators{/collaborator}",
      permissions: %{
        admin: false,
        maintain: false,
        pull: false,
        push: false,
        triage: false
      },
      node_id: "R_kgDOGGc3xQ",
      watchers_count: 0,
      notifications_url:
        "https://api.github.com/repos/crevalle/mrgr/notifications{?since,all,participating}",
      compare_url: "https://api.github.com/repos/crevalle/mrgr/compare/{base}...{head}",
      trees_url: "https://api.github.com/repos/crevalle/mrgr/git/trees{/sha}",
      clone_url: "https://github.com/crevalle/mrgr.git",
      has_downloads: true,
      subscription_url: "https://api.github.com/repos/crevalle/mrgr/subscription",
      url: "https://api.github.com/repos/crevalle/mrgr",
      statuses_url: "https://api.github.com/repos/crevalle/mrgr/statuses/{sha}",
      milestones_url: "https://api.github.com/repos/crevalle/mrgr/milestones{/number}",
      svn_url: "https://github.com/crevalle/mrgr",
      events_url: "https://api.github.com/repos/crevalle/mrgr/events",
      updated_at: "2018-11-11T02:11:58Z",
      created_at: "2013-12-14T18:54:06Z",
      html_url: "https://github.com/crevalle/mrgr",
      archived: false,
      allow_forking: false,
      pulls_url: "https://api.github.com/repos/crevalle/mrgr/pulls{/number}",
      mirror_url: nil,
      has_projects: true,
      has_wiki: true,
      topics: [],
      language: "Elixir",
      contributors_url: "https://api.github.com/repos/crevalle/mrgr/contributors",
      web_commit_signoff_required: false,
      issue_events_url: "https://api.github.com/repos/crevalle/mrgr/issues/events{/number}",
      forks: 0,
      merges_url: "https://api.github.com/repos/crevalle/mrgr/merges",
      deployments_url: "https://api.github.com/repos/crevalle/mrgr/deployments",
      visibility: "private",
      assignees_url: "https://api.github.com/repos/crevalle/mrgr/assignees{/user}",
      git_url: "git://github.com/crevalle/mrgr.git",
      forks_url: "https://api.github.com/repos/crevalle/mrgr/forks",
      tags_url: "https://api.github.com/repos/crevalle/mrgr/tags",
      open_issues: 6,
      size: 635,
      pushed_at: "2018-11-11T02:11:57Z",
      issues_url: "https://api.github.com/repos/crevalle/mrgr/issues{/number}",
      homepage: nil,
      private: true,
      disabled: false,
      forks_count: 0,
      git_tags_url: "https://api.github.com/repos/crevalle/mrgr/git/tags{/sha}",
      archive_url: "https://api.github.com/repos/crevalle/mrgr/{archive_format}{/ref}",
      comments_url: "https://api.github.com/repos/crevalle/mrgr/comments{/number}",
      has_pages: false,
      issue_comment_url: "https://api.github.com/repos/crevalle/mrgr/issues/comments{/number}",
      branches_url: "https://api.github.com/repos/crevalle/mrgr/branches{/branch}",
      description: nil,
      subscribers_url: "https://api.github.com/repos/crevalle/mrgr/subscribers",
      stargazers_count: 0,
      license: nil,
      commits_url: "https://api.github.com/repos/crevalle/mrgr/commits{/sha}",
      has_issues: true,
      git_refs_url: "https://api.github.com/repos/crevalle/mrgr/git/refs{/sha}",
      ssh_url: "git@github.com:crevalle/mrgr.git",
      releases_url: "https://api.github.com/repos/crevalle/mrgr/releases{/id}",
      is_template: false,
      name: "mrgr",
      languages_url: "https://api.github.com/repos/crevalle/mrgr/languages",
      open_issues_count: 6,
      contents_url: "https://api.github.com/repos/crevalle/mrgr/contents/{+path}",
      watchers: 0
    }
  end

  def fetch_repositories(_installation) do
    [
      %{
        labels_url: "https://api.github.com/repos/crevalle/node-cql-binary/labels{/name}",
        keys_url: "https://api.github.com/repos/crevalle/node-cql-binary/keys{/key_id}",
        fork: false,
        owner: %{
          avatar_url: "https://avatars.githubusercontent.com/u/7728671?v=4",
          events_url: "https://api.github.com/users/crevalle/events{/privacy}",
          followers_url: "https://api.github.com/users/crevalle/followers",
          following_url: "https://api.github.com/users/crevalle/following{/other_user}",
          gists_url: "https://api.github.com/users/crevalle/gists{/gist_id}",
          gravatar_id: "",
          html_url: "https://github.com/crevalle",
          id: 7_728_671,
          login: "crevalle",
          node_id: "MDEyOk9yZ2FuaXphdGlvbjc3Mjg2NzE=",
          organizations_url: "https://api.github.com/users/crevalle/orgs",
          received_events_url: "https://api.github.com/users/crevalle/received_events",
          repos_url: "https://api.github.com/users/crevalle/repos",
          site_admin: false,
          starred_url: "https://api.github.com/users/crevalle/starred{/owner}{/repo}",
          subscriptions_url: "https://api.github.com/users/crevalle/subscriptions",
          type: "Organization",
          url: "https://api.github.com/users/crevalle"
        },
        hooks_url: "https://api.github.com/repos/crevalle/node-cql-binary/hooks",
        id: 8_829_819,
        teams_url: "https://api.github.com/repos/crevalle/node-cql-binary/teams",
        full_name: "crevalle/node-cql-binary",
        git_commits_url:
          "https://api.github.com/repos/crevalle/node-cql-binary/git/commits{/sha}",
        default_branch: "master",
        downloads_url: "https://api.github.com/repos/crevalle/node-cql-binary/downloads",
        stargazers_url: "https://api.github.com/repos/crevalle/node-cql-binary/stargazers",
        blobs_url: "https://api.github.com/repos/crevalle/node-cql-binary/git/blobs{/sha}",
        collaborators_url:
          "https://api.github.com/repos/crevalle/node-cql-binary/collaborators{/collaborator}",
        permissions: %{
          admin: false,
          maintain: false,
          pull: false,
          push: false,
          triage: false
        },
        node_id: "MDEwOlJlcG9zaXRvcnk4ODI5ODE5",
        watchers_count: 0,
        notifications_url:
          "https://api.github.com/repos/crevalle/node-cql-binary/notifications{?since,all,participating}",
        compare_url:
          "https://api.github.com/repos/crevalle/node-cql-binary/compare/{base}...{head}",
        trees_url: "https://api.github.com/repos/crevalle/node-cql-binary/git/trees{/sha}",
        clone_url: "https://github.com/crevalle/node-cql-binary.git",
        has_downloads: true,
        subscription_url: "https://api.github.com/repos/crevalle/node-cql-binary/subscription",
        url: "https://api.github.com/repos/crevalle/node-cql-binary",
        statuses_url: "https://api.github.com/repos/crevalle/node-cql-binary/statuses/{sha}",
        milestones_url:
          "https://api.github.com/repos/crevalle/node-cql-binary/milestones{/number}",
        svn_url: "https://github.com/crevalle/node-cql-binary",
        events_url: "https://api.github.com/repos/crevalle/node-cql-binary/events",
        updated_at: "2014-12-28T21:34:35Z",
        created_at: "2013-03-17T04:20:26Z",
        html_url: "https://github.com/crevalle/node-cql-binary",
        archived: false,
        allow_forking: true,
        pulls_url: "https://api.github.com/repos/crevalle/node-cql-binary/pulls{/number}",
        mirror_url: nil,
        has_projects: true,
        has_wiki: true,
        topics: [],
        language: "JavaScript",
        contributors_url: "https://api.github.com/repos/crevalle/node-cql-binary/contributors",
        web_commit_signoff_required: false,
        issue_events_url:
          "https://api.github.com/repos/crevalle/node-cql-binary/issues/events{/number}",
        forks: 0,
        merges_url: "https://api.github.com/repos/crevalle/node-cql-binary/merges",
        deployments_url: "https://api.github.com/repos/crevalle/node-cql-binary/deployments",
        visibility: "public",
        assignees_url: "https://api.github.com/repos/crevalle/node-cql-binary/assignees{/user}",
        git_url: "git://github.com/crevalle/node-cql-binary.git",
        forks_url: "https://api.github.com/repos/crevalle/node-cql-binary/forks",
        tags_url: "https://api.github.com/repos/crevalle/node-cql-binary/tags",
        open_issues: 0,
        size: 148,
        pushed_at: "2013-03-23T21:49:41Z",
        issues_url: "https://api.github.com/repos/crevalle/node-cql-binary/issues{/number}",
        homepage: nil,
        private: false,
        disabled: false,
        forks_count: 0,
        git_tags_url: "https://api.github.com/repos/crevalle/node-cql-binary/git/tags{/sha}",
        archive_url:
          "https://api.github.com/repos/crevalle/node-cql-binary/{archive_format}{/ref}",
        comments_url: "https://api.github.com/repos/crevalle/node-cql-binary/comments{/number}",
        has_pages: false,
        issue_comment_url:
          "https://api.github.com/repos/crevalle/node-cql-binary/issues/comments{/number}",
        branches_url: "https://api.github.com/repos/crevalle/node-cql-binary/branches{/branch}",
        description: nil,
        subscribers_url: "https://api.github.com/repos/crevalle/node-cql-binary/subscribers",
        stargazers_count: 0,
        license: nil,
        commits_url: "https://api.github.com/repos/crevalle/node-cql-binary/commits{/sha}",
        has_issues: true,
        git_refs_url: "https://api.github.com/repos/crevalle/node-cql-binary/git/refs{/sha}",
        ssh_url: "git@github.com:crevalle/node-cql-binary.git",
        releases_url: "https://api.github.com/repos/crevalle/node-cql-binary/releases{/id}",
        is_template: false,
        name: "node-cql-binary",
        languages_url: "https://api.github.com/repos/crevalle/node-cql-binary/languages",
        open_issues_count: 0,
        contents_url: "https://api.github.com/repos/crevalle/node-cql-binary/contents/{+path}",
        watchers: 0
      },
      %{
        labels_url: "https://api.github.com/repos/crevalle/mood_tracker/labels{/name}",
        keys_url: "https://api.github.com/repos/crevalle/mood_tracker/keys{/key_id}",
        fork: false,
        owner: %{
          avatar_url: "https://avatars.githubusercontent.com/u/7728671?v=4",
          events_url: "https://api.github.com/users/crevalle/events{/privacy}",
          followers_url: "https://api.github.com/users/crevalle/followers",
          following_url: "https://api.github.com/users/crevalle/following{/other_user}",
          gists_url: "https://api.github.com/users/crevalle/gists{/gist_id}",
          gravatar_id: "",
          html_url: "https://github.com/crevalle",
          id: 7_728_671,
          login: "crevalle",
          node_id: "MDEyOk9yZ2FuaXphdGlvbjc3Mjg2NzE=",
          organizations_url: "https://api.github.com/users/crevalle/orgs",
          received_events_url: "https://api.github.com/users/crevalle/received_events",
          repos_url: "https://api.github.com/users/crevalle/repos",
          site_admin: false,
          starred_url: "https://api.github.com/users/crevalle/starred{/owner}{/repo}",
          subscriptions_url: "https://api.github.com/users/crevalle/subscriptions",
          type: "Organization",
          url: "https://api.github.com/users/crevalle"
        },
        hooks_url: "https://api.github.com/repos/crevalle/mood_tracker/hooks",
        id: 15_190_989,
        teams_url: "https://api.github.com/repos/crevalle/mood_tracker/teams",
        full_name: "crevalle/mood_tracker",
        git_commits_url: "https://api.github.com/repos/crevalle/mood_tracker/git/commits{/sha}",
        default_branch: "master",
        downloads_url: "https://api.github.com/repos/crevalle/mood_tracker/downloads",
        stargazers_url: "https://api.github.com/repos/crevalle/mood_tracker/stargazers",
        blobs_url: "https://api.github.com/repos/crevalle/mood_tracker/git/blobs{/sha}",
        collaborators_url:
          "https://api.github.com/repos/crevalle/mood_tracker/collaborators{/collaborator}",
        permissions: %{
          admin: false,
          maintain: false,
          pull: false,
          push: false,
          triage: false
        },
        node_id: "MDEwOlJlcG9zaXRvcnkxNTE5MDk4OQ==",
        watchers_count: 0,
        notifications_url:
          "https://api.github.com/repos/crevalle/mood_tracker/notifications{?since,all,participating}",
        compare_url: "https://api.github.com/repos/crevalle/mood_tracker/compare/{base}...{head}",
        trees_url: "https://api.github.com/repos/crevalle/mood_tracker/git/trees{/sha}",
        clone_url: "https://github.com/crevalle/mood_tracker.git",
        has_downloads: true,
        subscription_url: "https://api.github.com/repos/crevalle/mood_tracker/subscription",
        url: "https://api.github.com/repos/crevalle/mood_tracker",
        statuses_url: "https://api.github.com/repos/crevalle/mood_tracker/statuses/{sha}",
        milestones_url: "https://api.github.com/repos/crevalle/mood_tracker/milestones{/number}",
        svn_url: "https://github.com/crevalle/mood_tracker",
        events_url: "https://api.github.com/repos/crevalle/mood_tracker/events",
        updated_at: "2018-11-11T02:11:58Z",
        created_at: "2013-12-14T18:54:06Z",
        html_url: "https://github.com/crevalle/mood_tracker",
        archived: false,
        allow_forking: false,
        pulls_url: "https://api.github.com/repos/crevalle/mood_tracker/pulls{/number}",
        mirror_url: nil,
        has_projects: true,
        has_wiki: true,
        topics: [],
        language: "Ruby",
        contributors_url: "https://api.github.com/repos/crevalle/mood_tracker/contributors",
        web_commit_signoff_required: false,
        issue_events_url:
          "https://api.github.com/repos/crevalle/mood_tracker/issues/events{/number}",
        forks: 0,
        merges_url: "https://api.github.com/repos/crevalle/mood_tracker/merges",
        deployments_url: "https://api.github.com/repos/crevalle/mood_tracker/deployments",
        visibility: "private",
        assignees_url: "https://api.github.com/repos/crevalle/mood_tracker/assignees{/user}",
        git_url: "git://github.com/crevalle/mood_tracker.git",
        forks_url: "https://api.github.com/repos/crevalle/mood_tracker/forks",
        tags_url: "https://api.github.com/repos/crevalle/mood_tracker/tags",
        open_issues: 6,
        size: 635,
        pushed_at: "2018-11-11T02:11:57Z",
        issues_url: "https://api.github.com/repos/crevalle/mood_tracker/issues{/number}",
        homepage: nil,
        private: true,
        disabled: false,
        forks_count: 0,
        git_tags_url: "https://api.github.com/repos/crevalle/mood_tracker/git/tags{/sha}",
        archive_url: "https://api.github.com/repos/crevalle/mood_tracker/{archive_format}{/ref}",
        comments_url: "https://api.github.com/repos/crevalle/mood_tracker/comments{/number}",
        has_pages: false,
        issue_comment_url:
          "https://api.github.com/repos/crevalle/mood_tracker/issues/comments{/number}",
        branches_url: "https://api.github.com/repos/crevalle/mood_tracker/branches{/branch}",
        description: nil,
        subscribers_url: "https://api.github.com/repos/crevalle/mood_tracker/subscribers",
        stargazers_count: 0,
        license: nil,
        commits_url: "https://api.github.com/repos/crevalle/mood_tracker/commits{/sha}",
        has_issues: true,
        git_refs_url: "https://api.github.com/repos/crevalle/mood_tracker/git/refs{/sha}",
        ssh_url: "git@github.com:crevalle/mood_tracker.git",
        releases_url: "https://api.github.com/repos/crevalle/mood_tracker/releases{/id}",
        is_template: false,
        name: "mood_tracker",
        languages_url: "https://api.github.com/repos/crevalle/mood_tracker/languages",
        open_issues_count: 6,
        contents_url: "https://api.github.com/repos/crevalle/mood_tracker/contents/{+path}",
        watchers: 0
      },
      %{
        labels_url: "https://api.github.com/repos/crevalle/mrgr/labels{/name}",
        keys_url: "https://api.github.com/repos/crevalle/mrgr/keys{/key_id}",
        fork: false,
        owner: %{
          avatar_url: "https://avatars.githubusercontent.com/u/7728671?v=4",
          events_url: "https://api.github.com/users/crevalle/events{/privacy}",
          followers_url: "https://api.github.com/users/crevalle/followers",
          following_url: "https://api.github.com/users/crevalle/following{/other_user}",
          gists_url: "https://api.github.com/users/crevalle/gists{/gist_id}",
          gravatar_id: "",
          html_url: "https://github.com/crevalle",
          id: 7_728_671,
          login: "crevalle",
          node_id: "MDEyOk9yZ2FuaXphdGlvbjc3Mjg2NzE=",
          organizations_url: "https://api.github.com/users/crevalle/orgs",
          received_events_url: "https://api.github.com/users/crevalle/received_events",
          repos_url: "https://api.github.com/users/crevalle/repos",
          site_admin: false,
          starred_url: "https://api.github.com/users/crevalle/starred{/owner}{/repo}",
          subscriptions_url: "https://api.github.com/users/crevalle/subscriptions",
          type: "Organization",
          url: "https://api.github.com/users/crevalle"
        },
        hooks_url: "https://api.github.com/repos/crevalle/mrgr/hooks",
        id: 15_190_990,
        teams_url: "https://api.github.com/repos/crevalle/mrgr/teams",
        full_name: "crevalle/mrgr",
        git_commits_url: "https://api.github.com/repos/crevalle/mrgr/git/commits{/sha}",
        default_branch: "master",
        downloads_url: "https://api.github.com/repos/crevalle/mrgr/downloads",
        stargazers_url: "https://api.github.com/repos/crevalle/mrgr/stargazers",
        blobs_url: "https://api.github.com/repos/crevalle/mrgr/git/blobs{/sha}",
        collaborators_url:
          "https://api.github.com/repos/crevalle/mrgr/collaborators{/collaborator}",
        permissions: %{
          admin: false,
          maintain: false,
          pull: false,
          push: false,
          triage: false
        },
        node_id: "R_kgDOGGc3xQ",
        watchers_count: 0,
        notifications_url:
          "https://api.github.com/repos/crevalle/mrgr/notifications{?since,all,participating}",
        compare_url: "https://api.github.com/repos/crevalle/mrgr/compare/{base}...{head}",
        trees_url: "https://api.github.com/repos/crevalle/mrgr/git/trees{/sha}",
        clone_url: "https://github.com/crevalle/mrgr.git",
        has_downloads: true,
        subscription_url: "https://api.github.com/repos/crevalle/mrgr/subscription",
        url: "https://api.github.com/repos/crevalle/mrgr",
        statuses_url: "https://api.github.com/repos/crevalle/mrgr/statuses/{sha}",
        milestones_url: "https://api.github.com/repos/crevalle/mrgr/milestones{/number}",
        svn_url: "https://github.com/crevalle/mrgr",
        events_url: "https://api.github.com/repos/crevalle/mrgr/events",
        updated_at: "2018-11-11T02:11:58Z",
        created_at: "2013-12-14T18:54:06Z",
        html_url: "https://github.com/crevalle/mrgr",
        archived: false,
        allow_forking: false,
        pulls_url: "https://api.github.com/repos/crevalle/mrgr/pulls{/number}",
        mirror_url: nil,
        has_projects: true,
        has_wiki: true,
        topics: [],
        language: "Elixir",
        contributors_url: "https://api.github.com/repos/crevalle/mrgr/contributors",
        web_commit_signoff_required: false,
        issue_events_url: "https://api.github.com/repos/crevalle/mrgr/issues/events{/number}",
        forks: 0,
        merges_url: "https://api.github.com/repos/crevalle/mrgr/merges",
        deployments_url: "https://api.github.com/repos/crevalle/mrgr/deployments",
        visibility: "private",
        assignees_url: "https://api.github.com/repos/crevalle/mrgr/assignees{/user}",
        git_url: "git://github.com/crevalle/mrgr.git",
        forks_url: "https://api.github.com/repos/crevalle/mrgr/forks",
        tags_url: "https://api.github.com/repos/crevalle/mrgr/tags",
        open_issues: 6,
        size: 635,
        pushed_at: "2018-11-11T02:11:57Z",
        issues_url: "https://api.github.com/repos/crevalle/mrgr/issues{/number}",
        homepage: nil,
        private: true,
        disabled: false,
        forks_count: 0,
        git_tags_url: "https://api.github.com/repos/crevalle/mrgr/git/tags{/sha}",
        archive_url: "https://api.github.com/repos/crevalle/mrgr/{archive_format}{/ref}",
        comments_url: "https://api.github.com/repos/crevalle/mrgr/comments{/number}",
        has_pages: false,
        issue_comment_url: "https://api.github.com/repos/crevalle/mrgr/issues/comments{/number}",
        branches_url: "https://api.github.com/repos/crevalle/mrgr/branches{/branch}",
        description: nil,
        subscribers_url: "https://api.github.com/repos/crevalle/mrgr/subscribers",
        stargazers_count: 0,
        license: nil,
        commits_url: "https://api.github.com/repos/crevalle/mrgr/commits{/sha}",
        has_issues: true,
        git_refs_url: "https://api.github.com/repos/crevalle/mrgr/git/refs{/sha}",
        ssh_url: "git@github.com:crevalle/mrgr.git",
        releases_url: "https://api.github.com/repos/crevalle/mrgr/releases{/id}",
        is_template: false,
        name: "mrgr",
        languages_url: "https://api.github.com/repos/crevalle/mrgr/languages",
        open_issues_count: 6,
        contents_url: "https://api.github.com/repos/crevalle/mrgr/contents/{+path}",
        watchers: 0
      }
    ]
  end

  def head_commit(_pull_request, _installation) do
    %{}
  end

  def commits(_pull_request, _installation) do
    %{}
  end
end
