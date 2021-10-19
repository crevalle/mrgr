defmodule Mrgr.DateMath do
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
    before?(dt, DateTime.utc_now())
  end

  def in_the_future?(dt) do
    after?(dt, DateTime.utc_now())
  end
end
