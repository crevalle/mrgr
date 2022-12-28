defmodule Mrgr.Repo.Migrations.AddApprovingReviewCountToPRs do
  use Ecto.Migration

  def up do
    alter table(:pull_requests) do
      add(:approving_review_count, :integer, default: 0)
    end

    execute """
    CREATE OR REPLACE FUNCTION update_pr_approving_review_count()
    RETURNS TRIGGER
    LANGUAGE PLPGSQL
    AS
    $$

    BEGIN

    UPDATE pull_requests
    SET approving_review_count = (SELECT count(id)
                                  FROM pr_reviews
                                  WHERE state = 'approved'
                                  AND pr_reviews.pull_request_id = pull_requests.id)
    WHERE pull_requests.id in (OLD.pull_request_id, NEW.pull_request_id);

    RETURN NEW;

    END;
    $$
    """

    execute """
    CREATE TRIGGER update_pr_approving_review_count_trigger
    AFTER INSERT OR UPDATE OR DELETE ON pr_reviews
    FOR EACH row
    EXECUTE FUNCTION update_pr_approving_review_count();
    """
  end

  def down do
    alter table(:pull_requests) do
      remove(:approving_review_count)
    end

    execute """
    DROP TRIGGER IF EXISTS update_pr_approving_review_count_trigger ON pr_reviews;
    """

    execute """
    DROP FUNCTION IF EXISTS update_pr_approving_review_count;
    """
  end
end
