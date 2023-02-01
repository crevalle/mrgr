import_if_available(Ecto.Query)
import_if_available(Ecto.Changeset)

alias Mrgr.Installation, as: I
alias Mrgr.Repo, as: R
alias Mrgr.PullRequest, as: PR

Code.require_file("test/support/factory.ex")
