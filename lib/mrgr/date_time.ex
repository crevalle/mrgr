defmodule Mrgr.DateTime do
  # false if they're the same time
  def before?(dt1, dt2) do
    case DateTime.compare(dt1, dt2) do
      :lt -> true
      _ -> false
    end
  end

  # false if they're the same time
  def after?(dt1, dt2) do
    case DateTime.compare(dt1, dt2) do
      :gt -> true
      _ -> false
    end
  end

  def in_the_past?(dt) do
    before?(dt, now())
  end

  def in_the_future?(dt) do
    after?(dt, now())
  end

  def future?(dt) do
    dt
    |> DateTime.compare(now())
    |> case do
      :gt -> true
      _ -> false
    end
  end

  def now do
    DateTime.utc_now()
  end

  def safe_truncate(nil), do: nil

  def safe_truncate(dt) do
    DateTime.truncate(dt, :second)
  end
end
